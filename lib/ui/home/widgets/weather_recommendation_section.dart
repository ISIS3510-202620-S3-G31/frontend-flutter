import 'package:flutter/material.dart';

import '../../../data/models/recommendation_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import 'recommendation_section.dart';

/// The weather-based pick of the home screen, in its own permanent section
/// apart from the personal one in [RecommendationSection]: what the weather
/// where the user is calls for. Shows nothing only when the weather could
/// not be read.
class WeatherRecommendationSection extends StatelessWidget {
  const WeatherRecommendationSection({
    super.key,
    required this.weatherRecommendation,
    required this.onOpen,
  });

  /// The weather-based recommendation. Null when the weather could not be
  /// read.
  final Recommendation? weatherRecommendation;

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final suggested = weatherRecommendation;
    if (suggested == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weather pick',
            style: AppText.h3.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          RecommendationCard(
            eyebrow: 'BECAUSE OF THE WEATHER',
            eyebrowColor: AppColors.secondary,
            iconAsset: suggested.tool.iconAsset,
            title: suggested.tool.title,
            subtitle: suggested.reason,
            onTap: onOpen,
          ),
        ],
      ),
    );
  }
}
