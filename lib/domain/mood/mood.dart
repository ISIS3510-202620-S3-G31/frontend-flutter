import '../../data/models/check_in_model.dart';

/// Component: a feeling, made of one emotion or of several.
abstract class Mood {
  const Mood();

  /// "Fear" for one emotion, or a name like "Anxiety" for a mix.
  String get name;

  /// The single emotions inside, in the order the user picked them.
  List<SimpleEmotion> get emotions;

  /// How strong it is, from 1 to 5.
  double get intensity;
}

/// Leaf: one emotion with its own intensity (1 to 5).
class SimpleEmotion extends Mood {
  const SimpleEmotion(this.emotion, {this.level = 3});

  final Emotion emotion;
  final int level;

  @override
  String get name => emotion.label;

  @override
  List<SimpleEmotion> get emotions => [this];

  @override
  double get intensity => level.toDouble();
}
