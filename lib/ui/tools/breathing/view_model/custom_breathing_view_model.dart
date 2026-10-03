import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/models/breathing_model.dart';
import '../../../../data/repositories/breathing_repository.dart';
import '../../../../data/services/breathing_audio_player_service.dart';

const _minSeconds = 1;
const _maxSeconds = 15;
const _tick = Duration(milliseconds: 50);

class CustomBreathingViewModel extends ChangeNotifier {
  CustomBreathingViewModel({
    BreathingRepository? repository,
    BreathingAudioPlayerService? audioPlayer,
  })  : _repository = repository ?? BreathingRepository(),
        _ownsRepository = repository == null,
        _audioPlayer = audioPlayer ?? BreathingAudioPlayerService(),
        _ownsAudioPlayer = audioPlayer == null {
    _initMusic();
  }

  final BreathingRepository _repository;
  final bool _ownsRepository;
  final BreathingAudioPlayerService _audioPlayer;
  final bool _ownsAudioPlayer;

  CustomBreathingState _state = const CustomBreathingState();
  Timer? _timer;
  StreamSubscription<bool>? _connectivitySub;
  StreamSubscription<BreathingMusicTrack>? _trackCachedSub;

  double _phaseElapsed = 0;
  String? _message;

  CustomBreathingState get state => _state;
  List<BreathingStep> get visibleSteps => _state.visibleSteps;

  /// Message to show once in a snack bar.
  String? get message => _message;

  Future<void> _initMusic() async {
    _state = _state.copyWith(isLoadingMusic: true);
    notifyListeners();

    // Listen to network changes
    _connectivitySub = _repository.onConnectivityChanged.listen((isOnline) {
      _state = _state.copyWith(isOnline: isOnline);
      notifyListeners();
    });

    // Listen to tracks being cached (either background or user initiated)
    _trackCachedSub = _repository.onTrackCached.listen((cachedTrack) {
      final updatedTracks = _state.availableTracks.map((t) {
        return t.id == cachedTrack.id ? cachedTrack : t;
      }).toList();

      final updatedSelected = _state.selectedTrack?.id == cachedTrack.id
          ? cachedTrack
          : _state.selectedTrack;

      _state = _state.copyWith(
        availableTracks: updatedTracks,
        selectedTrack: updatedSelected,
      );
      notifyListeners();
    });

    final online = await _repository.isOnline();
    final isMusicEnabled = await _repository.isMusicEnabled();
    final tracks = await _repository.getTracks();
    final savedTrackId = await _repository.getSelectedTrackId();

    BreathingMusicTrack? selectedTrack;
    if (savedTrackId != null && tracks.any((t) => t.id == savedTrackId)) {
      selectedTrack = tracks.firstWhere((t) => t.id == savedTrackId);
    } else if (tracks.isNotEmpty) {
      selectedTrack = tracks.first;
    }

    _state = _state.copyWith(
      isOnline: online,
      isMusicEnabled: isMusicEnabled,
      availableTracks: tracks,
      selectedTrack: selectedTrack,
      isLoadingMusic: false,
    );
    notifyListeners();
  }

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
    _audioPlayer.stop();
    _state = _state.copyWith(isRunning: false, progress: 1);
    _message = 'Breathing session complete! Well done.';
    HapticFeedback.heavyImpact();
    notifyListeners();
  }

  void toggleRunning() {
    final nextRunning = !_state.isRunning;
    _state = _state.copyWith(isRunning: nextRunning);

    if (nextRunning) {
      if (!(_timer?.isActive ?? false)) _startTimer();
      if (_state.isMusicEnabled) {
        _playMusic();
      }
    } else {
      _audioPlayer.pause();
    }

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
    if (_state.isMusicEnabled) {
      _playMusic();
    }
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _audioPlayer.stop();
  }

  Future<void> _playMusic() async {
    final track = _state.selectedTrack;
    if (track == null) return;

    try {
      await _audioPlayer.playTrack(track, repository: _repository);
    } on SocketException catch (_) {
      _message = 'Track "${track.title}" is not cached for offline use. Connect to the internet to listen and cache it.';
      notifyListeners();
    } catch (e) {
      _message = 'Could not play audio track.';
      notifyListeners();
    }
  }

  /// Toggles whether background music is enabled during sessions.
  Future<void> toggleMusic() async {
    final newEnabled = !_state.isMusicEnabled;
    _state = _state.copyWith(isMusicEnabled: newEnabled);
    await _repository.setMusicEnabled(newEnabled);

    if (newEnabled) {
      if (_state.isRunning) {
        await _playMusic();
      }
    } else {
      await _audioPlayer.pause();
    }

    notifyListeners();
  }

  /// Selects a new music track.
  Future<void> selectTrack(BreathingMusicTrack track) async {
    _state = _state.copyWith(selectedTrack: track);
    await _repository.setSelectedTrackId(track.id);

    if (_state.isRunning && _state.isMusicEnabled) {
      await _playMusic();
    }

    notifyListeners();
  }

  /// Explicitly downloads and caches a track for offline listening.
  Future<void> downloadTrack(BreathingMusicTrack track) async {
    if (_state.downloadingTrackId != null) return;

    _state = _state.copyWith(downloadingTrackId: track.id);
    notifyListeners();

    try {
      final updatedTrack = await _repository.downloadAndCacheTrack(track);

      final updatedList = _state.availableTracks.map((t) {
        return t.id == updatedTrack.id ? updatedTrack : t;
      }).toList();

      final updatedSelected = _state.selectedTrack?.id == updatedTrack.id
          ? updatedTrack
          : _state.selectedTrack;

      _state = _state.copyWith(
        availableTracks: updatedList,
        selectedTrack: updatedSelected,
        clearDownloadingTrackId: true,
      );
      _message = '"${track.title}" downloaded and cached for offline use.';
    } catch (_) {
      _state = _state.copyWith(clearDownloadingTrackId: true);
      _message = 'Failed to download "${track.title}". Check your internet connection.';
    }

    notifyListeners();
  }

  /// Removes a cached track from local storage to free up space.
  Future<void> removeTrackFromCache(BreathingMusicTrack track) async {
    try {
      final updatedTrack = await _repository.removeCachedTrack(track);

      final updatedList = _state.availableTracks.map((t) {
        return t.id == updatedTrack.id ? updatedTrack : t;
      }).toList();

      final updatedSelected = _state.selectedTrack?.id == updatedTrack.id
          ? updatedTrack
          : _state.selectedTrack;

      _state = _state.copyWith(
        availableTracks: updatedList,
        selectedTrack: updatedSelected,
      );
      _message = '"${track.title}" removed from offline cache.';
    } catch (_) {
      _message = 'Could not remove "${track.title}" from cache.';
    }

    notifyListeners();
  }

  /// Refreshes track catalog from remote Jamendo API if online.
  Future<void> refreshTracks() async {
    _state = _state.copyWith(isLoadingMusic: true);
    notifyListeners();

    try {
      final tracks = await _repository.getTracks(refreshFromRemote: true);
      _state = _state.copyWith(
        availableTracks: tracks,
        isLoadingMusic: false,
      );
    } catch (_) {
      _state = _state.copyWith(isLoadingMusic: false);
    }

    notifyListeners();
  }

  void selectPattern(BreathingPattern pattern) {
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
    _connectivitySub?.cancel();
    _trackCachedSub?.cancel();
    if (_ownsAudioPlayer) {
      _audioPlayer.stop();
      _audioPlayer.dispose();
    }
    if (_ownsRepository) {
      _repository.dispose();
    }
    super.dispose();
  }
}
