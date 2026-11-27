import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/models/cookie_model.dart';
import '../../../../data/repositories/cookie_repository.dart';
import '../../../../data/services/connectivity_service.dart';
import '../../../../domain/cookie_jar/cookie_messages.dart';

/// A notice to show once as a Snackbar.
class CookieMessage {
  const CookieMessage(
    this.text, {
    this.long = false,
    this.actionLabel,
    this.onAction,
  });

  final String text;

  /// Long for warnings, short for confirmations.
  final bool long;

  final String? actionLabel;
  final void Function()? onAction;
}

/// Why a photo is or is not on screen.
enum PhotoStatus { ready, offline, failed, missing }

class PhotoLoad {
  const PhotoLoad(this.status, [this.bytes]);

  final PhotoStatus status;
  final Uint8List? bytes;
}

/// State and actions of the jar screen, its list sheet and the detail dialog.
class CookieJarViewModel extends ChangeNotifier {
  CookieJarViewModel({CookieRepository? repository, this._onlineChanges})
    : _repository = repository ?? CookieRepository.shared;

  static const connectionDebounce = Duration(seconds: 2);

  final CookieRepository _repository;
  final Stream<bool> Function()? _onlineChanges;
  final _messages = StreamController<CookieMessage>.broadcast();
  StreamSubscription<List<CookieModel>>? _cookiesSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  Timer? _debounce;
  bool _disposed = false;

  List<CookieModel> _cookies = const [];
  List<CookieModel> _today = const [];
  bool _loading = true;
  bool _budgetChecked = false;
  bool _isOnline = true;

  Stream<CookieMessage> get messages => _messages.stream;

  /// True until the first read of the database arrives.
  bool get loading => _loading;

  bool get isOnline => _isOnline;

  /// Today's cookies, the ones the jar draws (10 at most).
  List<CookieModel> get today => _today;

  /// Cookies in the jar, for the first tab of the list.
  List<CookieModel> get inJar => _cookies.where((c) => c.isActive).toList();

  /// Eaten cookies, for the history tab.
  List<CookieModel> get eaten => _cookies.where((c) => !c.isActive).toList();

  /// Cookies with something still waiting to upload (shown with ⏳).
  int get pendingCount => _cookies.where((c) => !c.isSynced).length;

  void start() {
    _cookiesSubscription ??= _repository.watchCookies().listen(_onCookies);
    _connectionSubscription ??=
        (_onlineChanges?.call() ?? ConnectivityService().onlineChanges).listen(
          _onConnectionChanged,
        );
    unawaited(_firstLoad());
  }

  Future<void> _firstLoad() async {
    _isOnline = await _repository.isOnline();
    _notify();
    await _syncWithCloud();
  }

  void _onCookies(List<CookieModel> cookies) {
    _cookies = cookies;
    _today = _repository.todaysCookies(cookies);
    _loading = false;
    _notify();
    if (!_budgetChecked) {
      _budgetChecked = true;
      unawaited(_repository.enforceImageBudget(_today));
    }
  }

  void _onConnectionChanged(bool online) {
    _debounce?.cancel();
    _debounce = Timer(connectionDebounce, () {
      if (online == _isOnline) return;
      _isOnline = online;
      _notify();
      if (online) {
        _show(const CookieMessage(CookieMessages.backOnline));
        unawaited(_syncWithCloud(afterReconnect: true));
      } else {
        _show(const CookieMessage(CookieMessages.wentOffline, long: true));
      }
    });
  }

  Future<void> _syncWithCloud({bool afterReconnect = false}) async {
    final hadPending = pendingCount > 0;
    final sync = await _repository.sync();
    final refresh = await _repository.refreshFromCloud();
    if (_disposed) return;

    if (refresh.offline && refresh.neverDownloaded) {
      _show(
        CookieMessage(
          CookieMessages.cookiesInCloud,
          long: true,
          actionLabel: CookieMessages.retry,
          onAction: () => unawaited(_syncWithCloud()),
        ),
      );
    } else if (refresh.failed || sync.failed) {
      _show(const CookieMessage(CookieMessages.syncFailed));
    }
    if (refresh.arrived > 0) {
      _show(
        CookieMessage(CookieMessages.arrivedFromOtherDevices(refresh.arrived)),
      );
    }
    for (final (title, finalTitle) in refresh.renamed) {
      _show(
        CookieMessage(
          CookieMessages.existedOnTwoPhones(title, finalTitle),
          long: true,
        ),
      );
    }
    if (afterReconnect && hadPending && sync.allBackedUp) {
      _show(const CookieMessage(CookieMessages.allBackedUp));
    }
    await _repository.prefetchToday(_today);
  }

  /// The latest version of a cookie (a dialog may hold an older copy).
  CookieModel? cookieById(String id) {
    for (final cookie in _cookies) {
      if (cookie.id == id) return cookie;
    }
    return null;
  }

  /// Called when the detail opens, for the disk budget's LRU order.
  Future<void> opened(CookieModel cookie) => _repository.markOpened(cookie.id);

  /// The photo for the detail: RAM, then the private file, then the cloud.
  Future<PhotoLoad> loadPhoto(CookieModel cookie) async {
    if (!cookie.hasImage) return const PhotoLoad(PhotoStatus.missing);
    final local = await _repository.photoOf(cookie);
    if (local != null) return PhotoLoad(PhotoStatus.ready, local);
    if (!await _repository.isOnline()) {
      _show(const CookieMessage(CookieMessages.pictureNeedsInternet));
      return const PhotoLoad(PhotoStatus.offline);
    }
    try {
      final downloaded = await _repository.downloadPhoto(cookie);
      return downloaded == null
          ? const PhotoLoad(PhotoStatus.missing)
          : PhotoLoad(PhotoStatus.ready, downloaded);
    } on Exception {
      return const PhotoLoad(PhotoStatus.failed);
    }
  }

  Future<void> eat(CookieModel cookie) async {
    await _repository.eat(cookie.id);
    _show(
      CookieMessage(
        CookieMessages.eaten,
        actionLabel: CookieMessages.undo,
        onAction: () => unawaited(_repository.returnToJar(cookie.id)),
      ),
    );
  }

  Future<void> returnToJar(CookieModel cookie) async {
    await _repository.returnToJar(cookie.id);
    _show(CookieMessage(CookieMessages.backInJar(cookie.title)));
  }

  Future<void> deleteForever(CookieModel cookie) async {
    await _repository.deleteForever(cookie.id);
    final online = await _repository.isOnline();
    _show(
      online
          ? const CookieMessage(CookieMessages.deleted)
          : const CookieMessage(CookieMessages.deletedOffline, long: true),
    );
  }

  Future<void> created(CreatedCookie created) async {
    if (created.wasRenamed) {
      _show(
        CookieMessage(
          CookieMessages.renamed(created.typedTitle, created.cookie.title),
          long: true,
        ),
      );
      return;
    }
    final online = await _repository.isOnline();
    _show(
      online
          ? const CookieMessage(CookieMessages.added)
          : const CookieMessage(CookieMessages.savedOffline, long: true),
    );
  }

  void _show(CookieMessage message) {
    if (!_disposed) _messages.add(message);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    _cookiesSubscription?.cancel();
    _connectionSubscription?.cancel();
    _messages.close();
    super.dispose();
  }
}
