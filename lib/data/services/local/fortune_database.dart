import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// The Fortune Cookie's sqflite database, with one table per list: the
/// fortunes kept and the cards shared. Rows carry the account they belong to.
abstract final class FortuneDatabase {
  static const _version = 2;

  static Future<Database> open() async => openDatabase(
    join(await getDatabasesPath(), 'fortune.db'),
    version: _version,
    onCreate: create,
    onUpgrade: upgrade,
  );

  static Future<void> create(Database db, int version) async {
    await _createFavorites(db);
    await _createCards(db);
  }

  /// Version 1 only had the kept fortunes.
  static Future<void> upgrade(Database db, int from, int to) async {
    if (from < 2) await _createCards(db);
  }

  static Future<void> _createFavorites(Database db) => db.execute('''
    CREATE TABLE favorite_fortunes (
      user_id TEXT NOT NULL,
      id INTEGER NOT NULL,
      quote TEXT NOT NULL,
      category TEXT NOT NULL,
      saved_at INTEGER NOT NULL,
      is_synced INTEGER NOT NULL DEFAULT 0,
      is_deleted INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (user_id, id)
    )''');

  /// One card per fortune: its image is drawn once and reused.
  static Future<void> _createCards(Database db) => db.execute('''
    CREATE TABLE saved_fortune_cards (
      user_id TEXT NOT NULL,
      cookie_id INTEGER NOT NULL,
      quote TEXT NOT NULL,
      local_path TEXT NOT NULL,
      saved_at INTEGER NOT NULL,
      is_synced INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (user_id, cookie_id)
    )''');
}
