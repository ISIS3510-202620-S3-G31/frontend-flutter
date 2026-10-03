import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Repository abstracting authentication and user profile access.
class AuthRepository {
  AuthRepository({AuthService? service}) : _customService = service;

  final AuthService? _customService;
  AuthService get _service => _customService ?? AuthService();

  Stream<User?> get authStateChanges => _service.authStateChanges;

  User? get currentUser => _service.currentUser;

  String? get currentUserId => _service.currentUserId;

  /// Loads the profile document for the given [uid] from Firestore.
  Future<UserModel?> getUserProfile(String uid) => _service.getUserProfile(uid);

  /// Loads the profile of the current active user.
  Future<UserModel?> getCurrentUserProfile() =>
      _service.getCurrentUserProfile();

  /// Authenticates with email and password.
  Future<UserModel> signIn({required String email, required String password}) =>
      _service.signIn(email: email, password: password);

  /// Registers a new user and persists their metadata in Firestore.
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required int age,
  }) => _service.signUp(email: email, password: password, name: name, age: age);

  /// Signs out the user.
  Future<void> signOut() => _service.signOut();
}
