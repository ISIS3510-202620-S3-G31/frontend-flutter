import 'package:flutter/material.dart';

import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

/// ViewModel managing user authentication and profile state.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({AuthRepository? repository})
      : _repository = repository ?? AuthRepository();

  final AuthRepository _repository;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Clears any existing error message.
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      _notify();
    }
  }

  /// Refreshes the currently active user profile from Firestore.
  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    _notify();

    try {
      _currentUser = await _repository.getCurrentUserProfile();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  /// Signs in with [email] and [password]. Returns true on success.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _notify();

    try {
      _currentUser = await _repository.signIn(
        email: email,
        password: password,
      );
      _isLoading = false;
      _notify();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      _notify();
      return false;
    }
  }

  /// Registers a new account, persists name and age in Firestore, and authenticates.
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required int age,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _notify();

    try {
      _currentUser = await _repository.signUp(
        email: email,
        password: password,
        name: name,
        age: age,
      );
      _isLoading = false;
      _notify();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      _notify();
      return false;
    }
  }

  /// Signs out the current user and clears in-memory user data.
  Future<void> signOut() async {
    _isLoading = true;
    _errorMessage = null;
    _notify();

    try {
      await _repository.signOut();
      _currentUser = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _notify();
    }
  }
}
