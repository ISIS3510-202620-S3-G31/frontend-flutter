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


  String newPath(String userId) => _feedback(userId).doc().path;


  Future<void> add(String userId, ToolFeedback feedback) async {
    unawaited(
      _feedback(userId).doc().set(feedback.toMap()).catchError(_report),
    );
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
