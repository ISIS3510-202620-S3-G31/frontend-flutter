import 'package:frontend_flutter/data/models/check_in_model.dart';
import 'package:frontend_flutter/data/repositories/check_in_repository.dart';
import 'package:frontend_flutter/data/services/microphone_service.dart';
import 'package:frontend_flutter/data/services/network/network_connectivity_service.dart';
import 'package:frontend_flutter/data/services/speech_recognition_service.dart';

/// Keeps what the sheet saves, so no Firebase is needed.
class FakeCheckInRepository implements CheckInRepository {
  CheckIn? saved;

  @override
  Future<void> save(CheckIn checkIn) async => saved = checkIn;

  @override
  Future<CheckIn?> todaysCheckIn() async => saved;

  @override
  Future<List<CheckIn>> since(DateTime from) async => [?saved];
}

/// Lets a test play the recognizer: report words, fail, or be unavailable.
class FakeSpeechRecognitionService implements SpeechRecognitionService {
  FakeSpeechRecognitionService({this.available = true});

  final bool available;

  bool? askedForOnDevice;
  int stopCount = 0;

  void Function(String words, bool isFinal)? _onWords;
  void Function(String error)? _onError;
  void Function(bool isListening)? _onStatus;

  @override
  Future<bool> initialize({
    void Function(String error)? onError,
    void Function(bool isListening)? onStatus,
  }) async {
    _onError = onError;
    _onStatus = onStatus;
    return available;
  }

  @override
  Future<void> listen({
    required void Function(String words, bool isFinal) onWords,
    bool preferOnDevice = false,
  }) async {
    askedForOnDevice = preferOnDevice;
    _onWords = onWords;
    _onStatus?.call(true);
  }

  @override
  Future<void> stop() async {
    stopCount++;
    _onStatus?.call(false);
  }

  /// Reports a result the way the platform does: the whole phrase so far.
  void say(String words, {bool isFinal = false}) =>
      _onWords?.call(words, isFinal);

  void fail() => _onError?.call('error_network');
}

class FakeMicrophoneService implements MicrophoneService {
  FakeMicrophoneService({this.permission = MicPermission.granted});

  final MicPermission permission;

  @override
  Future<MicPermission> requestPermission() async => permission;

  @override
  Future<void> openSettings() async {}

  @override
  Stream<double> decibels() => const Stream.empty();
}

class FakeNetworkConnectivityService implements NetworkConnectivityService {
  FakeNetworkConnectivityService({this.online = true});

  final bool online;

  @override
  Future<bool> checkOnline() async => online;

  @override
  Stream<bool> get onConnectivityChanged => Stream.value(online);
}
