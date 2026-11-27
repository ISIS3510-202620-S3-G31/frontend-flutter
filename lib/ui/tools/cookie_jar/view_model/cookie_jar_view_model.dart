import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/models/cookie_model.dart';
import '../../../../data/repositories/cookie_repository.dart';
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

/// State and actions of the jar screen, its list sheet and the detail dialog.
class CookieJarViewModel extends ChangeNotifier {
  CookieJarViewModel({CookieRepository? repository})
    : _repository = repository ?? CookieRepository.shared;

  final CookieRepository _repository;
  final _messages = StreamController<CookieMessage>.broadcast();
  StreamSubscription<List<CookieModel>>? _cookiesSubscription;
  bool _disposed = false;

  List<CookieModel> _cookies = const [];
  List<CookieModel> _today = const [];
  bool _loading = true;
  bool _budgetChecked = false;

  Stream<CookieMessage> get messages => _messages.stream;

  /// True until the first read of the database arrives.
  bool get loading => _loading;

  /// Today's cookies, the ones the jar draws (10 at most).
  List<CookieModel> get today => _today;

  /// Cookies in the jar, for the first tab of the list.
  List<CookieModel> get inJar => _cookies.where((c) => c.isActive).toList();

  /// Eaten cookies, for the history tab.
  List<CookieModel> get eaten => _cookies.where((c) => !c.isActive).toList();

  void start() {
    _cookiesSubscription ??= _repository.watchCookies().listen(_onCookies);
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

  /// The latest version of a cookie (a dialog may hold an older copy).
  CookieModel? cookieById(String id) {
    for (final cookie in _cookies) {
      if (cookie.id == id) return cookie;
    }
    return null;
  }

  /// Called when the detail opens, for the disk budget's LRU order.
  Future<void> opened(CookieModel cookie) => _repository.markOpened(cookie.id);

  Future<Uint8List?> photoOf(CookieModel cookie) => _repository.photoOf(cookie);

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
    _show(const CookieMessage(CookieMessages.deleted));
  }

  void created(CreatedCookie created) {
    _show(
      created.wasRenamed
          ? CookieMessage(
              CookieMessages.renamed(created.typedTitle, created.cookie.title),
              long: true,
            )
          : const CookieMessage(CookieMessages.added),
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
    _cookiesSubscription?.cancel();
    _messages.close();
    super.dispose();
  }
}
