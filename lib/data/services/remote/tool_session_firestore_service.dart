import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/tool_session_record_model.dart';

/// Keeps the tool sessions in `users/{uid}/tool_sessions`, one document per time the user opened a tool, the same place and shape the backend rules allow for the owner.
class ToolSessionFirestoreService {
  ToolSessionFirestoreService({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _sessions(String userId) =>
      _firestore.collection('users/$userId/tool_sessions');

  /// Creates the session document when the tool is opened and returns its id.
  Future<String> create(String userId, ToolSessionRecord record) async {
    final doc = await _sessions(userId).add(record.toMap());
    return doc.id;
  }

  /// Patches the session document as the user progresses or leaves the tool.
  Future<void> update(
    String userId,
    String sessionId,
    Map<String, Object?> fields,
  ) => _sessions(userId).doc(sessionId).update(fields);

  /// The user's own sessions since [from].
  Future<List<ToolSessionRecord>> since(String userId, DateTime from) async {
    final snapshot = await _sessions(userId)
        .where(
          'startedAt',
          isGreaterThanOrEqualTo: from.toUtc().toIso8601String(),
        )
        .get();
    return [
      for (final doc in snapshot.docs) ToolSessionRecord.fromMap(doc.data()),
    ];
  }
}
