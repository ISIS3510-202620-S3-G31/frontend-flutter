import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/tool_feedback_model.dart';

class FeedbackFirestoreService {
  FeedbackFirestoreService({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _feedback(String userId) =>
      _firestore.collection('users/$userId/tool_feedback');


  /// Saves one answer in a new document and returns its path right away. The
  /// id is made on the phone, so the offline queue can send the same document
  /// again without duplicating it.
  ///
  /// Not awaited: a Firestore write only completes once the server confirms
  /// it. Firestore keeps the answer on the phone and sends it when it can.
  Future<String> add(String userId, ToolFeedback feedback) async {
    final doc = _feedback(userId).doc();
    unawaited(doc.set(feedback.toMap()).catchError(_report));
    return doc.path;
  }

  static void _report(Object error) =>
      debugPrint('[Feedback] Could not save the feedback: $error');

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
