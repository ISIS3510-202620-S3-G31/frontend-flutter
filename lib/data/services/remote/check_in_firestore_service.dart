import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../models/check_in_model.dart';
import '../../models/place_model.dart';


class CheckInFirestoreService {
  CheckInFirestoreService({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  static final _dayFormat = DateFormat('yyyy-MM-dd');

  final FirebaseFirestore? _customFirestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _checkIns(String userId) =>
      _firestore.collection('users/$userId/check_ins');

  Future<CheckIn?> forDay(String userId, DateTime day) async {
    final doc = await _checkIns(userId).doc(_dayFormat.format(day)).get();
    final data = doc.data();
    return data == null ? null : CheckIn.fromMap(data);
  }


  /// The document of the day of [checkIn], the same one [save] writes. Built
  /// as text, so it needs no Firestore (offline queue, tests).
  String pathFor(String userId, CheckIn checkIn) =>
      'users/$userId/check_ins/${_dayFormat.format(checkIn.timestamp)}';

  /// Saving the same day again replaces it, so the user can correct it.
  ///
  /// Not awaited: a Firestore write only completes once the server confirms
  /// it, so without a connection the check-in sheet spun forever. Firestore
  /// keeps the check-in on the phone and sends it when it can.
  Future<void> save(String userId, CheckIn checkIn) async {
    unawaited(
      _checkIns(userId)
          .doc(_dayFormat.format(checkIn.timestamp))
          .set(checkIn.toMap())
          .catchError(_report),
    );
  }

  /// Adds where the check-in of [day] was made, once that is known. Merged
  /// into the document so it never replaces the answers themselves.
  Future<void> addPlace(String userId, DateTime day, Place place) async {
    unawaited(
      _checkIns(userId)
          .doc(_dayFormat.format(day))
          .set(place.toMap(), SetOptions(merge: true))
          .catchError(_report),
    );
  }

  static void _report(Object error) =>
      debugPrint('[CheckIns] Could not save the check-in: $error');

  Future<List<CheckIn>> since(String userId, DateTime from) async {
    final snapshot = await _checkIns(userId)
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: from.toUtc().toIso8601String(),
        )
        .get();
    return [for (final doc in snapshot.docs) CheckIn.fromMap(doc.data())];
  }
}
