import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders a teardrop shape with either a solid color, gradient, or default SVG.
class Teardrop extends StatelessWidget {
  const Teardrop({
    super.key,
    required this.width,
    required this.height,
    this.color,
    this.gradient,
  });

  final double width;
  final double height;
  final Color? color;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    if (color == null && gradient == null) {
      return SvgPicture.asset(
        'assets/illustrations/teardrop.svg',
        width: width,
        height: height,
        fit: BoxFit.contain,
      );
    }

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

/// Large floating teardrop illustration with halo and ground shadow loaded from SVG asset.
class FloatingHeroTeardrop extends StatelessWidget {
  const FloatingHeroTeardrop({
    super.key,
    this.width = 160,
    this.height = 160,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/illustrations/hero_teardrop.svg',
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }
}
