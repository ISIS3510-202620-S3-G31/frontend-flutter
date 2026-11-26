import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/fortune_model.dart';

/// The fortunes an account kept, in Firestore at
/// `users/{uid}/favorite_fortunes/{id}`: the same documents the Kotlin app
/// writes, so they show on either phone.
class FortuneRemoteService {
  FortuneRemoteService({FirebaseFirestore? firestore, Duration? timeLimit})
    : _customFirestore = firestore,
      timeLimit = timeLimit ?? const Duration(seconds: 10);

  final FirebaseFirestore? _customFirestore;

  /// Firestore waits for the server forever; past this the change stays
  /// pending and goes up later.
  final Duration timeLimit;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _favorites(String userId) =>
      _firestore.collection('users/$userId/favorite_fortunes');

  Future<void> keep(String userId, Fortune fortune) => _favorites(userId)
      .doc('${fortune.id}')
      .set({
        'id': fortune.id,
        'quote': fortune.quote,
        'category': fortune.category,
        'savedAt': fortune.savedAt.millisecondsSinceEpoch,
      })
      .timeout(timeLimit);

  Future<void> remove(String userId, int id) =>
      _favorites(userId).doc('$id').delete().timeout(timeLimit);

  Future<List<Fortune>> favorites(String userId) async {
    final snapshot = await _favorites(
      userId,
    ).get(const GetOptions(source: Source.server)).timeout(timeLimit);
    return [
      for (final doc in snapshot.docs)
        if ((doc.data()['quote'] as String?)?.isNotEmpty ?? false)
          Fortune.fromJson(doc.data()),
    ];
  }
}
