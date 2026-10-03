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
  DateTime? startedAt;
  int durationSeconds = 0;
  bool finished = false;

  @override
  bool get isComplete => finished;
}

/// The tool feedback screen: rating, mood and comments, saved in Firebase.
class FeedbackStep extends SingleStep {
  FeedbackStep() : super('Tool feedback');

  bool answered = false;

  @override
  bool get isComplete => answered;
}
