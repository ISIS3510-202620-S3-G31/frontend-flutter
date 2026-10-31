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

  Future<SaveOutcome> save(ToolFeedback feedback) async {
    final userId = _auth.currentUserId;
    if (userId == null) {
      throw const AuthException('Sign in to save your feedback.');
    }
    return _sync.save(
      PendingWrite(
        path: _service.newPath(userId),
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
