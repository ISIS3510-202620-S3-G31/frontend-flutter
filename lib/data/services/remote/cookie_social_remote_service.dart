import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../domain/cookie_jar/cookie_social_rules.dart';
import '../../models/cookie_social_models.dart';

/// The network dropped (or was too slow) during a social action.
class ConnectionLostException implements Exception {
  const ConnectionLostException();
}

/// The server refused the action (blocked, not friends, not 18+...).
class SocialRefusedException implements Exception {
  const SocialRefusedException();
}

/// Friends and gifts of the Cookie Jar in Firebase.
class CookieSocialRemoteService {
  CookieSocialRemoteService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _customFirestore = firestore,
       _customStorage = storage;

  static const timeout = Duration(seconds: 20);
  static const photoTimeout = Duration(seconds: 90);
  static const maxImageBytes = 10 * 1024 * 1024;
  static const _server = GetOptions(source: Source.server);

  final FirebaseFirestore? _customFirestore;
  final FirebaseStorage? _customStorage;

  FirebaseFirestore get _db => _customFirestore ?? FirebaseFirestore.instance;
  FirebaseStorage get _storage => _customStorage ?? FirebaseStorage.instance;

  DocumentReference<Map<String, dynamic>> _username(String name) =>
      _db.doc('usernames/$name');
  DocumentReference<Map<String, dynamic>> _profile(String uid) =>
      _db.doc('public_profiles/$uid');
  DocumentReference<Map<String, dynamic>> _request(String from, String to) =>
      _db.doc('friend_requests/${CookieSocialRules.requestId(from, to)}');
  DocumentReference<Map<String, dynamic>> _friendship(String a, String b) =>
      _db.doc('friendships/${CookieSocialRules.friendshipId(a, b)}');
  DocumentReference<Map<String, dynamic>> _blocked(String me, String other) =>
      _db.doc('users/$me/blocked/$other');
  DocumentReference<Map<String, dynamic>> _gift(String shareId) =>
      _db.doc('shared_cookies/$shareId');
  Reference _giftImage(String shareId) => _storage.ref('shared/$shareId.jpg');

