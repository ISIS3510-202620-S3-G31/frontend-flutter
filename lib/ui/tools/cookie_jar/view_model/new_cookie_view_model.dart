import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../../data/repositories/cookie_repository.dart';
import '../../../../data/services/camera_service.dart';
import '../../../../data/services/connectivity_service.dart';
import '../../../../data/services/microphone_service.dart';
import '../../../../data/services/photo_compressor.dart';
import '../../../../data/services/speech_recognition_service.dart';
import '../../../../domain/cookie_jar/cookie_messages.dart';
import '../../../../domain/cookie_jar/cookie_rules.dart';

/// State of the new-cookie form: title, text (typed or dictated) and an optional photo from the camera.
class NewCookieViewModel extends ChangeNotifier {
  NewCookieViewModel({
    CookieRepository? repository,
    CameraService? camera,
    SpeechRecognitionService? speech,
    MicrophoneService? microphone,
    ConnectivityChecker? connectivity,
    PhotoCompressor? compressor,
  }) : _repository = repository ?? CookieRepository.shared,
       _camera = camera ?? const CameraService(),
       _compressor = compressor ?? cookieCompressor,
       _speech = speech ?? SpeechRecognitionService(),
       _microphone = microphone ?? const MicrophoneService(),
       _connectivity = connectivity ?? ConnectivityService();

  static const cookieCompressor = PhotoCompressor(maxSide: 1440, quality: 85);

  final CookieRepository _repository;
  final CameraService _camera;
  final PhotoCompressor _compressor;
  final SpeechRecognitionService _speech;
  final MicrophoneService _microphone;
  final ConnectivityChecker _connectivity;

  String _title = '';
  String _text = '';
  Uint8List? _photo;
  String? _finalTitle;
  bool _saving = false;
  bool _triedToSave = false;
  CreatedCookie? _saved;
  String? _message;
  bool _disposed = false;

  int _titleChecks = 0;

  bool _canDictate = false;
  bool _isListening = false;
  bool _offline = false;

  /// True while the mic is held down.
  bool _holding = false;

  int _session = 0;
  int _restarts = 0;
  Timer? _restartTimer;
  String _textBeforeHold = '';
  int _caretBeforeHold = 0;

  /// The stretch of [_text] the current dictation is writing.
  int _spanStart = 0;
  int _spanLength = 0;

  static const _maxRestarts = 30;

  static const _silenceErrors = {
    'error_no_match',
    'error_speech_timeout',
    'error_client',
    'error_busy',
  };

  String get title => _title;
  String get text => _text;
  Uint8List? get photo => _photo;
  bool get saving => _saving;

  /// Set once the cookie is saved: the screen closes with it.
  CreatedCookie? get saved => _saved;

  bool get canDictate => _canDictate;
  bool get isListening => _isListening;
  bool get isRecording => _holding;

  /// Where the caret belongs after a dictated update: right after the words.
  int get textCaret => _spanStart + _spanLength;

  /// Errors are shown only after the first try, not while typing.
  String? get titleError =>
      _triedToSave ? CookieRules.titleError(_title) : null;
  String? get textError => _triedToSave ? CookieRules.textError(_text) : null;

  /// "Will be saved as ..." when the title already exists.
  String? get willBeSavedAs {
    final finalTitle = _finalTitle;
    if (finalTitle == null) return null;
    return finalTitle == CookieRules.cleanTitle(_title)
        ? null
        : CookieMessages.willBeSavedAs(finalTitle);
  }

  /// A notice for the Snackbar; the screen reads it and calls [clearMessage].
  String? get message => _message;

  void clearMessage() => _message = null;

  void setTitle(String value) {
    _title = value;
    _notify();
    unawaited(_checkTitle());
  }

  Future<void> _checkTitle() async {
    final check = ++_titleChecks;
    if (CookieRules.cleanTitle(_title).isEmpty) {
      _finalTitle = null;
      _notify();
      return;
    }
    final finalTitle = await _repository.finalTitleFor(_title);
    if (check != _titleChecks) return;
    _finalTitle = finalTitle;
    _notify();
  }

  void setText(String value) {
    _text = _limit(value);
    if (!_holding) _spanLength = 0;
    _notify();
  }

  static String _limit(String text) => text.length > CookieRules.maxTextLength
      ? text.substring(0, CookieRules.maxTextLength)
      : text;

  Future<void> prepareDictation() async {
    _canDictate = await _speech.initialize(
      onError: _onSpeechError,
      onStatus: (listening) {
        _isListening = listening;
        _notify();
      },
    );
    _notify();
  }

