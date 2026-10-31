import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Writes analytics events to `users/{uid}/analytics_events`, one document per event
class AnalyticsFirestoreService {
  AnalyticsFirestoreService({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _events(String userId) =>
      _firestore.collection('users/$userId/analytics_events');

  /// Saves one event document and returns its id right away.
  ///
  /// The write is not awaited: a Firestore write only completes once the
  /// server confirms it, so every screen that logged an event waited a round
  /// trip, and forever without a connection. Firestore keeps the event on the
  /// phone and sends it when it can.
  Future<String> create(String userId, Map<String, Object?> event) async {
    final doc = _events(userId).doc();
    unawaited(doc.set(event).catchError(_report));
    return doc.id;
  }

  static void _report(Object error) =>
      debugPrint('[Analytics] Could not save the event: $error');
}
