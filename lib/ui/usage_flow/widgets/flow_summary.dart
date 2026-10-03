import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../domain/usage_flow/flow_step.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import 'flow_button.dart';

/// Last screen: how strong the emotion was before and after the tool.
class FlowSummary extends StatelessWidget {
  const FlowSummary({
    super.key,
    required this.before,
    required this.after,
    required this.usefulness,
    required this.message,
    required this.onDone,
  });

  final int before;
  final int after;
  final Usefulness usefulness;
  final String message;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SvgPicture.asset('assets/icons/bloom_mindful.svg', height: 110),
        const SizedBox(height: 16),
        Text('Well done', style: AppText.h2),
        const SizedBox(height: 4),
        Text(message, style: AppText.bodyMuted, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _Score(label: 'Before', value: before),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Score(label: 'After', value: after),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'It helped: ${usefulness.label.toLowerCase()}',
          style: AppText.bodyMuted,
        ),
        const SizedBox(height: 32),
        FlowButton(label: 'Back to tools', onPressed: onDone),
      ],
    );
  }
}

class _Score extends StatelessWidget {
  const _Score({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDim,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(label, style: AppText.bodyMuted.copyWith(fontSize: 13)),
          Text(
            '$value / 5',
            style: AppText.h2.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
