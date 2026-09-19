enum BreathingPattern {
  twoStep('2-step', 'assets/icons/ic_two_step.svg', false),
  threeStep('3-step', 'assets/icons/ic_three_step.svg', true),
  fourSevenEight('4-7-8', 'assets/icons/ic_sleep_step.svg', true);

  const BreathingPattern(this.label, this.icon, this.hasHold);

  final String label;
  final String icon;
  final bool hasHold;
}

enum BreathingPhase {
  inhale('Breathe in'),
  hold('Hold'),
  exhale('Breathe out');

  const BreathingPhase(this.label);

  final String label;
}

enum BreathingStep {
  inhale('Inhale'),
  hold('Hold'),
  exhale('Exhale');

  const BreathingStep(this.label);

  final String label;
}

const List<int> sessionDurations = [2, 5, 10];

/// State representation for Custom Breathing.
/// The default values match the mid-session state shown in the mockup:
/// 3-step, 4s breathe in, cycle 2 of 6, Inhale 4s, Hold 7s, Exhale 6s, 5 min.
class CustomBreathingState {
  const CustomBreathingState({
    this.pattern = BreathingPattern.threeStep,
    this.inhaleSeconds = 4,
    this.holdSeconds = 7,
    this.exhaleSeconds = 6,
    this.sessionMinutes = 5,
    this.isRunning = true,
    this.phase = BreathingPhase.inhale,
    this.secondsLeft = 4,
    this.cycle = 2,
    this.totalCycles = 6,
    this.progress = 0.4,
  });

  final BreathingPattern pattern;
  final int inhaleSeconds;
  final int holdSeconds;
  final int exhaleSeconds;
  final int sessionMinutes;
  final bool isRunning;
  final BreathingPhase phase;
  final int secondsLeft;
  final int cycle;
  final int totalCycles;
  final double progress;

  int secondsOf(BreathingStep step) {
    switch (step) {
      case BreathingStep.inhale:
        return inhaleSeconds;
      case BreathingStep.hold:
        return holdSeconds;
      case BreathingStep.exhale:
        return exhaleSeconds;
    }
  }

  int get cycleDuration =>
      inhaleSeconds + (pattern.hasHold ? holdSeconds : 0) + exhaleSeconds;

  List<BreathingStep> get visibleSteps => BreathingStep.values
      .where((step) => step != BreathingStep.hold || pattern.hasHold)
      .toList();

  CustomBreathingState copyWith({
    BreathingPattern? pattern,
    int? inhaleSeconds,
    int? holdSeconds,
    int? exhaleSeconds,
    int? sessionMinutes,
    bool? isRunning,
    BreathingPhase? phase,
    int? secondsLeft,
    int? cycle,
    int? totalCycles,
    double? progress,
  }) {
    return CustomBreathingState(
      pattern: pattern ?? this.pattern,
      inhaleSeconds: inhaleSeconds ?? this.inhaleSeconds,
      holdSeconds: holdSeconds ?? this.holdSeconds,
      exhaleSeconds: exhaleSeconds ?? this.exhaleSeconds,
      sessionMinutes: sessionMinutes ?? this.sessionMinutes,
      isRunning: isRunning ?? this.isRunning,
      phase: phase ?? this.phase,
      secondsLeft: secondsLeft ?? this.secondsLeft,
      cycle: cycle ?? this.cycle,
      totalCycles: totalCycles ?? this.totalCycles,
      progress: progress ?? this.progress,
    );
  }
}
