import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/check_in_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../stats/widgets/emotion_style.dart';
import '../view_model/check_in_view_model.dart';

/// Asks the user how they feel. Shown once a day, the first time they open
/// the app.
///
/// Use [showMoodCheckIn] to open it.
class MoodCheckInSheet extends StatefulWidget {
  const MoodCheckInSheet({super.key, this.viewModel});

  /// Pass one in tests; otherwise the sheet builds and disposes its own.
  final CheckInViewModel? viewModel;

  @override
  State<MoodCheckInSheet> createState() => _MoodCheckInSheetState();
}

/// Opens the check-in and returns true when the user saved it.
Future<bool> showMoodCheckIn(BuildContext context) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const MoodCheckInSheet(),
  );
  return saved ?? false;
}

class _MoodCheckInSheetState extends State<MoodCheckInSheet> {
  late final CheckInViewModel _viewModel =
      widget.viewModel ?? CheckInViewModel();
  late final bool _ownsViewModel = widget.viewModel == null;

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    if (_ownsViewModel) _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (!mounted) return;
    final message = _viewModel.message;
    if (message != null) {
      _viewModel.clearMessage();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
    if (_viewModel.saved) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Lifts the sheet above the keyboard while the note is being written.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final selected = _viewModel.emotion;
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Mood Check-In', style: AppText.h1)),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        icon: const Icon(Icons.close),
                        color: AppColors.text,
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  Text(
                    DateFormat('EEEE, MMMM d').format(DateTime.now()),
                    style: AppText.bodyMuted,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'How are you feeling?',
                    style: AppText.h3.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pick the one that fits best.',
                    style: AppText.bodyMuted,
                  ),
                  const SizedBox(height: 14),
                  _EmotionGrid(
                    selected: selected,
                    onSelected: _viewModel.selectEmotion,
                  ),
                  const SizedBox(height: 20),
                  _IntensitySlider(
                    value: _viewModel.intensity,
                    color: selected?.color ?? AppColors.primary,
                    onChanged: _viewModel.setIntensity,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    maxLines: 3,
                    maxLength: CheckInViewModel.maxNoteLength,
                    style: AppText.body,
                    onChanged: _viewModel.setNote,
                    decoration: InputDecoration(
                      hintText: 'Add a note about your day (optional)',
                      hintStyle: AppText.bodyMuted,
                      filled: true,
                      fillColor: AppColors.panel,
                      counterStyle: AppText.bodyMuted.copyWith(fontSize: 12),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _viewModel.canSave ? _viewModel.save : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.text,
                      disabledBackgroundColor: AppColors.surfaceDim,
                      disabledForegroundColor: AppColors.textMuted,
                      minimumSize: const Size.fromHeight(56),
                      shape: const StadiumBorder(),
                      textStyle: AppText.h3.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: _viewModel.saving
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.text,
                            ),
                          )
                        : const Text('Save check-in'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The six emotions, three per row so the names stay readable.
class _EmotionGrid extends StatelessWidget {
  const _EmotionGrid({required this.selected, required this.onSelected});

  final Emotion? selected;
  final ValueChanged<Emotion> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final itemWidth = (constraints.maxWidth - gap * 2) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final emotion in Emotion.values)
              SizedBox(
                width: itemWidth,
                child: _EmotionTile(
                  emotion: emotion,
                  isSelected: emotion == selected,
                  onTap: () => onSelected(emotion),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EmotionTile extends StatelessWidget {
  const _EmotionTile({
    required this.emotion,
    required this.isSelected,
    required this.onTap,
  });

  final Emotion emotion;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: emotion.label,
      child: Material(
        color: isSelected ? emotion.color : AppColors.panel,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            child: Column(
              children: [
                Text(emotion.emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 6),
                Text(
                  emotion.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IntensitySlider extends StatelessWidget {
  const _IntensitySlider({
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final int value;
  final Color color;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How strong is it?', style: AppText.bodyMuted),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 8,
            activeTrackColor: color,
            inactiveTrackColor: AppColors.surfaceDim,
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.15),
            showValueIndicator: ShowValueIndicator.never,
          ),
          child: Slider(
            value: value.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (picked) => onChanged(picked.round()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Barely', style: AppText.bodyMuted),
              Text('In the middle', style: AppText.bodyMuted),
              Text('A lot', style: AppText.bodyMuted),
            ],
          ),
        ),
      ],
    );
  }
}
