import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../../data/repositories/cookie_repository.dart';
import '../../../../data/services/camera_service.dart';
import '../../../../data/services/connectivity_service.dart';
import '../../../../data/services/microphone_service.dart';
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
  }) : _repository = repository ?? CookieRepository.shared,
       _camera = camera ?? const CameraService(),
       _speech = speech ?? SpeechRecognitionService(),
       _microphone = microphone ?? const MicrophoneService(),
       _connectivity = connectivity ?? ConnectivityService();

  final CookieRepository _repository;
  final CameraService _camera;
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

  /// The stretch of [_text] the current dictation is writing.
  int _spanStart = 0;
  int _spanLength = 0;

  String get title => _title;
  String get text => _text;
  Uint8List? get photo => _photo;
  bool get saving => _saving;

  /// Set once the cookie is saved: the screen closes with it.
  CreatedCookie? get saved => _saved;

  bool get canDictate => _canDictate;
  bool get isListening => _isListening;

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
    if (!_isListening) _spanLength = 0;
    _notify();
  }

  static String _limit(String text) => text.length > CookieRules.maxTextLength
      ? text.substring(0, CookieRules.maxTextLength)
      : text;

  Future<void> prepareDictation() async {
    _canDictate = await _speech.initialize(
      onError: (_) => _failDictation(),
      onStatus: (listening) {
        _isListening = listening;
        _notify();
      },
    );
    _notify();
  }

  Future<void> toggleDictation({required int at}) async {
    if (_isListening) {
      await _speech.stop();
      return;
    }
    if (!_canDictate) return;
    if (await _microphone.requestPermission() != MicPermission.granted) {
      _message = CookieMessages.allowMicrophone;
      _notify();
      return;
    }
    _spanStart = at.clamp(0, _text.length);
    _spanLength = 0;
    _offline = !await _connectivity.isOnline();
    try {
      await _speech.listen(onWords: _onWords, preferOnDevice: _offline);
    } on Exception {
      _failDictation();
    }
  }

  void _onWords(String words, bool isFinal) {
    final before = _text.substring(0, _spanStart);
    final after = _text.substring(_spanStart + _spanLength);
    final merged = '$before$words$after';
    _text = _limit(merged);
    if (_text.length < merged.length && _isListening) unawaited(_speech.stop());
    _spanLength = _text.length - before.length - after.length;
    if (isFinal) {
      _spanStart += _spanLength;
      _spanLength = 0;
    }
    _notify();
  }

  void _failDictation() {
    _isListening = false;
    _message = _offline
        ? CookieMessages.offlineVoiceNotReady
        : CookieMessages.dictationStopped;
    _notify();
  }

  /// Opens the camera; the photo replaces any previous one.
  Future<void> takePhoto() async {
    try {
      final shot = await _camera.takeWithSystemCamera();
      if (shot == null) return;
      _photo = await shot.readAsBytes();
    } on PlatformException catch (error) {
      _message = error.code.contains('denied')
          ? CookieMessages.allowCamera
          : CookieMessages.cameraFailed;
    }
    _notify();
  }

  void removePhoto() {
    _photo = null;
    _notify();
  }

  /// Saves the cookie on the phone. On success [saved] is set.
  Future<void> save() async {
    if (_saving) return;
    _triedToSave = true;
    if (CookieRules.validationError(_title, _text) != null) {
      _notify();
      return;
    }
    _saving = true;
    _notify();
    if (_isListening) await _speech.stop();
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
    if (_isListening) unawaited(_speech.stop());
    super.dispose();
  }
}
