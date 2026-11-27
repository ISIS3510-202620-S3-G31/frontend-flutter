import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/cookie_jar/cookie_image_budget.dart';
import '../../domain/cookie_jar/cookie_jar_rules.dart';
import '../../domain/cookie_jar/cookie_rules.dart';
import '../../utils/uuid.dart';
import '../models/cookie_model.dart';
import '../services/connectivity_service.dart';
import '../services/local/cookie_dao.dart';
import '../services/local/cookie_image_store.dart';
import '../services/local/cookie_memory_cache.dart';
import '../services/local/cookie_sync_preferences.dart';
import '../services/remote/cookie_remote_service.dart';

/// A cookie just saved, and whether its title had to change.
class CreatedCookie {
  const CreatedCookie(this.cookie, {required this.typedTitle});

  final CookieModel cookie;

  /// The title as the user typed it (cleaned).
  final String typedTitle;

  /// True when the title already existed and got a `-N` suffix.
  bool get wasRenamed => cookie.title != typedTitle;
}

/// What a round of uploads left behind.
class SyncReport {
  const SyncReport({
    this.offline = false,
    this.failed = false,
    this.uploaded = 0,
    this.pending = 0,
  });

  /// Nothing was tried: there is no network.
  final bool offline;

  /// The network dropped or was too slow halfway; the rest waits.
  final bool failed;

  /// Cookies (or deletes) that reached the cloud in this round.
  final int uploaded;

  /// Cookies and deletes still waiting to upload.
  final int pending;

  bool get allBackedUp => !offline && !failed && pending == 0;
}

/// What a download of the cloud's metadata brought.
class RefreshReport {
  const RefreshReport({
    this.offline = false,
    this.failed = false,
    this.neverDownloaded = false,
    this.arrived = 0,
    this.renamed = const [],
  });

  final bool offline;
  final bool failed;

  /// This phone never brought this account's cookies (a new phone).
  final bool neverDownloaded;

  /// Cookies created on another phone that are now here.
  final int arrived;

  /// Titles two phones created offline: (title, the one now renamed).
  final List<(String, String)> renamed;
}

class CookieRuleException implements Exception {
  const CookieRuleException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The single entry point of the Cookie Jar data.
class CookieRepository {
  CookieRepository({
    CookieDao? dao,
    CookieImageStore? images,
    CookieMemoryCache? memory,
    CookieRemoteService? remote,
    ConnectivityChecker? connectivity,
    this._onlineChanges,
    CookieSyncPreferences? syncPreferences,
    String? Function()? currentUserId,
    DateTime Function()? now,
  }) : _dao = dao ?? CookieDao(),
       _images = images ?? CookieImageStore(),
       _memory = memory ?? CookieMemoryCache(),
       _customRemote = remote,
       _customConnectivity = connectivity,
       _syncPreferences = syncPreferences ?? const CookieSyncPreferences(),
       _currentUserId = currentUserId ?? _firebaseUserId,
       _now = now ?? DateTime.now;

  static final shared = CookieRepository();

  static String? _firebaseUserId() => FirebaseAuth.instance.currentUser?.uid;

  static final _dayFormat = DateFormat('yyyy-MM-dd');

  final CookieDao _dao;
  final CookieImageStore _images;
  final CookieMemoryCache _memory;
  final CookieRemoteService? _customRemote;
  final ConnectivityChecker? _customConnectivity;
  final Stream<bool> Function()? _onlineChanges;
  final CookieSyncPreferences _syncPreferences;
  final String? Function() _currentUserId;
  final DateTime Function() _now;

  /// Built on first use, so creating the repository never touches Firebase.
  late final CookieRemoteService _remote =
      _customRemote ?? CookieRemoteService();
  late final ConnectivityChecker _connectivity =
      _customConnectivity ?? ConnectivityService();

  final _changes = StreamController<void>.broadcast();

  final Map<String, Set<String>> _titleKeys = {};

  Future<SyncReport>? _syncing;

  /// A change arrived while a sync was running: run one more round after it.
  bool _syncAgain = false;

  Future<RefreshReport>? _refreshing;
  StreamSubscription<bool>? _autoSync;

  String? get userId {
    try {
      return _currentUserId();
    } on Exception {
      return null;
    }
  }

  String _requireUser() {
    final uid = userId;
    if (uid == null) throw StateError('No user is signed in.');
    return uid;
  }

  int get _nowMillis => _now().millisecondsSinceEpoch;

  /// The phone's date as `yyyy-MM-dd`, which decides today's 10.
  String get todayKey => _dayFormat.format(_now());

