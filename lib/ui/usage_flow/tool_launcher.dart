import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/models/tool_model.dart';
import '../../domain/usage_flow/flow_step.dart';
import '../feedback/widgets/tool_feedback_screen.dart';
import 'view_model/usage_flow_view_model.dart';

/// Opens [tool] straight away and, if the user stayed long enough to have an
/// opinion, asks for feedback once they come back.
///
/// The flow itself (the tool, then the feedback) is still the composite built
/// by `UsageFlowTemplate` and walked by [UsageFlowViewModel]; what is gone is
/// the screen that used to stand between the tap and the tool. With nothing
/// underneath but the screen the user came from, there is nothing to flash on
/// the way in or on the way out.
Future<void> openTool(
  BuildContext context, {
  required ToolItem tool,
  required WidgetBuilder screen,
  UsageFlowViewModel? flow,
}) async {
  final usage = flow ?? UsageFlowViewModel(tool: tool);
  try {
    // Logging the start must never stand between the tap and the tool.
    unawaited(usage.startTool());
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: screen,
        settings: RouteSettings(name: '/tools/${tool.id}'),
      ),
    );
    await usage.finishTool(completed: completed ?? false);
    // A visit too short to rate leaves the flow on the tool step.
    if (!context.mounted || usage.currentStep is! FeedbackStep) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ToolFeedbackScreen(
          toolId: tool.id,
          toolName: tool.title,
          startedAt: usage.toolStartedAt,
          durationSeconds: usage.toolSeconds,
        ),
      ),
    );
    usage.finishFeedback();
  } finally {
    if (flow == null) usage.dispose();
  }
}
