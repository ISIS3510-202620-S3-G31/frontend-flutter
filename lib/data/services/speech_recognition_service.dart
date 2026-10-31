import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Turns speech into text using whatever recognizer the phone ships with.
///
/// The platform recognizer stops on its own after a pause, so callers must
/// follow [onStatus] instead of assuming a session lasts until [stop].
class SpeechRecognitionService {
  SpeechRecognitionService({SpeechToText? speech})
    : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;

  /// False when the phone has no recognizer, so the caller can hide the
  /// button instead of offering something that cannot work.
  Future<bool> initialize({
    void Function(String error)? onError,
    void Function(bool isListening)? onStatus,
  }) {
    return _speech.initialize(
      onError: (error) => onError?.call(error.errorMsg),
      onStatus: (status) => onStatus?.call(status == 'listening'),
    );
  }

  /// Reports the words so far on every partial result, and again with
  /// [isFinal] true when the recognizer settles on them.
  ///
  /// Each report replaces the previous one; it is not an addition.
  Future<void> listen({
    required void Function(String words, bool isFinal) onWords,
    bool preferOnDevice = false,
  }) {
    return _speech.listen(
      onResult: (SpeechRecognitionResult result) =>
          onWords(result.recognizedWords, result.finalResult),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        // There is no way to ask whether on-device recognition exists, so
        // offline the only option is to try and let it fail.
        onDevice: preferOnDevice,
      ),
    );
  }

  Future<void> stop() => _speech.stop();
}
