import 'package:flutter/foundation.dart';

import '../../../data/models/tool_model.dart';
import '../../../data/repositories/analytics_repository.dart';
import '../../../domain/usage_flow/flow_group.dart';
import '../../../domain/usage_flow/flow_step.dart';
import '../../../domain/usage_flow/usage_flow_template.dart';

/// Walks the usage flow of one tool: the tool itself, then its feedback.
class UsageFlowViewModel extends ChangeNotifier {
  UsageFlowViewModel({
    required this.tool,
    DateTime Function()? now,
    AnalyticsRepository? analytics,
  }) : flow = UsageFlowTemplate.forTool(tool),
       _now = now ?? DateTime.now,
       _analytics = analytics ?? AnalyticsRepository();

  static const _minToolSeconds = 10;

  final ToolItem tool;
  final FlowGroup flow;
  final DateTime Function() _now;
  final AnalyticsRepository _analytics;
  late final List<SingleStep> _steps = flow.steps;
  late final ToolStep _toolStep = _steps.whereType<ToolStep>().first;

  /// The first step not done yet, or null when the flow is over.
  SingleStep? get currentStep =>
      _steps.where((step) => !step.isComplete).firstOrNull;

  /// When the tool was opened and for how long, for the feedback screen.
  DateTime get toolStartedAt => _toolStep.startedAt ?? _now();
  int get toolSeconds => _toolStep.durationSeconds;

  /// Opens the tool: remembers when it started and begins its analytics
  /// session, so completion and abandonment can be measured.
  Future<void> startTool() async {
    if (currentStep is! ToolStep) return;
    _toolStep.startedAt = _now();
    await _analytics.startToolSession(
      toolId: tool.id,
      toolName: tool.title,
    );
  }


  Future<void> finishTool({bool completed = false}) async {
    final startedAt = _toolStep.startedAt;
    if (currentStep is! ToolStep || startedAt == null) return;
    final seconds = _now().difference(startedAt).inSeconds;
    await _analytics.endToolSession(
      toolId: tool.id,
      toolName: tool.title,
      durationSeconds: seconds,
      exitReason: 'left_tool',
    );
    final counts = tool.finishesByGoal
        ? completed
        : seconds >= _minToolSeconds;
    if (!counts) return;
    _toolStep
      ..durationSeconds = seconds
      ..finished = true;
    notifyListeners();
  }

  void finishFeedback() {
    final step = currentStep;
    if (step is! FeedbackStep) return;
    step.answered = true;
    notifyListeners();
  }
}
