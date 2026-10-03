import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

/// Uploads a daily photo to Firebase: the image goes to Cloud Storage and a
/// small record to Firestore, both under `users/{uid}/photos/{yyyy-MM-dd}`,
/// which are the paths the backend security rules allow for the owner.
class PhotoRemoteService {
  PhotoRemoteService({FirebaseStorage? storage, FirebaseFirestore? firestore})
    : _customStorage = storage,
      _customFirestore = firestore;

  static final _dayFormat = DateFormat('yyyy-MM-dd');

  final FirebaseStorage? _customStorage;
  final FirebaseFirestore? _customFirestore;

  FirebaseStorage get _storage => _customStorage ?? FirebaseStorage.instance;
  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  /// Uploading the same day again replaces it, so a retry never duplicates.
  Future<void> upload(String userId, DateTime day, File file) async {
    final name = _dayFormat.format(day);
    final image = _storage.ref('users/$userId/photos/$name.jpg');
    // The storage rules only accept files that say they are images.
    await image.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    await _firestore.doc('users/$userId/photos/$name').set({
      'day': name,
      'storagePath': image.fullPath,
      'uploadedAt': FieldValue.serverTimestamp(),
    });
  }
}
