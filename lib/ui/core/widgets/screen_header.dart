import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import 'circle_icon_button.dart';

/// Back button followed by a title and an optional subtitle.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
  });

  /// Usually `Text(..., style: AppText.h1)`, or the Scream Tank wordmark.
  final Widget title;
  final String? subtitle;

  /// Defaults to popping the current route.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Row(
        children: [
          CircleIconButton(
            asset: 'assets/icons/ic_chevron_left.svg',
            semanticLabel: 'Back',
            onPressed: onBack ?? () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                title,
                if (subtitle != null) Text(subtitle!, style: AppText.bodyMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
