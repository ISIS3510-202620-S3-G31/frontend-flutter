import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

import '../models/breathing_music_model.dart';
import '../repositories/breathing_repository.dart';

class BreathingAudioPlayerService {
  BreathingAudioPlayerService({AudioPlayer? player}) : _providedPlayer = player;

  final AudioPlayer? _providedPlayer;
  AudioPlayer? _lazyPlayer;

  AudioPlayer get _player {
    final player = _providedPlayer;
    if (player != null) return player;
    return _lazyPlayer ??= AudioPlayer();
  }

  BreathingMusicTrack? _currentTrack;
  bool _isPlaying = false;

  BreathingMusicTrack? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  PlayerState get state => _player.state;
  Stream<PlayerState> get onPlayerStateChanged => _player.onPlayerStateChanged;

  Future<void> playTrack(
    BreathingMusicTrack track, {
    required BreathingRepository repository,
  }) async {
    _currentTrack = track;
    final source = await repository.resolveAudioSource(track);
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(source);
      _isPlaying = true;
    } catch (_) {
      rethrow;
    }
  }

  Future<void> resume() async {
    if (_currentTrack != null) {
      try {
        await _player.resume();
        _isPlaying = true;
      } catch (_) {}
    }
  }

  /// Pauses playback.
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (_) {}
    _isPlaying = false;
  }

  /// Stops playback and resets position.
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
    _isPlaying = false;
  }

  /// Sets audio volume between 0.0 and 1.0.
  Future<void> setVolume(double volume) async {
    try {
      await _player.setVolume(volume);
    } catch (_) {}
  }

  /// Disposes the underlying audio player.
  Future<void> dispose() async {
    try {
      await _lazyPlayer?.dispose();
      await _providedPlayer?.dispose();
    } catch (_) {}
  }
}
