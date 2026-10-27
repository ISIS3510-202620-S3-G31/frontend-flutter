import 'package:flutter/material.dart';

import '../../core/theme/app_text.dart';

/// Top header for the toolbox screen with title and subtitle.
class ToolHubHeader extends StatelessWidget {
  const ToolHubHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your toolbox',
            style: AppText.breathingTitle.copyWith(fontSize: 32),
          ),
          const SizedBox(height: 4),
          Text(
            'Pick a tool \u2014 or let chance pick for you.',
            style: AppText.bodyMuted,
          ),
        ],
      ),
    );
  }
}
