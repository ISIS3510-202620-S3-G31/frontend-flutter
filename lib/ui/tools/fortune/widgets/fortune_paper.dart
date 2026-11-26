import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import 'fortune_stage.dart';

/// Colors of the Fortune Cookie, the Kotlin app's.
abstract final class FortuneColors {
  static const backdropTop = Color(0xFFFCEFD5);
  static const paperTop = Color(0xFFFBEACB);
  static const paperBottom = Color(0xFFFAE3B8);
  static Color get mutedText => AppColors.text.withValues(alpha: 0.62);
}

/// The Fortune Cookie's headline font.
TextStyle fortuneHeadline(double size) => TextStyle(
  fontFamily: AppText.headlineFamily,
  fontSize: size,
  height: 1.25,
  color: AppColors.text,
);

/// How wavy the top and bottom edges of a flat paper are, as a share of its
/// height.
const fortunePaperRestingWave = 0.035;

/// The slip of paper with the phrase, its top and bottom edges gently wavy
/// like the Kotlin app's. The cookie halves rest on its ends.
///
/// [wave] is the height of the waves in pixels; by default, the resting
/// wave of a flat paper. While it comes out of the cookie the paper is drawn
/// smaller, [widthFactor] and [heightFactor] of its size, and the phrase
/// shows as it flattens ([textOpacity]).
class FortunePaper extends StatelessWidget {
  const FortunePaper({
    super.key,
    required this.quote,
    this.wave,
    this.widthFactor = 1,
    this.heightFactor = 1,
    this.textOpacity = 1,
  });

  final String quote;
  final double? wave;
  final double widthFactor;
  final double heightFactor;
  final double textOpacity;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: fortunePaperSidePadding),
      child: CustomPaint(
        painter: FortunePaperPainter(
          wave: wave,
          widthFactor: widthFactor,
          heightFactor: heightFactor,
        ),
        child: Container(
          constraints: const BoxConstraints(minHeight: 112),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          alignment: Alignment.center,
          child: Opacity(
            opacity: textOpacity,
            child: Text(
              quote,
              textAlign: TextAlign.center,
              style: fortuneHeadline(20),
            ),
          ),
        ),
      ),
    );
  }
}

/// The paper itself: wavy top and bottom edges, rounded corners, a soft
/// shadow below, a light cream that warms towards the bottom and a thin
/// orange line around it.
class FortunePaperPainter extends CustomPainter {
  const FortunePaperPainter({
    this.wave,
    this.widthFactor = 1,
    this.heightFactor = 1,
  });

  final double? wave;

  /// The share of the space the paper takes, centered: smaller while it is
  /// still coming out of the cookie.
  final double widthFactor;
  final double heightFactor;

  static const _cream = Color(0xFFFAE5BB);

  @override
  void paint(Canvas canvas, Size size) {
    final wave = this.wave ?? size.height * fortunePaperRestingWave;
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width * widthFactor,
      height: size.height * heightFactor,
    );
    canvas.drawPath(
      paperPath(rect.shift(const Offset(0, 4)), wave),
      Paint()..color = AppColors.text.withValues(alpha: 0.16),
    );
    final path = paperPath(rect, wave);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_cream, _cream, Color.lerp(_cream, AppColors.primary, 0.1)!],
        ).createShader(rect),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.primary.withValues(alpha: 0.5),
    );
  }

  /// The outline: one smooth wave from end to end on the top and bottom
  /// edges, straight sides and rounded corners.
  static Path paperPath(Rect rect, double wave) {
    const steps = 28;
    final radius = [32.0, rect.height / 4, rect.width / 8].reduce(math.min);
    double edge(double base, int i) =>
        base + wave * math.sin(i * 2 * math.pi / steps);
    double x(int i) => rect.left + rect.width * i / steps;

    final path = Path()..moveTo(rect.left + radius, edge(rect.top, 1));
    for (var i = 1; i < steps; i++) {
      path.lineTo(x(i), edge(rect.top, i));
    }
    path
      ..quadraticBezierTo(
        rect.right,
        edge(rect.top, steps),
        rect.right,
        rect.top + radius,
      )
      ..lineTo(rect.right, rect.bottom - radius)
      ..quadraticBezierTo(
        rect.right,
        edge(rect.bottom, steps),
        x(steps - 1),
        edge(rect.bottom, steps - 1),
      );
    for (var i = steps - 2; i >= 1; i--) {
      path.lineTo(x(i), edge(rect.bottom, i));
    }
    return path
      ..quadraticBezierTo(
        rect.left,
        edge(rect.bottom, 0),
        rect.left,
        rect.bottom - radius,
      )
      ..lineTo(rect.left, rect.top + radius)
      ..quadraticBezierTo(rect.left, edge(rect.top, 0), x(1), edge(rect.top, 1))
      ..close();
  }

  @override
  bool shouldRepaint(FortunePaperPainter old) =>
      old.wave != wave ||
      old.widthFactor != widthFactor ||
      old.heightFactor != heightFactor;
}

/// Bits of cookie that jump out when it splits and fall with gravity.
class CookieShardsPainter extends CustomPainter {
  const CookieShardsPainter(this.progress);

  final double progress;

  static const _light = Color(0xFFE0A85E);
  static const _dark = Color(0xFFA8652A);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final origin = Offset(size.width * 0.5, size.height * 0.35);
    for (var i = 0; i < 12; i++) {
      final angle = (-175 + i * 15) * math.pi / 180;
      final distance = size.width * 0.7 * progress * (0.7 + (i % 3) * 0.15);
      final fall = size.height * 0.55 * progress * progress;
      final x = origin.dx + math.cos(angle) * distance;
      final y = origin.dy + math.sin(angle) * distance + fall;
      final r = size.width * 0.022 * (1 + i % 3);
      final shard = Path()
        ..moveTo(x, y - r)
        ..lineTo(x + r, y + r)
        ..lineTo(x - r * 0.8, y + r * 0.6)
        ..close();
      canvas.drawPath(
        shard,
        Paint()
          ..color = (i.isEven ? _light : _dark).withValues(alpha: 1 - progress),
      );
    }
  }

  @override
  bool shouldRepaint(CookieShardsPainter old) => old.progress != progress;
}

/// A rounded button of the Fortune Cookie: light with an icon, or solid
/// orange for the main action.
class FortunePill extends StatelessWidget {
  const FortunePill({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconColor,
    this.solid = false,
    this.width = 128,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? iconColor;
  final bool solid;
  final double width;

  @override
  Widget build(BuildContext context) {
    final background = solid
        ? AppColors.primary
        : FortuneColors.backdropTop.withValues(alpha: 0.85);
    return SizedBox(
      width: width,
      height: 44,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(22),
        elevation: solid ? 3 : 1,
        shadowColor: AppColors.primary.withValues(alpha: 0.4),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
