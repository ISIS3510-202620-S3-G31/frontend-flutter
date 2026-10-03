import 'breathing_music_model.dart';
export 'breathing_music_model.dart';

enum BreathingPattern {
  twoStep(
    '2-step',
    'assets/icons/ic_two_step.svg',
    false,
    defaultInhale: 4,
    defaultHold: 4,
    defaultExhale: 4,
  ),
  threeStep(
    '3-step',
    'assets/icons/ic_three_step.svg',
    true,
    defaultInhale: 4,
    defaultHold: 4,
    defaultExhale: 4,
  ),
  fourSevenEight(
    '4-7-8',
    'assets/icons/ic_sleep_step.svg',
    true,
    defaultInhale: 4,
    defaultHold: 7,
    defaultExhale: 8,
  );

  const BreathingPattern(
    this.label,
    this.icon,
    this.hasHold, {
    this.defaultInhale = 4,
    this.defaultHold = 4,
    this.defaultExhale = 4,
  });

  final String label;
  final String icon;
  final bool hasHold;
  final int defaultInhale;
  final int defaultHold;
  final int defaultExhale;
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

  BreathingPhase get phase => switch (this) {
    BreathingStep.inhale => BreathingPhase.inhale,
    BreathingStep.hold => BreathingPhase.hold,
    BreathingStep.exhale => BreathingPhase.exhale,
  };
}

const List<int> sessionDurations = [2, 5, 10];

class CustomBreathingState {
  const CustomBreathingState({
    this.pattern = BreathingPattern.threeStep,
    this.inhaleSeconds = 4,
    this.holdSeconds = 4,
    this.exhaleSeconds = 4,
    this.sessionMinutes = 5,
    this.isRunning = false,
    this.phase = BreathingPhase.inhale,
    this.cycle = 1,
    this.progress = 0,
    this.selectedTrack,
    this.availableTracks = const [],
    this.isMusicEnabled = true,
    this.isOnline = true,
    this.isLoadingMusic = false,
    this.downloadingTrackId,
    this.previewTrack,
    this.isPreviewPlaying = false,
  });

  final BreathingPattern pattern;
  final int inhaleSeconds;
  final int holdSeconds;
  final int exhaleSeconds;
  final int sessionMinutes;
  final bool isRunning;
  final BreathingPhase phase;
  final int cycle;
  final double progress;
  final BreathingMusicTrack? selectedTrack;
  final List<BreathingMusicTrack> availableTracks;
  final bool isMusicEnabled;
  final bool isOnline;
  final bool isLoadingMusic;
  final String? downloadingTrackId;
  final BreathingMusicTrack? previewTrack;
  final bool isPreviewPlaying;

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

  int secondsOfPhase(BreathingPhase phase) => switch (phase) {
    BreathingPhase.inhale => inhaleSeconds,
    BreathingPhase.hold => holdSeconds,
    BreathingPhase.exhale => exhaleSeconds,
  };

  int get cycleDuration =>
      inhaleSeconds + (pattern.hasHold ? holdSeconds : 0) + exhaleSeconds;
    
  int get totalCycles =>
      (sessionMinutes * 60 / cycleDuration).round().clamp(1,99);
  
  int get secondsLeft =>
      (secondsOfPhase(phase) * (1 - progress)).ceil();

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
    int? cycle,
    double? progress,
    BreathingMusicTrack? selectedTrack,
    List<BreathingMusicTrack>? availableTracks,
    bool? isMusicEnabled,
    bool? isOnline,
    bool? isLoadingMusic,
    String? downloadingTrackId,
    bool clearDownloadingTrackId = false,
    BreathingMusicTrack? previewTrack,
    bool clearPreviewTrack = false,
    bool? isPreviewPlaying,
  }) {
    return CustomBreathingState(
      pattern: pattern ?? this.pattern,
      inhaleSeconds: inhaleSeconds ?? this.inhaleSeconds,
      holdSeconds: holdSeconds ?? this.holdSeconds,
      exhaleSeconds: exhaleSeconds ?? this.exhaleSeconds,
      sessionMinutes: sessionMinutes ?? this.sessionMinutes,
      isRunning: isRunning ?? this.isRunning,
      phase: phase ?? this.phase,
      cycle: cycle ?? this.cycle,
      progress: progress ?? this.progress,
      selectedTrack: selectedTrack ?? this.selectedTrack,
      availableTracks: availableTracks ?? this.availableTracks,
      isMusicEnabled: isMusicEnabled ?? this.isMusicEnabled,
      isOnline: isOnline ?? this.isOnline,
      isLoadingMusic: isLoadingMusic ?? this.isLoadingMusic,
      downloadingTrackId: clearDownloadingTrackId
          ? null
          : (downloadingTrackId ?? this.downloadingTrackId),
      previewTrack: clearPreviewTrack
          ? null
          : (previewTrack ?? this.previewTrack),
      isPreviewPlaying: isPreviewPlaying ?? this.isPreviewPlaying,
    );
  }
}
