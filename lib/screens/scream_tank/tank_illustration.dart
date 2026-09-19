import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

/// Voice waves, the tank, its fill gauge and the fill percentage (294 × 250).
class TankIllustration extends StatelessWidget {
  const TankIllustration({
    super.key,
    required this.fill,
    required this.micLevel,
    required this.listening,
  });

  /// How full the tank is, 0..1.
  final double fill;

  /// Current mic level, 0..1. Makes the voice waves brighter.
  final double micLevel;
  final bool listening;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 294,
      height: 250,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 100),
              opacity: listening ? 0.4 + 0.6 * micLevel : 0.4,
              child: SvgPicture.asset(
                'assets/illustrations/voice_waves.svg',
                width: 80,
                height: 250,
              ),
            ),
          ),
          Positioned(
            left: 90,
            top: 2,
            child: SvgPicture.asset(
              'assets/illustrations/scream_tank.svg',
              width: 116,
              height: 246,
            ),
          ),
          // Sits exactly on the dark window of the tank.
          Positioned(left: 140.4, top: 63.5, child: TankGauge(level: fill)),
          Positioned(
            left: 228,
            top: 0,
            child: Text(
              '${(fill * 100).round()}%',
              style: AppText.body.copyWith(color: AppColors.background),
            ),
          ),
        ],
      ),
    );
  }
}

/// 5 segments inside the tank window that light up from the bottom.
class TankGauge extends StatelessWidget {
  const TankGauge({super.key, required this.level});

  /// How full the tank is, 0..1.
  final double level;

  static const _count = 5;

  @override
  Widget build(BuildContext context) {
    final lit = (level.clamp(0.0, 1.0) * _count).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(7.5),
      child: Container(
        width: 15,
        height: 115,
        color: AppColors.text,
        padding: const EdgeInsets.symmetric(horizontal: 1.5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _count; i++) ...[
              if (i > 0) const SizedBox(height: 4),
              Container(
                height: 18,
                decoration: BoxDecoration(
                  // i = 0 is the top segment, so the lit ones are the last `lit`.
                  color: i >= _count - lit
                      ? AppColors.accent
                      : AppColors.background.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
