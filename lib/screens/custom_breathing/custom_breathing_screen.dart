import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/screen_header.dart';
import 'custom_breathing_models.dart';
import 'duration_pills.dart';
import 'pattern_selector.dart';
import 'session_controls.dart';
import 'stepper_row.dart';
import 'timer_card.dart';

const int _minSeconds = 1;
const int _maxSeconds = 15;

/// Tool screen for Custom Breathing with interactive rhythm countdown,
/// pattern selector, steppers and session controls.
class CustomBreathingScreen extends StatefulWidget {
  const CustomBreathingScreen({
    super.key,
    this.onBack,
    this.onReset,
    this.onPause,
    this.onFinish,
  });

  final VoidCallback? onBack;
  final VoidCallback? onReset;
  final VoidCallback? onPause;
  final VoidCallback? onFinish;

  @override
  State<CustomBreathingScreen> createState() => _CustomBreathingScreenState();
}

class _CustomBreathingScreenState extends State<CustomBreathingScreen> {
  CustomBreathingState _state = const CustomBreathingState();
  Timer? _timer;
  double _phaseElapsed = 1.6; // starts at mockup state (0.4 progress of 4s)

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), _onTick);
  }

  int _currentPhaseDuration() {
    switch (_state.phase) {
      case BreathingPhase.inhale:
        return _state.inhaleSeconds;
      case BreathingPhase.hold:
        return _state.holdSeconds;
      case BreathingPhase.exhale:
        return _state.exhaleSeconds;
    }
  }

  void _onTick(Timer timer) {
    if (!_state.isRunning) return;

    final duration = _currentPhaseDuration();
    final newElapsed = _phaseElapsed + 0.05;

    if (newElapsed >= duration) {
      // Transition to next phase
      _advancePhase();
    } else {
      final secondsLeft = (duration - newElapsed).ceil();
      final progress = (newElapsed / duration).clamp(0.0, 1.0);
      setState(() {
        _phaseElapsed = newElapsed;
        _state = _state.copyWith(
          secondsLeft: secondsLeft,
          progress: progress,
        );
      });
    }
  }

  void _advancePhase() {
    BreathingPhase nextPhase;
    int nextCycle = _state.cycle;

    if (_state.phase == BreathingPhase.inhale) {
      if (_state.pattern.hasHold) {
        nextPhase = BreathingPhase.hold;
      } else {
        nextPhase = BreathingPhase.exhale;
      }
    } else if (_state.phase == BreathingPhase.hold) {
      nextPhase = BreathingPhase.exhale;
    } else {
      // Exhale finished -> advance cycle
      nextCycle = _state.cycle + 1;
      if (nextCycle > _state.totalCycles) {
        // Session completed
        _timer?.cancel();
        setState(() {
          _state = _state.copyWith(
            isRunning: false,
            secondsLeft: 0,
            progress: 1.0,
          );
        });
        HapticFeedback.heavyImpact();
        _showCompletedMessage();
        return;
      }
      nextPhase = BreathingPhase.inhale;
    }

    _phaseElapsed = 0;
    int newDuration;
    switch (nextPhase) {
      case BreathingPhase.inhale:
        newDuration = _state.inhaleSeconds;
        break;
      case BreathingPhase.hold:
        newDuration = _state.holdSeconds;
        break;
      case BreathingPhase.exhale:
        newDuration = _state.exhaleSeconds;
        break;
    }

    setState(() {
      _state = _state.copyWith(
        phase: nextPhase,
        cycle: nextCycle,
        secondsLeft: newDuration,
        progress: 0.0,
      );
    });
  }

  void _showCompletedMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Breathing session complete! Well done.')),
    );
  }

  void _toggleRunning() {
    setState(() {
      _state = _state.copyWith(isRunning: !_state.isRunning);
    });
    if (_state.isRunning && (_timer == null || !_timer!.isActive)) {
      _startTimer();
    }
    widget.onPause?.call();
  }

  void _resetSession() {
    setState(() {
      _phaseElapsed = 0;
      _state = _state.copyWith(
        cycle: 1,
        phase: BreathingPhase.inhale,
        secondsLeft: _state.inhaleSeconds,
        progress: 0.0,
        isRunning: true,
      );
    });
    _startTimer();
    widget.onReset?.call();
  }

  void _finishSession() {
    _timer?.cancel();
    if (widget.onFinish != null) {
      widget.onFinish!();
    } else {
      Navigator.maybePop(context);
    }
  }

  void _selectPattern(BreathingPattern pattern) {
    setState(() {
      switch (pattern) {
        case BreathingPattern.twoStep:
          _state = _state.copyWith(
            pattern: pattern,
            phase: BreathingPhase.inhale,
            secondsLeft: _state.inhaleSeconds,
            progress: 0.0,
          );
          break;
        case BreathingPattern.threeStep:
          _state = _state.copyWith(
            pattern: pattern,
            inhaleSeconds: 4,
            holdSeconds: 7,
            exhaleSeconds: 6,
            phase: BreathingPhase.inhale,
            secondsLeft: 4,
            progress: 0.0,
          );
          break;
        case BreathingPattern.fourSevenEight:
          _state = _state.copyWith(
            pattern: pattern,
            inhaleSeconds: 4,
            holdSeconds: 7,
            exhaleSeconds: 8,
            phase: BreathingPhase.inhale,
            secondsLeft: 4,
            progress: 0.0,
          );
          break;
      }
      _phaseElapsed = 0;
      _recalculateTotalCycles();
    });
  }

  void _changeStep(BreathingStep step, int delta) {
    final seconds = (_state.secondsOf(step) + delta)
        .clamp(_minSeconds, _maxSeconds)
        .toInt();
    setState(() {
      switch (step) {
        case BreathingStep.inhale:
          _state = _state.copyWith(inhaleSeconds: seconds);
          if (_state.phase == BreathingPhase.inhale) {
            _phaseElapsed = 0;
            _state = _state.copyWith(secondsLeft: seconds, progress: 0.0);
          }
          break;
        case BreathingStep.hold:
          _state = _state.copyWith(holdSeconds: seconds);
          if (_state.phase == BreathingPhase.hold) {
            _phaseElapsed = 0;
            _state = _state.copyWith(secondsLeft: seconds, progress: 0.0);
          }
          break;
        case BreathingStep.exhale:
          _state = _state.copyWith(exhaleSeconds: seconds);
          if (_state.phase == BreathingPhase.exhale) {
            _phaseElapsed = 0;
            _state = _state.copyWith(secondsLeft: seconds, progress: 0.0);
          }
          break;
      }
      _recalculateTotalCycles();
    });
  }

  void _selectDuration(int minutes) {
    setState(() {
      _state = _state.copyWith(sessionMinutes: minutes);
      _recalculateTotalCycles();
    });
  }

  void _recalculateTotalCycles() {
    final duration = _state.cycleDuration;
    if (duration <= 0) return;
    final totalSeconds = _state.sessionMinutes * 60;
    final calculated = (totalSeconds / duration).round().clamp(1, 99);
    _state = _state.copyWith(totalCycles: calculated);
  }

  @override
  Widget build(BuildContext context) {
    final steps = _state.visibleSteps;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              ScreenHeader(
                title: Text(
                  'Custom breathing',
                  style: AppText.breathingTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: 'Build your own rhythm',
                onBack: widget.onBack,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: PatternSelector(
                          selected: _state.pattern,
                          onSelected: _selectPattern,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: TimerCard(state: _state),
                      ),
                      for (var i = 0; i < steps.length; i++)
                        Padding(
                          padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                          child: StepperRow(
                            label: steps[i].label,
                            seconds: _state.secondsOf(steps[i]),
                            onDecrease: () => _changeStep(steps[i], -1),
                            onIncrease: () => _changeStep(steps[i], 1),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 8),
                        child: DurationPills(
                          selectedMinutes: _state.sessionMinutes,
                          onSelected: _selectDuration,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 8, 40, 24),
                child: SessionControls(
                  isRunning: _state.isRunning,
                  onReset: _resetSession,
                  onToggleRunning: _toggleRunning,
                  onFinish: _finishSession,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}