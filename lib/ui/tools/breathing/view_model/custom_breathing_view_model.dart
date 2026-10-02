import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/models/breathing_model.dart';

const _minSeconds = 1;
const _maxSeconds = 15;
const _tick = Duration(milliseconds: 50);

class CustomBreathingViewModel extends ChangeNotifier {
  CustomBreathingState _state = const CustomBreathingState();
  Timer? _timer;


  double _phaseElapsed = 0;
  String? _message;

  CustomBreathingState get state => _state;
  List<BreathingStep> get visibleSteps => _state.visibleSteps;

  /// Message to show once in a snack bar.
  String? get message => _message;

  void start() {
    _startTimer();
  }  

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) => _onTick());
  }

  void _onTick() {
    if (!_state.isRunning) return;

    final duration = _state.secondsOfPhase(_state.phase);
    final elapsed = _phaseElapsed + _tick.inMilliseconds / 1000;

    if (elapsed >= duration) {
      _advancePhase();
      return;
    }
    _phaseElapsed = elapsed;
    _state = _state.copyWith(
      progress: (elapsed / duration).clamp(0.0, 1.0),
    );
    
    notifyListeners();
  }

  void _advancePhase() {
    var cycle = _state.cycle;
    BreathingPhase next;

    switch (_state.phase) {
      case BreathingPhase.inhale:
        next = _state.pattern.hasHold
            ? BreathingPhase.hold
            : BreathingPhase.exhale;
      case BreathingPhase.hold:
        next = BreathingPhase.exhale;
      case BreathingPhase.exhale:
        cycle = _state.cycle + 1;
        if (cycle > _state.totalCycles) {
          _completeSession();
          return;
        }
        next = BreathingPhase.inhale;
    }

    _phaseElapsed = 0;
    _state = _state.copyWith(
      phase: next,
      cycle: cycle,
      progress: 0,
    );
    notifyListeners();
  }

  void _completeSession() {
    _timer?.cancel();
    _state = _state.copyWith(isRunning: false, progress: 1);
    _message = 'Breathing session complete! Well done.';
    HapticFeedback.heavyImpact();
    notifyListeners();
  }

  void toggleRunning() {
    _state = _state.copyWith(isRunning: !_state.isRunning);
    if (_state.isRunning && !(_timer?.isActive ?? false)) _startTimer();
    notifyListeners();
  }

  void resetSession() {
    _phaseElapsed = 0;
    _state = _state.copyWith(
      cycle: 1,
      phase: BreathingPhase.inhale,
      progress: 0,
      isRunning: true,
    );
    _startTimer();
    notifyListeners();
  }

  void stop() => _timer?.cancel();

  void selectPattern(BreathingPattern pattern) {
    // The guided patterns come with their own timings.
    _state = switch (pattern) {
      BreathingPattern.twoStep => _state.copyWith(pattern: pattern),
      BreathingPattern.threeStep => _state.copyWith(
        pattern: pattern,
        inhaleSeconds: 4,
        holdSeconds: 7,
        exhaleSeconds: 6,
      ),
      BreathingPattern.fourSevenEight => _state.copyWith(
        pattern: pattern,
        inhaleSeconds: 4,
        holdSeconds: 7,
        exhaleSeconds: 8,
      ),
    };
    _phaseElapsed = 0;
    _state = _state.copyWith(
      phase: BreathingPhase.inhale,
      progress: 0,
    );
    notifyListeners();
  }

  void changeStep(BreathingStep step, int delta) {
    final seconds = (_state.secondsOf(step) + delta).clamp(
      _minSeconds,
      _maxSeconds,
    );
    _state = switch (step) {
      BreathingStep.inhale => _state.copyWith(inhaleSeconds: seconds),
      BreathingStep.hold => _state.copyWith(holdSeconds: seconds),
      BreathingStep.exhale => _state.copyWith(exhaleSeconds: seconds),
    };
    // Restart the phase when its own length changed under it.
    if (step.phase == _state.phase) {
      _phaseElapsed = 0;
      _state = _state.copyWith(progress: 0);
    }
    notifyListeners();
  }

  void selectDuration(int minutes) {
    _state = _state.copyWith(sessionMinutes: minutes);
    notifyListeners();
  }

  

  void clearMessage() => _message = null;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
