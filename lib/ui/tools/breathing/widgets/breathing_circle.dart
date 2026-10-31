import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../data/models/breathing_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

const _circleSize = 260.0;

/// At rest the circle fills half of the ring.
const _minScale = 0.5;


class BreathingCircle extends StatelessWidget {
  const BreathingCircle({
    super.key,
    required this.state,
    required this.isReady,
    required this.isCompleted,
  });

  final CustomBreathingState state;
  final bool isReady;
  final bool isCompleted;

  double get _scale {
    if (isReady || isCompleted) return _minScale;
    final progress = state.progress.clamp(0.0, 1.0);
    return switch (state.phase) {
      BreathingPhase.inhale => _minScale + (1 - _minScale) * progress,
      BreathingPhase.hold => 1.0,
      BreathingPhase.exhale => 1 - (1 - _minScale) * progress,
    };
  }

  String get _description {
    final hasHold = state.pattern.hasHold && state.holdSeconds > 0;
    final rhythm = hasHold
        ? 'Inhale ${state.inhaleSeconds} seconds, '
              'hold ${state.holdSeconds} seconds, '
              'exhale ${state.exhaleSeconds} seconds'
        : 'Inhale ${state.inhaleSeconds} seconds, '
              'exhale ${state.exhaleSeconds} seconds';
    if (isReady) {
      return 'Ready. Tap start to begin your breathing exercise. $rhythm';
    }
    if (isCompleted) return 'Session complete. $rhythm';
    return '${state.phase.word}. ${state.phase.label}. $rhythm';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _description,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: _circleSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _DottedRingPainter()),
            ),
            // The timer ticks every 50 ms; the animation fills the gaps.
            AnimatedScale(
              scale: _scale,
              duration: const Duration(milliseconds: 60),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.expand(),
              ),
            ),
            _content(),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    if (isReady) {
      // Bloom, the app's avatar, waits inside the circle until the start.
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/icons/bloom_mindful.svg',
            width: 62,
            height: 70,
          ),
          const SizedBox(height: 8),
          Text('Ready?', style: AppText.h1),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(isCompleted ? 'Done' : state.phase.word, style: AppText.h1),
        // The seconds only while running; paused, the word stays alone.
        if (state.isRunning) Text('${state.secondsLeft}', style: AppText.h2),
      ],
    );
  }
}

/// Guide ring: dashes of 6 and gaps of 5 around the biggest circle.
class _DottedRingPainter extends CustomPainter {
  const _DottedRingPainter();

  static const _stroke = 1.5;
  static const _dash = 6.0;
  static const _gap = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2 - _stroke / 2;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: radius,
    );
    final paint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;

    final dashes = (2 * math.pi * radius / (_dash + _gap)).floor();
    final step = 2 * math.pi / dashes;
    final sweep = step * _dash / (_dash + _gap);
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, i * step, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DottedRingPainter oldDelegate) => false;
}
