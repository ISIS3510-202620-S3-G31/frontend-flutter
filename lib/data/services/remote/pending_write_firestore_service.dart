import 'package:cloud_firestore/cloud_firestore.dart';

class PendingWriteFirestoreService {
  PendingWriteFirestoreService({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  Future<void> set(String path, Map<String, Object?> data) =>
      _firestore.doc(path).set(data);
}
