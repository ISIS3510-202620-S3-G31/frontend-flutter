import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Keeps every recommendation the home screen showed in `users/{uid}/recommendations`, so the BQ3 dashboard can count them.
class RecommendationFirestoreService {
  RecommendationFirestoreService({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _recommendations(String userId) =>
      _firestore.collection('users/$userId/recommendations');

  /// Returns the id of the new document right away. The write is not awaited: without a connection Firestore keeps it and sends it later.
  String add(String userId, Map<String, Object?> data) {
    final doc = _recommendations(userId).doc();
    doc.set(data).catchError(_report);
    return doc.id;
  }

  void update(String userId, String id, Map<String, Object?> data) {
    _recommendations(userId).doc(id).update(data).catchError(_report);
  }

  static void _report(Object error) =>
      debugPrint('[BQ3] Could not save the recommendation: $error');
}
