import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';

enum MicPermission { granted, denied, permanentlyDenied }

class MicrophoneService {
  const MicrophoneService();

  Future<MicPermission> requestPermission() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) return MicPermission.granted;
    return status.isPermanentlyDenied
        ? MicPermission.permanentlyDenied
        : MicPermission.denied;
  }

  Future<void> openSettings() => openAppSettings();

  /// Loudness in dB. A completely silent buffer reads as -infinity, so those
  /// readings are dropped.
  Stream<double> decibels() => NoiseMeter().noise
      .map((reading) => reading.meanDecibel)
      .where((db) => db.isFinite);
}
