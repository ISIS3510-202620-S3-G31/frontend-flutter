import 'package:flutter/material.dart';

import '../../../data/models/recommendation_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import 'tool_card.dart';


class RecommendationSection extends StatelessWidget {
  const RecommendationSection({
    super.key,
    required this.recommendation,
    required this.onOpen,
  });

  final Recommendation recommendation;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recommended for you',
            style: AppText.h3.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            recommendation.reason,
            style: AppText.bodyMuted.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 12),
          ToolCard(tool: recommendation.tool, onTap: onOpen),
        ],
      ),
    );
  }
}
