import '../../data/models/tool_model.dart';

/// Component: anything that can be part of a usage flow, from a single screen
/// to the whole flow. Groups and single steps answer the same questions.
abstract class FlowStep {
  const FlowStep(this.title);

  final String title;

  /// The single steps inside, in the order the user goes through them.
  List<SingleStep> get steps;

  /// True when the user finished everything inside.
  bool get isComplete;
}

/// Leaf: one screen of the flow.
sealed class SingleStep extends FlowStep {
  const SingleStep(super.title);

  @override
  List<SingleStep> get steps => [this];
}

/// Asks how strong the emotion is, from 1 (calm) to 5 (very strong).
class MoodCheckStep extends SingleStep {
  MoodCheckStep(super.title);

  int? intensity;

  @override
  bool get isComplete => intensity != null;
}

/// The tool itself.
class ToolStep extends SingleStep {
  ToolStep(this.tool) : super(tool.title);

  final ToolItem tool;
  bool finished = false;

  @override
  bool get isComplete => finished;
}

enum Usefulness {
  notReally('Not really'),
  aLittle('A little'),
  aLot('A lot');

  const Usefulness(this.label);

  final String label;
}

/// Asks if the tool helped.
class RatingStep extends SingleStep {
  RatingStep(super.title);

  Usefulness? answer;

  @override
  bool get isComplete => answer != null;
}
