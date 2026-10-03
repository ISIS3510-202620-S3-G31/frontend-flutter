import '../../data/models/tool_model.dart';
import 'flow_group.dart';
import 'flow_step.dart';

/// The same flow for every tool:
///
///     Use <tool>
///     ├── Before the tool
///     │   └── Mood check
///     ├── <tool>
///     └── After the tool
///         ├── Mood check
///         └── Tool feedback
abstract final class UsageFlowTemplate {
  static FlowGroup forTool(ToolItem tool) => FlowGroup('Use ${tool.title}')
    ..add(
      FlowGroup('Before the tool')
        ..add(MoodCheckStep('How strong is what you feel right now?')),
    )
    ..add(ToolStep(tool))
    ..add(
      FlowGroup('After the tool')
        ..add(MoodCheckStep('And now, how strong is it?'))
        ..add(FeedbackStep()),
    );
}
