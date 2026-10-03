import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/screen_header.dart';
import '../view_model/tool_feedback_view_model.dart';
import 'mood_picker.dart';
import 'rating_card.dart';
import 'reflection_card.dart';

/// Asked right after the user leaves a tool, to keep track of how it went.
class ToolFeedbackScreen extends StatefulWidget {
  const ToolFeedbackScreen({
    super.key,
    required this.toolId,
    required this.toolName,
    required this.startedAt,
    required this.durationSeconds,
    this.viewModel,
  });

  final String toolId;
  final String toolName;
  final DateTime startedAt;
  final int durationSeconds;

  /// Pass one in tests; otherwise the screen builds and disposes its own.
  final ToolFeedbackViewModel? viewModel;

  @override
  State<ToolFeedbackScreen> createState() => _ToolFeedbackScreenState();
}

class _ToolFeedbackScreenState extends State<ToolFeedbackScreen> {
  late final ToolFeedbackViewModel _viewModel =
      widget.viewModel ??
      ToolFeedbackViewModel(
        toolId: widget.toolId,
        startedAt: widget.startedAt,
        durationSeconds: widget.durationSeconds,
      );
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
    // Saving is the end of the flow, so the screen closes itself.
    if (_viewModel.saved) Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              return Column(
                children: [
                  ScreenHeader(
                    title: Text('Tool feedback', style: AppText.h1),
                    subtitle: widget.toolName,
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                      children: [
                        RatingCard(
                          rating: _viewModel.rating,
                          label: _viewModel.ratingLabel,
                          onChanged: _viewModel.setRating,
                        ),
                        const SizedBox(height: 16),
                        MoodPicker(
                          selected: _viewModel.mood,
                          onSelected: _viewModel.selectMood,
                        ),
                        const SizedBox(height: 16),
                        ReflectionCard(
                          selectedTags: _viewModel.tags,
                          onTagToggled: _viewModel.toggleTag,
                          onCommentChanged: _viewModel.setComment,
                          maxCommentLength:
                              ToolFeedbackViewModel.maxCommentLength,
                        ),
                      ],
                    ),
                  ),
                  _BottomBar(
                    favorite: _viewModel.favorite,
                    saving: _viewModel.saving,
                    onFavorite: _viewModel.toggleFavorite,
                    onSave: _viewModel.canSave ? _viewModel.save : null,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.favorite,
    required this.saving,
    required this.onFavorite,
    required this.onSave,
  });

  final bool favorite;
  final bool saving;
  final VoidCallback onFavorite;

  /// Null until the user picks a mood.
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        children: [
          Semantics(
            button: true,
            selected: favorite,
            label: 'Mark this tool as a favourite',
            child: Material(
              color: AppColors.panel,
              shape: CircleBorder(
                side: BorderSide(color: AppColors.text.withValues(alpha: 0.15)),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onFavorite,
                child: SizedBox.square(
                  dimension: 56,
                  child: Icon(
                    favorite ? Icons.favorite : Icons.favorite_border,
                    color: favorite ? AppColors.accent : AppColors.text,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: saving ? null : onSave,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.text,
                disabledBackgroundColor: AppColors.surfaceDim,
                disabledForegroundColor: AppColors.textMuted,
                minimumSize: const Size.fromHeight(56),
                shape: const StadiumBorder(),
                textStyle: AppText.h3.copyWith(fontWeight: FontWeight.w600),
              ),
              child: saving
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.text,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Save feedback'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
