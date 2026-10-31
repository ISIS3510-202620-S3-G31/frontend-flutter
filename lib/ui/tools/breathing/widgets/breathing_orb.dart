import 'package:flutter/material.dart';

import '../../../../data/models/breathing_model.dart';
import '../../../core/theme/app_colors.dart';

/// orb
class BreathingOrb extends StatelessWidget {
  const BreathingOrb({
    super.key,
    required this.phase,
    required this.progress,
    required this.child,
    this.size = 250,
  });

  final BreathingPhase phase;
  final double progress;
  final double size;
  final Widget child;

  /// How open the breath is: 0 fully exhaled, 1 fully inhaled.
  double get _breathTarget {
    final value = progress.clamp(0.0, 1.0).toDouble();
    return switch (phase) {
      BreathingPhase.inhale => value,
      BreathingPhase.hold => 1.0,
      BreathingPhase.exhale => 1 - value,
    };
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: _breathTarget),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        builder: (context, breath, child) => Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(child: CustomPaint(painter: _OrbPainter(breath))),
            // The label gently grows with the breath.
            Transform.scale(scale: 1 + 0.05 * breath, child: child),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  _OrbPainter(this.breath);

  final double breath;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide / 2;

    // to make it feel more organic
    final core = (breath - 0.08).clamp(0.0, 1.0).toDouble();
    final halo = (breath - 0.04).clamp(0.0, 1.0).toDouble();

    // Outer aura: the faintest and largest layer.
    _glow(
      canvas,
      center,
      maxRadius * (0.50 + 0.50 * breath),
      0.04 + 0.26 * breath,
    );
    // Mid halo.
    _glow(canvas, center, maxRadius * (0.38 + 0.52 * halo), 0.08 + 0.38 * halo);
    // Core: the brightest and most opaque layer.
    _glow(
      canvas,
      center,
      maxRadius * (0.26 + 0.46 * core),
      0.30 + 0.25 * core,
      edge: 0.85,
    );
  }

  void _glow(
    Canvas canvas,
    Offset center,
    double radius,
    double alpha, {
    double edge = 0.65,
  }) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          stops: [0.0, edge, 1.0],
          colors: [
            AppColors.secondary.withValues(alpha: alpha),
            AppColors.secondary.withValues(alpha: alpha * 0.6),
            AppColors.secondary.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_OrbPainter oldDelegate) => oldDelegate.breath != breath;
}
