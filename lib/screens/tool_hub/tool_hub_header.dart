import 'package:flutter/material.dart';

import '../../theme/app_text.dart';
import '../../widgets/circle_icon_button.dart';

/// Top header for the toolbox screen with title, subtitle, and profile button.
class ToolHubHeader extends StatelessWidget {
  const ToolHubHeader({super.key, this.onProfileTap});

  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
          ),
          const SizedBox(width: 12),
          CircleIconButton(
            asset: 'assets/icons/ic_profile.svg',
            semanticLabel: 'Profile',
            onPressed: onProfileTap ?? () {},
            size: 48,
            iconSize: 22,
          ),
        ],
      ),
    );
  }
}
