import 'dart:async';

import '../models/check_in_model.dart';
import '../services/auth_service.dart';
import '../services/place_service.dart';
import '../services/remote/check_in_firestore_service.dart';

class CheckInRepository {
  CheckInRepository({
    CheckInFirestoreService? service,
    AuthService? auth,
    PlaceService? places,
  }) : _service = service ?? CheckInFirestoreService(),
       _auth = auth ?? AuthService(),
       _places = places ?? PlaceService();

  final CheckInFirestoreService _service;
  final AuthService _auth;
  final PlaceService _places;

  /// What the user answered today, or null when they have not answered yet.
  Future<CheckIn?> todaysCheckIn() async {
    final userId = _auth.currentUserId;
    if (userId == null) return null;
    return _service.forDay(userId, DateTime.now());
  }

  /// Throws [AuthException] when nobody is signed in, and a [FirebaseException]
  /// when the write fails.
  Future<void> save(CheckIn checkIn) async {
    final userId = _auth.currentUserId;
    if (userId == null) {
      throw const AuthException('Sign in to save your check-in.');
    }
    await _service.save(userId, checkIn);
    // BQ10: where the user was. Finding it takes the GPS and the network, so
    // it is added afterwards and the check-in never waits for it.
    unawaited(_addPlace(userId, checkIn.timestamp));
  }

  Future<void> _addPlace(String userId, DateTime day) async {
    final place = await _places.currentPlace();
    if (place != null) await _service.addPlace(userId, day, place);
  }

  /// Every check-in since [from]. Empty when nobody is signed in.
  Future<List<CheckIn>> since(DateTime from) async {
    final userId = _auth.currentUserId;
    if (userId == null) return [];
    return _service.since(userId, from);
  }
}
