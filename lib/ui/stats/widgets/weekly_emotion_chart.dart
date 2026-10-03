import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../view_model/stats_view_model.dart';
import 'emotion_style.dart';

/// One bar per day of the week: its height is the intensity (1 to 5) and the
/// emoji above it is the dominant emotion.
class WeeklyEmotionChart extends StatelessWidget {
  const WeeklyEmotionChart({super.key, required this.days})
    : assert(days.length == 7);

  final List<DayMood?> days;

  static const _labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _barsHeight = 120.0;
  static const _labelSpace = 28.0;

  @override
  Widget build(BuildContext context) {
    final scaleStyle = AppText.bodyMuted.copyWith(fontSize: 11, height: 1);
    return SizedBox(
      height: _barsHeight + _labelSpace + 32,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: _labelSpace),
            child: SizedBox(
              height: _barsHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var level = 5; level >= 1; level--)
                    Text('$level', style: scaleStyle),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          for (var i = 0; i < 7; i++)
            Expanded(
              child: _DayBar(label: _labels[i], mood: days[i]),
            ),
        ],
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({required this.label, required this.mood});

  final String label;
  final DayMood? mood;

  @override
  Widget build(BuildContext context) {
    final mood = this.mood;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (mood != null)
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: mood.emotion.color.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Text(
              mood.emotion.emoji,
              style: const TextStyle(fontSize: 15, height: 1),
            ),
          ),
        const SizedBox(height: 4),
        Container(
          width: 22,
          height: mood == null
              ? 8
              : WeeklyEmotionChart._barsHeight * mood.intensity / 5,
          decoration: BoxDecoration(
            color:
                mood?.emotion.color ?? AppColors.text.withValues(alpha: 0.08),
            // Light colors (Success, Warning) need an edge on the beige card.
            border: mood == null
                ? null
                : Border.all(color: AppColors.text.withValues(alpha: 0.15)),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        SizedBox(
          height: WeeklyEmotionChart._labelSpace,
          child: Center(
            child: Text(
              label,
              style: mood == null
                  ? AppText.bodyMuted.copyWith(fontSize: 12)
                  : AppText.body.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
