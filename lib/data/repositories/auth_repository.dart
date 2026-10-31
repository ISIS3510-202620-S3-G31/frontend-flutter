import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/local/user_profile_cache.dart';

export '../services/auth_service.dart' show AuthException;

/// Repository abstracting authentication and user profile access.
class AuthRepository {
  AuthRepository({
    AuthService? service,
    ConnectivityService? connectivity,
    UserProfileCache? profileCache,
  }) : _customService = service,
       _connectivity = connectivity ?? ConnectivityService(),
       _profileCache = profileCache ?? UserProfileCache.shared;

  final AuthService? _customService;
  AuthService get _service => _customService ?? AuthService();

  final ConnectivityService _connectivity;
  final UserProfileCache _profileCache;

  Stream<User?> get authStateChanges => _service.authStateChanges;

  User? get currentUser => _service.currentUser;

  String? get currentUserId => _service.currentUserId;

  /// Loads the profile document for the given [uid] from Firestore.
  Future<UserModel?> getUserProfile(String uid) => _service.getUserProfile(uid);

  UserModel? get cachedCurrentUserProfile {
    final uid = currentUserId;
    return uid == null ? null : _profileCache.get(uid);
  }

  Future<UserModel?> getCurrentUserProfile({bool refresh = false}) async {
    final uid = currentUserId;
    if (uid == null) return null;
    if (!refresh) {
      final cached = _profileCache.get(uid);
      if (cached != null) return cached;
    }
    try {
      final profile = await _service.getUserProfile(uid);
      if (profile != null) {
        _profileCache.put(profile);
        return profile;
      }
    } on AuthException {
      // Offline or slow. A refresh that fails keeps the copy it already had,
      // which knows more than the session alone (the birth date, for one).
    }
    return _profileCache.get(uid) ?? _service.currentSessionProfile();
  }

  /// Forgets the cached profile. For any write that changes `users/{uid}`.
  void invalidateProfile() => _profileCache.clear();


  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    await _requireConnection();
    _profileCache.clear();
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
    _profileCache.clear();
    return _service.signUp(
      email: email,
      password: password,
      name: name,
      birthDate: birthDate,
    );
  }

  /// Signs out the user. The cached profile goes too, so the next account
  /// never sees it.
  Future<void> signOut() async {
    try {
      await _service.signOut();
    } finally {
      _profileCache.clear();
    }
  }

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
