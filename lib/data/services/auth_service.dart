import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../domain/auth/registration_rules.dart';
import '../models/user_model.dart';

/// Exception thrown by [AuthService] with a user-friendly error message.
class AuthException implements Exception {
  const AuthException(this.message, {this.code});

  static const offline = 'offline';

  final String message;
  final String? code;

  bool get isOffline => code == offline || code == 'network-request-failed';

  @override
  String toString() => message;
}

/// Service handling Firebase Authentication and Firestore user synchronization.
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _customAuth = auth,
      _customFirestore = firestore;

  static const offlineMessage =
      'No internet connection. Connect to Wi-Fi or mobile data and try again.';
  static const _signInFailed = 'Could not sign in. Please try again.';
  static const _signUpFailed =
      'Could not create your account. Please try again.';

  /// How long a profile read or write may take before the app moves on.
  static const _timeLimit = Duration(seconds: 10);

  final FirebaseAuth? _customAuth;
  final FirebaseFirestore? _customFirestore;

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  String? get currentUserId => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _profileOf(String uid) =>
      _firestore.collection('users').doc(uid);

  /// Fetches a user's profile from Firestore `users/{uid}`.
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 10));
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return UserModel.fromMap(doc.data()!, id: doc.id);
    } catch (e) {
      debugPrint('[AuthService] getUserProfile error: $e');
      throw AuthException('Failed to fetch user profile: ${e.toString()}');
    }
  }

  /// The profile of the signed-in user, without ever failing: the Firestore
  /// document when it can be read (from the server or the phone's copy),
  /// otherwise what the session saved on the phone knows. Null only when
  /// nobody is signed in.
  Future<UserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final snapshot = await _profileOf(user.uid).get().timeout(_timeLimit);
      final data = snapshot.data();
      if (data != null) return UserModel.fromMap(data, id: user.uid);
    } on Exception catch (error) {
      debugPrint('[AuthService] Could not load users/${user.uid}: $error');
    }
    return _sessionProfile(user);
  }

  /// Registers a new user with Firebase Auth and saves their profile in Firestore.
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required DateTime birthDate,
  }) async {
    final UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      debugPrint('[AuthService] signUp [${error.code}]: ${error.message}');
      throw AuthException(_mapFirebaseError(error), code: error.code);
    }
    final user = credential.user;
    if (user == null) throw const AuthException(_signUpFailed);

    final profile = UserModel(
      uid: user.uid,
      email: email.trim(),
      name: name.trim(),
      birthDate: birthDate,
    );
    try {
      await user.updateDisplayName(profile.name);
    } on Exception catch (error) {
      debugPrint('[AuthService] Could not save the display name: $error');
    }
    try {
      await _profileOf(user.uid).set(profile.toMap()).timeout(_timeLimit);
    } on TimeoutException {
      debugPrint('[AuthService] users/${user.uid} will be saved when online.');
    } on FirebaseException catch (error) {
      debugPrint('[AuthService] Could not save users/${user.uid}: $error');
      await _deleteQuietly(user);
      throw const AuthException(_signUpFailed);
    }
    return profile;
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final UserCredential credential;
    try {
      credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      debugPrint('[AuthService] signIn [${error.code}]: ${error.message}');
      throw AuthException(_mapFirebaseError(error), code: error.code);
    }
    final user = credential.user;
    if (user == null) throw const AuthException(_signInFailed);

    try {
      return await _ensureProfile(user);
    } on Exception catch (error) {
      debugPrint('[AuthService] Could not check users/${user.uid}: $error');
      return _sessionProfile(user);
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthException('Failed to sign out: ${e.toString()}');
    }
  }

  Future<UserModel> _ensureProfile(User user) async {
    final document = _profileOf(user.uid);
    final snapshot = await document.get().timeout(_timeLimit);
    final data = snapshot.data();
    if (data != null) return UserModel.fromMap(data, id: user.uid);

    final email = user.email ?? '';
    final displayName = user.displayName?.trim() ?? '';
    final profile = UserModel(
      uid: user.uid,
      email: email,

      name: displayName.isNotEmpty ? displayName : email.split('@').first,
    );

    if (!snapshot.metadata.isFromCache) {
      await document.set(profile.toMap()).timeout(_timeLimit);
    }
    return profile;
  }

  UserModel _sessionProfile(User user) => UserModel(
    uid: user.uid,
    email: user.email ?? '',
    name: user.displayName?.trim() ?? '',
  );

  Future<void> _deleteQuietly(User user) async {
    try {
      await user.delete();
    } on Exception catch (error) {
      debugPrint('[AuthService] Could not remove the account: $error');
    }
  }


  String _mapFirebaseError(FirebaseAuthException error) => switch (error.code) {

    'invalid-credential' ||
    'user-not-found' ||
    'wrong-password' => 'Incorrect email or password.',
    'invalid-email' => 'Enter a valid email address.',
    'email-already-in-use' =>
      'This email is already registered. Try signing in instead.',
    'weak-password' =>
      'Use at least ${RegistrationRules.minPasswordLength} characters, '
          'one uppercase letter and one number.',
    'user-disabled' => 'This account has been disabled.',
    'too-many-requests' => 'Too many attempts. Wait a moment and try again.',
    'network-request-failed' => offlineMessage,
    _ => 'Something went wrong. Please try again.',
  };
}
