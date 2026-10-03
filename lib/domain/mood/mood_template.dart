import '../../data/models/check_in_model.dart';
import 'compound_emotion.dart';
import 'mood.dart';

abstract final class MoodTemplate {
  /// One emotion stays a [SimpleEmotion]; several become a [CompoundEmotion].
  /// Null when nothing is chosen.
  static Mood? fromEmotions(Iterable<Emotion> emotions, {required int level}) {
    final leaves = [
      for (final emotion in emotions) SimpleEmotion(emotion, level: level),
    ];
    if (leaves.isEmpty) return null;
    if (leaves.length == 1) return leaves.single;
    final mix = CompoundEmotion();
    for (final leaf in leaves) {
      mix.add(leaf);
    }
    return mix;
  }
}
