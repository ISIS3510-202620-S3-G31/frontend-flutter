import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/models/fortune_card_model.dart';
import '../../../../data/models/fortune_model.dart';
import '../../../../data/repositories/analytics_repository.dart';
import '../../../../data/repositories/fortune_repository.dart';

/// The moments of a visit: picking a cookie, watching it open and reading it.
enum FortunePhase { choosing, opening, revealed }

class FortuneCookieViewModel extends ChangeNotifier {
  FortuneCookieViewModel({
    FortuneRepository? repository,
    AnalyticsRepository? analytics,
    Duration? openingTime,
  }) : _repository = repository ?? FortuneRepository(),
       _analytics = analytics ?? AnalyticsRepository(),
       openingTime = openingTime ?? const Duration(milliseconds: 2700);

  static const toolId = 'fortune_cookie';
  static const toolName = 'Fortune cookie';

  final FortuneRepository _repository;
  final AnalyticsRepository _analytics;

  /// How long the cookie takes to reach the middle, shake, split and let the
  /// paper out. The phrase is ready long before, so the wait is not noticed.
  final Duration openingTime;

  bool _disposed = false;
  Future<void>? _tableLoad;

  FortunePhase _phase = FortunePhase.choosing;
  List<TableFortune> _table = const [];
  int _chosenIndex = -1;
  Fortune? _opened;
  int _chancesLeft = -1;
  List<Fortune> _recents = const [];
  Fortune? _preview;
  String? _message;
  List<Fortune> _kept = const [];
  List<FortuneCard> _cards = const [];
  bool _sharing = false;
  StreamSubscription<bool>? _onlineChanges;

  /// The fortunes the user kept, newest first.
  List<Fortune> get kept => _kept;

  /// The cards the user shared, newest first.
  List<FortuneCard> get cards => _cards;

  /// True while a card is being drawn.
  bool get isSharing => _sharing;

  /// Draws the card of [fortune] the first time, saves it to the gallery and
  /// opens the share sheet. Later it reuses the same image.
  Future<void> share(Fortune fortune) async {
    if (_sharing) return;
    _sharing = true;
    _notify();
    try {
      final result = await _repository.cardFor(fortune);
      _cards = await _repository.cards();
      if (result.isNew) {
        _message = 'Saved in your gallery and in Shared';
        unawaited(
          _analytics.logToolStep(toolId: toolId, stepName: 'card_shared'),
        );
      }
      _sharing = false;
      _notify();
      await _repository.openShareSheet(result.card);
    } on Exception catch (error) {
      debugPrint('[Fortune] Could not make the card: $error');
      _sharing = false;
      _message = "We couldn't make the image. Try again.";
      _notify();
    }
  }

  Future<void> shareAgain(FortuneCard card) => _repository.openShareSheet(card);

  Future<void> removeCard(FortuneCard card) async {
    await _repository.removeCard(card);
    _cards = await _repository.cards();
    _message = 'Removed from Shared';
    _notify();
  }

  FortunePhase get phase => _phase;
  List<TableFortune> get table => _table;
  int get chosenIndex => _chosenIndex;

  /// The phrase of the cookie opened in this visit.
  Fortune? get opened => _opened;

  /// -1 until it is read from the phone.
  int get chancesLeft => _chancesLeft;
  bool get hasChances => _chancesLeft != 0;
  List<Fortune> get recents => _recents;

  /// A recent phrase being read again; it costs no cookie.
  Fortune? get preview => _preview;

  /// The phrase in the middle of the table, if any.
  Fortune? get shownFortune => _preview ?? _opened;

  bool get isChoosing => _phase == FortunePhase.choosing && _preview == null;

  /// A cookie was opened, which is what completes the tool.
  bool get isCompleted => _opened != null;

  /// Only when, offline, the phone ran out of downloaded phrases and the
  /// table had to use the app's own.
  String? get offlineNotice {
    final offline = _table.any((cookie) => cookie.isOffline);
    final builtIn = _table.any(
      (cookie) => cookie.source == FortuneSource.builtIn,
    );
    return offline && builtIn
        ? "No internet and no saved cookies left, so these come from Ark's own jar."
        : null;
  }

  String? takeMessage() {
    final message = _message;
    _message = null;
    return message;
  }

  Future<void> load() async {
    _tableLoad = _loadTable();
    final chances = await _repository.chancesLeft();
    final recents = await _repository.recents();
    final kept = await _repository.favorites();
    final cards = await _repository.cards();
    if (_disposed) return;
    _chancesLeft = chances;
    _recents = recents;
    _kept = kept;
    _cards = cards;
    _notify();
    // Pending changes go up now and every time the connection returns.
    _onlineChanges ??= _repository.onlineChanges.listen((online) {
      if (online) unawaited(_sync());
    });
    unawaited(_sync());
  }

  Future<void> _sync() async {
    await _repository.sync();
    final kept = await _repository.favorites();
    if (_disposed) return;
    _kept = kept;
    _notify();
  }

  /// Whether [fortune] is in the Kept list.
  bool isKept(Fortune fortune) => _repository.isKept(fortune.id);

  /// Keeps the fortune or lets it go. Works offline: it is saved on the phone
  /// and goes up to the account when there is a connection.
  Future<void> toggleKept(Fortune fortune) async {
    final kept = await _repository.toggleKept(fortune);
    _kept = await _repository.favorites();
    _message = kept ? 'Kept' : 'Removed from Kept';
    _notify();
    unawaited(
      _analytics.logToolStep(
        toolId: toolId,
        stepName: kept ? 'favorite_added' : 'favorite_removed',
      ),
    );
    unawaited(_sync());
  }

  Future<void> _loadTable() async {
    final table = await _repository.table();
    if (_disposed) return;
    _table = table;
    _notify();
  }

  /// Opens the cookie at [index]. One per visit.
  Future<void> crack(int index) async {
    if (_phase != FortunePhase.choosing || _preview != null) return;
    if (_chancesLeft == 0) {
      _message = 'No cookies left today. Come back tomorrow.';
      _notify();
      return;
    }
    _phase = FortunePhase.opening;
    _chosenIndex = index;
    _notify();

    // The phrase is prepared while the animation runs.
    final opening = () async {
      await _tableLoad;
      final cookie = index < _table.length ? _table[index] : null;
      return cookie == null ? null : _repository.open(cookie);
    }();
    // The phrase is on the paper as soon as it is ready, long before the
    // paper comes out of the cookie.
    unawaited(
      opening.then((result) {
        if (_disposed || result == null || _phase != FortunePhase.opening) {
          return;
        }
        _opened = result.fortune;
        _notify();
      }, onError: (Object _) {}),
    );
    await Future<void>.delayed(openingTime);
    final result = await opening.catchError((Object _) => null);
    if (_disposed) return;

    if (result == null) {
      _phase = FortunePhase.choosing;
      _chosenIndex = -1;
      _chancesLeft = await _repository.chancesLeft();
      _message = "This cookie didn't open. Try another one.";
      _notify();
      return;
    }
    _opened = result.fortune;
    _chancesLeft = result.remainingChances;
    _phase = FortunePhase.revealed;
    _recents = await _repository.recents();
    _notify();
    unawaited(
      _analytics.logToolStep(toolId: toolId, stepName: 'cookie_opened'),
    );
    unawaited(
      _analytics.completeToolSession(toolId: toolId, toolName: toolName),
    );
  }

  void openRecent(Fortune fortune) {
    if (!isChoosing) return;
    _preview = fortune;
    _notify();
  }

  void closeRecent() {
    if (_preview == null) return;
    _preview = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _onlineChanges?.cancel();
    super.dispose();
  }
}
