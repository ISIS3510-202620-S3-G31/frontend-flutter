import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/models/cookie_model.dart';
import '../../../../data/models/cookie_social_models.dart';
import '../../../../data/repositories/cookie_social_repository.dart';
import '../../../../data/services/connectivity_service.dart';
import '../../../../domain/cookie_jar/cookie_messages.dart';
import '../../../../domain/cookie_jar/cookie_social_rules.dart';
import 'cookie_jar_view_model.dart';

/// State of the social part of the Cookie Jar: the live gift inbox (with its badge), the friends screen and sending gifts.
class CookieSocialViewModel extends ChangeNotifier {
  CookieSocialViewModel({
    CookieSocialRepository? repository,
    this._onlineChanges,
  }) : _repository = repository ?? CookieSocialRepository();

  final CookieSocialRepository _repository;
  final Stream<bool> Function()? _onlineChanges;
  final _messages = StreamController<CookieMessage>.broadcast();
  StreamSubscription<InboxSnapshot>? _inboxSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  bool _disposed = false;

  bool? _isAdult;
  bool _isOnline = true;

  List<Gift> _inbox = const [];
  bool _inboxOffline = false;
  bool _inboxLoaded = false;
  final Set<String> _seenGifts = {};
  final Set<String> _accepting = {};

  PublicProfile? _profile;
  bool _friendsLoaded = false;
  bool _loadingFriends = false;
  bool _busy = false;
  List<Friend> _friends = const [];
  List<FriendRequest> _requests = const [];
  List<BlockedUser> _blocked = const [];
  List<SentGift> _sentGifts = const [];

  /// Opens the inbox screen; set by the jar screen for the "View" action.
  void Function()? onOpenInbox;

  Stream<CookieMessage> get messages => _messages.stream;

  /// Friends, gifts and the inbox only show when this is true.
  bool get isAdult => _isAdult ?? false;

  bool get isOnline => _isOnline;

  List<Gift> get inbox => _inbox;

  bool get inboxOffline => _inboxOffline || !_isOnline;

  bool get inboxLoaded => _inboxLoaded;

  /// The 🎁 badge, live.
  int get badgeCount => inboxOffline ? 0 : _inbox.length;

  bool isAccepting(Gift gift) => _accepting.contains(gift.shareId);

  PublicProfile? get profile => _profile;
  bool get friendsLoaded => _friendsLoaded;
  bool get loadingFriends => _loadingFriends;

  /// A social action is running: its buttons are disabled meanwhile.
  bool get busy => _busy;
  List<Friend> get friends => _friends;
  List<FriendRequest> get requests => _requests;
  List<BlockedUser> get blocked => _blocked;
  List<SentGift> get sentGifts => _sentGifts;

  Future<void> start() async {
    try {
      _isAdult = await _repository.isAdult();
    } on Exception {
      _isAdult = false;
    }
    _isOnline = await _repository.isOnline();
    _notify();
    if (!isAdult || _disposed) return;
    _connectionSubscription ??=
        (_onlineChanges?.call() ?? ConnectivityService().onlineChanges).listen((
          online,
        ) {
          _isOnline = online;
          _notify();
        });
    _inboxSubscription ??= _repository.watchInbox().listen(
      _onInbox,
      onError: (Object error) {
        debugPrint('[CookieJar] Inbox listener error: $error');
        _inboxOffline = true;
        _notify();
      },
    );
  }

