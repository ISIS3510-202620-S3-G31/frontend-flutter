import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Renders a teardrop shape with either a solid color or a gradient.
class Teardrop extends StatelessWidget {
  const Teardrop({
    super.key,
    required this.width,
    required this.height,
    this.color,
    this.gradient,
  }) : assert(color != null || gradient != null, 'Either color or gradient must be provided');

  final double width;
  final double height;
  final Color? color;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _TeardropPainter(color: color, gradient: gradient),
    );
  }
}

class _TeardropPainter extends CustomPainter {
  const _TeardropPainter({this.color, this.gradient});

  final Color? color;
  final Gradient? gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w / 2, 0)
      ..cubicTo(w * 0.98, h * 0.40, w, h * 0.72, w / 2, h)
      ..cubicTo(0, h * 0.72, w * 0.02, h * 0.40, w / 2, 0)
      ..close();

    final paint = Paint()..isAntiAlias = true;
    if (gradient != null) {
      paint.shader = gradient!.createShader(Rect.fromLTWH(0, 0, w, h));
    } else {
      paint.color = color!;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TeardropPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.gradient != gradient;
  }
}

/// Large floating teardrop with a soft radial halo and subtle ground shadow.
class FloatingHeroTeardrop extends StatelessWidget {
  const FloatingHeroTeardrop({
    super.key,
    this.width = 62,
    this.height = 84,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft radial glow aura behind the teardrop
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.75),
                  Colors.white.withValues(alpha: 0.4),
                  AppColors.background.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Floating teardrop with vertical gradient
          Positioned(
            top: 24,
            child: Teardrop(
              width: width,
              height: height,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.secondary, // Teal at top
                  AppColors.primary,   // Orange at bottom
                ],
              ),
            ),
          ),

          // Ground shadow beneath the floating tear
          Positioned(
            bottom: 22,
            child: Container(
              width: 38,
              height: 10,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.elliptical(19, 5)),
                color: AppColors.text.withValues(alpha: 0.12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
