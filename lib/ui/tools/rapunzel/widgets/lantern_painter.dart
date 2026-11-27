import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'rapunzel_colors.dart';

/// Draws one paper lantern centered at [center], [width] wide and [height]
/// tall: string, caps, ribbed paper body and, when lit, the glow and flame.
///
/// [light] goes 0 to 1 (the lighting animation) and [flamePhase] is the
/// flicker angle, so a lit lantern can be drawn with a steady flame (phase 0,
/// no animation slot) or a flickering one.
void paintLantern(
  Canvas canvas,
  Offset center,
  double width,
  double height, {
  required bool lit,
  double light = 1,
  double flamePhase = 0,
}) {
  final cx = center.dx;
  final cy = center.dy;
  final w = width / 2;
  final h = height / 2;

  // Glow behind the paper, growing with the light.
  if (light > 0) {
    final glowRadius = width * 1.9;
    canvas.drawCircle(
      center,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            RapunzelColors.glow.withValues(alpha: 0.42 * light),
            RapunzelColors.glow.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: glowRadius)),
    );
  }

  // String and caps.
  canvas.drawLine(
    Offset(cx, cy - h - height * 0.22),
    Offset(cx, cy - h),
    Paint()
      ..color = RapunzelColors.cap
      ..strokeWidth = math.max(1, width * 0.03),
  );
  final capPaint = Paint()..color = RapunzelColors.cap;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy - h), width: width * 0.36, height: height * 0.09),
      Radius.circular(height * 0.04),
    ),
    capPaint,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + h), width: width * 0.3, height: height * 0.08),
      Radius.circular(height * 0.04),
    ),
    capPaint,
  );

  // Paper body with vertical ribs, clipped to the ellipse.
  final body = Rect.fromCenter(center: center, width: width, height: height);
  canvas.save();
  canvas.clipPath(Path()..addOval(body));
  canvas.drawRect(
    body,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: lit
            ? const [RapunzelColors.lanternTop, RapunzelColors.lanternBottom]
            : const [RapunzelColors.lanternDarkTop, RapunzelColors.lanternDarkBottom],
      ).createShader(body),
  );
  final ribPaint = Paint()
    ..color = RapunzelColors.cap.withValues(alpha: 0.28)
    ..strokeWidth = math.max(1, width * 0.025);
  for (var k = -2; k <= 2; k++) {
    final x = cx + k * width * 0.19;
    canvas.drawLine(Offset(x, cy - h), Offset(x, cy + h), ribPaint);
  }
  // A horizontal band across the middle, where the paper is folded.
  canvas.drawLine(
    Offset(cx - w, cy),
    Offset(cx + w, cy),
    Paint()
      ..color = RapunzelColors.cap.withValues(alpha: 0.35)
      ..strokeWidth = math.max(1, width * 0.03),
  );
  canvas.restore();

  // Flame: a teardrop that flickers with the phase and grows with the light.
  if (light > 0) {
    final flameHeight = height * 0.2 * light * (1 + 0.18 * math.sin(flamePhase));
    final flameWidth = width * 0.16 * light;
    final path = Path()
      ..moveTo(cx, cy - flameHeight)
      ..quadraticBezierTo(
        cx + flameWidth,
        cy - flameHeight * 0.25,
        cx,
        cy + flameHeight * 0.55,
      )
      ..quadraticBezierTo(
        cx - flameWidth,
        cy - flameHeight * 0.25,
        cx,
        cy - flameHeight,
      );
    canvas.drawPath(
      path,
      Paint()..color = RapunzelColors.flameOuter.withValues(alpha: 0.9 * light),
    );
    final coreHeight = flameHeight * 0.55;
    final coreWidth = flameWidth * 0.5;
    final core = Path()
      ..moveTo(cx, cy - coreHeight * 0.4)
      ..quadraticBezierTo(
        cx + coreWidth,
        cy + coreHeight * 0.1,
        cx,
        cy + coreHeight * 0.5,
      )
      ..quadraticBezierTo(
        cx - coreWidth,
        cy + coreHeight * 0.1,
        cx,
        cy - coreHeight * 0.4,
      );
    canvas.drawPath(
      core,
      Paint()..color = RapunzelColors.flameCore.withValues(alpha: light),
    );
  }
}

/// Paints a single lantern in its own box; used inside a RepaintBoundary so
/// the flicker repaints only this lantern.
class LanternPainter extends CustomPainter {
  const LanternPainter({
    required this.lit,
    this.light = 1,
    this.flamePhase = 0,
  });

  final bool lit;
  final double light;
  final double flamePhase;

  @override
  void paint(Canvas canvas, Size size) {
    paintLantern(
      canvas,
      size.center(Offset.zero),
      size.width * 0.78,
      size.height * 0.78,
      lit: lit,
      light: light,
      flamePhase: flamePhase,
    );
  }

  @override
  bool shouldRepaint(covariant LanternPainter oldDelegate) => true;
}
