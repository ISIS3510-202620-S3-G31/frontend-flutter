import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';

/// Exception thrown by [AuthService] with a user-friendly error message.
class AuthException implements Exception {
  const AuthException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

/// Service handling Firebase Authentication and Firestore user synchronization.
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _customAuth = auth,
      _customFirestore = firestore;

  final FirebaseAuth? _customAuth;
  final FirebaseFirestore? _customFirestore;

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  String? get currentUserId => _auth.currentUser?.uid;

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

  /// Fetches the profile of the currently logged-in user.
  Future<UserModel?> getCurrentUserProfile() async {
    final uid = currentUserId;
    if (uid == null) return null;
    return getUserProfile(uid);
  }

  /// Registers a new user with Firebase Auth and saves their profile in Firestore.
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required int age,
  }) async {
    UserCredential? credential;
    try {
      debugPrint('[AuthService] Creating user account for: ${email.trim()}');
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthException('Registration failed: no user returned.');
      }

      debugPrint(
        '[AuthService] Auth account created (${user.uid}). Updating display name...',
      );
      try {
        await user.updateDisplayName(name.trim());
      } catch (e) {
        debugPrint('[AuthService] Non-fatal error updating displayName: $e');
      }

      final userModel = UserModel(
        uid: user.uid,
        email: email.trim(),
        name: name.trim(),
        age: age,
      );

      debugPrint(
        '[AuthService] Saving user profile to Firestore users/${user.uid}...',
      );
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toMap())
          .timeout(
            const Duration(seconds: 12),
            onTimeout: () => throw const AuthException(
              'Firestore timed out while saving profile. Please check your internet connection and Firestore rules in Firebase Console.',
              code: 'timeout',
            ),
          );

      debugPrint(
        '[AuthService] User profile created and saved to Firestore successfully.',
      );
      return userModel;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '[AuthService] FirebaseAuthException [${e.code}]: ${e.message}',
      );
      throw AuthException(_mapFirebaseError(e), code: e.code);
    } on FirebaseException catch (e) {
      debugPrint(
        '[AuthService] FirebaseException (${e.plugin}) [${e.code}]: ${e.message}',
      );
      // Clean up orphaned Auth user if Firestore persistence failed
      if (credential?.user != null) {
        try {
          await credential!.user!.delete();
          debugPrint('[AuthService] Rolled back orphaned auth user.');
        } catch (_) {}
      }
      if (e.plugin == 'cloud_firestore' && e.code == 'permission-denied') {
        throw const AuthException(
          'Firestore permission denied. Please verify your Firestore security rules in Firebase Console.',
          code: 'permission-denied',
        );
      }
      throw AuthException(
        'Database error (${e.plugin}/${e.code}): ${e.message ?? e.toString()}',
        code: e.code,
      );
    } catch (e, stack) {
      debugPrint('[AuthService] Unexpected error: $e\n$stack');
      if (credential?.user != null) {
        try {
          await credential!.user!.delete();
        } catch (_) {}
      }
      if (e is AuthException) rethrow;
      throw AuthException('Registration failed: ${e.toString()}');
    }
  }

  /// Signs in an existing user with Firebase Auth and loads their Firestore profile.
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('[AuthService] Signing in user: ${email.trim()}');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthException('Sign in failed: no user returned.');
      }

      // Fetch profile from Firestore
      var profile = await getUserProfile(user.uid);

      // If document is missing in Firestore, build an in-memory profile
      if (profile == null) {
        debugPrint(
          '[AuthService] User profile document not found in Firestore. Using in-memory fallback.',
        );
        profile = UserModel(
          uid: user.uid,
          email: user.email ?? email.trim(),
          name: user.displayName ?? '',
          age: null,
        );
      }

      return profile;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '[AuthService] signIn FirebaseAuthException [${e.code}]: ${e.message}',
      );
      throw AuthException(_mapFirebaseError(e), code: e.code);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        'An unexpected error occurred during sign in: ${e.toString()}',
      );
    }
  }

  /// Signs out the currently authenticated user.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthException('Failed to sign out: ${e.toString()}');
    }
  }

  /// Maps Firebase authentication error codes to human-readable messages.
  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please verify your credentials.';
      case 'email-already-in-use':
        return 'An account already exists with this email address. Try signing in instead.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is disabled in Firebase Console. Please enable it under Authentication > Sign-in method.';
      default:
        return e.message ?? 'Authentication failed (${e.code}).';
    }
  }
}
