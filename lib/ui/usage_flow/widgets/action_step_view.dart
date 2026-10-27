import 'package:flutter/material.dart';

import '../../../data/models/tool_model.dart';
import '../../core/theme/app_text.dart';
import '../../home/widgets/tool_card.dart';
import 'flow_button.dart';

/// A step that opens another screen: the tool or its feedback.
class ActionStepView extends StatelessWidget {
  const ActionStepView({
    super.key,
    required this.title,
    required this.message,
    required this.tool,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String message;
  final ToolItem tool;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.h2),
        const SizedBox(height: 4),
        Text(message, style: AppText.bodyMuted),
        const SizedBox(height: 24),
        ToolCard(tool: tool, onTap: onPressed),
        const SizedBox(height: 24),
        FlowButton(label: buttonLabel, onPressed: onPressed),
      ],
    );
  }
}
