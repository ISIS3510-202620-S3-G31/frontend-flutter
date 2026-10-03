import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../../data/models/breathing_model.dart';
import '../view_model/custom_breathing_view_model.dart';
import 'breathing_music_sheet.dart';

class BreathingMusicCard extends StatelessWidget {
  const BreathingMusicCard({super.key, required this.viewModel});

  final CustomBreathingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final state = viewModel.state;
    final track = state.selectedTrack;
    final isOnline = state.isOnline;
    final isMusicEnabled = state.isMusicEnabled;

    return Semantics(
      button: true,
      label: 'Session background music settings',
      child: Material(
        color: AppColors.surfaceDim,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => BreathingMusicSheet(viewModel: viewModel),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Music note badge
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isMusicEnabled
                        ? AppColors.secondary
                        : AppColors.text.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isMusicEnabled ? Icons.music_note : Icons.music_off,
                    color: isMusicEnabled ? Colors.white : AppColors.textMuted,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                // Title & caching state
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              track?.title ?? 'Select ambient music',
                              style: AppText.body.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _buildCacheBadge(track, isOnline),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        track != null
                            ? '${track.artist} • ${track.duration > 0 ? "${(track.duration ~/ 60)}:${(track.duration % 60).toString().padLeft(2, '0')}" : "Ambient"}'
                            : 'Jamendo free ambient audio',
                        style: AppText.bodyMuted.copyWith(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Quick mute button
                IconButton(
                  tooltip: isMusicEnabled ? 'Mute music' : 'Unmute music',
                  icon: Icon(
                    isMusicEnabled ? Icons.volume_up : Icons.volume_off,
                    color: isMusicEnabled
                        ? AppColors.text
                        : AppColors.textMuted,
                    size: 22,
                  ),
                  onPressed: viewModel.toggleMusic,
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.text,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCacheBadge(BreathingMusicTrack? track, bool isOnline) {
    if (track == null) return const SizedBox.shrink();

    if (track.isCached) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 12,
              color: Color(0xFF2E7D32),
            ),
            const SizedBox(width: 3),
            Text(
              'Offline',
              style: AppText.body.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
      );
    } else if (isOnline) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_queue_rounded,
              size: 12,
              color: AppColors.primary,
            ),
            const SizedBox(width: 3),
            Text(
              'Stream',
              style: AppText.body.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 12,
              color: AppColors.accent,
            ),
            const SizedBox(width: 3),
            Text(
              'No cache',
              style: AppText.body.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      );
    }
  }
}
