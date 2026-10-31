import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../domain/speech/speech_chunks.dart';

/// What the voice is doing.
enum SpeechState { idle, speaking, paused }

class TextToSpeechService {
  factory TextToSpeechService({FlutterTts? tts, String? language}) {
    if (tts != null || language != null) {
      return TextToSpeechService._internal(tts ?? FlutterTts(), language);
    }
    return _instance ??= TextToSpeechService._internal(FlutterTts(), null);
  }

  TextToSpeechService._internal(this._tts, String? language)
    : language = language ?? 'en-US';

  static TextToSpeechService? _instance;

  final FlutterTts _tts;

  /// The app's texts are in English.
  final String language;

  final _state = ValueNotifier(SpeechState.idle);
  Future<bool>? _ready;

  String? _text;
  List<String> _chunks = const [];

  int _next = 0;

  /// Changes every time a reading starts, pauses or stops, so a reading that was interrupted knows it must not go on.

  int _run = 0;

  /// What the voice is doing, for screens to follow.
  ValueListenable<SpeechState> get state => _state;


  String? get text => _text;


  Future<bool> initialize() => _ready ??= _setUp();

  Future<bool> _setUp() async {
    try {

      await _tts.awaitSpeakCompletion(true);
      _tts.setErrorHandler((_) => _finish());
      if (await _tts.isLanguageAvailable(language) != true) return false;
      await _tts.setLanguage(language);
      return true;
    } on Exception {
      return false;
    }
  }

  Future<void> speak(String text) async {
    await stop();
    final chunks = speechChunks(text);
    if (chunks.isEmpty || !await initialize()) return;
    _text = text;
    _chunks = chunks;
    _next = 0;
    await _readOn();
  }


  Future<void> pause() async {
    if (_state.value != SpeechState.speaking) return;
    _run++;
    _state.value = SpeechState.paused;
    await _tts.stop();
  }

  Future<void> resume() async {
    if (_state.value != SpeechState.paused) return;
    await _readOn();
  }

  /// Silences the voice and forgets the text.
  Future<void> stop() async {
    final wasIdle = _state.value == SpeechState.idle;
    _finish();
    if (!wasIdle) await _tts.stop();
  }

  Future<void> _readOn() async {
    final run = ++_run;
    _state.value = SpeechState.speaking;
    while (_next < _chunks.length) {
      await _tts.speak(_chunks[_next]);

      if (run != _run) return;
      _next++;
    }
    _finish();
  }

  void _finish() {
    _run++;
    _text = null;
    _chunks = const [];
    _next = 0;
    _state.value = SpeechState.idle;
  }
}
