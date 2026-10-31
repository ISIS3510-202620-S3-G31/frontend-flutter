import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import 'breathing_round_button.dart';

class SessionControls extends StatelessWidget {
  const SessionControls({
    super.key,
    required this.onReset,
    required this.onToggleRunning,
    required this.onFinish,
    this.isRunning = true,
    this.isReady = false,
    this.canReset = true,
  });

  final VoidCallback onReset;
  final VoidCallback onToggleRunning;
  final VoidCallback onFinish;
  final bool isRunning;
  final bool isReady;
  final bool canReset;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Visibility(
          visible: canReset,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: _LabeledButton(
            label: 'Reset',
            button: BreathingRoundButton(
              icon: SvgPicture.asset(
                'assets/icons/ic_restart.svg',
                width: 22,
                height: 22,
              ),
              semanticLabel: 'Reset the session',
              onPressed: onReset,
            ),
          ),
        ),
        const SizedBox(width: 40),
        _PlayPauseButton(
          isRunning: isRunning,
          isReady: isReady,
          onPressed: onToggleRunning,
        ),
        const SizedBox(width: 40),
        _LabeledButton(
          label: 'Finish',
          button: BreathingRoundButton(
            icon: SvgPicture.asset(
              'assets/icons/ic_check.svg',
              width: 22,
              height: 22,
            ),
            semanticLabel: 'Finish the session',
            onPressed: onFinish,
          ),
        ),
      ],
    );
  }
}

/// 48 dp round button with its name under it.
class _LabeledButton extends StatelessWidget {
  const _LabeledButton({required this.label, required this.button});

  final String label;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          button,
          const SizedBox(height: 4),
          // The button already says it to the screen reader.
          ExcludeSemantics(child: Text(label, style: AppText.body)),
        ],
      ),
    );
  }
}

/// The only orange thing on the screen: 72 dp, play or pause.
class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({
    required this.isRunning,
    required this.isReady,
    required this.onPressed,
  });

  final bool isRunning;
  final bool isReady;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = isRunning
        ? 'Pause'
        : isReady
        ? 'Start breathing'
        : 'Resume';

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: AppColors.primary,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 72,
            child: Icon(
              isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: AppColors.text,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}
