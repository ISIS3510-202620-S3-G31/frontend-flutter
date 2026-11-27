/// The models of the Cookie Jar social part.
library;

/// `public_profiles/{uid}`: only username and avatar.
class PublicProfile {
  const PublicProfile({
    required this.uid,
    required this.username,
    this.avatarId = defaultAvatar,
  });

  /// The Flutter app has no avatar picker yet; the rules only ask for text.
  static const defaultAvatar = 'default';

  final String uid;
  final String username;
  final String avatarId;

  Map<String, Object?> toFirestore() => {
    'username': username,
    'avatarId': avatarId,
  };

  factory PublicProfile.fromFirestore(String uid, Map<String, Object?> data) =>
      PublicProfile(
        uid: uid,
        username: data['username'] as String? ?? '',
        avatarId: data['avatarId'] as String? ?? defaultAvatar,
      );
}

/// `friend_requests/{fromUid_toUid}`, pending until the receiver answers.
class FriendRequest {
  const FriendRequest({
    required this.from,
    required this.to,
    required this.fromUsername,
    required this.createdAt,
  });

  final String from;
  final String to;
  final String fromUsername;
  final int createdAt;

  Map<String, Object?> toFirestore() => {
    'from': from,
    'to': to,
    'fromUsername': fromUsername,
    'status': 'pending',
    'createdAt': createdAt,
  };

  factory FriendRequest.fromFirestore(Map<String, Object?> data) =>
      FriendRequest(
        from: data['from'] as String? ?? '',
        to: data['to'] as String? ?? '',
        fromUsername: data['fromUsername'] as String? ?? '',
        createdAt: (data['createdAt'] as num?)?.toInt() ?? 0,
      );
}

/// A friend, from `friendships/{a_b}` plus the other one's public profile.
class Friend {
  const Friend({required this.uid, required this.username, this.since = 0});

  final String uid;
  final String username;
  final int since;
}

/// `users/{uid}/blocked/{otherUid}`: only the one who blocked sees it.
class BlockedUser {
  const BlockedUser({required this.uid, required this.username});

  final String uid;
  final String username;
}

/// `shared_cookies/{shareId}`: a copy of a cookie sent to one friend.
class Gift {
  const Gift({
    required this.shareId,
    required this.from,
    required this.fromUsername,
    required this.to,
    required this.title,
    required this.text,
    required this.hasImage,
    required this.sentAt,
    required this.expiresAt,
  });

  final String shareId;
  final String from;
  final String fromUsername;
  final String to;
  final String title;
  final String text;
  final bool hasImage;
  final int sentAt;
  final int expiresAt;

  Map<String, Object?> toFirestore() => {
    'from': from,
    'fromUsername': fromUsername,
    'to': to,
    'title': title,
    'text': text,
    'hasImage': hasImage,
    'sentAt': sentAt,
    'expiresAt': expiresAt,
  };

  factory Gift.fromFirestore(String shareId, Map<String, Object?> data) => Gift(
    shareId: shareId,
    from: data['from'] as String? ?? '',
    fromUsername: data['fromUsername'] as String? ?? '',
    to: data['to'] as String? ?? '',
    title: data['title'] as String? ?? '',
    text: data['text'] as String? ?? '',
    hasImage: data['hasImage'] == true,
    sentAt: (data['sentAt'] as num?)?.toInt() ?? 0,
    expiresAt: (data['expiresAt'] as num?)?.toInt() ?? 0,
  );
}

/// A gift this phone sent, kept only on this phone (sqflite).
class SentGift {
  const SentGift({
    required this.shareId,
    required this.toUsername,
    required this.title,
    required this.sentAt,
  });

  final String shareId;
  final String toUsername;
  final String title;
  final int sentAt;

  Map<String, Object?> toDb() => {
    'share_id': shareId,
    'to_username': toUsername,
    'title': title,
    'sent_at': sentAt,
  };

  factory SentGift.fromDb(Map<String, Object?> row) => SentGift(
    shareId: row['share_id']! as String,
    toUsername: row['to_username']! as String,
    title: row['title']! as String,
    sentAt: row['sent_at']! as int,
  );
}

/// What the live inbox listener delivers.
class InboxSnapshot {
  const InboxSnapshot({required this.gifts, required this.fromCache});

  final List<Gift> gifts;

  final bool fromCache;
}
