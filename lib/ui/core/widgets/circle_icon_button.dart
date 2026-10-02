import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

/// 48 × 48 round button with an SVG icon (back, gallery, flip, restart, done…).
///
/// When [onPressed] is null the button is drawn at 40% opacity.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.asset,
    required this.semanticLabel,
    required this.onPressed,
    this.background = AppColors.secondary,
    this.size = 48,
    this.iconSize = 22,
  });

  final String asset;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final Color background;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      child: Opacity(
        opacity: onPressed == null ? 0.4 : 1,
        child: Material(
          color: background,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox.square(
              dimension: size,
              child: Center(
                child: SvgPicture.asset(
                  asset,
                  width: iconSize,
                  height: iconSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
