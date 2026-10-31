import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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

  /// Creates the session document when the tool is opened and returns its id
  /// right away.
  ///
  /// The id is made on the phone and the write is not awaited. A Firestore
  /// write only completes once the server confirms it, so awaiting it kept the
  /// tool from opening for a full round trip, and forever without a
  /// connection. Firestore keeps the write on the phone and sends it later.
  Future<String> create(String userId, ToolSessionRecord record) async {
    final doc = _sessions(userId).doc();
    unawaited(doc.set(record.toMap()).catchError(_report));
    return doc.id;
  }

  /// Patches the session document as the user progresses or leaves the tool.
  /// Not awaited either, for the same reason as [create].
  Future<void> update(
    String userId,
    String sessionId,
    Map<String, Object?> fields,
  ) async {
    unawaited(
      _sessions(userId).doc(sessionId).update(fields).catchError(_report),
    );
  }

  static void _report(Object error) =>
      debugPrint('[ToolSessions] Could not save the session: $error');

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
