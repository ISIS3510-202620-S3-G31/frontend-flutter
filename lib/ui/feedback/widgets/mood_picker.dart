import 'package:flutter/material.dart';

import '../../../data/models/tool_feedback_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

/// Dark card with the four ways the user can feel after a tool.
class MoodPicker extends StatelessWidget {
  const MoodPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final FeedbackMood? selected;
  final ValueChanged<FeedbackMood> onSelected;

  static IconData _iconOf(FeedbackMood mood) => switch (mood) {
    FeedbackMood.calm => Icons.self_improvement,
    FeedbackMood.inspired => Icons.lightbulb_outline,
    FeedbackMood.focused => Icons.center_focus_strong,
    FeedbackMood.satisfied => Icons.sentiment_satisfied_alt,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.text,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'How did you feel afterwards?',
              style: AppText.h3.copyWith(
                color: AppColors.background,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final mood in FeedbackMood.values) ...[
                if (mood != FeedbackMood.values.first) const SizedBox(width: 8),
                Expanded(
                  child: _MoodTile(
                    mood: mood,
                    isSelected: mood == selected,
                    onTap: () => onSelected(mood),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MoodTile extends StatelessWidget {
  const _MoodTile({
    required this.mood,
    required this.isSelected,
    required this.onTap,
  });

  final FeedbackMood mood;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.text : AppColors.background;
    return Semantics(
      button: true,
      selected: isSelected,
      label: mood.label,
      child: Material(
        color: isSelected
            ? AppColors.secondary
            : AppColors.background.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Column(
              children: [
                Icon(MoodPicker._iconOf(mood), size: 26, color: color),
                const SizedBox(height: 8),
                Text(
                  mood.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(
                    fontSize: 12,
                    color: isSelected ? AppColors.text : AppColors.onDarkMuted,
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
