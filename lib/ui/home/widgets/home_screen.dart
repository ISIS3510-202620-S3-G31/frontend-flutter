import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../view_model/tool_hub_view_model.dart';
import 'recommendation_section.dart';
import 'user_avatar.dart';
import 'weather_context_line.dart';
import 'weather_recommendation_section.dart';

/// Home tab: the greeting and what the app suggests doing today.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.viewModel,
    required this.onOpenRecommendation,
    required this.onOpenWeatherRecommendation,
    required this.onOpenLastRecommendation,
    required this.onSurpriseMe,
  });

  final ToolHubViewModel viewModel;
  final VoidCallback onOpenRecommendation;
  final VoidCallback onOpenWeatherRecommendation;
  final VoidCallback onOpenLastRecommendation;
  final VoidCallback onSurpriseMe;

  @override
  Widget build(BuildContext context) {
    final name = viewModel.userName;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                UserAvatar(name: name),
                const SizedBox(width: 12),
                Text(
                  'Ark',
                  style: AppText.breathingTitle.copyWith(
                    fontSize: 26,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                const SizedBox(height: 8),
                Center(
                  child: SvgPicture.asset(
                    'assets/illustrations/sprout_mascot.svg',
                    height: 120,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    name == null
                        ? 'Welcome back!'
                        : 'Welcome back, $name!',
                    textAlign: TextAlign.center,
                    style: AppText.breathingTitle.copyWith(fontSize: 26),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: WeatherContextLine(
                    reading: viewModel.weatherReading,
                    onFixLocation: viewModel.fixLocationAccess,
                  ),
                ),
                const SizedBox(height: 28),
                if (viewModel.weatherRecommendation != null) ...[
                  WeatherRecommendationSection(
                    weatherRecommendation: viewModel.weatherRecommendation,
                    onOpen: onOpenWeatherRecommendation,
                  ),
                  const SizedBox(height: 28),
                ],
                RecommendationSection(
                  recommendation: viewModel.recommendation,
                  lastRecommendation: viewModel.lastRecommendation,
                  isLoading: viewModel.isRecommendationLoading,
                  onOpen: onOpenRecommendation,
                  onOpenLast: onOpenLastRecommendation,
                  onSurpriseMe: onSurpriseMe,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
