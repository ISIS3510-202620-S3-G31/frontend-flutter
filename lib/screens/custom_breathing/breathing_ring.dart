import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_colors.dart';

/// In the mockup the sparkles are drawn for a ring at 40%, so they are rotated from there.
const double _sparklesProgress = 0.4;

/// Circular timer: a dim track, an arc that goes from teal to orange, a soft glow
/// and some sparkles at the head of the arc. The child goes in the middle.
class BreathingRing extends StatelessWidget {
  const BreathingRing({super.key, required this.progress, required this.child});

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final value = progress.clamp(0.0, 1.0).toDouble();
    return SizedBox(
      width: 190,
      height: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: CustomPaint(painter: _RingPainter(value))),
          Positioned.fill(
            child: Transform.rotate(
              angle: 2 * math.pi * (value - _sparklesProgress),
              child: SvgPicture.asset(
                'assets/icons/breathing_ring_sparkles.svg',
                width: 190,
                height: 190,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);

  final double progress;

  static const double _stroke = 12;
  static const double _startAngle = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - _stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweep = 2 * math.pi * progress;
    final head = Offset(
      center.dx + radius * math.cos(_startAngle + sweep),
      center.dy + radius * math.sin(_startAngle + sweep),
    );

    // Glow behind the head of the arc (primary colour at 55%).
    const glowRadius = 25.0;
    final glowRect = Rect.fromCircle(center: head, radius: glowRadius);
    canvas.drawCircle(
      head,
      glowRadius,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x8CF8840E), Color(0x00F8840E)],
        ).createShader(glowRect),
    );

    // Track: background colour at 14%.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..color = const Color(0x24F9DEAA),
    );

    if (progress <= 0) return;

    // The gradient goes from the top of the ring to the head of the arc.
    // After half a turn the head goes up again, so the bottom of the ring is used.
    final top = center.dy - radius;
    final gradientEnd =
        sweep < math.pi ? math.max(head.dy, top + 1) : center.dy + radius;
    canvas.drawArc(
      rect,
      _startAngle,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.secondary, AppColors.primary],
        ).createShader(Rect.fromLTRB(rect.left, top, rect.right, gradientEnd)),
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
