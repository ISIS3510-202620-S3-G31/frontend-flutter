import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/repositories/analytics_repository.dart';
import '../../../../data/services/microphone_service.dart';
import '../../../../domain/scream/scream_goal.dart';
import '../../../../utils/noise_level.dart';

class ScreamTankViewModel extends ChangeNotifier {
  ScreamTankViewModel({
    MicrophoneService? microphone,
    AnalyticsRepository? analytics,
    ScreamGoal goal = const ScreamGoal(),
  }) : _microphone = microphone ?? const MicrophoneService(),
       _analytics = analytics ?? AnalyticsRepository(),
       _goal = goal;

  final MicrophoneService _microphone;
  final AnalyticsRepository _analytics;
  final ScreamGoal _goal;


  static const _smoothingSeconds = 0.15;


  static const _firstReadingSeconds = 0.1;

  static const _maxStepSeconds = 0.5;

  StreamSubscription<double>? _readings;
  DateTime? _lastReading;
  bool _requestingPermission = false;
  bool _disposed = false;

  double _db = 0;

  /// The loudest the (smoothed) mic has been in this session, for analytics.
  double _peakDb = 0;

  /// Seconds screamed, each one counted by how loud it was. Pausing keeps them.
  double _loudSeconds = 0;
  String? _errorMessage;
  bool _canOpenSettings = false;

  ScreamGoal get goal => _goal;
  double get db => _db;

  /// How full the tank is, 0..1.
  double get fill => _goal.progressOf(_loudSeconds);
  double get micLevel => levelFromDb(_db);
  bool get listening => _readings != null;

  /// True once the tank is full: the session is complete.
  bool get isFull => _goal.isReached(_loudSeconds);
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
    _analytics.logToolStep(
      toolId: 'scream',
      stepName: 'mic_started',
      stepIndex: 0,
    );
    _notify();
  }

  void _onReading(double db) {
    final now = DateTime.now();
    final last = _lastReading;
    _lastReading = now;
    final dt = last == null
        ? _firstReadingSeconds
        : math.min(
            now.difference(last).inMicroseconds / 1e6,
            _maxStepSeconds,
          );

    final smoothing = 1 - math.exp(-dt / _smoothingSeconds);
    _db += (db - _db) * smoothing;
    _peakDb = math.max(_peakDb, _db);
    _loudSeconds += _goal.fillRateOf(_db) * dt;
    _notify();


    if (isFull) {
      HapticFeedback.heavyImpact();
      stopListening();
      _analytics.logToolStep(toolId: 'scream', stepName: 'tank_full', stepIndex: 1);
      _analytics.completeToolSession(
        toolId: 'scream',
        toolName: 'Scream Tank',
        additionalParams: {
          'peak_db': _peakDb.round(),
          'goal_db': _goal.targetDb.round(),
          'goal_seconds': _goal.secondsToFill.round(),
        },
      );
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
    _peakDb = 0;
    _loudSeconds = 0;
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
