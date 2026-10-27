import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../models/check_in_model.dart';

/// Keeps the daily check-ins in `users/{uid}/check_ins`, one document per day
/// named `yyyy-MM-dd`, so a day can never end up with two of them.
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

  /// Saving the same day again replaces it, so the user can correct it.
  Future<void> save(String userId, CheckIn checkIn) => _checkIns(
    userId,
  ).doc(_dayFormat.format(checkIn.timestamp)).set(checkIn.toMap());

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
