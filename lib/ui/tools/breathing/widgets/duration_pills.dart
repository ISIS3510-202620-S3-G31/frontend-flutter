import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../../data/models/breathing_model.dart';

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
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: const ShapeDecoration(
        shape: StadiumBorder(side: BorderSide(color: AppColors.secondary)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final minutes in sessionDurations)
            _DurationPill(
              minutes: minutes,
              selected: minutes == selectedMinutes,
              onTap: () => onSelected(minutes),
            ),
        ],
      ),
    );
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
      label: '$minutes minute session',
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.secondary : AppColors.background,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: Text('$minutes min', style: AppText.body),
            ),
          ),
        ),
      ),
    );
  }
}
