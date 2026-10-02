import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/services/microphone_service.dart';
import '../../../../utils/noise_level.dart';

class ScreamTankViewModel extends ChangeNotifier {
  ScreamTankViewModel({MicrophoneService? microphone})
    : _microphone = microphone ?? const MicrophoneService();

  final MicrophoneService _microphone;

  /// Seconds of screaming at full level needed to fill the tank.
  static const _secondsToFill = 20.0;

  /// Quieter readings don't fill the tank, so silence doesn't count.
  static const _fillThresholdDb = 60.0;

  /// How fast the meter follows the mic, so it doesn't flicker.
  static const _smoothingSeconds = 0.15;

  StreamSubscription<double>? _readings;
  DateTime? _lastReading;
  bool _requestingPermission = false;
  bool _disposed = false;

  double _db = 0;
  double _fill = 0;
  String? _errorMessage;
  bool _canOpenSettings = false;

  double get db => _db;
  double get fill => _fill;
  double get micLevel => levelFromDb(_db);
  bool get listening => _readings != null;
  bool get isFull => _fill >= 1;
  bool get canToggleMic => !_requestingPermission && !isFull;
  String? get errorMessage => _errorMessage;
  bool get canOpenSettings => _canOpenSettings;

  void toggleMic() => listening ? stopListening() : _startListening();

  Future<void> _startListening() async {
    if (listening || _requestingPermission || isFull) return;
    _requestingPermission = true;
    _notify();

    final permission = await _microphone.requestPermission();
    _requestingPermission = false;
    if (_disposed) return;

    if (permission != MicPermission.granted) {
      _setError(
        'Scream Tank needs the microphone to hear you.',
        canOpenSettings: permission == MicPermission.permanentlyDenied,
      );
      return;
    }

    _lastReading = null;
    _readings = _microphone.decibels().listen(
      _onReading,
      onError: (Object _) {
        stopListening();
        _setError('The microphone stopped working.');
      },
    );
    _notify();
  }

  void _onReading(double db) {
    final now = DateTime.now();
    final last = _lastReading;
    _lastReading = now;
    // Capped so a hiccup between readings can't fill the tank in one step.
    final dt = last == null
        ? 0.0
        : math.min(now.difference(last).inMicroseconds / 1e6, 0.5);

    final smoothing = dt == 0 ? 1.0 : 1 - math.exp(-dt / _smoothingSeconds);
    _db += (db - _db) * smoothing;
    if (_db >= _fillThresholdDb) {
      _fill = math.min(1.0, _fill + levelFromDb(_db) * dt / _secondsToFill);
    }
    _notify();

    if (isFull) {
      HapticFeedback.heavyImpact();
      stopListening();
    }
  }

  void stopListening() {
    final readings = _readings;
    if (readings == null) return;
    _readings = null;
    _db = 0;
    readings.cancel();
    _notify();
  }

  void restart() {
    stopListening();
    _fill = 0;
    _notify();
  }

  void onAppLifecycleChanged(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) stopListening();
  }

  Future<void> openSettings() => _microphone.openSettings();

  void clearError() {
    _errorMessage = null;
    _canOpenSettings = false;
  }

  void _setError(String message, {bool canOpenSettings = false}) {
    _errorMessage = message;
    _canOpenSettings = canOpenSettings;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _readings?.cancel();
    super.dispose();
  }
}
