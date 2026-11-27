import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/models/wish_model.dart';
import '../../../../data/repositories/wish_repository.dart';

/// The state of the wish list screen: every wish of the account, newest
/// first, plus the delete confirmation and the offline flag.
class WishListViewModel extends ChangeNotifier {
  WishListViewModel({WishRepository? repository})
    : _repository = repository ?? WishRepository();

  final WishRepository _repository;
  StreamSubscription<bool>? _onlineChanges;
  bool _disposed = false;

  List<Wish> _wishes = const [];
  bool _loading = true;
  bool _offline = false;
  String? _message;
  Wish? _wishToDelete;

  List<Wish> get wishes => _wishes;
  bool get isLoading => _loading;
  bool get isOffline => _offline;

  /// The wish the user asked to delete; while not null the screen shows the
  /// confirmation dialog.
  Wish? get wishToDelete => _wishToDelete;

  /// A snackbar message for the screen, taken once.
  String? takeMessage() {
    final message = _message;
    _message = null;
    return message;
  }

  /// Loads the wishes, newest first, and watches the connection for the
  /// offline banner.
  Future<void> load() async {
    _loading = true;
    _notify();
    _offline = !await _repository.isOnline();
    _wishes = await _repository.wishes();
    if (_disposed) return;
    _loading = false;
    _onlineChanges ??= _repository.onlineChanges.listen((online) {
      if (_disposed || online == !_offline) return;
      _offline = !online;
      _notify();
    });
    _notify();
  }

  /// Reloads after the editor changed a wish.
  Future<void> refresh() => load();

  /// The user tapped delete on [wish]: ask first.
  void askToDelete(Wish wish) {
    _wishToDelete = wish;
    _notify();
  }

  /// The user said no: close the confirmation.
  void cancelDelete() {
    _wishToDelete = null;
    _notify();
  }

  /// The user said yes: delete the wish, locally and in the cloud.
  Future<void> confirmDelete() async {
    final wish = _wishToDelete;
    if (wish == null) return;
    _wishToDelete = null;
    _notify();
    try {
      await _repository.delete(wish);
    } on Exception catch (error) {
      debugPrint('[Wishes] Could not delete the wish: $error');
      if (_disposed) return;
      _message = "We couldn't delete your wish. Please try again.";
      _notify();
      return;
    }
    if (_disposed) return;
    _wishes = [
      for (final w in _wishes)
        if (w.id != wish.id) w,
    ];
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _onlineChanges?.cancel();
    super.dispose();
  }
}
