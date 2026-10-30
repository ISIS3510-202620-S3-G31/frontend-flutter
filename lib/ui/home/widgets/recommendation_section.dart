import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../data/models/recommendation_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

/// The "Today's Recommendations" block of the home screen: what the app
/// suggests today, plus the option of letting it pick at random.
class RecommendationSection extends StatelessWidget {
  const RecommendationSection({
    super.key,
    required this.recommendation,
    required this.onOpen,
    required this.onSurpriseMe,
  });

  /// Null until the recommendation finishes loading.
  final Recommendation? recommendation;
  final VoidCallback onOpen;
  final VoidCallback onSurpriseMe;

  @override
  Widget build(BuildContext context) {
    final suggested = recommendation;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Recommendations",
            style: AppText.h3.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          if (suggested != null) ...[
            RecommendationCard(
              eyebrow: 'SUGGESTED FOR TODAY',
              eyebrowColor: AppColors.primary,
              iconAsset: suggested.tool.iconAsset,
              title: suggested.tool.title,
              subtitle: suggested.reason,
              onTap: onOpen,
            ),
            const SizedBox(height: 12),
          ],
          RecommendationCard(
            eyebrow: 'SURPRISE TOOL',
            eyebrowColor: AppColors.secondary,
            iconAsset: 'assets/icons/ic_random.svg',
            title: 'Leave it to chance',
            subtitle: 'Not sure? Let Ark pick one tool for you.',
            onTap: onSurpriseMe,
          ),
        ],
      ),
    );
  }
}

/// A row in the recommendations list, built like [ToolCard] so the home and
/// the toolbox read as the same list.
class RecommendationCard extends StatelessWidget {
  const RecommendationCard({
    super.key,
    required this.eyebrow,
    required this.eyebrowColor,
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String eyebrow;
  final Color eyebrowColor;
  final String iconAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$eyebrow: $title, $subtitle',
      child: Material(
        color: AppColors.surfaceDim,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: SvgPicture.asset(iconAsset, width: 32, height: 32),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        eyebrow,
                        style: AppText.body.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: eyebrowColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        style: AppText.h3.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                          fontSize: 17,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppText.body.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SvgPicture.asset(
                  'assets/icons/ic_chevron_right.svg',
                  width: 18,
                  height: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
