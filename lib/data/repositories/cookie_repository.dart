import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/cookie_jar/cookie_image_budget.dart';
import '../../domain/cookie_jar/cookie_jar_rules.dart';
import '../../domain/cookie_jar/cookie_rules.dart';
import '../../utils/uuid.dart';
import '../models/cookie_model.dart';
import '../services/local/cookie_dao.dart';
import '../services/local/cookie_image_store.dart';
import '../services/local/cookie_memory_cache.dart';

/// A cookie just saved, and whether its title had to change.
class CreatedCookie {
  const CreatedCookie(this.cookie, {required this.typedTitle});

  final CookieModel cookie;

  /// The title as the user typed it (cleaned).
  final String typedTitle;

  /// True when the title already existed and got a `-N` suffix.
  bool get wasRenamed => cookie.title != typedTitle;
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
    String? Function()? currentUserId,
    DateTime Function()? now,
  }) : _dao = dao ?? CookieDao(),
       _images = images ?? CookieImageStore(),
       _memory = memory ?? CookieMemoryCache(),
       _currentUserId = currentUserId ?? _firebaseUserId,
       _now = now ?? DateTime.now;

  static final shared = CookieRepository();

  static String? _firebaseUserId() => FirebaseAuth.instance.currentUser?.uid;

  static final _dayFormat = DateFormat('yyyy-MM-dd');

  final CookieDao _dao;
  final CookieImageStore _images;
  final CookieMemoryCache _memory;
  final String? Function() _currentUserId;
  final DateTime Function() _now;

  final _changes = StreamController<void>.broadcast();

  final Map<String, Set<String>> _titleKeys = {};

  String? get userId => _currentUserId();

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
    notifyChanged();
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
    notifyChanged();
    return changed;
  }


  Future<CookieModel> deleteForever(String cookieId) async {
    final cookie = await _require(cookieId);
    if (!cookie.canBeDeletedForever) {
      throw const CookieRuleException(
        'Only eaten cookies can be deleted forever',
      );
    }
    await _dao.delete(cookie.userId, cookie.id);
    final path = cookie.localImagePath;
    if (path != null) await _images.delete(path);
    _memory.remove(cookie.id);
    _titleKeys[cookie.userId]?.remove(cookie.titleKey);
    notifyChanged();
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

  Future<CookieModel> _require(String cookieId) async {
    final cookie = await _dao.byId(_requireUser(), cookieId);
    if (cookie == null) throw StateError('Cookie $cookieId does not exist.');
    return cookie;
  }
}