  Stream<List<CookieModel>> watchCookies() {
    late final StreamController<List<CookieModel>> controller;
    StreamSubscription<void>? changes;

    Future<void> emit() async {
      final uid = userId;
      final cookies = uid == null ? const <CookieModel>[] : await _dao.all(uid);
      if (!controller.isClosed) controller.add(cookies);
    }

    controller = StreamController(
      onListen: () {
        // Subscribed before the first read, so no change can slip between.
        changes = _changes.stream.listen((_) => emit());
        emit();
      },
      onCancel: () => changes?.cancel(),
    );
    return controller.stream;
  }

  Future<List<CookieModel>> cookies() async => _dao.all(_requireUser());

  /// Tells every listener that the data changed.
  void notifyChanged() => _changes.add(null);

  List<CookieModel> todaysCookies(List<CookieModel> cookies) =>
      CookieJarRules.dailyPick(cookies, userId: userId ?? '', dayKey: todayKey);

  Future<Set<String>> titleKeys() async {
    final uid = _requireUser();
    return _titleKeys[uid] ??= await _dao.titleKeys(uid);
  }

  Future<String> finalTitleFor(String title) async =>
      CookieRules.uniqueTitle(title, await titleKeys());

  
  Future<CreatedCookie> create({
    required String title,
    required String text,
    Uint8List? photo,
  }) async {
    final uid = _requireUser();
    final problem = CookieRules.validationError(title, text);
    if (problem != null) throw CookieRuleException(problem);

    final id = newUuid();
    final now = _nowMillis;
    final localPath = photo == null ? null : await _images.save(uid, id, photo);
    var cookie = CookieModel(
      id: id,
      userId: uid,
      title: await finalTitleFor(title),
      text: text.trim(),
      hasImage: photo != null,
      localImagePath: localPath,
      lastOpenedAt: now,
      createdAt: now,
      updatedAt: now,
    );
    try {
      await _dao.insert(cookie);
    } on DatabaseException catch (error) {
      if (!error.isUniqueConstraintError()) rethrow;

      _titleKeys.remove(uid);
      cookie = cookie.copyWith(title: await finalTitleFor(title));
      await _dao.insert(cookie);
    }

    (await titleKeys()).add(cookie.titleKey);
    if (photo != null) _memory.put(id, photo);
    _afterWrite();
    return CreatedCookie(cookie, typedTitle: CookieRules.cleanTitle(title));
  }

  /// Moves a cookie from the jar to the history. It is a change of state, not a deletion, so it can come back.
  Future<CookieModel> eat(String cookieId) =>
      _changeState(cookieId, CookieState.eaten);

  Future<CookieModel> returnToJar(String cookieId) =>
      _changeState(cookieId, CookieState.active);

  Future<CookieModel> _changeState(String cookieId, CookieState state) async {
    final cookie = await _require(cookieId);
    final changed = cookie.copyWith(
      state: state,
      updatedAt: _nowMillis,
      isSynced: false,
    );
    await _dao.update(changed);
    _afterWrite();
    return changed;
  }


  Future<CookieModel> deleteForever(String cookieId) async {
    final cookie = await _require(cookieId);
    if (!cookie.canBeDeletedForever) {
      throw const CookieRuleException(
        'Only eaten cookies can be deleted forever',
      );
    }
    await _dao.addPendingDelete(cookie.userId, cookie.id);
    await _dao.delete(cookie.userId, cookie.id);
    final path = cookie.localImagePath;
    if (path != null) await _images.delete(path);
    _memory.remove(cookie.id);
    _titleKeys[cookie.userId]?.remove(cookie.titleKey);
    _afterWrite();
    return cookie;
  }


  Future<void> markOpened(String cookieId) async {
    final cookie = await _dao.byId(_requireUser(), cookieId);
    if (cookie == null) return;
    await _dao.update(cookie.copyWith(lastOpenedAt: _nowMillis));
  }

  Future<Uint8List?> photoOf(CookieModel cookie) async {
    if (!cookie.hasImage) return null;
    final cached = _memory.get(cookie.id);
    if (cached != null) return cached;
    final path = cookie.localImagePath;
    if (path == null) return null;
    final photo = await _images.read(path);
    if (photo != null) _memory.put(cookie.id, photo);
    return photo;
  }

  Future<Uint8List?> downloadPhoto(CookieModel cookie) async {
    if (!cookie.hasImage) return null;
    final local = await photoOf(cookie);
    if (local != null) return local;
    final jpeg = await _remote.downloadImage(cookie.userId, cookie.id);
    if (jpeg == null) return null;
    final path = await _images.save(cookie.userId, cookie.id, jpeg);
    final current = await _dao.byId(cookie.userId, cookie.id);
    if (current != null) {
      await _dao.update(current.copyWith(localImagePath: path));
    }
    _memory.put(cookie.id, jpeg);
    return jpeg;
  }

