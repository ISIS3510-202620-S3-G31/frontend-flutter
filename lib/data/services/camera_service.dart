import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

class CameraService {
  const CameraService();

  Future<List<CameraDescription>> listCameras() => availableCameras();

  /// Throws a [CameraException] when the permission is denied or the camera
  /// cannot be opened.
  Future<CameraController> open(
    CameraDescription camera, {
    bool flashOn = false,
  }) async {
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    try {
      await controller.initialize();
      await setFlash(controller, flashOn);
      return controller;
    } on Exception {
      await controller.dispose();
      rethrow;
    }
  }

  Future<void> setFlash(CameraController controller, bool on) async {
    try {
      await controller.setFlashMode(on ? FlashMode.always : FlashMode.off);
    } on CameraException {
      // Most front cameras have no flash.
    }
  }

  Future<XFile> takePicture(CameraController controller) =>
      controller.takePicture();

  Future<XFile?> pickFromGallery() => ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 2048,
    imageQuality: 90,
  );
}
