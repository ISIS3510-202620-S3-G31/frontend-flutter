// Generated automatically by Firebase-Analytics
// Google Analytics 4 2026-10-01 14:15:27

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import '../repositories/tool_session_repository.dart';

/// One tool session in progress: when it started and where its Firestore
/// document lives, so completion and abandonment can be recorded there.
class _ActiveSession {
  _ActiveSession(this.startedAt);

  final DateTime startedAt;
  String? docId;
  bool completed = false;

  int get secondsSinceStart => DateTime.now().difference(startedAt).inSeconds;
}

/// Minimal service to manage Firebase Analytics throughout the app.
class AnalyticsService {
  factory AnalyticsService({
    FirebaseAnalytics? analytics,
    ToolSessionRepository? sessionRepository,
  }) {
    if (analytics != null || sessionRepository != null) {
      return AnalyticsService._internal(analytics, sessionRepository);
    }
    return _instance ??= AnalyticsService._internal(null, null);
  }

  AnalyticsService._internal(
    FirebaseAnalytics? analytics,
    ToolSessionRepository? sessionRepository,
  ) : _analytics = analytics ?? FirebaseAnalytics.instance,
      _sessions = sessionRepository ?? ToolSessionRepository();

  static AnalyticsService? _instance;
  final FirebaseAnalytics _analytics;
  final ToolSessionRepository _sessions;
  final Map<String, _ActiveSession> _activeSessions = {};

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

  /// Starts tracking an activity session, logging the 'tool_start' event and
  /// creating its Firestore document.
  Future<void> startToolSession({
    required String toolId,
    required String toolName,
    Map<String, Object>? additionalParams,
  }) async {
    final session = _ActiveSession(DateTime.now());
    _activeSessions[toolId] = session;
    await logEvent(
      name: 'tool_start',
      parameters: {
        'tool_id': toolId,
        'tool_name': toolName,
        ...?additionalParams,
      },
    );
    session.docId = await _sessions.start(
      toolId: toolId,
      toolName: toolName,
      startedAt: session.startedAt,
    );
  }

  /// Marks an activity session as completed and logs the 'tool_complete' event.
  Future<void> completeToolSession({
    required String toolId,
    required String toolName,
    int? durationSeconds,
    Map<String, Object>? additionalParams,
  }) async {
    final session = _activeSessions[toolId];
    final alreadyCompleted = session?.completed ?? false;
    final duration = durationSeconds ?? session?.secondsSinceStart;
    if (session != null) session.completed = true;
    if (!alreadyCompleted) {
      await logEvent(
        name: 'tool_complete',
        parameters: {
          'tool_id': toolId,
          'tool_name': toolName,
          'duration_seconds': ?duration,
          ...?additionalParams,
        },
      );
      final docId = session?.docId;
      if (docId != null && duration != null) {
        await _sessions.markCompleted(
          sessionId: docId,
          durationSeconds: duration,
        );
      }
    }
  }

  /// Ends an activity session when the user leaves the tool. If the tool was not completed, logs 'tool_abandon' with duration spent and exit reason.
  Future<void> endToolSession({
    required String toolId,
    required String toolName,
    int? durationSeconds,
    String? exitReason,
  }) async {
    final session = _activeSessions.remove(toolId);
    final wasCompleted = session?.completed ?? false;
    final duration = durationSeconds ?? session?.secondsSinceStart ?? 0;
    if (!wasCompleted) {
      await logEvent(
        name: 'tool_abandon',
        parameters: {
          'tool_id': toolId,
          'tool_name': toolName,
          'duration_seconds': duration,
          'exit_reason': ?exitReason,
        },
      );
      final docId = session?.docId;
      if (docId != null) {
        await _sessions.markAbandoned(
          sessionId: docId,
          durationSeconds: duration,
          exitReason: exitReason,
        );
      }
    }
  }

  /// Logs progress steps within an activity (e.g., clues in Emotional Detective) and records the last step on the Firestore session.
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
    final docId = _activeSessions[toolId]?.docId;
    if (docId != null) {
      await _sessions.markStep(sessionId: docId, stepName: stepName);
    }
  }
}