  Future<void> _onInbox(InboxSnapshot snapshot) async {
    if (snapshot.fromCache) {
      _inboxOffline = true;
      _notify();
      return;
    }
    _inboxOffline = false;

    final expired = snapshot.gifts.where(_repository.isExpired).toList();
    if (expired.isNotEmpty) unawaited(_repository.deleteExpired(expired));

    final pending = <Gift>[];
    for (final gift in snapshot.gifts) {
      if (_repository.isExpired(gift)) continue;
      if (await _repository.isAccepted(gift)) {
        unawaited(_quietly(_repository.finishAccepted(gift)));
        continue;
      }
      pending.add(gift);
    }

    final fresh = pending.where((g) => !_seenGifts.contains(g.shareId));
    if (!_inboxLoaded) {
      if (pending.isNotEmpty) {
        _show(
          CookieMessage(
            CookieMessages.giftsWaiting(pending.length),
            long: true,
            actionLabel: CookieMessages.view,
            onAction: onOpenInbox,
          ),
        );
      }
    } else {
      for (final gift in fresh) {
        _show(
          CookieMessage(
            CookieMessages.newGift(gift.fromUsername),
            long: true,
            actionLabel: CookieMessages.view,
            onAction: onOpenInbox,
          ),
        );
      }
    }
    _seenGifts.addAll(pending.map((g) => g.shareId));
    _inboxLoaded = true;
    _inbox = pending;
    _notify();
  }

