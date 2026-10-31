import 'package:flutter/material.dart';

import '../../../../utils/noise_level.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';


class IntensityMeter extends StatelessWidget {
  const IntensityMeter({super.key, required this.db, required this.goalDb});

  final double db;

  /// Loudness that completes the session; drawn as a line on the bar.
  final double goalDb;

  /// Segments 1–4 are the soft zone, 5–8 medium and 9–12 strong.
  Color _zoneColor(int i) => i < 4
      ? AppColors.secondary
      : i < 8
      ? AppColors.primary
      : AppColors.accent;

  @override
  Widget build(BuildContext context) {
    final lit = litSegments(db);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Intensity', style: AppText.bodyMuted),
              Text('${db.round()} dB · ${zoneLabel(db)}', style: AppText.h3),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 20,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final goalX = constraints.maxWidth * levelFromDb(goalDb);
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      top: 4,
                      bottom: 4,
                      child: Row(
                        children: [
                          for (var i = 0; i < meterSegments; i++) ...[
                            if (i > 0) const SizedBox(width: 4),
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 80),
                                height: 12,
                                decoration: BoxDecoration(
                                  color: i < lit
                                      ? _zoneColor(i)
                                      : AppColors.text.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Positioned(
                      left: goalX - 1,
                      top: 0,
                      bottom: 0,
                      child: Semantics(
                        label: 'Goal: ${goalDb.round()} decibels',
                        child: const SizedBox(
                          width: 2,
                          child: ColoredBox(color: AppColors.text),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Soft', style: AppText.bodyMuted),
              Text('Medium', style: AppText.bodyMuted),
              Text('Strong', style: AppText.bodyMuted),
            ],
          ),
        ],
      ),
    );
  }
}
