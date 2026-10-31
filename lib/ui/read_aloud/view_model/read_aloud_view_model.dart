import 'package:flutter/foundation.dart';

import '../../../data/services/text_to_speech_service.dart';


class ReadAloudViewModel extends ChangeNotifier {
  ReadAloudViewModel({required this.text, TextToSpeechService? speech})
    : _speech = speech ?? TextToSpeechService() {
    _speech.state.addListener(notifyListeners);
    _checkAvailable();
  }

  final String text;
  final TextToSpeechService _speech;

  bool? _available;
  bool _disposed = false;

  /// Null while the phone is being asked, false when it cannot read aloud.
  bool? get available => _available;

  /// The voice's state for this text; another text being read counts as idle.
  SpeechState get state =>
      _speech.text == text ? _speech.state.value : SpeechState.idle;

  Future<void> _checkAvailable() async {
    final available = await _speech.initialize();
    if (_disposed) return;
    _available = available;
    notifyListeners();
  }

  /// The main button: listen, pause or resume, depending on the state.
  Future<void> toggle() => switch (state) {
    SpeechState.idle => _speech.speak(text),
    SpeechState.speaking => _speech.pause(),
    SpeechState.paused => _speech.resume(),
  };

  /// Pauses this text if it is being read, and does nothing otherwise.
  Future<void> pause() async {
    if (state == SpeechState.speaking) await _speech.pause();
  }

  Future<void> stop() async {
    if (state != SpeechState.idle) await _speech.stop();
  }

  @override
  void dispose() {
    _disposed = true;
    _speech.state.removeListener(notifyListeners);
    // Leaving the screen silences its own text, not another screen's.
    if (state != SpeechState.idle) _speech.stop();
    super.dispose();
  }
}
