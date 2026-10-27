/// How the user felt right after finishing a tool.
enum FeedbackMood {
  calm('Calm'),
  inspired('Inspired'),
  focused('Focused'),
  satisfied('Satisfied');

  const FeedbackMood(this.label);

  final String label;
}

/// Short notes the user can tap instead of writing.
enum FeedbackTag {
  easyToUse('Easy to use'),
  goodPace('Good pace'),
  broughtPeace('It brought me peace');

  const FeedbackTag(this.label);

  final String label;
}

/// What the user said about one use of a tool.
class ToolFeedback {
  const ToolFeedback({
    required this.toolId,
    required this.rating,
    required this.mood,
    required this.startedAt,
    required this.durationSeconds,
    this.tags = const [],
    this.comment = '',
    this.favorite = false,
  });

  /// Same id as in the tool catalog, for example "breathing".
  final String toolId;

  /// How the tool felt to use, from 1 to 10.
  final int rating;

  final FeedbackMood mood;
  final DateTime startedAt;
  final int durationSeconds;
  final List<FeedbackTag> tags;
  final String comment;

  /// The user marked this tool as one to come back to.
  final bool favorite;

  Map<String, Object?> toMap() => {
    'toolId': toolId,
    'rating': rating,
    'mood': mood.name,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'durationSeconds': durationSeconds,
    'tags': [for (final tag in tags) tag.name],
    'comment': comment,
    'favorite': favorite,
  };

  static ToolFeedback fromMap(Map<String, Object?> map) => ToolFeedback(
    toolId: map['toolId'] as String? ?? '',
    rating: (map['rating'] as num?)?.toInt() ?? 5,
    mood: _moodNamed(map['mood'] as String?),
    startedAt:
        DateTime.tryParse(map['startedAt'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
    durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
    tags: [
      for (final name in (map['tags'] as List?) ?? [])
        ?_tagNamed(name as String?),
    ],
    comment: map['comment'] as String? ?? '',
    favorite: map['favorite'] as bool? ?? false,
  );

  static FeedbackMood _moodNamed(String? name) => FeedbackMood.values
      .firstWhere((mood) => mood.name == name, orElse: () => FeedbackMood.calm);

  static FeedbackTag? _tagNamed(String? name) {
    for (final tag in FeedbackTag.values) {
      if (tag.name == name) return tag;
    }
    return null;
  }
}
