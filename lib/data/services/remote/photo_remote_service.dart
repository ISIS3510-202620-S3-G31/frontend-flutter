import 'dart:io';

/// Uploads daily photos to Firebase Cloud Storage.
///
/// Firebase is not connected to the app yet, so for now the upload only
/// waits a moment. When it is, the file goes to
/// `users/{uid}/photos/{yyyy-MM-dd}.jpg` with content type `image/jpeg`,
/// which is what the backend storage rules accept.
class PhotoRemoteService {
  const PhotoRemoteService();

  Future<void> upload(DateTime day, File file) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
}
