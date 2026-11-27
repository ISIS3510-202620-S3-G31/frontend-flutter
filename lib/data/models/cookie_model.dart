import '../../domain/cookie_jar/cookie_rules.dart';

/// Where a cookie is in the jar, or eaten (moved to the history, not deleted)

enum CookieState {
  active('ACTIVE'),
  eaten('EATEN');

  const CookieState(this.code);

  final String code;

  /// Anything unknown is read as active, so a bad value never hides a cookie.
  static CookieState fromCode(Object? code) =>
      code == eaten.code ? eaten : active;
}

/// A memory or achievement in the Cookie Jar: title, text and an optional photo

class CookieModel {
  const CookieModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.text,
    this.state = CookieState.active,
    this.hasImage = false,
    this.localImagePath,
    this.remoteImageUrl,
    this.lastOpenedAt = 0,
    this.receivedFrom,
    this.createdAt = 0,
    this.updatedAt = 0,
    this.isSynced = false,
  });

  /// UUID made on the phone: the same id in sqflite, in the private file and in Firestore and Storage.
  final String id;

  /// Firebase uid of the owner.
  final String userId;

  final String title;
  final String text;
  final CookieState state;

  /// True when the cookie has a photo, even if the file is not on this phone
  final bool hasImage;

  /// Path of the JPEG in app-private storage
  final String? localImagePath;

  /// Download URL of the photo in Storage; null until it is uploaded.
  final String? remoteImageUrl;

  /// Last time the cookie was opened, in milliseconds
  final int lastOpenedAt;

  /// Username of whoever gave this cookie as a gift; null when it is ours.
  final String? receivedFrom;

  /// Milliseconds since epoch.
  final int createdAt;

  /// Milliseconds since epoch. Between two phones, the latest change wins.
  final int updatedAt;

  /// False while something is still waiting to upload.
  final bool isSynced;

  /// The title as compared for duplicates: "Mi Grado" and "mí grado " match.
  String get titleKey => CookieRules.titleKeyOf(title);

  bool get isActive => state == CookieState.active;

  /// Only cookies in the history (eaten) can be deleted forever.
  bool get canBeDeletedForever => state == CookieState.eaten;

  /// The photo can be shown offline only if its file is on this phone.
  bool get hasLocalImage => hasImage && localImagePath != null;

  CookieModel copyWith({
    String? title,
    String? text,
    CookieState? state,
    bool? hasImage,
    String? localImagePath,
    bool clearLocalImagePath = false,
    String? remoteImageUrl,
    int? lastOpenedAt,
    int? updatedAt,
    bool? isSynced,
  }) => CookieModel(
    id: id,
    userId: userId,
    title: title ?? this.title,
    text: text ?? this.text,
    state: state ?? this.state,
    hasImage: hasImage ?? this.hasImage,
    localImagePath: clearLocalImagePath
        ? null
        : localImagePath ?? this.localImagePath,
    remoteImageUrl: remoteImageUrl ?? this.remoteImageUrl,
    lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    receivedFrom: receivedFrom,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isSynced: isSynced ?? this.isSynced,
  );

  Map<String, Object?> toDb() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'title_key': titleKey,
    'text': text,
    'state': state.code,
    'has_image': hasImage ? 1 : 0,
    'local_image_path': localImagePath,
    'remote_image_url': remoteImageUrl,
    'last_opened_at': lastOpenedAt,
    'received_from': receivedFrom,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'is_synced': isSynced ? 1 : 0,
  };

  factory CookieModel.fromDb(Map<String, Object?> row) => CookieModel(
    id: row['id']! as String,
    userId: row['user_id']! as String,
    title: row['title']! as String,
    text: row['text']! as String,
    state: CookieState.fromCode(row['state']),
    hasImage: row['has_image'] == 1,
    localImagePath: row['local_image_path'] as String?,
    remoteImageUrl: row['remote_image_url'] as String?,
    lastOpenedAt: row['last_opened_at'] as int? ?? 0,
    receivedFrom: row['received_from'] as String?,
    createdAt: row['created_at'] as int? ?? 0,
    updatedAt: row['updated_at'] as int? ?? 0,
    isSynced: row['is_synced'] == 1,
  );


  Map<String, Object?> toFirestore() => {
    'userId': userId,
    'title': title,
    'text': text,
    'state': state.code,
    'hasImage': hasImage,
    'imageUrl': remoteImageUrl ?? '',
    'receivedFrom': receivedFrom,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };


  factory CookieModel.fromFirestore(String id, Map<String, Object?> data) {
    final imageUrl = data['imageUrl'];
    return CookieModel(
      id: id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      text: data['text'] as String? ?? '',
      state: CookieState.fromCode(data['state']),
      hasImage: data['hasImage'] == true,
      remoteImageUrl: imageUrl is String && imageUrl.isNotEmpty
          ? imageUrl
          : null,
      receivedFrom: data['receivedFrom'] as String?,
      createdAt: (data['createdAt'] as num?)?.toInt() ?? 0,
      updatedAt: (data['updatedAt'] as num?)?.toInt() ?? 0,
      isSynced: true,
    );
  }
}
