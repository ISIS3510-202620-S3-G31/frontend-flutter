import 'package:cloud_firestore/cloud_firestore.dart';

class PendingWriteFirestoreService {
  PendingWriteFirestoreService({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  /// Merged into the document, so sending a queued check-in again keeps the place that was added to it afterwards (BQ10).
  Future<void> set(String path, Map<String, Object?> data) =>
      _firestore.doc(path).set(data, SetOptions(merge: true));

  /// Removes the document. Like [set], Firestore itself keeps the delete on the phone when there is no network and sends it when it returns.
  Future<void> delete(String path) => _firestore.doc(path).delete();
}
