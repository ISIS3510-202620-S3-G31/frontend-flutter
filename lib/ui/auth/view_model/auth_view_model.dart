import 'package:flutter/material.dart';

import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/photo_repository.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({AuthRepository? repository, PhotoRepository? photos})
      : _repository = repository ?? AuthRepository(),
        _photos = photos ?? PhotoRepository();

  final AuthRepository _repository;
  final PhotoRepository _photos;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOffline = false;
  bool _disposed = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  bool get isOffline => _isOffline;

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
    if (_errorMessage != null || _isOffline) {
      _errorMessage = null;
      _isOffline = false;
      _notify();
    }
  }

  /// Loads the signed-in user's profile. A valid cached copy is shown at once,
  /// with no spinner; [refresh] (pull-to-refresh) always reads Firestore.
  Future<void> loadProfile({bool refresh = false}) async {
    final cached = refresh ? null : _repository.cachedCurrentUserProfile;
    if (cached != null) {
      _currentUser = cached;
      _errorMessage = null;
      _notify();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _notify();

    try {
      _currentUser = await _repository.getCurrentUserProfile(refresh: refresh);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  /// Signs in with [email] and [password]. Returns true on success.
  Future<bool> signIn({required String email, required String password}) =>
      _attempt(() => _repository.signIn(email: email, password: password));

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required DateTime birthDate,
  }) => _attempt(
    () => _repository.signUp(
      email: email,
      password: password,
      name: name,
      birthDate: birthDate,
    ),
  );

  Future<bool> _attempt(Future<UserModel> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    _isOffline = false;
    _notify();

    try {
      _currentUser = await action();
      return true;
    } on AuthException catch (error) {
      _isOffline = error.isOffline;
      _errorMessage = error.isOffline ? null : error.message;
      return false;
    } catch (error) {
      debugPrint('[AuthViewModel] Unexpected error: $error');
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    _errorMessage = null;
    _notify();

    final userId = _repository.currentUserId;

    try {
      await _repository.signOut();
      _currentUser = null;
    } catch (e) {
      _errorMessage = e.toString();
      return;
    } finally {
      _isLoading = false;
      _notify();
    }

    if (userId != null) await _forgetCachedPhotos(userId);
  }

  /// Drops the photos this phone downloaded for the account that just left.
  ///
  /// They can all be fetched from Firebase again, so keeping them would only
  /// hold disk for someone who is no longer using this phone. It runs after
  /// the sign-out and swallows its own errors: the user is already out, and
  /// failing to delete a file is no reason to tell them otherwise.
  Future<void> _forgetCachedPhotos(String userId) async {
    try {
      await _photos.forgetCached(userId);
    } on Exception catch (error) {
      debugPrint('[Auth] Could not clear the cached photos: $error');
    }
  }
}