  Future<void> startDictation({required int at}) async {
    if (!_canDictate || _holding || _saving) return;
    final session = ++_session;
    _holding = true;
    _restarts = 0;
    _textBeforeHold = _text;
    _spanStart = _caretBeforeHold = at.clamp(0, _text.length);
    _spanLength = 0;
    _notify();
    if (await _microphone.requestPermission() != MicPermission.granted) {
      if (session == _session) {
        _holding = false;
        _message = CookieMessages.allowMicrophone;
        _notify();
      }
      return;
    }
    _offline = !await _connectivity.isOnline();
    if (session != _session || !_holding) return;
    await _listen(session);
    if (!_holding && session == _session) unawaited(_speech.stop());
  }

  /// Mic released: keeps what was dictated.
  Future<void> finishDictation() async {
    if (!_holding) return;
    _holding = false;
    _restartTimer?.cancel();
    _notify();
    await _speech.stop();
  }

  /// Slid off the mic: drops what this hold dictated.
  Future<void> cancelDictation() async {
    if (!_holding) return;
    _holding = false;
    _session++;
    _restartTimer?.cancel();
    _text = _textBeforeHold;
    _spanStart = _caretBeforeHold;
    _spanLength = 0;
    _notify();
    await _speech.stop();
  }

  Future<void> _listen(int session) async {
    try {
      await _speech.listen(
        onWords: (words, isFinal) {
          if (session == _session) _onWords(words, isFinal);
        },
        preferOnDevice: _offline,
      );
    } on Exception {
      _failDictation();
    }
  }

  /// While the mic is held, listens again after the phone stops on a pause.
  void _keepListeningWhileHeld() {
    if (!_holding || _restarts >= _maxRestarts) return;
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(milliseconds: 200), () {
      if (!_holding || _disposed) return;
      _restarts++;
      _spanStart += _spanLength;
      _spanLength = 0;
      unawaited(_listen(_session));
    });
  }

  void _onWords(String words, bool isFinal) {
    final before = _text.substring(0, _spanStart);
    final after = _text.substring(_spanStart + _spanLength);
    final gap = words.isNotEmpty && before.isNotEmpty && !before.endsWith(' ')
        ? ' '
        : '';
    final merged = '$before$gap$words$after';
    _text = _limit(merged);
    final full = _text.length < merged.length;
    _spanLength = (_text.length - before.length - after.length).clamp(
      0,
      _text.length - before.length,
    );
    if (isFinal) {
      _spanStart += _spanLength;
      _spanLength = 0;
    }
    if (full) {
      _holding = false;
      _restartTimer?.cancel();
      unawaited(_speech.stop());
    } else if (isFinal) {
      _keepListeningWhileHeld();
    }
    _notify();
  }

  void _onSpeechError(String error) {
    if (_silenceErrors.contains(error)) {
      _keepListeningWhileHeld();
      return;
    }
    _failDictation();
  }

  void _failDictation() {
    _holding = false;
    _isListening = false;
    _restartTimer?.cancel();
    _message = _offline
        ? CookieMessages.offlineVoiceNotReady
        : CookieMessages.dictationStopped;
    _notify();
  }

  bool _preparingPhoto = false;
  bool get preparingPhoto => _preparingPhoto;

  /// Opens the camera; the photo replaces any previous one.
  Future<void> takePhoto() async {
    try {
      final shot = await _camera.takeWithSystemCamera();
      if (shot == null) return;
      _preparingPhoto = true;
      _notify();
      _photo = await _compressor.compress(shot.path);
    } on PlatformException catch (error) {
      _message = error.code.contains('denied')
          ? CookieMessages.allowCamera
          : CookieMessages.cameraFailed;
    } on FormatException {
      _message = CookieMessages.cameraFailed;
    } finally {
      _preparingPhoto = false;
      _notify();
    }
  }

  void removePhoto() {
    _photo = null;
    _notify();
  }

  /// Saves the cookie on the phone. On success [saved] is set.
  Future<void> save() async {
    if (_saving || _preparingPhoto) return;
    _triedToSave = true;
    if (CookieRules.validationError(_title, _text) != null) {
      _notify();
      return;
    }
    _saving = true;
    _notify();
    if (_holding) await finishDictation();
    try {
      _saved = await _repository.create(
        title: _title,
        text: _text,
        photo: _photo,
      );
    } on CookieRuleException catch (error) {
      _message = error.message;
    } on FileSystemException {
      _message = CookieMessages.notEnoughSpace;
    } finally {
      _saving = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _restartTimer?.cancel();
    if (_holding || _isListening) unawaited(_speech.stop());
    _holding = false;
    super.dispose();
  }
}
