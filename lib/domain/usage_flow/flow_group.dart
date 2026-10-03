import 'flow_step.dart';

/// Composite: a group of steps, like "Before the tool" or the whole flow.
/// It answers by asking its children, so groups can hold other groups.
class FlowGroup extends FlowStep {
  FlowGroup(super.title);

  final List<FlowStep> _children = [];

  List<FlowStep> get children => List.unmodifiable(_children);

  void add(FlowStep step) => _children.add(step);

  void remove(FlowStep step) => _children.remove(step);

  @override
  List<SingleStep> get steps => [for (final child in _children) ...child.steps];

  @override
  bool get isComplete => _children.every((child) => child.isComplete);
}