  Future<int> prefetchToday(List<CookieModel> today) async {
    final missing = today.where((c) => c.hasImage && !c.hasLocalImage);
    if (missing.isEmpty || !await isOnline()) return 0;
    final results = await Future.wait(
      missing.map((cookie) async {
        try {
          return await downloadPhoto(cookie) != null;
        } on Exception {
          return false;
        }
      }),
    );
    final arrived = results.where((ok) => ok).length;
    if (arrived > 0) notifyChanged();
    return arrived;
  }

  Future<void> enforceImageBudget(List<CookieModel> today) async {
    final uid = _requireUser();
    final withFile = (await _dao.all(uid)).where((c) => c.hasLocalImage);
    final stored = [
      for (final cookie in withFile)
        StoredCookieImage(
          cookieId: cookie.id,
          bytes: await _images.sizeOf(cookie.localImagePath!),
          lastOpenedAt: cookie.lastOpenedAt,
          isSynced: cookie.isSynced && cookie.remoteImageUrl != null,
        ),
    ];
    final evict = CookieImageBudget.toEvict(
      stored,
      protectedIds: {for (final cookie in today) cookie.id},
    );
    if (evict.isEmpty) return;
    for (final cookie in withFile.where((c) => evict.contains(c.id))) {
      await _images.delete(cookie.localImagePath!);
      await _dao.update(cookie.copyWith(clearLocalImagePath: true));
      _memory.remove(cookie.id);
    }
    notifyChanged();
  }

  void _afterWrite() {
    notifyChanged();
    unawaited(sync());
  }

  Future<bool> isOnline() async {
    try {
      return await _connectivity.isOnline();
    } on Exception {
      return true;
    }
  }

  void startAutoSync() {
    if (_autoSync != null) return;
    final changes =
        _onlineChanges?.call() ?? ConnectivityService().onlineChanges;
    _autoSync = changes.where((online) => online).listen((_) {
      unawaited(sync());
    });
    unawaited(sync());
  }

  Future<SyncReport> sync() {
    final running = _syncing;
    if (running != null) {
      _syncAgain = true;
      return running;
    }
    return _syncing = _runSync();
  }

  Future<SyncReport> _runSync() async {
    try {
      SyncReport report;
      do {
        _syncAgain = false;
        report = await _syncOnce();
      } while (_syncAgain);
      return report;
    } finally {
      _syncing = null;
    }
  }

  @visibleForTesting
  Future<void> whenIdle() async {
    while (_syncing != null || _refreshing != null) {
      await _syncing;
      await _refreshing;
    }
  }

  Future<SyncReport> _syncOnce() async {
    final uid = userId;
    if (uid == null) return const SyncReport(offline: true);
    if (!await isOnline()) {
      return SyncReport(offline: true, pending: await _pendingCount(uid));
    }
    var uploaded = 0;
    try {
      for (final id in await _dao.pendingDeletes(uid)) {
        await _remote.delete(uid, id);
        await _dao.removePendingDelete(uid, id);
        uploaded++;
      }
      for (final cookie in await _dao.unsynced(uid)) {
        await _upload(uid, cookie);
        uploaded++;
      }
      return SyncReport(uploaded: uploaded, pending: await _pendingCount(uid));
    } on Exception catch (error) {
      debugPrint('[CookieJar] Sync will retry later: $error');
      return SyncReport(
        failed: true,
        uploaded: uploaded,
        pending: await _pendingCount(uid),
      );
    }
  }

  Future<int> _pendingCount(String uid) async =>
      (await _dao.unsynced(uid)).length +
      (await _dao.pendingDeletes(uid)).length;

  Future<void> _upload(String uid, CookieModel cookie) async {
    var url = cookie.remoteImageUrl;
    final path = cookie.localImagePath;
    if (cookie.hasImage && url == null && path != null) {
      final jpeg = await _images.read(path);
      if (jpeg != null) url = await _remote.uploadImage(uid, cookie.id, jpeg);
    }
    final cloudWon = await _remote.push(cookie.copyWith(remoteImageUrl: url));

    final current = await _dao.byId(uid, cookie.id);
    if (current == null) return;
    if (cloudWon != null) {
      String? title;
      if (cloudWon.titleKey != current.titleKey) {
        final keys = await _dao.titleKeys(uid)
          ..remove(current.titleKey);
        if (keys.contains(cloudWon.titleKey)) {
          title = CookieRules.uniqueTitle(cloudWon.title, keys);
        }
      }
      await _dao.update(_withCloudData(cloudWon, current, title: title));
      _titleKeys.remove(uid);
    } else {
      await _dao.update(
        current.copyWith(
          remoteImageUrl: url,
          isSynced: current.updatedAt == cookie.updatedAt,
        ),
      );
    }
    notifyChanged();
  }

