/// The six basic emotions the user can log in a check-in.
enum Emotion {
  happiness('Happiness'),
  sadness('Sadness'),
  fear('Fear'),
  anger('Anger'),
  disgust('Disgust'),
  surprise('Surprise');

  const Emotion(this.label);

  final String label;

  /// The emotions the app tries to help the user bring down.
  bool get isDifficult =>
      this == sadness || this == fear || this == anger || this == disgust;
}

/// One emotional check-in: what the user felt, how strong (1 to 5) and when.
class CheckIn {
  const CheckIn({
    required this.emotions,
    required this.intensity,
    required this.timestamp,
    this.note = '',
  });

  final List<Emotion> emotions;
  final int intensity;
  final DateTime timestamp;

  /// What the user wrote about the day, empty when they wrote nothing.
  final String note;

  /// A check-in is difficult if it has at least one difficult emotion.
  bool get isDifficult => emotions.any((emotion) => emotion.isDifficult);

  Map<String, Object?> toMap() => {
    'emotions': [for (final emotion in emotions) emotion.name],
    'intensity': intensity,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'note': note,
  };

  static CheckIn fromMap(Map<String, Object?> map) => CheckIn(
    emotions: [
      for (final name in (map['emotions'] as List?) ?? [])
        ?_emotionNamed(name as String?),
    ],
    intensity: (map['intensity'] as num?)?.toInt() ?? 3,
    timestamp:
        DateTime.tryParse(map['timestamp'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
    note: map['note'] as String? ?? '',
  );

  static Emotion? _emotionNamed(String? name) {
    for (final emotion in Emotion.values) {
      if (emotion.name == name) return emotion;
    }
    return null;
  }
}
