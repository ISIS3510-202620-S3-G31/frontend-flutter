import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

/// A question with its answers as pills. Tapping a pill answers it.
class QuestionView extends StatelessWidget {
  const QuestionView({
    super.key,
    required this.question,
    required this.options,
    required this.onSelected,
    this.hint,
  });

  final String question;
  final String? hint;
  final List<String> options;

  /// Gets the position of the chosen answer in [options].
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question, style: AppText.h2),
        if (hint != null) ...[
          const SizedBox(height: 4),
          Text(hint!, style: AppText.bodyMuted),
        ],
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < options.length; i++)
              _AnswerPill(label: options[i], onTap: () => onSelected(i)),
          ],
        ),
      ],
    );
  }
}

class _AnswerPill extends StatelessWidget {
  const _AnswerPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: AppColors.surfaceDim,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: AppText.body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
