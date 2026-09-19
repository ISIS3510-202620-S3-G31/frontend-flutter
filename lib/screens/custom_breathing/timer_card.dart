import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import 'breathing_ring.dart';
import 'custom_breathing_models.dart';

/// Dark card with the state of the session. Bloom uses the Mindful pose,
/// assigned to the breathing exercises.
class TimerCard extends StatelessWidget {
  const TimerCard({super.key, required this.state});

  final CustomBreathingState state;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 320,
        width: double.infinity,
        color: AppColors.text,
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(top: 48, bottom: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BreathingRing(
                      progress: state.progress,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${state.secondsLeft}',
                            style: AppText.h2.copyWith(
                              fontSize: 64,
                              height: 1,
                              color: AppColors.background,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.phase.label,
                            style: AppText.h3.copyWith(
                              color: AppColors.background,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Cycle ${state.cycle} of ${state.totalCycles}',
                      style: AppText.body.copyWith(
                        color: AppColors.onDarkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: _StatusChip(isRunning: state.isRunning),
            ),
            Positioned(
              left: 16,
              bottom: 16,
              child: SvgPicture.asset(
                'assets/icons/bloom_mindful.svg',
                width: 62,
                height: 70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isRunning});

  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isRunning ? AppColors.secondary : const Color(0x33221100),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isRunning ? 'Running' : 'Paused',
            style: AppText.body.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}