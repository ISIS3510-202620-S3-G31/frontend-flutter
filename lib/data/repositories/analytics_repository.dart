import '../models/tool_model.dart';
import '../services/analytics_service.dart';
import 'tool_session_repository.dart';

/// One tool session in progress: when it started and where its Firestore document lives, so completion and abandonment can be recorded there.
class _ActiveSession {
  _ActiveSession(this.startedAt);

  final DateTime startedAt;
  String? docId;
  bool completed = false;

  int get secondsSinceStart => DateTime.now().difference(startedAt).inSeconds;
}

/// The app's analytics: toolbox sessions as events in Firestore plus their outcome in the session documents, so abandonment can be measured (business question #9).
class AnalyticsRepository {
  factory AnalyticsRepository({
    AnalyticsService? analytics,
    ToolSessionRepository? sessionRepository,
  }) {
    if (analytics != null || sessionRepository != null) {
      return AnalyticsRepository._internal(analytics, sessionRepository);
    }
    return _instance ??= AnalyticsRepository._internal(null, null);
  }

  AnalyticsRepository._internal(
    AnalyticsService? analytics,
    ToolSessionRepository? sessionRepository,
  ) : _analytics = analytics ?? AnalyticsService(),
      _sessions = sessionRepository ?? ToolSessionRepository();

  static AnalyticsRepository? _instance;
  final AnalyticsService _analytics;
  final ToolSessionRepository _sessions;
  final Map<String, _ActiveSession> _activeSessions = {};

  /// Sets the user id for analytics tracking, so events and Firestore session documents belong to the signed-in user.
  Future<void> setUserId(String? userId) => _analytics.setUserId(userId);

  /// Logs a screen view for screens the navigator observer cannot see, like the tabs of the bottom bar.
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) => _analytics.logScreenView(
    screenName: screenName,
    screenClass: screenClass,
  );

  /// Starts tracking an activity session, logging the 'tool_start' event and creating its Firestore document.
  Future<void> startToolSession({
    required String toolId,
    required String toolName,
    ToolEntryPoint? entryPoint,
    Map<String, Object>? additionalParams,
  }) async {
    final session = _ActiveSession(DateTime.now());
    _activeSessions[toolId] = session;
    await _analytics.logEvent(
      name: 'tool_start',
      parameters: {
        'tool_id': toolId,
        'tool_name': toolName,
        'entry_point': ?entryPoint?.name,
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
      await _analytics.logEvent(
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
      await _analytics.logEvent(
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
    await _analytics.logEvent(
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
