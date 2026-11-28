import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/cookie_jar/cookie_social_rules.dart';
import '../../utils/uuid.dart';
import '../models/cookie_model.dart';
import '../models/cookie_social_models.dart';
import '../services/remote/cookie_social_remote_service.dart';
import 'auth_repository.dart';
import 'cookie_repository.dart';

export '../services/remote/cookie_social_remote_service.dart'
    show ConnectionLostException, SocialRefusedException;

enum SendRequestResult { sent, noSuchUser, alreadyFriends, notActivated }

/// The result of accepting a gift.
class AcceptedGift {
  const AcceptedGift(this.cookie, {required this.finished});

  final CookieModel cookie;

  final bool finished;
}

/// Friends and gifts of the Cookie Jar (18+ only).
class CookieSocialRepository {
  CookieSocialRepository({
    CookieRepository? cookies,
    CookieSocialRemoteService? remote,
    AuthRepository? auth,
    DateTime Function()? now,
  }) : _cookies = cookies ?? CookieRepository.shared,
       _customRemote = remote,
       _customAuth = auth,
       _now = now ?? DateTime.now;

  final CookieRepository _cookies;
  final CookieSocialRemoteService? _customRemote;
  final AuthRepository? _customAuth;
  final DateTime Function() _now;

  late final CookieSocialRemoteService _remote =
      _customRemote ?? CookieSocialRemoteService();
  late final AuthRepository _auth = _customAuth ?? AuthRepository();

  /// Cached for the session: the username never changes.
  PublicProfile? _profile;

  int get _nowMillis => _now().millisecondsSinceEpoch;

  String _requireUser() {
    final uid = _cookies.userId;
    if (uid == null) throw StateError('No user is signed in.');
    return uid;
  }

  Future<bool> isOnline() => _cookies.isOnline();

  Future<bool> isAdult() async {
    final profile = await _auth.getCurrentUserProfile();
    return CookieSocialRules.isAdult(profile?.age);
  }

  /// This user's public profile, or null when friends are not activated.
  Future<PublicProfile?> myProfile({bool refresh = false}) async {
    if (_profile != null && !refresh) return _profile;
    return _profile = await _remote.myProfile(_requireUser());
  }

  /// Reserves [input] as this user's username. False when it is taken.
  Future<bool> activate(String input) async {
    final uid = _requireUser();
    final username = CookieSocialRules.normalizeUsername(input);
    final ok = await _remote.activate(uid, username);
    if (ok) _profile = PublicProfile(uid: uid, username: username);
    return ok;
  }

  Future<SendRequestResult> sendRequest(
    String input, {
    required Iterable<Friend> currentFriends,
  }) async {
    final me = _requireUser();
    final profile = await myProfile();
    if (profile == null) return SendRequestResult.notActivated;
    final username = CookieSocialRules.normalizeUsername(input);
    if (currentFriends.any((f) => f.username == username)) {
      return SendRequestResult.alreadyFriends;
    }
    final uid = await _remote.uidOf(username);
    if (uid == null || uid == me) return SendRequestResult.noSuchUser;
    try {
      await _remote.sendRequest(
        FriendRequest(
          from: me,
          to: uid,
          fromUsername: profile.username,
          createdAt: _nowMillis,
        ),
      );
    } on SocialRefusedException {
      return SendRequestResult.noSuchUser;
    }
    return SendRequestResult.sent;
  }

  Future<List<FriendRequest>> incomingRequests() =>
      _remote.incomingRequests(_requireUser());

  Future<void> acceptRequest(FriendRequest request) =>
      _remote.acceptRequest(_requireUser(), request.from, _nowMillis);

  Future<void> declineRequest(FriendRequest request) =>
      _remote.deleteRequest(request.from, _requireUser());

  Future<List<Friend>> friends() => _remote.friends(_requireUser());

  Future<void> removeFriend(Friend friend) =>
      _remote.removeFriend(_requireUser(), friend.uid);

