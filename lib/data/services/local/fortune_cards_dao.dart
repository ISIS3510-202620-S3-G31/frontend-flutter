import 'package:sqflite/sqflite.dart';

import '../../models/fortune_card_model.dart';
import 'fortune_database.dart';

/// The cards each account shared, in sqflite: which fortune, when, and where
/// the app keeps its own copy of the image.
class FortuneCardsDao {
  FortuneCardsDao({Future<Database> Function()? open})
    : _open = open ?? FortuneDatabase.open;

  final Future<Database> Function() _open;
  Future<Database>? _database;

  static const _table = 'saved_fortune_cards';

  Future<Database> get _db => _database ??= _open();

  /// Newest first.
  Future<List<FortuneCard>> cards(String userId) async {
    final rows = await (await _db).query(
      _table,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'saved_at DESC',
    );
    return rows.map(_cardOf).toList();
  }

  Future<FortuneCard?> card(String userId, int cookieId) async {
    final rows = await (await _db).query(
      _table,
      where: 'user_id = ? AND cookie_id = ?',
      whereArgs: [userId, cookieId],
    );
    return rows.isEmpty ? null : _cardOf(rows.single);
  }

  Future<void> save(String userId, FortuneCard card) async {
    await (await _db).insert(_table, {
      'user_id': userId,
      'cookie_id': card.cookieId,
      'quote': card.quote,
      'local_path': card.localPath,
      'saved_at': card.savedAt.millisecondsSinceEpoch,
      'is_synced': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

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
