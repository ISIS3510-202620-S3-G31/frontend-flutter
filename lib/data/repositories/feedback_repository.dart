import '../models/pending_write_model.dart';
import '../models/tool_feedback_model.dart';
import '../services/auth_service.dart';
import '../services/remote/feedback_firestore_service.dart';
import 'offline_sync_repository.dart';

class FeedbackRepository {
  FeedbackRepository({
    FeedbackFirestoreService? service,
    AuthService? auth,
    OfflineSyncRepository? sync,
  }) : _service = service ?? FeedbackFirestoreService(),
       _auth = auth ?? AuthService(),
       _sync = sync ?? OfflineSyncRepository.shared;

  final FeedbackFirestoreService _service;
  final AuthService _auth;
  final OfflineSyncRepository _sync;

  /// Saves the answer and tells whether it went out or stayed on the phone
  /// ([SaveOutcome.savedOffline]). Throws [AuthException] when nobody is
  /// signed in.
  Future<SaveOutcome> save(ToolFeedback feedback) async {
    final userId = _auth.currentUserId;
    if (userId == null) {
      throw const AuthException('Sign in to save your feedback.');
    }
    final path = await _service.add(userId, feedback);
    return _sync.track(
      PendingWrite(
        path: path,
        userId: userId,
        data: feedback.toMap(),
        createdAt: DateTime.now(),
      ),
    );
  }


  Future<List<ToolFeedback>> since(DateTime from) async {
    final userId = _auth.currentUserId;
    if (userId == null) return [];
    return _service.since(userId, from);
  }
}
