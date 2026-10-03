import 'package:flutter/foundation.dart';

import '../../../data/models/check_in_model.dart';
import '../../../data/repositories/check_in_repository.dart';

class CheckInViewModel extends ChangeNotifier {
  CheckInViewModel({CheckInRepository? repository, DateTime Function()? now})
    : _repository = repository ?? CheckInRepository(),
      _now = now ?? DateTime.now;

  static const maxNoteLength = 500;

  final CheckInRepository _repository;
  final DateTime Function() _now;

  Emotion? _emotion;
  int _intensity = 3;
  String _note = '';
  bool _saving = false;
  bool _saved = false;
  String? _message;
  bool _disposed = false;

  Emotion? get emotion => _emotion;

  /// How strong the feeling is, from 1 to 5.
  int get intensity => _intensity;

  String get note => _note;
  bool get saving => _saving;

  /// True once the check-in is stored, so the sheet can close itself.
  bool get saved => _saved;

  /// Message to show once in a snack bar. The sheet calls [clearMessage].
  String? get message => _message;

  bool get canSave => _emotion != null && !_saving;

  void selectEmotion(Emotion emotion) {
    _emotion = emotion;
    notifyListeners();
  }

  void setIntensity(int value) {
    _intensity = value.clamp(1, 5);
    notifyListeners();
  }

  void setNote(String value) {
    _note = value;
    notifyListeners();
  }

  Future<void> save() async {
    final emotion = _emotion;
    if (emotion == null || _saving) return;
    _saving = true;
    _notify();
    try {
      await _repository.save(
        CheckIn(
          emotions: [emotion],
          intensity: _intensity,
          timestamp: _now(),
          note: _note.trim(),
        ),
      );
      _saved = true;
      _message = 'Check-in saved. See you tomorrow.';
    } on Exception {
      _message = 'Could not save your check-in. Check your connection.';
    } finally {
      _saving = false;
      _notify();
    }
  }

  void clearMessage() => _message = null;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
