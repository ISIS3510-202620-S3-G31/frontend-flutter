import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_colors.dart';
import '../../widgets/circle_icon_button.dart';

/// Bottom row with three controls:
/// - Small teal reset button on the left
/// - Big orange play/pause button with a dark ring in the center
/// - Small teal check/done button on the right
class SessionControls extends StatelessWidget {
  const SessionControls({
    super.key,
    required this.onReset,
    required this.onToggleRunning,
    required this.onFinish,
    this.isRunning = true,
  });

  final VoidCallback onReset;
  final VoidCallback onToggleRunning;
  final VoidCallback onFinish;
  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CircleIconButton(
          asset: 'assets/icons/ic_restart.svg',
          semanticLabel: 'Reset the session',
          onPressed: onReset,
        ),
        _MainActionButton(
          isRunning: isRunning,
          onPressed: onToggleRunning,
        ),
        CircleIconButton(
          asset: 'assets/icons/ic_check.svg',
          semanticLabel: 'Finish the session',
          onPressed: onFinish,
        ),
      ],
    );
  }
}

class _MainActionButton extends StatelessWidget {
  const _MainActionButton({
    required this.isRunning,
    required this.onPressed,
  });

  final bool isRunning;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isRunning ? 'Pause the session' : 'Resume the session',
      child: Container(
        width: 84,
        height: 84,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.text, width: 3.5),
        ),
        child: Material(
          color: AppColors.primary,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 66,
              height: 66,
              child: Center(
                child: isRunning
                    ? SvgPicture.asset(
                        'assets/icons/ic_pause.svg',
                        width: 28,
                        height: 28,
                      )
                    : const Icon(
                        Icons.play_arrow_rounded,
                        color: AppColors.text,
                        size: 38,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}