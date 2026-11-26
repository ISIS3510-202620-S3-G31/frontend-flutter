import 'package:sqflite/sqflite.dart';

import '../../models/fortune_model.dart';
import 'fortune_database.dart';

/// The fortunes each account kept, in sqflite: the source of truth on the
/// phone, with Firestore as the backup.
///
/// The same columns as the Kotlin app's Room table. `is_synced` marks what
/// still has to go up; a fortune removed offline stays as `is_deleted` until
/// Firestore deletes it too, so it does not come back on the next download.
class FortuneFavoritesDao {
  FortuneFavoritesDao({Future<Database> Function()? open})
    : _open = open ?? FortuneDatabase.open;

  final Future<Database> Function() _open;
  Future<Database>? _database;

  static const _table = 'favorite_fortunes';

  Future<Database> get _db => _database ??= _open();

  /// What the account keeps, newest first.
  Future<List<Fortune>> favorites(String userId) async {
    final rows = await (await _db).query(
      _table,
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'saved_at DESC',
    );
    return rows.map(_fortuneOf).toList();
  }

  /// Keeps [fortune], or keeps it again if it had been removed.
  Future<void> keep(String userId, Fortune fortune) async {
    await (await _db).insert(_table, {
      'user_id': userId,
      'id': fortune.id,
      'quote': fortune.quote,
      'category': fortune.category,
      'saved_at': fortune.savedAt.millisecondsSinceEpoch,
      'is_synced': 0,
      'is_deleted': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Hides it at once and leaves it pending, so Firestore deletes it too.
  Future<void> markRemoved(String userId, int id) async {
    await (await _db).update(
      _table,
      {'is_deleted': 1, 'is_synced': 0},
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, id],
    );
  }

  /// Changes not in Firestore yet: kept or removed.
  Future<List<({Fortune fortune, bool removed})>> pending(String userId) async {
    final rows = await (await _db).query(
      _table,
      where: 'user_id = ? AND is_synced = 0',
      whereArgs: [userId],
    );
    return [
      for (final row in rows)
        (fortune: _fortuneOf(row), removed: row['is_deleted'] == 1),
    ];
  }

  Future<void> markSynced(String userId, int id) async {
    await (await _db).update(
      _table,
      {'is_synced': 1},
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, id],
    );
  }

  /// Gone from Firestore as well, so the row is no longer needed.
  Future<void> delete(String userId, int id) async {
    await (await _db).delete(
      _table,
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, id],
    );
  }

  /// Adds what another phone kept. Anything this phone already has, even
  /// removed and pending, wins: a fortune let go offline is not revived.
  Future<void> addFromAccount(String userId, List<Fortune> fortunes) async {
    final db = await _db;
    final batch = db.batch();
    for (final fortune in fortunes) {
      batch.insert(_table, {
        'user_id': userId,
        'id': fortune.id,
        'quote': fortune.quote,
        'category': fortune.category,
        'saved_at': fortune.savedAt.millisecondsSinceEpoch,
        'is_synced': 1,
        'is_deleted': 0,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  static Fortune _fortuneOf(Map<String, Object?> row) => Fortune(
    id: row['id']! as int,
    quote: row['quote']! as String,
    category: row['category']! as String,
    savedAt: DateTime.fromMillisecondsSinceEpoch(row['saved_at']! as int),
  );
}
