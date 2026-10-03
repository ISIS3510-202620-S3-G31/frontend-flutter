import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../view_model/stats_view_model.dart';

/// Ring split by how much each tool was used, with the list of tools beside it.
class ToolsFrequencyChart extends StatelessWidget {
  const ToolsFrequencyChart({super.key, required this.shares});

  final List<ToolShare> shares;

  static const _colors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.accent,
    Color(0xFF6CC070),
  ];

  @override
  Widget build(BuildContext context) {
    if (shares.isEmpty) {
      return Text(
        'Finish a tool to see which ones you use the most.',
        style: AppText.bodyMuted,
      );
    }
    return Row(
      children: [
        SizedBox.square(
          dimension: 116,
          child: CustomPaint(
            painter: _RingPainter(
              percents: [for (final share in shares) share.percent],
              colors: _colors,
            ),
            child: Center(
              child: Text(
                '100%',
                style: AppText.h3.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            children: [
              for (var i = 0; i < shares.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _colors[i % _colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          shares[i].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body.copyWith(fontSize: 13),
                        ),
                      ),
                      Text(
                        '${shares[i].percent}%',
                        style: AppText.body.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.percents, required this.colors});

  final List<int> percents;
  final List<Color> colors;

  static const _stroke = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - _stroke) / 2,
    );
    var start = -math.pi / 2;
    for (var i = 0; i < percents.length; i++) {
      final sweep = 2 * math.pi * percents[i] / 100;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke
          ..color = colors[i % colors.length],
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      !listEquals(oldDelegate.percents, percents);
}
