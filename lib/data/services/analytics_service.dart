// Generated automatically by Firebase-Analytics
// Google Analytics 4 2026-10-01 14:15:27

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Minimal service to manage Firebase Analytics throughout the app.
class AnalyticsService {
  factory AnalyticsService({FirebaseAnalytics? analytics}) {
    if (analytics != null) {
      return AnalyticsService._internal(analytics);
    }
    return _instance ??= AnalyticsService._internal(FirebaseAnalytics.instance);
  }

  AnalyticsService._internal(this._analytics);

  static AnalyticsService? _instance;
  final FirebaseAnalytics _analytics;
  final Set<String> _completedTools = <String>{};

  /// Exposes the underlying [FirebaseAnalytics] instance.
  FirebaseAnalytics get analytics => _analytics;

  /// [NavigatorObserver] to automatically log screen views when navigation changes.
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// Logs a custom analytics event with optional parameters.
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (kDebugMode) {
      debugPrint('[Analytics] 📊 Event: $name | params: $parameters');
    }
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  /// Sets the user ID for analytics tracking.
  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }

  /// Sets a custom user property.
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  /// Manually logs a screen view.
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (kDebugMode) {
      debugPrint('[Analytics] 📱 Screen: $screenName');
    }
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  Future<void> logAppOpen() async {
    if (kDebugMode) {
      debugPrint('[Analytics] 🚀 App Open');
    }
    await _analytics.logAppOpen();
  }

  /// Starts tracking an activity session, logging the 'tool_start' event.
  Future<void> startToolSession({
    required String toolId,
    required String toolName,
    Map<String, Object>? additionalParams,
  }) async {
    _completedTools.remove(toolId);
    await logEvent(
      name: 'tool_start',
      parameters: {
        'tool_id': toolId,
        'tool_name': toolName,
        ...?additionalParams,
      },
    );
  }

  /// Marks an activity session as completed and logs the 'tool_complete' event.
  Future<void> completeToolSession({
    required String toolId,
    required String toolName,
    int? durationSeconds,
    Map<String, Object>? additionalParams,
  }) async {
    final alreadyCompleted = _completedTools.contains(toolId);
    _completedTools.add(toolId);
    if (!alreadyCompleted) {
      await logEvent(
        name: 'tool_complete',
        parameters: {
          'tool_id': toolId,
          'tool_name': toolName,
          'duration_seconds': ?durationSeconds,
          ...?additionalParams,
        },
      );
    }
  }

  /// Ends an activity session when the user leaves the tool. If the tool was not completed, logs 'tool_abandon' with duration spent.
  Future<void> endToolSession({
    required String toolId,
    required String toolName,
    required int durationSeconds,
    String? exitReason,
  }) async {
    final wasCompleted = _completedTools.remove(toolId);
    if (!wasCompleted) {
      await logEvent(
        name: 'tool_abandon',
        parameters: {
          'tool_id': toolId,
          'tool_name': toolName,
          'duration_seconds': durationSeconds,
          'exit_reason': ?exitReason,
        },
      );
    }
  }

  /// Logs progress steps within an activity (e.g., clues in Emotional Detective).
  Future<void> logToolStep({
    required String toolId,
    required String stepName,
    int? stepIndex,
  }) async {
    await logEvent(
      name: 'tool_step',
      parameters: {
        'tool_id': toolId,
        'step_name': stepName,
        'step_index': ?stepIndex,
      },
    );
  }
}
