import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_colors.dart';

/// 116 × 116 mic button. While listening, the two outer rings grow with the
/// mic level.
class MicButton extends StatelessWidget {
  const MicButton({
    super.key,
    required this.listening,
    required this.level,
    required this.onPressed,
  });

  final bool listening;

  /// Mic level 0..1, from `levelFromDb`.
  final double level;

  /// Null disables the button (drawn at 40% opacity).
  final VoidCallback? onPressed;

  Widget _ring(double size, double alpha) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: alpha),
      shape: BoxShape.circle,
    ),
  );

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 80);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: listening ? 'Pause microphone' : 'Start microphone',
      child: GestureDetector(
        onTap: onPressed,
        child: Opacity(
          opacity: onPressed == null ? 0.4 : 1,
          child: SizedBox.square(
            dimension: 116,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (listening)
                  AnimatedScale(
                    scale: 1 + 0.15 * level,
                    duration: duration,
                    child: _ring(116, 0.15),
                  ),
                if (listening)
                  AnimatedScale(
                    scale: 1 + 0.08 * level,
                    duration: duration,
                    child: _ring(96, 0.30),
                  ),
                _ring(76, 1),
                SvgPicture.asset(
                  'assets/icons/ic_mic.svg',
                  width: 34,
                  height: 34,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
