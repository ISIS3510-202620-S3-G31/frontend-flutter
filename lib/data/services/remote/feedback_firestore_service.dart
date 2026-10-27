import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/tool_feedback_model.dart';

/// Keeps the tool feedback in `users/{uid}/tool_feedback`, the same place and
/// shape the backend rules allow for the owner.
class FeedbackFirestoreService {
  FeedbackFirestoreService({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _feedback(String userId) =>
      _firestore.collection('users/$userId/tool_feedback');

  Future<void> add(String userId, ToolFeedback feedback) =>
      _feedback(userId).add(feedback.toMap());

  Future<List<ToolFeedback>> since(String userId, DateTime from) async {
    final snapshot = await _feedback(userId)
        .where(
          'startedAt',
          isGreaterThanOrEqualTo: from.toUtc().toIso8601String(),
        )
        .get();
    return [for (final doc in snapshot.docs) ToolFeedback.fromMap(doc.data())];
  }
}
