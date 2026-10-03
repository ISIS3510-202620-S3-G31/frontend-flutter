import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

/// "Use experience" card: the 1 to 10 slider with its scale and legend.
class RatingCard extends StatelessWidget {
  const RatingCard({
    super.key,
    required this.rating,
    required this.label,
    required this.onChanged,
  });

  final int rating;

  /// Short description of the current rating, such as "Smooth and clear".
  final String label;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'USE EXPERIENCE',
                  style: AppText.bodyMuted.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              DecoratedBox(
                decoration: ShapeDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: const StadiumBorder(),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Text(
                    label,
                    style: AppText.body.copyWith(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$rating',
                style: AppText.h1.copyWith(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '/10',
                style: AppText.h3.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 8,
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.surfaceDim,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.15),
              showValueIndicator: ShowValueIndicator.never,
            ),
            child: Slider(
              value: rating.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (value) => onChanged(value.round()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 1; i <= 10; i++)
                  Text(
                    '$i',
                    style: i == rating
                        ? AppText.body.copyWith(fontWeight: FontWeight.w700)
                        : AppText.bodyMuted,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _Legend(
                icon: Icons.keyboard_double_arrow_down,
                color: AppColors.accent,
                text: '1. Hard',
              ),
              _Legend(
                icon: Icons.remove,
                color: AppColors.text,
                text: '5. Neutral',
              ),
              _Legend(
                icon: Icons.star_rounded,
                color: AppColors.primary,
                text: '10. Exceptional',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.bodyMuted,
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: child,
    );
  }
}
