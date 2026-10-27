import '../../data/models/tool_model.dart';
import 'flow_group.dart';
import 'flow_step.dart';

abstract final class UsageFlowTemplate {
  /// How the user feels is asked once a day in the check-in, not around every
  /// tool, so the flow is the tool itself plus one short feedback.
  static FlowGroup forTool(ToolItem tool) => FlowGroup('Use ${tool.title}')
    ..add(ToolStep(tool))
    ..add(FlowGroup('After the tool')..add(FeedbackStep()));
}