  static CookieModel _withCloudData(
    CookieModel cloud,
    CookieModel local, {
    String? title,
  }) => CookieModel(
    id: local.id,
    userId: local.userId,
    title: title ?? cloud.title,
    text: cloud.text,
    state: cloud.state,
    hasImage: cloud.hasImage,
    localImagePath: cloud.hasImage ? local.localImagePath : null,
    remoteImageUrl: cloud.remoteImageUrl ?? local.remoteImageUrl,
    lastOpenedAt: local.lastOpenedAt,
    receivedFrom: cloud.receivedFrom,
    createdAt: cloud.createdAt,
    updatedAt: cloud.updatedAt,
    isSynced: title == null,
  );

  Future<RefreshReport> refreshFromCloud() =>
      _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<RefreshReport> _refresh() async {
    final uid = userId;
    if (uid == null) return const RefreshReport(offline: true);
    final local = {for (final c in await _dao.all(uid)) c.id: c};
    if (!await isOnline()) {
      return RefreshReport(
        offline: true,
        neverDownloaded:
            local.isEmpty && !await _syncPreferences.hasDownloaded(uid),
      );
    }
    final List<CookieModel> cloud;
    try {
      cloud = await _remote.fetchAll(uid);
    } on Exception catch (error) {
      debugPrint('[CookieJar] Could not fetch the cloud cookies: $error');
      return const RefreshReport(failed: true);
    }

    final pendingDeletes = await _dao.pendingDeletes(uid);
    final idByKey = {for (final c in local.values) c.titleKey: c.id};
    final renamed = <(String, String)>[];
    var arrived = 0;
    var changed = false;

    String freeTitle(String title) =>
        CookieRules.uniqueTitle(title, idByKey.keys.toSet());

    for (final remote in cloud) {
      if (pendingDeletes.contains(remote.id)) continue;
      final mine = local[remote.id];
      final clashId = idByKey[remote.titleKey];
      final clash = clashId == null || clashId == remote.id
          ? null
          : local[clashId];

      if (mine == null) {
        var incoming = remote.copyWith(lastOpenedAt: remote.createdAt);
        if (clash != null) {
          if (remote.createdAt >= clash.createdAt) {
            incoming = incoming.copyWith(
              title: freeTitle(remote.title),
              updatedAt: math.max(_nowMillis, remote.updatedAt + 1),
              isSynced: false,
            );
            renamed.add((remote.title, incoming.title));
          } else {
            final older = clash.copyWith(
              title: freeTitle(clash.title),
              updatedAt: math.max(_nowMillis, clash.updatedAt + 1),
              isSynced: false,
            );
            idByKey.remove(clash.titleKey);
            idByKey[older.titleKey] = older.id;
            await _dao.update(older);
            renamed.add((clash.title, older.title));
          }
        }
        await _dao.insert(incoming);
        idByKey[incoming.titleKey] = incoming.id;
        arrived++;
        changed = true;
      } else if (remote.updatedAt > mine.updatedAt) {
        final newTitle = clash != null ? freeTitle(remote.title) : null;
        final merged = _withCloudData(remote, mine, title: newTitle);
        idByKey.remove(mine.titleKey);
        idByKey[merged.titleKey] = merged.id;
        await _dao.update(merged);
        changed = true;
      }
    }

    final inCloud = {for (final c in cloud) c.id};
    for (final mine in local.values) {
      if (mine.isSynced && !inCloud.contains(mine.id)) {
        await _dao.delete(uid, mine.id);
        final path = mine.localImagePath;
        if (path != null) await _images.delete(path);
        _memory.remove(mine.id);
        changed = true;
      }
    }

    await _syncPreferences.markDownloaded(uid);
    if (changed) {
      _titleKeys.remove(uid);
      notifyChanged();
    }
    if (renamed.isNotEmpty) unawaited(sync());
    return RefreshReport(arrived: arrived, renamed: renamed);
  }

  Future<CookieModel> _require(String cookieId) async {
    final cookie = await _dao.byId(_requireUser(), cookieId);
    if (cookie == null) throw StateError('Cookie $cookieId does not exist.');
    return cookie;
  }
}
