import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../data/models/cookie_model.dart';
import '../../../../domain/cookie_jar/cookie_jar_rules.dart';
import '../../../core/theme/app_colors.dart';

class _Slot {
  const _Slot(this.x, this.y, this.degrees);

  final double x;
  final double y;
  final double degrees;
}

const _slots = [
  _Slot(0.19, 0.86, -8), _Slot(0.50, 0.88, 6), _Slot(0.81, 0.86, -4),
  _Slot(0.34, 0.64, 10), _Slot(0.66, 0.65, -7),
  _Slot(0.19, 0.43, 4), _Slot(0.50, 0.44, -10), _Slot(0.81, 0.43, 7),
  _Slot(0.34, 0.22, -5), _Slot(0.66, 0.22, 9),
];

const _jarAspect = 0.78;
const _bodyInsetX = 0.07;
const _bodyTop = 0.20;
const _bodyBottom = 0.95;

const _cookieSizeFraction = 0.34;

const _glassLight = Color(0xFFFFF4DC);

class CookieJarDrawing extends StatelessWidget {
  const CookieJarDrawing({
    super.key,
    required this.cookies,
    required this.onCookieTap,
  });

  final List<CookieModel> cookies;
  final ValueChanged<CookieModel> onCookieTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _jarAspect,
      child: LayoutBuilder(
        builder: (context, box) {
          final bodyLeft = box.maxWidth * _bodyInsetX;
          final bodyWidth = box.maxWidth * (1 - 2 * _bodyInsetX);
          final bodyTop = box.maxHeight * _bodyTop;
          final bodyHeight = box.maxHeight * (_bodyBottom - _bodyTop);
          final cookieSize = bodyWidth * _cookieSizeFraction;
          final shown = cookies.take(CookieJarRules.capacity).toList();

          return Stack(
            children: [
              const Positioned.fill(child: CustomPaint(painter: JarPainter())),
              for (var i = 0; i < shown.length; i++)
                Positioned(
                  left: bodyLeft + bodyWidth * _slots[i].x - cookieSize / 2,
                  top: bodyTop + bodyHeight * _slots[i].y - cookieSize / 2,
                  width: cookieSize,
                  height: cookieSize,
                  child: Transform.rotate(
                    angle: _slots[i].degrees * math.pi / 180,
                    child: _CookieButton(
                      cookie: shown[i],
                      onTap: () => onCookieTap(shown[i]),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CookieButton extends StatelessWidget {
  const _CookieButton({required this.cookie, required this.onTap});

  final CookieModel cookie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: cookie.title,
      onTapHint: 'Open',
      child: Material(
        type: MaterialType.transparency,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const CustomPaint(painter: CookiePainter()),
        ),
      ),
    );
  }
}

/// The glass: light, semi-transparent body with rounded corners, a neck and a lid in the secondary color.
class JarPainter extends CustomPainter {
  const JarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final outline = Paint()
      ..color = AppColors.text.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.018;

    final lidWidth = w * 0.62;
    final lid = RRect.fromRectAndRadius(
      Rect.fromLTWH((w - lidWidth) / 2, h * 0.02, lidWidth, h * 0.075),
      Radius.circular(w * 0.03),
    );
    canvas
      ..drawRRect(lid, Paint()..color = AppColors.secondary)
      ..drawRRect(lid, outline);

    final neckWidth = w * 0.54;
    final neckLeft = (w - neckWidth) / 2;
    final neckRight = neckLeft + neckWidth;
    final glass = Path()
      ..moveTo(neckLeft, h * 0.10)
      ..lineTo(neckLeft, h * 0.13)
      ..cubicTo(neckLeft, h * 0.16, w * 0.02, h * 0.15, w * 0.02, h * 0.22)
      ..lineTo(w * 0.02, h * 0.90)
      ..quadraticBezierTo(w * 0.02, h * 0.985, w * 0.10, h * 0.985)
      ..lineTo(w * 0.90, h * 0.985)
      ..quadraticBezierTo(w * 0.98, h * 0.985, w * 0.98, h * 0.90)
      ..lineTo(w * 0.98, h * 0.22)
      ..cubicTo(w * 0.98, h * 0.15, neckRight, h * 0.16, neckRight, h * 0.13)
      ..lineTo(neckRight, h * 0.10)
      ..close();
    canvas
      ..drawPath(glass, Paint()..color = _glassLight.withValues(alpha: 0.65))
      ..drawPath(glass, outline);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, h * 0.27, w * 0.035, h * 0.45),
        Radius.circular(w * 0.02),
      ),
      Paint()..color = _glassLight,
    );
  }

  /// The jar never changes, so it never needs repainting.
  @override
  bool shouldRepaint(JarPainter oldDelegate) => false;
}

/// A round cookie in the primary color with a rim and chocolate chips.
class CookiePainter extends CustomPainter {
  const CookiePainter();

  static const _chips = [
    Offset(-0.35, -0.30), Offset(0.25, -0.42), Offset(0.40, 0.10),
    Offset(-0.10, 0.05), Offset(-0.42, 0.30), Offset(0.12, 0.45),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final center = size.center(Offset.zero);
    canvas
      ..drawCircle(center, r, Paint()..color = AppColors.primary)
      ..drawCircle(
        center,
        r * 0.94,
        Paint()
          ..color = AppColors.text.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.08,
      )
      ..drawCircle(
        center + Offset(-r * 0.12, -r * 0.12),
        r * 0.62,
        Paint()..color = AppColors.background.withValues(alpha: 0.35),
      );
    final chip = Paint()..color = AppColors.text.withValues(alpha: 0.8);
    for (var i = 0; i < _chips.length; i++) {
      canvas.drawCircle(
        center + _chips[i] * r,
        r * (i.isEven ? 0.11 : 0.085),
        chip,
      );
    }
  }

  @override
  bool shouldRepaint(CookiePainter oldDelegate) => false;
}
