import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/circle_icon_button.dart';

/// Label on the left and "minus, value, plus" on the right.
class StepperRow extends StatelessWidget {
  const StepperRow({
    super.key,
    required this.label,
    required this.seconds,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String label;
  final int seconds;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.only(left: 16, right: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDim,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppText.h3.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.text,
              ),
            ),
          ),
          _StepButton(
            asset: 'assets/icons/ic_minus.svg',
            semanticLabel: 'Decrease $label',
            onPressed: onDecrease,
          ),
          SizedBox(
            width: 52,
            child: Text(
              '${seconds}s',
              style: AppText.h2.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          _StepButton(
            asset: 'assets/icons/ic_plus.svg',
            semanticLabel: 'Increase $label',
            onPressed: onIncrease,
          ),
        ],
      ),
    );
  }
}

/// 40px circle button inside a 48px box for standard touch target.
class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.asset,
    required this.semanticLabel,
    required this.onPressed,
  });

  final String asset;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Center(
        child: CircleIconButton(
          asset: asset,
          semanticLabel: semanticLabel,
          onPressed: onPressed,
          size: 40,
          iconSize: 18,
          background: AppColors.secondary,
        ),
      ),
    );
  }
}
