import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../../data/models/breathing_model.dart';


class PatternSelector extends StatelessWidget {
  const PatternSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    this.onEditCustom,
  });

  final BreathingPattern selected;
  final ValueChanged<BreathingPattern> onSelected;
  final VoidCallback? onEditCustom;

  @override
  Widget build(BuildContext context) {
    final editCustom = onEditCustom;
    final patterns = BreathingPattern.selectablePatterns;

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: const ShapeDecoration(
        shape: StadiumBorder(side: BorderSide(color: AppColors.secondary)),
      ),
      child: Row(
        children: [
          for (final pattern in patterns)
            Expanded(
              child: _PatternOption(
                pattern: pattern,
                selected: pattern == selected,
                onTap: pattern.isCustom && pattern == selected && editCustom != null
                    ? editCustom
                    : () => onSelected(pattern),
              ),
            ),
        ],
      ),
    );
  }
}

class _PatternOption extends StatelessWidget {
  const _PatternOption({
    required this.pattern,
    required this.selected,
    required this.onTap,
  });

  final BreathingPattern pattern;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final showEdit = selected && pattern.isCustom;

    return Semantics(
      button: true,
      selected: selected,
      label: showEdit ? 'Custom, edit rhythm' : pattern.label,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.secondary : AppColors.background,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(pattern.label, style: AppText.body, maxLines: 1),
                  if (showEdit) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.edit, size: 14, color: AppColors.text),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
