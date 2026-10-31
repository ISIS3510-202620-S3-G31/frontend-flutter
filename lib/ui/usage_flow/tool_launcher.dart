import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/models/tool_model.dart';
import '../../domain/usage_flow/flow_step.dart';
import '../feedback/widgets/tool_feedback_screen.dart';
import 'view_model/usage_flow_view_model.dart';


Future<void> openTool(
  BuildContext context, {
  required ToolItem tool,
  required WidgetBuilder screen,
  ToolEntryPoint? entryPoint,
  UsageFlowViewModel? flow,
}) async {
  final usage = flow ?? UsageFlowViewModel(tool: tool);
  try {
    // Logging the start must never stand between the tap and the tool.
    unawaited(usage.startTool(entryPoint: entryPoint));
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: screen,
        settings: RouteSettings(name: '/tools/${tool.id}'),
      ),
    );
    await usage.finishTool();
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
