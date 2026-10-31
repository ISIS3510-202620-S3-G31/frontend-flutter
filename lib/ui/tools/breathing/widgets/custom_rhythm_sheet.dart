import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../data/models/breathing_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import 'breathing_round_button.dart';


Future<void> showCustomRhythmSheet(
  BuildContext context, {
  required int inhale,
  required int hold,
  required int exhale,
  required void Function(int inhale, int hold, int exhale) onDone,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.background,
    showDragHandle: true,
    builder: (_) => CustomRhythmSheet(
      inhale: inhale,
      hold: hold,
      exhale: exhale,
      onDone: onDone,
    ),
  );
}

/// − / + for inhale, hold and exhale, inside the Custom limits.
class CustomRhythmSheet extends StatefulWidget {
  const CustomRhythmSheet({
    super.key,
    required this.inhale,
    required this.hold,
    required this.exhale,
    required this.onDone,
  });

  final int inhale;
  final int hold;
  final int exhale;
  final void Function(int inhale, int hold, int exhale) onDone;

  @override
  State<CustomRhythmSheet> createState() => _CustomRhythmSheetState();
}

class _CustomRhythmSheetState extends State<CustomRhythmSheet> {
  late int _inhale = widget.inhale.clamp(
    customMinBreathSeconds,
    customMaxSeconds,
  );
  late int _hold = widget.hold.clamp(0, customMaxSeconds);
  late int _exhale = widget.exhale.clamp(
    customMinBreathSeconds,
    customMaxSeconds,
  );

  void _done() {
    widget.onDone(_inhale, _hold, _exhale);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text('Custom rhythm', style: AppText.h2),
            ),
            const SizedBox(height: 8),
            _StepperRow(
              label: 'Inhale',
              value: _inhale,
              min: customMinBreathSeconds,
              max: customMaxSeconds,
              onChanged: (value) => setState(() => _inhale = value),
            ),
            const SizedBox(height: 8),
            _StepperRow(
              label: 'Hold',
              value: _hold,
              min: 0,
              max: customMaxSeconds,
              onChanged: (value) => setState(() => _hold = value),
            ),
            const SizedBox(height: 8),
            _StepperRow(
              label: 'Exhale',
              value: _exhale,
              min: customMinBreathSeconds,
              max: customMaxSeconds,
              onChanged: (value) => setState(() => _exhale = value),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _done,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.text,
                  shape: const StadiumBorder(),
                  textStyle: AppText.body,
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppText.h3)),
            BreathingRoundButton(
              icon: SvgPicture.asset(
                'assets/icons/ic_minus.svg',
                width: 18,
                height: 18,
              ),
              semanticLabel: 'Less $label',
              onPressed: value > min ? () => onChanged(value - 1) : null,
            ),
            SizedBox(
              width: 64,
              child: Text(
                '$value s',
                textAlign: TextAlign.center,
                style: AppText.h2,
                semanticsLabel: '$label $value seconds',
              ),
            ),
            BreathingRoundButton(
              icon: SvgPicture.asset(
                'assets/icons/ic_plus.svg',
                width: 18,
                height: 18,
              ),
              semanticLabel: 'More $label',
              onPressed: value < max ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ),
    );
  }
}
