import '../models/check_in_model.dart';
import '../models/pending_write_model.dart';
import '../services/auth_service.dart';
import '../services/remote/check_in_firestore_service.dart';
import 'offline_sync_repository.dart';

class CheckInRepository {
  CheckInRepository({
    CheckInFirestoreService? service,
    AuthService? auth,
    OfflineSyncRepository? sync,
  }) : _service = service ?? CheckInFirestoreService(),
       _auth = auth ?? AuthService(),
       _sync = sync ?? OfflineSyncRepository.shared;

  final CheckInFirestoreService _service;
  final AuthService _auth;
  final OfflineSyncRepository _sync;


  Future<CheckIn?> todaysCheckIn() async {
    final userId = _auth.currentUserId;
    if (userId == null) return null;
    return _service.forDay(userId, DateTime.now());
  }

  Future<SaveOutcome> save(CheckIn checkIn) async {
    final userId = _auth.currentUserId;
    if (userId == null) {
      throw const AuthException('Sign in to save your check-in.');
    }
    return _sync.save(
      PendingWrite(
        path: _service.pathFor(userId, checkIn),
        userId: userId,
        data: checkIn.toMap(),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<List<CheckIn>> since(DateTime from) async {
    final userId = _auth.currentUserId;
    if (userId == null) return [];
    return _service.since(userId, from);
  }
}
