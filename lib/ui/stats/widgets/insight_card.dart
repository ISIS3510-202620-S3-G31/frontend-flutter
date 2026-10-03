import 'package:flutter/material.dart';

import '../../../data/models/insight_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

/// One useful insight: what was found, a piece of advice and a button.
class InsightCard extends StatelessWidget {
  const InsightCard({super.key, required this.insight, required this.onAction});

  final Insight insight;
  final ValueChanged<InsightAction> onAction;

  IconData get _icon => switch (insight.type) {
    InsightType.toolMoodCorrelation => Icons.favorite_outline,
    InsightType.moodTrend => Icons.show_chart,
    InsightType.timeOfDay => Icons.schedule,
    InsightType.frequentEmotion => Icons.mood,
    InsightType.favoriteTool => Icons.star_outline,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDim,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, size: 20, color: AppColors.secondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  insight.title,
                  style: AppText.h3.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(insight.message, style: AppText.body),
          const SizedBox(height: 4),
          Text(insight.advice, style: AppText.bodyMuted.copyWith(fontSize: 13)),
          const SizedBox(height: 12),
          Material(
            color: AppColors.primary,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onAction(insight.action),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  insight.actionLabel,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
