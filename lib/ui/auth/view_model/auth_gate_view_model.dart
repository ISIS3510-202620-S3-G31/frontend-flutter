import 'package:firebase_auth/firebase_auth.dart';

import '../../../data/repositories/analytics_repository.dart';

/// Follows the signed-in user for the auth gate: the auth state itself and the
/// analytics user id that has to follow it.
class AuthGateViewModel {
  AuthGateViewModel({FirebaseAuth? auth, AnalyticsRepository? analytics})
    : _auth = auth ?? FirebaseAuth.instance,
      _analytics = analytics ?? AnalyticsRepository();

  final FirebaseAuth _auth;
  final AnalyticsRepository _analytics;

  /// Whether the user is signed in, and as whom.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Keeps analytics tied to the signed-in user, or cleared on sign-out.
  void syncAnalyticsUser(String? uid) {
    _analytics.setUserId(uid);
  }
}
