import 'package:sqflite/sqflite.dart';

import '../../models/fortune_card_model.dart';
import 'fortune_database.dart';

/// The cards each account shared, in sqflite: which fortune, when, where the
/// app keeps its own copy of the image, and whether the cloud has it yet.
class FortuneCardsDao {
  FortuneCardsDao({Future<Database> Function()? open})
    : _open = open ?? FortuneDatabase.open;

  final Future<Database> Function() _open;
  Future<Database>? _database;

  static const _table = 'saved_fortune_cards';

  Future<Database> get _db => _database ??= _open();

  /// The cards on the Shared list, newest first.
  Future<List<FortuneCard>> cards(String userId) async {
    final rows = await (await _db).query(
      _table,
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'saved_at DESC',
    );
    return rows.map(_cardOf).toList();
  }

  /// The card of [cookieId] on the Shared list, if any.
  Future<FortuneCard?> card(String userId, int cookieId) async {
    final rows = await (await _db).query(
      _table,
      where: 'user_id = ? AND cookie_id = ? AND is_deleted = 0',
      whereArgs: [userId, cookieId],
    );
    return rows.isEmpty ? null : _cardOf(rows.single);
  }

  /// Every card id this phone knows about, removed ones included, so the
  /// cloud does not bring back a card removed offline.
  Future<Set<int>> knownIds(String userId) async {
    final rows = await (await _db).query(
      _table,
      columns: ['cookie_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return {for (final row in rows) row['cookie_id']! as int};
  }

  /// Saves a card; [synced] when it came from the cloud.
  Future<void> save(
    String userId,
    FortuneCard card, {
    bool synced = false,
  }) async {
    await (await _db).insert(_table, {
      'user_id': userId,
      'cookie_id': card.cookieId,
      'quote': card.quote,
      'local_path': card.localPath,
      'saved_at': card.savedAt.millisecondsSinceEpoch,
      'is_synced': synced ? 1 : 0,
      'is_deleted': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Hides it at once and leaves it pending, so the cloud deletes it too.
  Future<void> markRemoved(String userId, int cookieId) async {
    await (await _db).update(
      _table,
      {'is_deleted': 1, 'is_synced': 0},
      where: 'user_id = ? AND cookie_id = ?',
      whereArgs: [userId, cookieId],
    );
  }

  /// Changes the cloud does not have yet: new cards and removed ones.
  Future<List<({FortuneCard card, bool removed})>> pending(
    String userId,
  ) async {
    final rows = await (await _db).query(
      _table,
      where: 'user_id = ? AND is_synced = 0',
      whereArgs: [userId],
    );
    return [
      for (final row in rows)
        (card: _cardOf(row), removed: row['is_deleted'] == 1),
    ];
  }

  Future<void> markSynced(String userId, int cookieId) async {
    await (await _db).update(
      _table,
      {'is_synced': 1},
      where: 'user_id = ? AND cookie_id = ?',
      whereArgs: [userId, cookieId],
    );
  }

  /// Gone everywhere, so the row is no longer needed.
  Future<void> delete(String userId, int cookieId) async {
    await (await _db).delete(
      _table,
      where: 'user_id = ? AND cookie_id = ?',
      whereArgs: [userId, cookieId],
    );
  }

  static FortuneCard _cardOf(Map<String, Object?> row) => FortuneCard(
    cookieId: row['cookie_id']! as int,
    quote: row['quote']! as String,
    localPath: row['local_path']! as String,
    savedAt: DateTime.fromMillisecondsSinceEpoch(row['saved_at']! as int),
  );
}
