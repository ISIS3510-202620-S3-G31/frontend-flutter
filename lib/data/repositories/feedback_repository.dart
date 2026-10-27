import 'dart:async';

import '../models/tool_feedback_model.dart';
import '../services/auth_service.dart';
import '../services/remote/feedback_firestore_service.dart';
import '../services/remote/sheets_live_service.dart';

class FeedbackRepository {
  FeedbackRepository({
    FeedbackFirestoreService? service,
    AuthService? auth,
    SheetsLiveService? sheets,
  }) : _service = service ?? FeedbackFirestoreService(),
       _auth = auth ?? AuthService(),
       _sheets = sheets ?? SheetsLiveService();

  final FeedbackFirestoreService _service;
  final AuthService _auth;
  final SheetsLiveService _sheets;

  /// Throws [AuthException] when nobody is signed in, and a [FirebaseException]
  /// when the write fails.
  Future<void> save(ToolFeedback feedback) async {
    final userId = _auth.currentUserId;
    if (userId == null) {
      throw const AuthException('Sign in to save your feedback.');
    }
    await _service.add(userId, feedback);
    unawaited(_sheets.pushFeedback(userId, feedback));
  }

  /// Everything the user answered since [from]. Empty when nobody is signed in.
  Future<List<ToolFeedback>> since(DateTime from) async {
    final userId = _auth.currentUserId;
    if (userId == null) return [];
    return _service.since(userId, from);
  }
}
