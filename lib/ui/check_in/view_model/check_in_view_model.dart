import 'package:flutter/foundation.dart';

import '../../../data/models/check_in_model.dart';
import '../../../data/repositories/check_in_repository.dart';
import '../../../domain/mood/mood.dart';
import '../../../domain/mood/mood_template.dart';

class CheckInViewModel extends ChangeNotifier {
  CheckInViewModel({CheckInRepository? repository, DateTime Function()? now})
    : _repository = repository ?? CheckInRepository(),
      _now = now ?? DateTime.now;

  static const maxNoteLength = 500;

  final CheckInRepository _repository;
  final DateTime Function() _now;

  final Set<Emotion> _emotions = {};
  int _intensity = 3;
  String _note = '';
  bool _saving = false;
  bool _saved = false;
  String? _message;
  bool _disposed = false;

  Set<Emotion> get emotions => Set.unmodifiable(_emotions);

  /// The chosen emotions as one mood: a single emotion, or a mix like
  /// "Anxiety" when there are several. Null while nothing is chosen.
  Mood? get mood => MoodTemplate.fromEmotions(_emotions, level: _intensity);

  /// How strong the feeling is, from 1 to 5.
  int get intensity => _intensity;

  String get note => _note;
  bool get saving => _saving;

  /// True once the check-in is stored, so the sheet can close itself.
  bool get saved => _saved;

  /// Message to show once in a snack bar. The sheet calls [clearMessage].
  String? get message => _message;

  bool get canSave => _emotions.isNotEmpty && !_saving;

  void toggleEmotion(Emotion emotion) {
    if (!_emotions.remove(emotion)) _emotions.add(emotion);
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
    final mood = this.mood;
    if (mood == null || _saving) return;
    _saving = true;
    _notify();
    try {
      await _repository.save(
        CheckIn(
          emotions: [for (final leaf in mood.emotions) leaf.emotion],
          intensity: mood.intensity.round(),
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
