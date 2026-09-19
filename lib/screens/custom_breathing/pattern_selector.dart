import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import 'custom_breathing_models.dart';

/// Three pills with the same width: 2-step, 3-step, 4-7-8.
/// Each option has an icon and a label.
class PatternSelector extends StatelessWidget {
  const PatternSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final BreathingPattern selected;
  final ValueChanged<BreathingPattern> onSelected;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (final pattern in BreathingPattern.values) {
      if (children.isNotEmpty) children.add(const SizedBox(width: 8));
      children.add(
        Expanded(
          child: _PatternPill(
            pattern: pattern,
            selected: pattern == selected,
            onTap: () => onSelected(pattern),
          ),
        ),
      );
    }
    return Row(children: children);
  }
}

class _PatternPill extends StatelessWidget {
  const _PatternPill({
    required this.pattern,
    required this.selected,
    required this.onTap,
  });

  final BreathingPattern pattern;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.secondary : AppColors.surfaceDim,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 46,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(pattern.icon, width: 20, height: 20),
                const SizedBox(width: 6),
                Text(
                  pattern.label,
                  style: AppText.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
