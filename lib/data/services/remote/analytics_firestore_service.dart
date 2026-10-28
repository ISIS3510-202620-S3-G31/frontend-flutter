import 'package:cloud_firestore/cloud_firestore.dart';

/// Writes analytics events to `users/{uid}/analytics_events`, one document per event
class AnalyticsFirestoreService {
  AnalyticsFirestoreService({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _events(String userId) =>
      _firestore.collection('users/$userId/analytics_events');

  /// Saves one event document and returns its id.
  Future<String> create(String userId, Map<String, Object?> event) async {
    final doc = await _events(userId).add(event);
    return doc.id;
  }
}
