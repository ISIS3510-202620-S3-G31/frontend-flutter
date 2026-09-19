import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import 'custom_breathing_models.dart';

class DurationPills extends StatelessWidget {
  const DurationPills({
    super.key,
    required this.selectedMinutes,
    required this.onSelected,
  });

  final int selectedMinutes;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (final minutes in sessionDurations) {
      if (children.isNotEmpty) children.add(const SizedBox(width: 8));
      children.add(
        _DurationPill(
          minutes: minutes,
          selected: minutes == selectedMinutes,
          onTap: () => onSelected(minutes),
        ),
      );
    }
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: children);
  }
}

class _DurationPill extends StatelessWidget {
  const _DurationPill({
    required this.minutes,
    required this.selected,
    required this.onTap,
  });

  final int minutes;
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
            height: 40,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: Text(
                  '$minutes min',
                  style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}