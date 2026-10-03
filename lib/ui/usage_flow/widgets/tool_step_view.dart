import 'package:flutter/material.dart';

import '../../../data/models/tool_model.dart';
import '../../core/theme/app_text.dart';
import '../../home/widgets/tool_card.dart';
import 'flow_button.dart';

/// The tool step: shows the tool and opens it.
class ToolStepView extends StatelessWidget {
  const ToolStepView({super.key, required this.tool, required this.onStart});

  final ToolItem tool;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Time for the tool', style: AppText.h2),
        const SizedBox(height: 4),
        Text(
          'When you finish, come back here to see how you feel.',
          style: AppText.bodyMuted,
        ),
        const SizedBox(height: 24),
        ToolCard(tool: tool, onTap: onStart),
        const SizedBox(height: 24),
        FlowButton(label: 'Start', onPressed: onStart),
      ],
    );
  }
}
