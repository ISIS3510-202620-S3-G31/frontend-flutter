import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../data/services/wish_sky_layout.dart';
import 'lantern_painter.dart';
import 'rapunzel_colors.dart';

/// One background lantern drawn static by the sky painter, because its
/// animation slot is taken: it keeps a fixed flame phase and never repaints.
class StaticLantern {
  const StaticLantern(this.slot, {required this.lit});

  /// Normalized position in the sky.
  final Offset slot;
  final bool lit;

  @override
  bool operator ==(Object other) =>
      other is StaticLantern && other.slot == slot && other.lit == lit;

  @override
  int get hashCode => Object.hash(slot, lit);
}

/// The night sky itself: gradient, moon, stars and every lantern that is not
/// animating. It sits inside a RepaintBoundary, so the animated lanterns on
/// top never repaint it, and it only repaints when the layout or the lit set
/// actually changed.
class NightSkyPainter extends CustomPainter {
  const NightSkyPainter({
    required this.layout,
    required this.staticLanterns,
    this.foreground,
    this.foregroundSize = 110,
  });

  final SkyLayout layout;

  /// Normalized slots of the lanterns drawn static, in logical lantern size
  /// [lanternSize].
  final List<StaticLantern> staticLanterns;
  static const lanternSize = 40.0;

  /// The held lantern when it is not animating, normalized slot.
  final Offset? foreground;
  final double foregroundSize;

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Offset.zero & size;
    canvas.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [RapunzelColors.skyTop, RapunzelColors.skyHorizon],
        ).createShader(sky),
    );

    // Moon with a soft halo, top right.
    final moonCenter = Offset(size.width * 0.82, size.height * 0.13);
    final moonRadius = size.width * 0.055;
    canvas.drawCircle(
      moonCenter,
      moonRadius * 2.1,
      Paint()
        ..shader = RadialGradient(
          colors: [
            RapunzelColors.moon.withValues(alpha: 0.35),
            RapunzelColors.moon.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: moonCenter, radius: moonRadius * 2.1)),
    );
    canvas.drawCircle(moonCenter, moonRadius, Paint()..color = RapunzelColors.moon);

    // Stars.
    for (final star in layout.stars) {
      canvas.drawCircle(
        Offset(star.position.dx * size.width, star.position.dy * size.height),
        star.radius,
        Paint()..color = RapunzelColors.star.withValues(alpha: star.alpha),
      );
    }

    // Lanterns without an animation slot: fixed phase, no flicker, no
    // repaint while the others animate.
    for (final lantern in staticLanterns) {
      paintLantern(
        canvas,
        Offset(
          lantern.slot.dx * size.width,
          lantern.slot.dy * size.height,
        ),
        lanternSize * 0.78,
        lanternSize,
        lit: lantern.lit,
        flamePhase: 0.8,
      );
    }

    final foreground = this.foreground;
    if (foreground != null) {
      paintLantern(
        canvas,
        Offset(foreground.dx * size.width, foreground.dy * size.height),
        foregroundSize * 0.78,
        foregroundSize,
        lit: true,
        flamePhase: 0.8,
      );
    }
  }

  @override
  bool shouldRepaint(covariant NightSkyPainter oldDelegate) =>
      !identical(oldDelegate.layout, layout) ||
      !listEquals(oldDelegate.staticLanterns, staticLanterns) ||
      oldDelegate.foreground != foreground;
}
