import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';

export '../services/auth_service.dart' show AuthException;

/// Repository abstracting authentication and user profile access.
class AuthRepository {
  AuthRepository({AuthService? service, ConnectivityService? connectivity})
    : _customService = service,
      _connectivity = connectivity ?? ConnectivityService();

  final AuthService? _customService;
  AuthService get _service => _customService ?? AuthService();

  final ConnectivityService _connectivity;

  Stream<User?> get authStateChanges => _service.authStateChanges;

  User? get currentUser => _service.currentUser;

  String? get currentUserId => _service.currentUserId;

  /// Loads the profile document for the given [uid] from Firestore.
  Future<UserModel?> getUserProfile(String uid) => _service.getUserProfile(uid);

  /// Loads the profile of the current active user.
  Future<UserModel?> getCurrentUserProfile() =>
      _service.getCurrentUserProfile();

  /// Authenticates with email and password.
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    await _requireConnection();
    return _service.signIn(email: email, password: password);
  }

  /// Registers a new user and persists their metadata in Firestore.
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required DateTime birthDate,
  }) async {
    await _requireConnection();
    return _service.signUp(
      email: email,
      password: password,
      name: name,
      birthDate: birthDate,
    );
  }

  /// Signs out the user.
  Future<void> signOut() => _service.signOut();

  Future<void> _requireConnection() async {
    final bool online;
    try {
      online = await _connectivity.isOnline();
    } on Exception {
      // When the phone cannot tell, Firebase tries and reports it itself.
      return;
    }
    if (!online) {
      throw const AuthException(
        AuthService.offlineMessage,
        code: AuthException.offline,
      );
    }
  }
}
