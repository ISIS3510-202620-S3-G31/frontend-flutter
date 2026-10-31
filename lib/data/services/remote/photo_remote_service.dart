import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

/// The daily photos of one account in Firebase: the image in Cloud Storage
/// and a small record in Firestore, both under
/// `users/{uid}/photos/{yyyy-MM-dd}`, which are the paths the backend security
/// rules allow for the owner.
///
/// The Firestore record is what lets another phone know a day has a photo
/// without downloading any image: listing Storage is slower and the rules do
/// not allow it.
class PhotoRemoteService {
  PhotoRemoteService({FirebaseStorage? storage, FirebaseFirestore? firestore})
    : _customStorage = storage,
      _customFirestore = firestore;

  static final _dayFormat = DateFormat('yyyy-MM-dd');

  /// A photo from the camera is a few MB; past this something is wrong and it
  /// is not worth pulling over mobile data.
  static const maxPhotoBytes = 12 * 1024 * 1024;

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

  /// Which days between [first] and [last] this account has a photo for,
  /// whichever phone took it.
  ///
  /// Reads only the small Firestore records, so marking the week costs one
  /// query and no images.
  Future<Set<DateTime>> daysWithPhoto(
    String userId,
    DateTime first,
    DateTime last,
  ) async {
    final found = await _firestore
        .collection('users/$userId/photos')
        .where(
          FieldPath.documentId,
          isGreaterThanOrEqualTo: _dayFormat.format(first),
          isLessThanOrEqualTo: _dayFormat.format(last),
        )
        .get();
    // A document whose id is not a date is not a daily photo.
    return {for (final doc in found.docs) ?DateTime.tryParse(doc.id)};
  }

  /// The image of [day], or null when this account has no photo that day or
  /// the file is too large to be one.
  Future<List<int>?> download(String userId, DateTime day) async {
    final name = _dayFormat.format(day);
    try {
      return await _storage
          .ref('users/$userId/photos/$name.jpg')
          .getData(maxPhotoBytes);
    } on FirebaseException catch (error) {
      // A day with no photo is an ordinary answer, not a failure.
      if (error.code == 'object-not-found') return null;
      rethrow;
    }
  }
}
