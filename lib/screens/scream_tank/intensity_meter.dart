import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

const _minDb = 40.0;
const _maxDb = 100.0;
const _segments = 12;

/// Mic level as 0..1 (40 dB → 0, 100 dB → 1).
double levelFromDb(double db) =>
    ((db - _minDb) / (_maxDb - _minDb)).clamp(0.0, 1.0);

/// How many of the 12 meter segments are lit (84 dB → 9, as in the mock-up).
int litSegments(double db) => (levelFromDb(db) * _segments).round();

String zoneLabel(double db) => db < 60
    ? 'Soft'
    : db < 80
    ? 'Medium'
    : 'Strong';

/// Live loudness: "84 dB · Strong" above a 12-segment bar.
class IntensityMeter extends StatelessWidget {
  const IntensityMeter({super.key, required this.db});

  final double db;

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
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < _segments; i++) ...[
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
          const SizedBox(height: 8),
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
