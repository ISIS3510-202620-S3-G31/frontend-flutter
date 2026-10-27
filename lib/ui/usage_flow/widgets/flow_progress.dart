import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// One bar per step of the flow; the finished ones are orange.
class FlowProgress extends StatelessWidget {
  const FlowProgress({super.key, required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step ${done + 1 > total ? total : done + 1} of $total',
      child: Row(
        children: [
          for (var i = 0; i < total; i++)
            Expanded(
              child: Container(
                height: 6,
                margin: EdgeInsets.only(left: i == 0 ? 0 : 6),
                decoration: BoxDecoration(
                  color: i < done ? AppColors.primary : AppColors.surfaceDim,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
