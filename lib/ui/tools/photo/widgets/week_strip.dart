import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../view_model/photo_of_the_day_view_model.dart' show DayState;

/// Monday to Sunday dots showing which days already have a photo. Tapping one
/// of those opens it; a day with nothing to show is not tappable.
class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required this.states,
    required this.selectedIndex,
    required this.onDaySelected,
  }) : assert(states.length == 7);

  final List<DayState> states;

  /// Which day the card is showing, or -1 when it is not one of these.
  final int selectedIndex;

  final ValueChanged<int> onDaySelected;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _names = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < 7; i++)
            _DayDot(
              label: _labels[i],
              name: _names[i],
              state: states[i],
              isSelected: i == selectedIndex,
              // Only a day with a photo, or today, has something to show.
              onTap: states[i] == DayState.future
                  ? null
                  : () => onDaySelected(i),
            ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.label,
    required this.name,
    required this.state,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String name;
  final DayState state;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dot = switch (state) {
      DayState.done => Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          'assets/icons/ic_check_small.svg',
          width: 16,
          height: 16,
        ),
      ),
      DayState.today => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
      ),
      DayState.future => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.text.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
      ),
    };

    return Semantics(
      button: onTap != null,
      selected: isSelected,
      label: state == DayState.future ? '$name, no photo' : '$name, open',
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The ring marks the day on the card, whichever state it is in.
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.text : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Padding(padding: const EdgeInsets.all(3), child: dot),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: state == DayState.today || isSelected
                  ? AppText.body
                  : AppText.bodyMuted,
            ),
          ],
        ),
      ),
    );
  }
}
