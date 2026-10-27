import '../models/check_in_model.dart';
import '../services/auth_service.dart';
import '../services/remote/check_in_firestore_service.dart';

class CheckInRepository {
  CheckInRepository({CheckInFirestoreService? service, AuthService? auth})
    : _service = service ?? CheckInFirestoreService(),
      _auth = auth ?? AuthService();

  final CheckInFirestoreService _service;
  final AuthService _auth;

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
  }

  /// Every check-in since [from]. Empty when nobody is signed in.
  Future<List<CheckIn>> since(DateTime from) async {
    final userId = _auth.currentUserId;
    if (userId == null) return [];
    return _service.since(userId, from);
  }
}