  Future<void> block(Friend friend) => _remote.block(
    _requireUser(),
    BlockedUser(uid: friend.uid, username: friend.username),
    _nowMillis,
  );

  Future<void> unblock(BlockedUser user) =>
      _remote.unblock(_requireUser(), user.uid);

  Future<List<BlockedUser>> blocked() => _remote.blocked(_requireUser());

  /// Gifts sent from this phone (local list, see [SentGift]).
  Future<List<SentGift>> sentGifts() => _cookies.dao.sentGifts(_requireUser());

  Future<void> sendGift(CookieModel cookie, Friend friend) async {
    final me = _requireUser();
    final profile = await myProfile();
    if (profile == null) throw const SocialRefusedException();
    final photo = cookie.hasImage
        ? await _cookies.photoOf(cookie) ?? await _cookies.downloadPhoto(cookie)
        : null;
    final now = _nowMillis;
    final gift = Gift(
      shareId: newUuid(),
      from: me,
      fromUsername: profile.username,
      to: friend.uid,
      title: cookie.title,
      text: cookie.text,
      hasImage: photo != null,
      sentAt: now,
      expiresAt: now + CookieSocialRules.giftLifetime.inMilliseconds,
    );
    if (photo != null) await _remote.uploadGiftImage(gift, photo);
    try {
      await _remote.createGift(gift);
    } on Exception {
      if (photo != null) {
        unawaited(_quietly(_remote.deleteGiftImage(gift.shareId)));
      }
      rethrow;
    }
    await _cookies.dao.addSentGift(
      me,
      SentGift(
        shareId: gift.shareId,
        toUsername: friend.username,
        title: gift.title,
        sentAt: now,
      ),
    );
  }

  Future<bool> cancelGift(SentGift gift) async {
    final existed = await _remote.deleteGiftIfExists(gift.shareId);
    await _quietly(_remote.deleteGiftImage(gift.shareId));
    await _cookies.dao.removeSentGift(_requireUser(), gift.shareId);
    return existed;
  }

  Stream<InboxSnapshot> watchInbox() => _remote.watchInbox(_requireUser());

  Future<AcceptedGift> acceptGift(Gift gift) async {
    final photo = gift.hasImage
        ? await _remote.downloadGiftImage(gift.shareId)
        : null;
    final cookie = await _cookies.saveReceivedGift(
      shareId: gift.shareId,
      title: gift.title,
      text: gift.text,
      fromUsername: gift.fromUsername,
      photo: photo,
    );
    try {
      await finishAccepted(gift);
      return AcceptedGift(cookie, finished: true);
    } on ConnectionLostException {
      return AcceptedGift(cookie, finished: false);
    }
  }

  /// Step 3 of [acceptGift], also for gifts already saved on the phone.
  Future<void> finishAccepted(Gift gift) async {
    await _remote.deleteGiftIfExists(gift.shareId);
    await _remote.deleteGiftImage(gift.shareId);
  }

  /// Whether this gift was already accepted on this phone.
  Future<bool> isAccepted(Gift gift) => _cookies.hasCookie(gift.shareId);

  /// Declining deletes the gift and its photo; the sender's cookie stays.
  Future<void> declineGift(Gift gift) async {
    await _remote.deleteGiftIfExists(gift.shareId);
    await _quietly(_remote.deleteGiftImage(gift.shareId));
  }

  Future<void> deleteExpired(Iterable<Gift> gifts) async {
    for (final gift in gifts) {
      await _quietly(declineGift(gift));
    }
  }

  bool isExpired(Gift gift) =>
      CookieSocialRules.isExpired(gift.expiresAt, _now());

  static Future<void> _quietly(Future<void> work) async {
    try {
      await work;
    } on Exception catch (error) {
      debugPrint('[CookieJar] Will be cleaned up later: $error');
    }
  }
}
