import 'dart:math';

import 'package:flutter/widgets.dart' show StringCharacters;

/// One wish written in the Rapunzel's lantern tool. It lives in sqflite on the
/// phone first (the sky screen reads it even with no connection) and goes to
/// Firestore as a pending write when there is no network.
///
/// A lantern in the sky is lit when the wish was released (it floated away),
/// unlit while it is still held.
class Wish {
  const Wish({
    required this.id,
    required this.text,
    required this.createdAt,
    this.released = false,
    this.releasedAt,
  });

  /// Longest wish the create screen accepts, same limit as a check-in note.
  static const maxLength = 280;

  static String limitText(String text) =>
      text.characters.take(maxLength).toString();

  final String id;
  final String text;
  final DateTime createdAt;

  /// True once the lantern was swiped up into the sky: the wish stays saved.
  final bool released;
  final DateTime? releasedAt;

  /// A new, still held wish. The id is made here so tests need no Firestore.
  factory Wish.create(String text, {DateTime? createdAt, String? id}) {
    final now = createdAt ?? DateTime.now();
    return Wish(
      id:
          id ??
          'w${now.toUtc().microsecondsSinceEpoch.toRadixString(36)}'
          '${Random().nextInt(1 << 30).toRadixString(36)}',
      text: limitText(text.trim()),
      createdAt: now,
    );
  }

  Wish copyWith({String? text, bool? released, DateTime? releasedAt}) => Wish(
    id: id,
    text: text ?? this.text,
    createdAt: createdAt,
    released: released ?? this.released,
    releasedAt: releasedAt ?? this.releasedAt,
  );

  /// Firestore shape, with the timestamps as ISO strings like a check-in.
  Map<String, Object?> toMap() => {
    'text': text,
    'created_at': createdAt.toUtc().toIso8601String(),
    'released': released,
    'released_at': releasedAt?.toUtc().toIso8601String(),
  };

  static Wish fromMap(String id, Map<String, Object?> map) => Wish(
    id: id,
    text: map['text'] as String? ?? '',
    createdAt:
        DateTime.tryParse(map['created_at'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
    released: map['released'] as bool? ?? false,
    releasedAt: DateTime.tryParse(map['released_at'] as String? ?? '')
        ?.toLocal(),
  );

  @override
  bool operator ==(Object other) =>
      other is Wish &&
      other.id == id &&
      other.text == text &&
      other.createdAt == createdAt &&
      other.released == released &&
      other.releasedAt == releasedAt;

  @override
  int get hashCode => Object.hash(id, text, createdAt, released, releasedAt);
}
