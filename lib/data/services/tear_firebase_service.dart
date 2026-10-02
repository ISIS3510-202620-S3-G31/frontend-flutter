import '../models/tear_model.dart';

// Everything here is temporal. Just in case

/// Service for handling Tear Collection persistence with Firebase.
///
/// Currently operates in a functional mock/in-memory mode with placeholder
/// Firebase hooks so all parts function smoothly before the real Firebase
/// backend is connected.
class TearFirebaseService {
  TearFirebaseService({List<Tear>? initialTears})
    : _inMemoryTears = initialTears != null
          ? List<Tear>.from(initialTears)
          : List<Tear>.from(Tear.samples);

  /// In-memory storage cache while Firebase is disconnected.
  final List<Tear> _inMemoryTears;

  /// Fetches the [TearCollection] summary object.
  /// ```dart
  /// final snapshot = await FirebaseFirestore.instance
  ///     .collection('tear_collections')
  ///     .doc(userId)
  ///     .get();
  /// return TearCollection.fromMap(snapshot.data()!, tears: await getTears());
  /// ```
  Future<TearCollection> getTearCollection() async {
    // Blank Firebase hook: connect FirebaseFirestore here.
    return TearCollection.fromTears(_inMemoryTears);
  }

  /// Fetches all preserved [Tear] records.
  /// ```dart
  /// final snapshot = await FirebaseFirestore.instance
  ///     .collection('users')
  ///     .doc(userId)
  ///     .collection('tears')
  ///     .orderBy('timestamp', descending: true)
  ///     .get();
  /// return snapshot.docs.map((doc) => Tear.fromMap(doc.data(), id: doc.id)).toList();
  /// ```
  Future<List<Tear>> getTears() async {
    // Blank Firebase hook: connect FirebaseFirestore here.
    return List.unmodifiable(_inMemoryTears);
  }

  /// Saves a new [Tear] to the collection.
  /// ```dart
  /// final docRef = await FirebaseFirestore.instance
  ///     .collection('users')
  ///     .doc(userId)
  ///     .collection('tears')
  ///     .add(tear.toMap());
  /// return tear.copyWith(id: docRef.id);
  /// ```
  Future<Tear> addTear(Tear tear) async {
    // Blank Firebase hook: connect FirebaseFirestore here.
    final savedTear = tear.id.isEmpty
        ? tear.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString())
        : tear;
    _inMemoryTears.insert(0, savedTear);
    return savedTear;
  }

  /// Deletes a tear by [id].
  /// ```dart
  /// await FirebaseFirestore.instance
  ///     .collection('users')
  ///     .doc(userId)
  ///     .collection('tears')
  ///     .doc(id)
  ///     .delete();
  /// ```
  Future<void> deleteTear(String id) async {
    // Blank Firebase hook: connect FirebaseFirestore here.
    _inMemoryTears.removeWhere((t) => t.id == id);
  }

  /// Updates an existing [Tear].
  /// ```dart
  /// await FirebaseFirestore.instance
  ///     .collection('users')
  ///     .doc(userId)
  ///     .collection('tears')
  ///     .doc(tear.id)
  ///     .update(tear.toMap());
  /// ```
  Future<Tear> updateTear(Tear tear) async {
    // Blank Firebase hook: connect FirebaseFirestore here.
    final index = _inMemoryTears.indexWhere((t) => t.id == tear.id);
    if (index != -1) {
      _inMemoryTears[index] = tear;
    }
    return tear;
  }
}