  Future<T> _guard<T>(Future<T> Function() call, {Duration? limit}) async {
    try {
      return await call().timeout(limit ?? timeout);
    } on TimeoutException {
      throw const ConnectionLostException();
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied' || error.code == 'unauthorized') {
        throw const SocialRefusedException();
      }
      if (const {
        'unavailable',
        'deadline-exceeded',
        'retry-limit-exceeded',
        'network-request-failed',
      }.contains(error.code)) {
        throw const ConnectionLostException();
      }
      rethrow;
    }
  }

  /// This user's public profile, or null when friends are not activated.
  Future<PublicProfile?> myProfile(String uid) => _guard(() async {
    final snapshot = await _profile(uid).get(_server);
    final data = snapshot.data();
    return data == null ? null : PublicProfile.fromFirestore(uid, data);
  });

  Future<bool> activate(String uid, String username) async {
    try {
      return await _guard(
        () => _db.runTransaction((tx) async {
          final owner = await tx.get(_username(username));
          if (owner.exists) return owner.data()?['uid'] == uid;
          tx.set(_username(username), {'uid': uid});
          tx.set(
            _profile(uid),
            PublicProfile(uid: uid, username: username).toFirestore(),
          );
          return true;
        }),
      );
    } on SocialRefusedException {
      return false;
    }
  }

  Future<String?> uidOf(String username) async {
    try {
      return await _guard(() async {
        final snapshot = await _username(username).get(_server);
        return snapshot.data()?['uid'] as String?;
      });
    } on SocialRefusedException {
      return null;
    }
  }

  Future<void> sendRequest(FriendRequest request) => _guard(
    () => _db.runTransaction((tx) async {
      final ref = _request(request.from, request.to);
      if ((await tx.get(ref)).exists) return;
      tx.set(ref, request.toFirestore());
    }),
  );

  Future<List<FriendRequest>> incomingRequests(String uid) => _guard(() async {
    final page = await _db
        .collection('friend_requests')
        .where('to', isEqualTo: uid)
        .get(_server);
    return page.docs.map((d) => FriendRequest.fromFirestore(d.data())).toList();
  });

  /// Deletes the request and creates the friendship in the same transaction.
  Future<void> acceptRequest(String myUid, String fromUid, int now) => _guard(
    () => _db.runTransaction((tx) async {
      final request = _request(fromUid, myUid);
      final friendship = _friendship(myUid, fromUid);
      final requestSnapshot = await tx.get(request);
      final friendshipSnapshot = await tx.get(friendship);
      if (!requestSnapshot.exists) return;
      tx.delete(request);
      if (!friendshipSnapshot.exists) {
        final members = [myUid, fromUid]..sort();
        tx.set(friendship, {'members': members, 'since': now});
      }
    }),
  );

  /// Declining deletes the request; the sender is never told.
  Future<void> deleteRequest(String fromUid, String toUid) =>
      _guard(() => _request(fromUid, toUid).delete());

  Future<List<Friend>> friends(String uid) => _guard(() async {
    final page = await _db
        .collection('friendships')
        .where('members', arrayContains: uid)
        .get(_server);
    final friends = await Future.wait(
      page.docs.map((doc) async {
        final members = List<String>.from(doc.data()['members'] as List);
        final other = members.firstWhere((m) => m != uid, orElse: () => uid);
        final profile = (await _profile(other).get(_server)).data();
        return Friend(
          uid: other,
          username: profile?['username'] as String? ?? '…',
          since: (doc.data()['since'] as num?)?.toInt() ?? 0,
        );
      }),
    );
    return friends..sort((a, b) => a.username.compareTo(b.username));
  });

  Future<void> removeFriend(String a, String b) =>
      _guard(() => _friendship(a, b).delete());

  Future<void> block(String me, BlockedUser other, int now) => _guard(
    () => _db.runTransaction((tx) async {
      final related = [
        _friendship(me, other.uid),
        _request(me, other.uid),
        _request(other.uid, me),
      ];
      final existing = [
        for (final ref in related)
          if ((await tx.get(ref)).exists) ref,
      ];
      tx.set(_blocked(me, other.uid), {
        'username': other.username,
        'blockedAt': now,
      });
      for (final ref in existing) {
        tx.delete(ref);
      }
    }),
  );

  Future<void> unblock(String me, String otherUid) =>
      _guard(() => _blocked(me, otherUid).delete());

  Future<List<BlockedUser>> blocked(String me) => _guard(() async {
    final page = await _db.collection('users/$me/blocked').get(_server);
    return [
      for (final doc in page.docs)
        BlockedUser(
          uid: doc.id,
          username: doc.data()['username'] as String? ?? '',
        ),
    ];
  });

  Future<void> uploadGiftImage(Gift gift, Uint8List jpeg) => _guard(
    () => _giftImage(gift.shareId).putData(
      jpeg,
      SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'from': gift.from, 'to': gift.to},
      ),
    ),
    limit: photoTimeout,
  );

  Future<void> createGift(Gift gift) => _guard(
    () => _db.runTransaction((tx) async {
      final ref = _gift(gift.shareId);
      if ((await tx.get(ref)).exists) return;
      tx.set(ref, gift.toFirestore());
    }),
  );

  Future<bool> deleteGiftIfExists(String shareId) => _guard(
    () => _db.runTransaction((tx) async {
      final ref = _gift(shareId);
      if (!(await tx.get(ref)).exists) return false;
      tx.delete(ref);
      return true;
    }),
  );

  /// Whether the gift is still pending in the backend.
  Future<bool> giftExists(String shareId) =>
      _guard(() async => (await _gift(shareId).get(_server)).exists);

  Future<Uint8List?> downloadGiftImage(String shareId) => _guard(
    () => _giftImage(shareId).getData(maxImageBytes),
    limit: photoTimeout,
  );

  Future<void> deleteGiftImage(String shareId) async {
    try {
      await _guard(() => _giftImage(shareId).delete());
    } on SocialRefusedException {
      return;
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
  }

  Stream<InboxSnapshot> watchInbox(String uid) => _db
      .collection('shared_cookies')
      .where('to', isEqualTo: uid)
      .snapshots(includeMetadataChanges: true)
      .map(
        (snapshot) => InboxSnapshot(
          gifts: [
            for (final doc in snapshot.docs)
              Gift.fromFirestore(doc.id, doc.data()),
          ]..sort((a, b) => b.sentAt.compareTo(a.sentAt)),
          fromCache: snapshot.metadata.isFromCache,
        ),
      );
}
