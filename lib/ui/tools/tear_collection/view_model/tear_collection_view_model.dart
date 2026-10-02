import 'package:flutter/material.dart';

import '../../../../data/models/tear_model.dart';
import '../../../../data/repositories/tear_repository.dart';
import '../../../core/theme/app_colors.dart';

/// ViewModel managing the Tear Collector feature state and business logic.
class TearCollectionViewModel extends ChangeNotifier {
  TearCollectionViewModel({TearRepository? repository})
      : _repository = repository ?? TearRepository();

  final TearRepository _repository;

  TearCollection _collection = const TearCollection();
  Tear? _selectedTear;
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  /// The aggregate tear collection state.
  TearCollection get tearCollection => _collection;

  /// Alias for [tearCollection].
  TearCollection get collection => _collection;

  /// Total count of tears logged.
  int get totalTearsLogged => _collection.totalTearsLogged;

  /// Average relief level across all logged tears (0.0 to 10.0).
  double get averageReliefLevel => _collection.averageReliefLevel;

  /// The list of logged tears.
  List<Tear> get tears => _collection.tears;

  /// Currently selected tear for detail inspection.
  Tear? get selectedTear => _selectedTear;

  /// Whether an async operation is currently executing.
  bool get isLoading => _isLoading;

  /// Active error message, if any.
  String? get errorMessage => _errorMessage;

  /// Whether the tear collection currently has no entries.
  bool get isEmpty => _collection.tears.isEmpty;

  /// Loads the tear collection and tears list from the repository.
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    _notify();

    try {
      final fetchedCollection = await _repository.fetchCollection();
      final fetchedTears = await _repository.fetchTears();

      // Ensure collection summary matches the actual fetched tears
      _collection = fetchedCollection.tears.isNotEmpty
          ? fetchedCollection
          : TearCollection.fromTears(fetchedTears);
    } catch (e) {
      _errorMessage = 'Failed to load tear collection: $e';
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  /// Logs and preserves a new tear entry.
  Future<Tear?> logTear({
    required String memoryTitle,
    required String cryingReason,
    required int reliefLevel,
    required String reflectionNote,
    DateTime? timestamp,
    Color color = AppColors.secondary,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _notify();

    try {
      final newTear = Tear(
        id: '', // Will be assigned by service/Firestore
        timestamp: timestamp ?? DateTime.now(),
        memoryTitle: memoryTitle,
        cryingReason: cryingReason,
        reliefLevel: reliefLevel.clamp(0, 10),
        reflectionNote: reflectionNote,
        color: color,
      );

      final savedTear = await _repository.saveTear(newTear);

      // Recalculate collection with newly added tear
      final updatedList = [savedTear, ..._collection.tears];
      _collection = TearCollection.fromTears(updatedList);

      _notify();
      return savedTear;
    } catch (e) {
      _errorMessage = 'Failed to preserve tear: $e';
      _notify();
      return null;
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  /// Deletes a preserved tear by its [id].
  Future<bool> deleteTear(String id) async {
    _isLoading = true;
    _errorMessage = null;
    _notify();

    try {
      await _repository.deleteTear(id);

      final updatedList = _collection.tears.where((t) => t.id != id).toList();
      _collection = TearCollection.fromTears(updatedList);

      if (_selectedTear?.id == id) {
        _selectedTear = null;
      }

      _notify();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete tear: $e';
      _notify();
      return false;
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  /// Sets the currently inspected tear.
  void selectTear(Tear? tear) {
    _selectedTear = tear;
    _notify();
  }

  /// Clears any active error message.
  void clearError() {
    _errorMessage = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Type alias allowing [TearCollectorViewModel] as requested by user.
typedef TearCollectorViewModel = TearCollectionViewModel;
