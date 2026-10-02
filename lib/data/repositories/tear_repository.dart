import '../models/tear_model.dart';
import '../services/tear_firebase_service.dart';

/// Repository abstracting data access for the Tear Collector feature.
class TearRepository {
  TearRepository({TearFirebaseService? service})
      : _service = service ?? TearFirebaseService();

  final TearFirebaseService _service;

  /// Fetches the overall [TearCollection] summary.
  Future<TearCollection> fetchCollection() => _service.getTearCollection();

  /// Fetches the list of all preserved tears.
  Future<List<Tear>> fetchTears() => _service.getTears();

  /// Adds a new tear and returns the saved instance.
  Future<Tear> saveTear(Tear tear) => _service.addTear(tear);

  /// Deletes a tear by its unique identifier.
  Future<void> deleteTear(String id) => _service.deleteTear(id);

  /// Updates an existing tear entry.
  Future<Tear> updateTear(Tear tear) => _service.updateTear(tear);
}
