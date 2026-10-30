import 'package:flutter/foundation.dart';

import '../models/tool_session_record_model.dart';
import '../services/auth_service.dart';
import '../services/remote/tool_session_firestore_service.dart';

/// Saves the outcome of every toolbox session in Firestore so abandonment can be compared against the sessions that were started (business question #9)
class ToolSessionRepository {
  ToolSessionRepository({
    ToolSessionFirestoreService? service,
    AuthService? auth,
  }) : _service = service ?? ToolSessionFirestoreService(),
       _auth = auth ?? AuthService();

  final ToolSessionFirestoreService _service;
  final AuthService _auth;

  /// Creates the session document and returns its id, or null when nobody is signed in
  Future<String?> start({
    required String toolId,
    required String toolName,
    required DateTime startedAt,
  }) async {
    final userId = _auth.currentUserId;
    if (userId == null) return null;
    try {
      return await _service.create(
        userId,
        ToolSessionRecord(
          toolId: toolId,
          toolName: toolName,
          startedAt: startedAt,
        ),
      );
    } on Exception catch (error) {
      _warn('start', error);
      return null;
    }
  }

  /// Marks the session document as completed.
  Future<void> markCompleted({
    required String sessionId,
    required int durationSeconds,
  }) async {
    final userId = _auth.currentUserId;
    if (userId == null) return;
    try {
      await _service.update(userId, sessionId, {
        'completed': true,
        'completedAt': DateTime.now().toUtc().toIso8601String(),
        'durationSeconds': durationSeconds,
      });
    } on Exception catch (error) {
      _warn('markCompleted', error);
    }
  }

  /// Marks the session document as abandoned when the user left the tool.
  Future<void> markAbandoned({
    required String sessionId,
    required int durationSeconds,
    String? exitReason,
  }) async {
    final userId = _auth.currentUserId;
    if (userId == null) return;
    try {
      await _service.update(userId, sessionId, {
        'endedAt': DateTime.now().toUtc().toIso8601String(),
        'durationSeconds': durationSeconds,
        'exitReason': exitReason ?? 'unknown',
      });
    } on Exception catch (error) {
      _warn('markAbandoned', error);
    }
  }

  /// Records the last progress step the user reached, so abandonment can be traced back to the step where it happened.
  Future<void> markStep({
    required String sessionId,
    required String stepName,
  }) async {
    final userId = _auth.currentUserId;
    if (userId == null) return;
    try {
      await _service.update(userId, sessionId, {
        'lastStepName': stepName,
        'lastStepAt': DateTime.now().toUtc().toIso8601String(),
      });
    } on Exception catch (error) {
      _warn('markStep', error);
    }
  }

  /// The user's own sessions since [from], for computing abandonment rates.
  Future<List<ToolSessionRecord>> since(DateTime from) async {
    final userId = _auth.currentUserId;
    if (userId == null) return [];
    try {
      return await _service.since(userId, from);
    } on Exception catch (error) {
      _warn('since', error);
      return [];
    }
  }

  void _warn(String action, Object error) {
    debugPrint('[ToolSessionRepository] $action failed: $error');
  }
}
