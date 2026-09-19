import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

enum DayState { done, today, future }

/// Monday → Sunday dots showing which days already have a photo.
class WeekStrip extends StatelessWidget {
  const WeekStrip({super.key, required this.states})
    : assert(states.length == 7);

  final List<DayState> states;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < 7; i++)
            DayDot(label: _labels[i], state: states[i]),
        ],
      ),
    );
  }
}

class DayDot extends StatelessWidget {
  const DayDot({super.key, required this.label, required this.state});

  final String label;
  final DayState state;

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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        const SizedBox(height: 4),
        Text(
          label,
          style: state == DayState.today ? AppText.body : AppText.bodyMuted,
        ),
      ],
    );
  }
}
