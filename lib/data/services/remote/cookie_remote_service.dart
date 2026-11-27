import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../models/cookie_model.dart';

/// The cookies of one account in Firebase: the document `users/{uid}/cookies/{id}` in Firestore and the photo `users/{uid}/cookies/{id}.jpg` in Storage.
class CookieRemoteService {
  CookieRemoteService({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _customFirestore = firestore,
      _customStorage = storage;

  static const remoteTimeout = Duration(seconds: 20);

  /// A photo weighs more than a document and takes longer.
  static const photoTimeout = Duration(seconds: 90);

  /// The same cap as storage.rules.
  static const maxImageBytes = 10 * 1024 * 1024;

  static const pageSize = 100;

  final FirebaseFirestore? _customFirestore;
  final FirebaseStorage? _customStorage;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;
  FirebaseStorage get _storage => _customStorage ?? FirebaseStorage.instance;

  static String imagePath(String userId, String cookieId) =>
      'users/$userId/cookies/$cookieId.jpg';

  CollectionReference<Map<String, dynamic>> _cookiesOf(String userId) =>
      _firestore.collection('users/$userId/cookies');

  Future<String> uploadImage(
    String userId,
    String cookieId,
    Uint8List jpeg,
  ) async {
    final reference = _storage.ref(imagePath(userId, cookieId));
    await reference
        .putData(jpeg, SettableMetadata(contentType: 'image/jpeg'))
        .timeout(photoTimeout);
    return reference.getDownloadURL().timeout(remoteTimeout);
  }

  Future<CookieModel?> push(CookieModel cookie) {
    final document = _cookiesOf(cookie.userId).doc(cookie.id);
    return _firestore
        .runTransaction<CookieModel?>((transaction) async {
          final snapshot = await transaction.get(document);
          final data = snapshot.data();
          final remoteUpdatedAt = (data?['updatedAt'] as num?)?.toInt();
          if (data != null &&
              remoteUpdatedAt != null &&
              remoteUpdatedAt > cookie.updatedAt) {
            return CookieModel.fromFirestore(snapshot.id, data);
          }
          transaction.set(document, cookie.toFirestore());
          return null;
        })
        .timeout(remoteTimeout);
  }

  Future<List<CookieModel>> fetchAll(String userId) async {
    final cookies = <CookieModel>[];
    DocumentSnapshot<Map<String, dynamic>>? last;
    while (true) {
      var query = _cookiesOf(
        userId,
      ).orderBy(FieldPath.documentId).limit(pageSize);
      if (last != null) query = query.startAfterDocument(last);
      final page = await query
          .get(const GetOptions(source: Source.server))
          .timeout(remoteTimeout);
      for (final document in page.docs) {
        cookies.add(CookieModel.fromFirestore(document.id, document.data()));
      }
      if (page.docs.length < pageSize) return cookies;
      last = page.docs.last;
    }
  }

  /// The whole JPEG (~400 KB) in memory; the private store saves it.
  Future<Uint8List?> downloadImage(String userId, String cookieId) => _storage
      .ref(imagePath(userId, cookieId))
      .getData(maxImageBytes)
      .timeout(photoTimeout);

  Future<void> delete(String userId, String cookieId) async {
    await _cookiesOf(userId).doc(cookieId).delete().timeout(remoteTimeout);
    try {
      await _storage
          .ref(imagePath(userId, cookieId))
          .delete()
          .timeout(remoteTimeout);
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
  }
}
