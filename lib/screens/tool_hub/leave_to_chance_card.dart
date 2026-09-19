import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

/// Dark card banner with Bloom Curious and "Surprise me" action.
class LeaveToChanceCard extends StatelessWidget {
  const LeaveToChanceCard({super.key, required this.onSurpriseMe});

  final VoidCallback onSurpriseMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: 184,
          width: double.infinity,
          color: AppColors.text,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Question sparkle decoration
              Positioned(
                top: 16,
                right: 76,
                child: SvgPicture.asset(
                  'assets/icons/question_sparkle.svg',
                  width: 52,
                  height: 48,
                ),
              ),
              // Bloom Curious illustration at the bottom right
              Positioned(
                bottom: -4,
                right: 0,
                child: SvgPicture.asset(
                  'assets/icons/bloom_curious.svg',
                  width: 112,
                  height: 122,
                ),
              ),
              // Left text and Surprise Me button
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 120, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Leave it to chance',
                            style: AppText.h2.copyWith(
                              color: AppColors.background,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Not sure what you need right now?\nWe\'ll pick one tool for you.',
                            style: AppText.body.copyWith(
                              color: AppColors.onDarkMuted,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                      Material(
                        color: AppColors.primary,
                        shape: const StadiumBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: onSurpriseMe,
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/ic_random.svg',
                                  width: 18,
                                  height: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Surprise me',
                                  style: AppText.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
