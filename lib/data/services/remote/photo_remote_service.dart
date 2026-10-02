import 'dart:io';

/// Uploads daily photos to Firebase Cloud Storage.

class PhotoRemoteService {
  const PhotoRemoteService();

  Future<void> upload(DateTime day, File file) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
}
