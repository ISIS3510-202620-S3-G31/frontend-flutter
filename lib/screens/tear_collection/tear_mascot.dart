import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class SproutMascot extends StatelessWidget {
  const SproutMascot({
    super.key,
    this.width = 60,
    this.height = 72,
    this.showGroundRipples = false,
  });

  final double width;
  final double height;
  final bool showGroundRipples;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _SproutMascotPainter(showGroundRipples: showGroundRipples),
    );
  }
}

class _SproutMascotPainter extends CustomPainter {
  const _SproutMascotPainter({required this.showGroundRipples});

  final bool showGroundRipples;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Line paints
    final strokePaint = Paint()
      ..color = AppColors.text
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // Optional ground ripple rings underneath
    if (showGroundRipples) {
      final ripplePaint = Paint()
        ..color = AppColors.text.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..isAntiAlias = true;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.94),
          width: w * 0.95,
          height: h * 0.12,
        ),
        ripplePaint,
      );

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.94),
          width: w * 0.65,
          height: h * 0.08,
        ),
        ripplePaint,
      );
    }

    // Body bounds (chubby egg/round shape)
    final bodyTop = h * 0.24;
    final bodyBottom = showGroundRipples ? h * 0.88 : h * 0.95;
    final bodyHeight = bodyBottom - bodyTop;
    final bodyRect = Rect.fromCenter(
      center: Offset(w * 0.5, bodyTop + bodyHeight * 0.5),
      width: w * 0.76,
      height: bodyHeight,
    );

    // 1. Sprout leaves on head
    final sproutPath = Path();
    sproutPath.moveTo(w * 0.5, bodyTop);
    sproutPath.lineTo(w * 0.5, h * 0.08);

    // Left leaf
    final leftLeaf = Path()
      ..moveTo(w * 0.5, h * 0.14)
      ..cubicTo(w * 0.36, h * 0.08, w * 0.32, h * 0.02, w * 0.44, h * 0.02)
      ..cubicTo(w * 0.49, h * 0.02, w * 0.5, h * 0.08, w * 0.5, h * 0.14)
      ..close();

    // Right leaf
    final rightLeaf = Path()
      ..moveTo(w * 0.5, h * 0.14)
      ..cubicTo(w * 0.64, h * 0.08, w * 0.68, h * 0.02, w * 0.56, h * 0.02)
      ..cubicTo(w * 0.51, h * 0.02, w * 0.5, h * 0.08, w * 0.5, h * 0.14)
      ..close();

    final leafFill = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(leftLeaf, leafFill);
    canvas.drawPath(rightLeaf, leafFill);
    canvas.drawPath(leftLeaf, strokePaint);
    canvas.drawPath(rightLeaf, strokePaint);
    canvas.drawLine(
      Offset(w * 0.5, bodyTop),
      Offset(w * 0.5, h * 0.14),
      strokePaint,
    );

    // 2. Body fill and stroke
    final bodyPath = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          bodyRect,
          topLeft: Radius.circular(bodyRect.width * 0.5),
          topRight: Radius.circular(bodyRect.width * 0.5),
          bottomLeft: Radius.circular(bodyRect.width * 0.45),
          bottomRight: Radius.circular(bodyRect.width * 0.45),
        ),
      );

    final bodyFill = Paint()
      ..color = const Color(0xFFF6DEB9)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(bodyPath, bodyFill);
    canvas.drawPath(bodyPath, strokePaint);

    // 3. Face features
    final eyeY = bodyTop + bodyHeight * 0.32;
    final leftEyeX = w * 0.41;
    final rightEyeX = w * 0.59;
    final eyeRadius = w * 0.045;

    final leftEyePath = Path()
      ..moveTo(leftEyeX - eyeRadius, eyeY)
      ..quadraticBezierTo(
        leftEyeX,
        eyeY - eyeRadius * 1.2,
        leftEyeX + eyeRadius,
        eyeY,
      );
    canvas.drawPath(leftEyePath, strokePaint);

    final rightEyePath = Path()
      ..moveTo(rightEyeX - eyeRadius, eyeY)
      ..quadraticBezierTo(
        rightEyeX,
        eyeY - eyeRadius * 1.2,
        rightEyeX + eyeRadius,
        eyeY,
      );
    canvas.drawPath(rightEyePath, strokePaint);
    final blushPaint = Paint()
      ..color = const Color(0xFFF79F9F).withValues(alpha: 0.65)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(leftEyeX - eyeRadius * 1.2, eyeY + eyeRadius * 0.8),
        width: eyeRadius * 1.8,
        height: eyeRadius * 1.1,
      ),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(rightEyeX + eyeRadius * 1.2, eyeY + eyeRadius * 0.8),
        width: eyeRadius * 1.8,
        height: eyeRadius * 1.1,
      ),
      blushPaint,
    );

    // Little smile mouth
    final mouthY = eyeY + eyeRadius * 0.9;
    final mouthPath = Path()
      ..moveTo(w * 0.48, mouthY)
      ..quadraticBezierTo(w * 0.5, mouthY + eyeRadius * 0.6, w * 0.52, mouthY);
    canvas.drawPath(mouthPath, strokePaint);

    // 4. Heart held at chest
    final heartCenter = Offset(w * 0.5, bodyTop + bodyHeight * 0.65);
    final hw = w * 0.22;
    final hh = hw * 0.95;

    final heartPath = Path()
      ..moveTo(heartCenter.dx, heartCenter.dy + hh * 0.45)
      ..cubicTo(
        heartCenter.dx - hw * 0.55,
        heartCenter.dy,
        heartCenter.dx - hw * 0.55,
        heartCenter.dy - hh * 0.45,
        heartCenter.dx,
        heartCenter.dy - hh * 0.2,
      )
      ..cubicTo(
        heartCenter.dx + hw * 0.55,
        heartCenter.dy - hh * 0.45,
        heartCenter.dx + hw * 0.55,
        heartCenter.dy,
        heartCenter.dx,
        heartCenter.dy + hh * 0.45,
      )
      ..close();

    final heartFill = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawPath(heartPath, heartFill);
    canvas.drawPath(heartPath, strokePaint);

    // Tiny hands holding the heart
    final handPaint = Paint()
      ..color = const Color(0xFFF6DEB9)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(
      Offset(heartCenter.dx - hw * 0.42, heartCenter.dy + hh * 0.05),
      hw * 0.22,
      handPaint,
    );
    canvas.drawCircle(
      Offset(heartCenter.dx - hw * 0.42, heartCenter.dy + hh * 0.05),
      hw * 0.22,
      strokePaint,
    );

    canvas.drawCircle(
      Offset(heartCenter.dx + hw * 0.42, heartCenter.dy + hh * 0.05),
      hw * 0.22,
      handPaint,
    );
    canvas.drawCircle(
      Offset(heartCenter.dx + hw * 0.42, heartCenter.dy + hh * 0.05),
      hw * 0.22,
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SproutMascotPainter oldDelegate) {
    return oldDelegate.showGroundRipples != showGroundRipples;
  }
}
