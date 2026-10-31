/// What the user said about one use of a tool.
class ToolFeedback {
  const ToolFeedback({
    required this.toolId,
    required this.rating,
    required this.startedAt,
    required this.durationSeconds,
    this.comment = '',
    this.favorite = false,
  });

  /// Same id as in the tool catalog, for example "breathing".
  final String toolId;

  /// How the tool felt to use, from 1 to 10.
  final int rating;

  final DateTime startedAt;
  final int durationSeconds;
  final String comment;

  /// The user marked this tool as one to come back to.
  final bool favorite;

  Map<String, Object?> toMap() => {
    'toolId': toolId,
    'rating': rating,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'durationSeconds': durationSeconds,
    'comment': comment,
    'favorite': favorite,
  };

  /// Older documents also carry a mood and quick tags; the app no longer asks
  /// for them, so they are left unread.
  static ToolFeedback fromMap(Map<String, Object?> map) => ToolFeedback(
    toolId: map['toolId'] as String? ?? '',
    rating: (map['rating'] as num?)?.toInt() ?? 5,
    startedAt:
        DateTime.tryParse(map['startedAt'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
    durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
    comment: map['comment'] as String? ?? '',
    favorite: map['favorite'] as bool? ?? false,
  );
}
