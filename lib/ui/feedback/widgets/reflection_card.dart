import 'package:flutter/material.dart';

import '../../../data/models/tool_feedback_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

/// Optional part: the quick tags and a short comment.
class ReflectionCard extends StatelessWidget {
  const ReflectionCard({
    super.key,
    required this.selectedTags,
    required this.onTagToggled,
    required this.onCommentChanged,
    required this.maxCommentLength,
  });

  final Set<FeedbackTag> selectedTags;
  final ValueChanged<FeedbackTag> onTagToggled;
  final ValueChanged<String> onCommentChanged;
  final int maxCommentLength;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'QUICK REFLECTION',
                  style: AppText.bodyMuted.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              Text('Optional', style: AppText.bodyMuted.copyWith(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in FeedbackTag.values)
                _TagChip(
                  tag: tag,
                  isSelected: selectedTags.contains(tag),
                  onTap: () => onTagToggled(tag),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            maxLines: 4,
            maxLength: maxCommentLength,
            style: AppText.body,
            onChanged: onCommentChanged,
            decoration: InputDecoration(
              hintText: 'What could we improve? (optional)',
              hintStyle: AppText.bodyMuted,
              filled: true,
              fillColor: AppColors.surfaceDim.withValues(alpha: 0.4),
              counterStyle: AppText.bodyMuted.copyWith(fontSize: 12),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.tag,
    required this.isSelected,
    required this.onTap,
  });

  final FeedbackTag tag;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: isSelected ? AppColors.secondary : AppColors.surfaceDim,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? Icons.check : Icons.add,
                  size: 16,
                  color: AppColors.text,
                ),
                const SizedBox(width: 6),
                Text(tag.label, style: AppText.body),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
