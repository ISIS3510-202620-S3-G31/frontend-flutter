import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../models/fortune_model.dart';

/// A card as the account keeps it in the cloud.
typedef RemoteFortuneCard = ({
  int cookieId,
  String quote,
  String imageUrl,
  DateTime savedAt,
});

/// The Fortune Cookie in the account, in the same places the Kotlin app
/// uses, so everything shows on either phone:
///
/// - `users/{uid}/favorite_fortunes/{id}`: the fortunes kept.
/// - `users/{uid}/saved_fortune_cards/{id}` and, in Storage,
///   `users/{uid}/fortune_cards/card_{id}.png`: the cards shared.
/// - `users/{uid}/fortune_daily/{yyyy-MM-dd}`: how many cookies were opened
///   that day, so another phone does not hand out five more.
/// - `users/{uid}/fortune_daily/recent`: the last five opened.
class FortuneRemoteService {
  FortuneRemoteService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    Duration? timeLimit,
  }) : _customFirestore = firestore,
       _customStorage = storage,
       timeLimit = timeLimit ?? const Duration(seconds: 10);

  final FirebaseFirestore? _customFirestore;
  final FirebaseStorage? _customStorage;

  /// Firestore waits for the server forever; past this the change stays
  /// pending and goes up later.
  final Duration timeLimit;

  /// A card is a megabyte or two, so its upload gets longer.
  Duration get _uploadLimit => timeLimit * 3;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;
  FirebaseStorage get _storage => _customStorage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> _favorites(String userId) =>
      _firestore.collection('users/$userId/favorite_fortunes');
  CollectionReference<Map<String, dynamic>> _cards(String userId) =>
      _firestore.collection('users/$userId/saved_fortune_cards');
  CollectionReference<Map<String, dynamic>> _daily(String userId) =>
      _firestore.collection('users/$userId/fortune_daily');
  Reference _cardImage(String userId, int cookieId) =>
      _storage.ref('users/$userId/fortune_cards/card_$cookieId.png');

  // Kept fortunes.

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

  // Shared cards.

  /// Uploads the image, then the document that points at it.
  Future<void> uploadCard(
    String userId, {
    required int cookieId,
    required String quote,
    required DateTime savedAt,
    required Uint8List png,
  }) async {
    final image = _cardImage(userId, cookieId);
    await image
        .putData(png, SettableMetadata(contentType: 'image/png'))
        .timeout(_uploadLimit);
    final url = await image.getDownloadURL().timeout(timeLimit);
    await _cards(userId)
        .doc('$cookieId')
        .set({
          'cookieId': cookieId,
          'quote': quote,
          'remoteImageUrl': url,
          'savedAt': savedAt.millisecondsSinceEpoch,
        })
        .timeout(timeLimit);
  }

  Future<void> removeCard(String userId, int cookieId) async {
    await _cards(userId).doc('$cookieId').delete().timeout(timeLimit);
    try {
      await _cardImage(userId, cookieId).delete().timeout(timeLimit);
    } on FirebaseException catch (error) {
      // Already gone is the outcome we wanted.
      if (error.code != 'object-not-found') rethrow;
    }
  }

  Future<List<RemoteFortuneCard>> cards(String userId) async {
    final snapshot = await _cards(
      userId,
    ).get(const GetOptions(source: Source.server)).timeout(timeLimit);
    return [
      for (final doc in snapshot.docs)
        if ((doc.data()['remoteImageUrl'] as String?)?.isNotEmpty ?? false)
          (
            cookieId: (doc.data()['cookieId'] as num).toInt(),
            quote: doc.data()['quote'] as String? ?? '',
            imageUrl: doc.data()['remoteImageUrl'] as String,
            savedAt: DateTime.fromMillisecondsSinceEpoch(
              (doc.data()['savedAt'] as num?)?.toInt() ?? 0,
            ),
          ),
    ];
  }

  Future<Uint8List?> downloadCard(String userId, int cookieId) => _cardImage(
    userId,
    cookieId,
  ).getData(8 * 1024 * 1024).timeout(_uploadLimit);

  // Today's cookies.

  /// How many cookies the account opened on [day], on any phone.
  Future<int> usedOn(String userId, String day) async {
    final snapshot = await _daily(
      userId,
    ).doc(day).get(const GetOptions(source: Source.server)).timeout(timeLimit);
    return (snapshot.data()?['used'] as num?)?.toInt() ?? 0;
  }

  /// Raises the count of [day] to [used], in a transaction: if another phone
  /// opened more meanwhile, the larger number stays.
  Future<void> raiseUsed(String userId, String day, int used) => _firestore
      .runTransaction((transaction) async {
        final doc = _daily(userId).doc(day);
        final remote = ((await transaction.get(doc)).data()?['used'] as num?)
            ?.toInt();
        if (remote == null || used > remote) {
          transaction.set(doc, {
            'date': day,
            'used': used,
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          });
        }
      })
      .timeout(timeLimit);

  // Recent cookies.

  Future<List<Fortune>> recents(String userId) async {
    final snapshot = await _daily(userId)
        .doc('recent')
        .get(const GetOptions(source: Source.server))
        .timeout(timeLimit);
    final items = snapshot.data()?['items'] as List<dynamic>? ?? const [];
    return [
      for (final item in items.whereType<Map<String, dynamic>>())
        if (item['quote'] is String)
          Fortune(
            quote: item['quote'] as String,
            id: (item['id'] as num?)?.toInt(),
            savedAt: DateTime.fromMillisecondsSinceEpoch(
              (item['openedAt'] as num?)?.toInt() ?? 0,
            ),
          ),
    ];
  }

  Future<void> setRecents(String userId, List<Fortune> recents) =>
      _daily(userId)
          .doc('recent')
          .set({
            'items': [
              for (final fortune in recents)
                {
                  'id': fortune.id,
                  'quote': fortune.quote,
                  'openedAt': fortune.savedAt.millisecondsSinceEpoch,
                },
            ],
          })
          .timeout(timeLimit);
}
