import '../../data/models/check_in_model.dart';
import 'mood.dart';

/// Composite: a mix of moods, like "Anxiety". It can hold single emotions and
/// other mixes, and answers by asking each of them.
class CompoundEmotion extends Mood {
  CompoundEmotion();

  final List<Mood> _children = [];

  List<Mood> get children => List.unmodifiable(_children);

  void add(Mood mood) => _children.add(mood);

  void remove(Mood mood) => _children.remove(mood);

  @override
  List<SimpleEmotion> get emotions => [
    for (final child in _children) ...child.emotions,
  ];

  /// The average of its parts.
  @override
  double get intensity {
    if (_children.isEmpty) return 0;
    final total = _children.fold(0.0, (sum, child) => sum + child.intensity);
    return total / _children.length;
  }

  /// Same names as the Kotlin app, from Plutchik's wheel of emotions.
  @override
  String get name {
    final all = {for (final leaf in emotions) leaf.emotion};
    bool has(Emotion a, Emotion b) => all.contains(a) && all.contains(b);
    if (has(Emotion.happiness, Emotion.sadness)) return 'Nostalgia';
    if (has(Emotion.anger, Emotion.disgust)) return 'Frustration';
    if (has(Emotion.fear, Emotion.surprise)) return 'Anxiety';
    if (has(Emotion.happiness, Emotion.surprise)) return 'Excitement';
    if (has(Emotion.anger, Emotion.fear)) return 'Stress';
    if (has(Emotion.sadness, Emotion.anger)) return 'Resentment';
    return 'Mixed Mood';
  }
}
