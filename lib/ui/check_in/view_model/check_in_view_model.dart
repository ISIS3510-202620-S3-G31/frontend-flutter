import 'package:flutter/foundation.dart';

import '../../../data/models/check_in_model.dart';
import '../../../data/models/pending_write_model.dart';
import '../../../data/repositories/check_in_repository.dart';
import '../../../data/services/microphone_service.dart';
import '../../../data/services/network/network_connectivity_service.dart';
import '../../../data/services/speech_recognition_service.dart';
import '../../../data/services/text_to_speech_service.dart';
import '../../../domain/mood/mood.dart';
import '../../../domain/mood/mood_template.dart';

class CheckInViewModel extends ChangeNotifier {
  CheckInViewModel({
    CheckInRepository? repository,
    DateTime Function()? now,
    SpeechRecognitionService? speech,
    MicrophoneService? microphone,
    NetworkConnectivityService? network,
    this._voice,
  }) : _repository = repository ?? CheckInRepository(),
       _now = now ?? DateTime.now,
       _speech = speech ?? SpeechRecognitionService(),
       _microphone = microphone ?? const MicrophoneService(),
       _network = network ?? NetworkConnectivityService();

  static const maxNoteLength = 500;

  final CheckInRepository _repository;
  final DateTime Function() _now;
  final SpeechRecognitionService _speech;
  final MicrophoneService _microphone;
  final NetworkConnectivityService _network;

  /// The voice a test passes in; the app uses the phone's shared one.
  final TextToSpeechService? _voice;
  TextToSpeechService? _activeVoice;

  /// The note as it was when the voice started reading it.
  String? _readText;

  final Set<Emotion> _emotions = {};
  int _intensity = 3;
  String _note = '';
  bool _saving = false;
  bool _saved = false;
  String? _message;
  bool _disposed = false;

  bool _canDictate = false;
  bool _isListening = false;
  String? _dictationMessage;


  int _spanStart = 0;
  int _spanLength = 0;


  bool _offline = false;

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

  /// True once the phone has reported a working recognizer. The button stays
  /// hidden until then, so it is never offered where it cannot work.
  bool get canDictate => _canDictate;

  bool get isListening => _isListening;

  /// Shown under the note field when dictation could not run.
  String? get dictationMessage => _dictationMessage;


  String? get dictationHint =>
      _dictationMessage ??
      (_isListening ? 'Listening… tap the mic when you finish.' : null);

  bool get canReadNote => _note.trim().isNotEmpty;

  bool get isReadingNote {
    final voice = _activeVoice;
    return voice != null &&
        voice.state.value != SpeechState.idle &&
        voice.text == _readText;
  }

  TextToSpeechService get _noteVoice {
    final existing = _activeVoice;
    if (existing != null) return existing;
    final voice = _voice ?? TextToSpeechService();
    voice.state.addListener(_notify);
    return _activeVoice = voice;
  }

  /// Where the caret belongs after a dictated update: right after the words.
  int get noteCaret => _spanStart + _spanLength;

  /// Asks the phone whether it can recognize speech at all.
  Future<void> prepareDictation() async {
    final available = await _speech.initialize(
      onError: _onSpeechError,
      onStatus: _onSpeechStatus,
    );
    _canDictate = available;
    _notify();
  }

  /// Starts dictating at [at], the caret position in the note, or stops when
  /// already listening.
  Future<void> toggleDictation({required int at}) async {
    if (_isListening) {
      await _speech.stop();
      return;
    }
    if (!_canDictate) return;
    if (isReadingNote) await _activeVoice?.stop();

    _dictationMessage = null;
    if (await _microphone.requestPermission() != MicPermission.granted) {
      _dictationMessage = 'Allow the microphone to dictate your note.';
      _notify();
      return;
    }

    _spanStart = at.clamp(0, _note.length);
    _spanLength = 0;
    _offline = !await _network.checkOnline();
    try {
      // Offline the recognizer has to run on the phone, which not every phone
      // can do. Trying is the only way to find out.
      await _speech.listen(onWords: _onWords, preferOnDevice: _offline);
    } on Exception {
      _failDictation();
    }
  }


  Future<void> toggleReadNote() async {
    if (isReadingNote) {
      await _activeVoice?.stop();
      return;
    }
    final text = _note.trim();
    if (text.isEmpty) return;
    // The microphone would hear the phone's own voice.
    if (_isListening) await _speech.stop();
    _readText = text;
    await _noteVoice.speak(text);
  }

  void _onWords(String words, bool isFinal) {
    final before = _note.substring(0, _spanStart);
    final after = _note.substring(_spanStart + _spanLength);
    final merged = '$before$words$after';
    final tooLong = merged.length > maxNoteLength;
    _note = tooLong ? merged.substring(0, maxNoteLength) : merged;
    if (tooLong && _isListening) {
      _dictationMessage =
          'Your note reached the $maxNoteLength character limit.';
      _speech.stop();
    }
    _spanLength = _note.length - before.length - after.length;
    if (isFinal) _spanStart = _spanStart + _spanLength;
    if (isFinal) _spanLength = 0;
    _notify();
  }

  void _onSpeechStatus(bool isListening) {
    _isListening = isListening;
    _notify();
  }

  void _onSpeechError(String error) => _failDictation();

  /// The recognizer reports a failed offline attempt as an error rather than
  /// an exception, so both paths end here.
  void _failDictation() {
    _isListening = false;
    _dictationMessage = _offline
        ? 'Dictation needs an internet connection on this phone.'
        : 'Dictation stopped. Try again or type your note.';
    _notify();
  }

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
    // Typing moves the text under the dictated stretch, so the next dictation
    // starts from the caret the widget reports instead of a stale span.
    if (!_isListening) _spanLength = 0;
    notifyListeners();
  }

  Future<void> save() async {
    final mood = this.mood;
    if (mood == null || _saving) return;
    _saving = true;
    _notify();

    if (_isListening) await _speech.stop();
    if (isReadingNote) await _activeVoice?.stop();
    try {
      final outcome = await _repository.save(
        CheckIn(
          emotions: [for (final leaf in mood.emotions) leaf.emotion],
          intensity: mood.intensity.round(),
          timestamp: _now(),
          note: _note.trim(),
        ),
      );
      _saved = true;
      _message = outcome == SaveOutcome.saved
          ? 'Check-in saved. See you tomorrow.'
          : 'Saved on your phone. It will sync when you are back online.';
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

    if (_isListening) _speech.stop();
    if (isReadingNote) _activeVoice?.stop();
    _activeVoice?.state.removeListener(_notify);
    super.dispose();
  }
}
