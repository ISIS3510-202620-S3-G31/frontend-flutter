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
  });

  final List<Emotion> emotions;
  final int intensity;
  final DateTime timestamp;

  /// A check-in is difficult if it has at least one difficult emotion.
  bool get isDifficult => emotions.any((emotion) => emotion.isDifficult);
}
