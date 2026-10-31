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
        final tracks = state.filteredTracks;
        final selectedTrack = state.selectedTrack;
        final previewTrack = state.previewTrack;
        final isPreviewPlaying = state.isPreviewPlaying;
        final isOnline = state.isOnline;

        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
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
                        Text('Ambient music', style: AppText.h2),
                        Row(
                          children: [
                            Text(
                              state.isMusicEnabled ? 'Music on' : 'Music off',
                              style: AppText.body,
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

                  // Ambient category filter chips
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        for (final category in AmbientCategory.values) ...[
                          _CategoryChip(
                            category: category,
                            selected: state.musicCategory == category,
                            onSelected: () =>
                                viewModel.selectMusicCategory(category),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tracks List
                  Expanded(
                    child: state.isLoadingMusic && tracks.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.secondary,
                            ),
                          )
                        : tracks.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'No tracks in this category.',
                                style: AppText.bodyMuted,
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                            itemCount: tracks.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final track = tracks[index];
                              final isSelected = selectedTrack?.id == track.id;
                              final isPreviewing = previewTrack?.id == track.id;
                              final isDownloading =
                                  state.downloadingTrackId == track.id;

                              return _TrackTile(
                                track: track,
                                isSelected: isSelected,
                                isPreviewing: isPreviewing,
                                isPreviewPlaying:
                                    isPreviewing && isPreviewPlaying,
                                isDownloading: isDownloading,
                                isOnline: isOnline,
                                onSelect: () {
                                  viewModel.selectTrack(track);
                                  viewModel.togglePreview(track);
                                },
                                onTogglePreview: () =>
                                    viewModel.togglePreview(track),
                                onDownload: () =>
                                    viewModel.downloadTrack(track),
                                onDeleteCache: () =>
                                    viewModel.removeTrackFromCache(track),
                              );
                            },
                          ),
                  ),

                  // Bottom Preview Bar (shows preview player when a song is previewed)
                  if (previewTrack != null)
                    _PreviewBottomBar(
                      track: previewTrack,
                      isPlaying: isPreviewPlaying,
                      isSelected: selectedTrack?.id == previewTrack.id,
                      onTogglePlay: () => viewModel.togglePreview(previewTrack),
                      onSelectTrack: () => viewModel.selectTrack(previewTrack),
                      onClose: viewModel.stopPreview,
                    ),

                  // Footer with Refresh from Jamendo
                  if (isOnline)
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.text,
                            side: const BorderSide(color: AppColors.secondary),
                            shape: const StadiumBorder(),
                            minimumSize: const Size.fromHeight(48),
                            textStyle: AppText.body,
                          ),
                          icon: const Icon(Icons.refresh, size: 20),
                          label: const Text('Refresh Jamendo catalog'),
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

/// Chip for selecting an ambient music category.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onSelected,
  });

  final AmbientCategory category;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${category.label} music',
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.secondary : AppColors.background,
        shape: const StadiumBorder(
          side: BorderSide(color: AppColors.secondary),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onSelected,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(category.label, style: AppText.body),
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewBottomBar extends StatelessWidget {
  const _PreviewBottomBar({
    required this.track,
    required this.isPlaying,
    required this.isSelected,
    required this.onTogglePlay,
    required this.onSelectTrack,
    required this.onClose,
  });

  final BreathingMusicTrack track;
  final bool isPlaying;
  final bool isSelected;
  final VoidCallback onTogglePlay;
  final VoidCallback onSelectTrack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.text,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Play / Pause preview button
          IconButton(
            tooltip: isPlaying ? 'Pause preview' : 'Resume preview',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            icon: Icon(
              isPlaying
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_filled_rounded,
              color: AppColors.background,
              size: 36,
            ),
            onPressed: onTogglePlay,
          ),
          const SizedBox(width: 8),

          // Preview info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.graphic_eq_rounded,
                      size: 14,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Previewing',
                      style: AppText.body.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  track.title,
                  style: AppText.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.background,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  track.artist,
                  style: AppText.body.copyWith(
                    color: AppColors.onDarkMuted,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          if (!isSelected)
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onSelectTrack,
              child: const Text(
                'Use Track',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check, size: 12, color: AppColors.success),
                  const SizedBox(width: 3),
                  Text(
                    'Selected',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(width: 4),

          IconButton(
            tooltip: 'Stop preview',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: Icon(
              Icons.close_rounded,
              color: AppColors.onDarkMuted,
              size: 20,
            ),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({
    required this.track,
    required this.isSelected,
    required this.isPreviewing,
    required this.isPreviewPlaying,
    required this.isDownloading,
    required this.isOnline,
    required this.onSelect,
    required this.onTogglePreview,
    required this.onDownload,
    required this.onDeleteCache,
  });

  final BreathingMusicTrack track;
  final bool isSelected;
  final bool isPreviewing;
  final bool isPreviewPlaying;
  final bool isDownloading;
  final bool isOnline;
  final VoidCallback onSelect;
  final VoidCallback onTogglePreview;
  final VoidCallback onDownload;
  final VoidCallback onDeleteCache;

  void _needsInternet(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'This track is not cached yet. Connect to the internet to listen and save it.',
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPlay = track.isCached || isOnline;

    return Semantics(
      button: true,
      selected: isSelected,
      label: track.title,
      child: Material(
        color: isSelected ? AppColors.secondary : AppColors.background,
        shape: StadiumBorder(
          side: BorderSide(
            color: isPreviewing && !isSelected
                ? AppColors.secondary
                : Colors.transparent,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: canPlay ? onSelect : () => _needsInternet(context),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: isPreviewPlaying
                        ? 'Pause preview of ${track.title}'
                        : 'Play preview of ${track.title}',
                    icon: Icon(
                      isPreviewPlaying ? Icons.graphic_eq : Icons.music_note,
                      color: AppColors.text,
                      size: 22,
                    ),
                    onPressed: canPlay
                        ? onTogglePreview
                        : () => _needsInternet(context),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      track.title,
                      style: AppText.body.copyWith(
                        color: canPlay ? AppColors.text : AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildActionWidget(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionWidget() {
    if (isDownloading) {
      return const SizedBox.square(
        dimension: 48,
        child: Padding(
          padding: EdgeInsets.all(14),
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.text,
          ),
        ),
      );
    }

    if (track.isCached) {
      return IconButton(
        tooltip: 'Saved offline. Tap to remove it',
        icon: const Icon(
          Icons.download_done_rounded,
          size: 22,
          color: AppColors.text,
        ),
        onPressed: onDeleteCache,
      );
    }

    if (isOnline) {
      return IconButton(
        tooltip: 'Download track for offline listening',
        icon: const Icon(
          Icons.download_rounded,
          size: 22,
          color: AppColors.text,
        ),
        onPressed: onDownload,
      );
    }

    return Semantics(
      label: 'Needs internet',
      child: SizedBox.square(
        dimension: 48,
        child: Icon(
          Icons.cloud_off_rounded,
          size: 22,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
