import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

/// Optional part of the feedback: a short comment.
class CommentCard extends StatelessWidget {
  const CommentCard({
    super.key,
    required this.onChanged,
    required this.maxLength,
  });

  final ValueChanged<String> onChanged;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDim,
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
                  'COMMENTS',
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
          TextField(
            maxLines: 4,
            maxLength: maxLength,
            style: AppText.body,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'What could we improve?',
              hintStyle: AppText.bodyMuted,
              filled: true,
              fillColor: AppColors.background,
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
