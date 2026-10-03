import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../../data/models/breathing_model.dart';
import '../view_model/custom_breathing_view_model.dart';

class BreathingMusicSheet extends StatelessWidget {
  const BreathingMusicSheet({super.key, required this.viewModel});

  final CustomBreathingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final state = viewModel.state;
        final tracks = state.availableTracks;
        final selectedTrack = state.selectedTrack;
        final isOnline = state.isOnline;

        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.text.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header and Toggle
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Session Music',
                              style: AppText.h2.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Jamendo Ambient & Meditation',
                              style: AppText.bodyMuted.copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              state.isMusicEnabled ? 'Music On' : 'Music Off',
                              style: AppText.body.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: state.isMusicEnabled
                                    ? AppColors.secondary
                                    : AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch.adaptive(
                              value: state.isMusicEnabled,
                              activeTrackColor: AppColors.secondary,
                              onChanged: (_) => viewModel.toggleMusic(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Tracks List
                  Expanded(
                    child: state.isLoadingMusic && tracks.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.secondary,
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                            itemCount: tracks.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final track = tracks[index];
                              final isSelected = selectedTrack?.id == track.id;
                              final isDownloading =
                                  state.downloadingTrackId == track.id;

                              return _TrackTile(
                                track: track,
                                isSelected: isSelected,
                                isDownloading: isDownloading,
                                isOnline: isOnline,
                                onSelect: () => viewModel.selectTrack(track),
                                onDownload: () =>
                                    viewModel.downloadTrack(track),
                                onDeleteCache: () =>
                                    viewModel.removeTrackFromCache(track),
                              );
                            },
                          ),
                  ),

                  // Footer with Refresh from Jamendo
                  if (isOnline)
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.text,
                            side: BorderSide(
                              color: AppColors.text.withValues(alpha: 0.2),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size.fromHeight(42),
                          ),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Refresh Jamendo Catalog'),
                          onPressed: state.isLoadingMusic
                              ? null
                              : () => viewModel.refreshTracks(),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({
    required this.track,
    required this.isSelected,
    required this.isDownloading,
    required this.isOnline,
    required this.onSelect,
    required this.onDownload,
    required this.onDeleteCache,
  });

  final BreathingMusicTrack track;
  final bool isSelected;
  final bool isDownloading;
  final bool isOnline;
  final VoidCallback onSelect;
  final VoidCallback onDownload;
  final VoidCallback onDeleteCache;

  @override
  Widget build(BuildContext context) {
    final canPlay = track.isCached || isOnline;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${track.title} by ${track.artist}',
      child: Material(
        color: isSelected
            ? AppColors.secondary.withValues(alpha: 0.12)
            : AppColors.surfaceDim.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? AppColors.secondary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: canPlay
              ? onSelect
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'This track is not cached yet. Connect to the internet to listen and save it.',
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Radio / Active play indicator
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.secondary
                        : AppColors.text.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSelected
                        ? Icons.play_arrow_rounded
                        : Icons.music_note_rounded,
                    color: isSelected ? Colors.white : AppColors.textMuted,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Title and Artist
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        style: AppText.body.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: canPlay ? AppColors.text : AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              track.artist,
                              style: AppText.bodyMuted.copyWith(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (track.duration > 0) ...[
                            Text(
                              ' • ${(track.duration ~/ 60)}:${(track.duration % 60).toString().padLeft(2, '0')}',
                              style: AppText.bodyMuted.copyWith(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Cache / Download Action Button
                _buildActionWidget(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionWidget(BuildContext context) {
    if (isDownloading) {
      return const SizedBox(
        width: 32,
        height: 32,
        child: Padding(
          padding: EdgeInsets.all(6),
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.secondary,
          ),
        ),
      );
    }

    if (track.isCached) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.download_done_rounded,
                  size: 14,
                  color: Color(0xFF2E7D32),
                ),
                const SizedBox(width: 4),
                Text(
                  'Saved',
                  style: AppText.body.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove from local cache',
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
            onPressed: onDeleteCache,
          ),
        ],
      );
    }

    if (isOnline) {
      return IconButton(
        tooltip: 'Download track for offline listening',
        icon: const Icon(
          Icons.download_rounded,
          size: 22,
          color: AppColors.secondary,
        ),
        onPressed: onDownload,
      );
    }

    // Offline and not cached
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 13,
            color: AppColors.accent,
          ),
          const SizedBox(width: 4),
          Text(
            'Needs net',
            style: AppText.body.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
