import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class BreathingRoundButton extends StatelessWidget {
  const BreathingRoundButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.filled = false,
    this.size = 48,
  });

  final Widget icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      excludeSemantics: true,
      child: Opacity(
        opacity: onPressed == null ? 0.4 : 1,
        child: Material(
          color: filled ? AppColors.secondary : AppColors.background,
          shape: const CircleBorder(
            side: BorderSide(color: AppColors.secondary),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox.square(
              dimension: size,
              child: Center(child: icon),
            ),
          ),
        ),
      ),
    );
  }
}
