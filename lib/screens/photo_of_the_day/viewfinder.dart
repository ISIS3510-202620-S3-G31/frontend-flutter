import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/circle_icon_button.dart';

/// Dark rounded card that holds the camera preview or today's photo.
///
/// Layers, bottom to top: [content] (or the dark fill), rule-of-thirds grid,
/// the "Frame your moment today" prompt, and the date pill + flash button.
class Viewfinder extends StatelessWidget {
  const Viewfinder({
    super.key,
    required this.date,
    required this.flashOn,
    required this.onFlash,
    this.content,
    this.showGrid = true,
    this.hint = 'One photo a day, one new memory',
  });

  final DateTime date;
  final bool flashOn;
  final VoidCallback? onFlash;

  /// Live camera preview or today's photo. When null, the prompt is shown.
  final Widget? content;
  final bool showGrid;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: ColoredBox(
        color: AppColors.text,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ?content,
            if (showGrid) const CustomPaint(painter: _ThirdsGridPainter()),
            if (content == null) Center(child: _Prompt(hint: hint)),
            Positioned(
              left: 16,
              right: 16,
              top: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _DatePill(date: date),
                  CircleIconButton(
                    asset: 'assets/icons/ic_flash.svg',
                    semanticLabel: flashOn ? 'Turn flash off' : 'Turn flash on',
                    background: flashOn
                        ? AppColors.primary
                        : AppColors.background.withValues(alpha: 0.16),
                    onPressed: onFlash,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Prompt extends StatelessWidget {
  const _Prompt({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/icons/ic_camera.svg',
            width: 34,
            height: 34,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 260,
          child: Text(
            'Frame your moment today',
            textAlign: TextAlign.center,
            style: AppText.h3.copyWith(color: AppColors.background),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 260,
          child: Text(
            hint,
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(
              color: AppColors.background.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        color: AppColors.background,
        shape: StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
        child: Text(DateFormat('MMM d').format(date), style: AppText.body),
      ),
    );
  }
}

/// Two vertical and two horizontal 1 px lines splitting the card in thirds.
class _ThirdsGridPainter extends CustomPainter {
  const _ThirdsGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.background.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    for (var i = 1; i <= 2; i++) {
      final x = size.width * i / 3;
      final y = size.height * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_ThirdsGridPainter oldDelegate) => false;
}
