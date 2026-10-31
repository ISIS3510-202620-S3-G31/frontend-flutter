import 'dart:async';

import '../models/check_in_model.dart';
import '../models/pending_write_model.dart';
import '../services/auth_service.dart';
import '../services/place_service.dart';
import '../services/remote/check_in_firestore_service.dart';
import 'offline_sync_repository.dart';

class CheckInRepository {
  CheckInRepository({
    CheckInFirestoreService? service,
    AuthService? auth,
    PlaceService? places,
    OfflineSyncRepository? sync,
  }) : _service = service ?? CheckInFirestoreService(),
       _auth = auth ?? AuthService(),
       _places = places ?? PlaceService(),
       _sync = sync ?? OfflineSyncRepository.shared;

  final CheckInFirestoreService _service;
  final AuthService _auth;
  final PlaceService _places;
  final OfflineSyncRepository _sync;

  Future<CheckIn?> todaysCheckIn() async {
    final userId = _auth.currentUserId;
    if (userId == null) return null;
    return _service.forDay(userId, DateTime.now());
  }

  /// Saves the check-in and tells whether it went out or stayed on the phone
  /// ([SaveOutcome.savedOffline]): without a connection it also goes to the
  /// offline queue, which sends it when the connection comes back. Throws
  /// [AuthException] when nobody is signed in.
  Future<SaveOutcome> save(CheckIn checkIn) async {
    final userId = _auth.currentUserId;
    if (userId == null) {
      throw const AuthException('Sign in to save your check-in.');
    }
    await _service.save(userId, checkIn);
    // BQ10: where the user was. Finding it takes the GPS and the network, so
    // it is added afterwards and the check-in never waits for it.
    unawaited(_addPlace(userId, checkIn.timestamp));
    return _sync.track(
      PendingWrite(
        path: _service.pathFor(userId, checkIn),
        userId: userId,
        data: checkIn.toMap(),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> _addPlace(String userId, DateTime day) async {
    final place = await _places.currentPlace();
    if (place != null) await _service.addPlace(userId, day, place);
  }

  Future<List<CheckIn>> since(DateTime from) async {
    final userId = _auth.currentUserId;
    if (userId == null) return [];
    return _service.since(userId, from);
  }
}