  Future<void> _social(
    Future<void> Function() action, {
    String offlineMessage = CookieMessages.friendsNeedInternet,
    String lostMessage = CookieMessages.connectionLost,
  }) async {
    if (_busy) return;
    if (!await _repository.isOnline()) {
      _isOnline = false;
      _show(CookieMessage(offlineMessage));
      _notify();
      return;
    }
    _busy = true;
    _notify();
    try {
      await action();
    } on ConnectionLostException {
      _show(
        CookieMessage(
          lostMessage,
          long: true,
          actionLabel: CookieMessages.retry,
          onAction: () => unawaited(_social(action)),
        ),
      );
    } on SocialRefusedException {
      _show(const CookieMessage(CookieMessages.noSuchUsername));
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<void> loadFriends() async {
    if (!await _repository.isOnline()) {
      _isOnline = false;
      _show(const CookieMessage(CookieMessages.friendsNeedInternet));
      _notify();
      return;
    }
    _loadingFriends = true;
    _notify();
    try {
      _profile = await _repository.myProfile(refresh: true);
      if (_profile != null) {
        final results = await Future.wait([
          _repository.friends(),
          _repository.incomingRequests(),
          _repository.blocked(),
          _repository.sentGifts(),
        ]);
        _friends = results[0] as List<Friend>;
        _requests = results[1] as List<FriendRequest>;
        _blocked = results[2] as List<BlockedUser>;
        _sentGifts = results[3] as List<SentGift>;
      }
      _friendsLoaded = true;
    } on ConnectionLostException {
      _show(
        CookieMessage(
          CookieMessages.connectionLost,
          long: true,
          actionLabel: CookieMessages.retry,
          onAction: () => unawaited(loadFriends()),
        ),
      );
    } finally {
      _loadingFriends = false;
      _notify();
    }
  }

  /// Chooses the username (friends get activated).
  Future<void> activate(String username) => _social(() async {
    final name = CookieSocialRules.normalizeUsername(username);
    if (await _repository.activate(name)) {
      _show(const CookieMessage(CookieMessages.friendsActivated));
      await loadFriends();
    } else {
      _show(CookieMessage(CookieMessages.usernameTaken(name)));
    }
  });

  Future<void> sendRequest(String username) => _social(() async {
    final name = CookieSocialRules.normalizeUsername(username);
    final result = await _repository.sendRequest(
      name,
      currentFriends: _friends,
    );
    _show(
      CookieMessage(switch (result) {
        SendRequestResult.sent => CookieMessages.requestSent(name),
        SendRequestResult.alreadyFriends => CookieMessages.alreadyFriends(name),
        _ => CookieMessages.noSuchUsername,
      }),
    );
  });

  Future<void> acceptRequest(FriendRequest request) => _social(() async {
    await _repository.acceptRequest(request);
    _show(CookieMessage(CookieMessages.nowFriends(request.fromUsername)));
    await _reloadLists();
  });

  /// Declining is silent for the sender: the request just disappears.
  Future<void> declineRequest(FriendRequest request) => _social(() async {
    await _repository.declineRequest(request);
    await _reloadLists();
  });

  Future<void> removeFriend(Friend friend) => _social(() async {
    await _repository.removeFriend(friend);
    _show(const CookieMessage(CookieMessages.friendRemoved));
    await _reloadLists();
  });

  Future<void> block(Friend friend) => _social(() async {
    await _repository.block(friend);
    _show(CookieMessage(CookieMessages.blocked(friend.username)));
    await _reloadLists();
  });

  Future<void> unblock(BlockedUser user) => _social(() async {
    await _repository.unblock(user);
    _show(const CookieMessage(CookieMessages.unblocked));
    await _reloadLists();
  });

  Future<void> cancelGift(SentGift gift) => _social(() async {
    final existed = await _repository.cancelGift(gift);
    _show(
      CookieMessage(
        existed ? CookieMessages.giftCanceled : CookieMessages.giftCannotCancel,
      ),
    );
    _sentGifts = await _repository.sentGifts();
  });

  /// Friends for the gift picker, loaded on demand.
  Future<List<Friend>> friendsForGift() async {
    if (!_friendsLoaded) await loadFriends();
    return _friends;
  }

  Future<void> sendGift(CookieModel cookie, Friend friend) => _social(
    () async {
      await _repository.sendGift(cookie, friend);
      _show(CookieMessage(CookieMessages.giftSent(friend.username)));
      _sentGifts = await _repository.sentGifts();
    },
    offlineMessage: CookieMessages.giftsNeedInternet,
    lostMessage: CookieMessages.giftNotSent,
  );

  /// Accepting is guarded per gift (a double tap never accepts twice).
  Future<void> acceptGift(Gift gift) async {
    if (_accepting.contains(gift.shareId)) return;
    if (_repository.isExpired(gift)) {
      _show(const CookieMessage(CookieMessages.giftExpired));
      _inbox = _inbox.where((g) => g.shareId != gift.shareId).toList();
      _notify();
      return;
    }
    if (!await _repository.isOnline()) {
      _show(const CookieMessage(CookieMessages.friendsNeedInternet));
      return;
    }
    _accepting.add(gift.shareId);
    _notify();
    try {
      final accepted = await _repository.acceptGift(gift);
      _inbox = _inbox.where((g) => g.shareId != gift.shareId).toList();
      _show(
        accepted.finished
            ? CookieMessage(CookieMessages.giftAccepted(accepted.cookie.title))
            : const CookieMessage(CookieMessages.giftSavedPending, long: true),
      );
    } on ConnectionLostException {
      _show(
        CookieMessage(
          CookieMessages.giftStillInInbox,
          long: true,
          actionLabel: CookieMessages.retry,
          onAction: () => unawaited(acceptGift(gift)),
        ),
      );
    } finally {
      _accepting.remove(gift.shareId);
      _notify();
    }
  }

  Future<void> declineGift(Gift gift) => _social(() async {
    await _repository.declineGift(gift);
    _inbox = _inbox.where((g) => g.shareId != gift.shareId).toList();
    _show(const CookieMessage(CookieMessages.giftDeclined));
  });

  Future<void> _reloadLists() async {
    final results = await Future.wait([
      _repository.friends(),
      _repository.incomingRequests(),
      _repository.blocked(),
    ]);
    _friends = results[0] as List<Friend>;
    _requests = results[1] as List<FriendRequest>;
    _blocked = results[2] as List<BlockedUser>;
  }

  static Future<void> _quietly(Future<void> work) async {
    try {
      await work;
    } on Exception catch (error) {
      debugPrint('[CookieJar] Will retry later: $error');
    }
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
    _inboxSubscription?.cancel();
    _connectionSubscription?.cancel();
    _messages.close();
    super.dispose();
  }
}
