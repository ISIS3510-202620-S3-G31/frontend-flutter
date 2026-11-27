import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/models/wish_model.dart';
import '../../../../data/repositories/wish_repository.dart';

/// The state of the wish editor screen, for a new wish or to change an
/// existing one ([editing] is the wish being changed, null for a new one).
class WishEditorViewModel extends ChangeNotifier {
  WishEditorViewModel({WishRepository? repository, Wish? editing})
    : _repository = repository ?? WishRepository(),
      _editing = editing {
    _text = editing?.text ?? '';
    _onlineChanges = _repository.onlineChanges.listen((online) {
      if (_disposed || online == !_offline) return;
      _offline = !online;
      notifyListeners();
    });
    loaded = _checkOnline();
  }

  final WishRepository _repository;

  /// The wish being edited, or null when writing a new one.
  final Wish? _editing;
  StreamSubscription<bool>? _onlineChanges;
  bool _disposed = false;

  /// Finishes when the first connectivity check is done, so tests can wait
  /// for [isOffline] to settle.
  late final Future<void> loaded;

  String _text = '';
  bool _saving = false;
  bool _offline = false;
  String? _errorMessage;

  String get text => _text;
  bool get isSaving => _saving;
  bool get isOffline => _offline;
  String? get errorMessage => _errorMessage;

  /// True while editing a wish that already exists.
  bool get isEditing => _editing != null;

  /// The save button only works with some text and while not saving already.
  bool get canSave => _text.trim().isNotEmpty && !_saving;

  /// The user typed; the text never passes the lantern's limit.
  void onTextChange(String newText) {
    final limited = Wish.limitText(newText);
    if (limited == _text) return;
    _text = limited;
    _errorMessage = null;
    notifyListeners();
  }

  /// Saves: creates a new wish or changes [editing]. True when it was saved
  /// and the screen can close; false when [errorMessage] explains why not.
  Future<bool> save() async {
    if (!canSave) return false;
    _saving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final editing = _editing;
      if (editing != null) {
        await _repository.update(editing, _text);
      } else {
        await _repository.save(_text);
      }
    } on Exception catch (error) {
      debugPrint('[Wishes] Could not save the wish: $error');
      if (_disposed) return false;
      _saving = false;
      _errorMessage = _editing == null
          ? "We couldn't save your wish. Please try again."
          : "We couldn't update your wish. Please try again.";
      notifyListeners();
      return false;
    }
    if (_disposed) return true;
    _saving = false;
    notifyListeners();
    return true;
  }

  Future<void> _checkOnline() async {
    _offline = !await _repository.isOnline();
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _onlineChanges?.cancel();
    super.dispose();
  }
}
