import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/wish_model.dart';

/// The wishes of the Rapunzel's lantern tool, in sqflite: one database per
/// account, the same split as [PhotoDao]. `is_synced` marks the rows that
/// still have to go up to Firestore through the pending-writes queue.
class WishDao {
  WishDao({Future<Database> Function()? open})
    : _open = open ?? _openDefault;

  final Future<Database> Function() _open;
  final Map<String, Database> _databases = {};

  static Future<Database> _openDefault() async => openDatabase(
    join(await getDatabasesPath(), 'rapunzel_wishes.db'),
    version: 1,
    onCreate: createSchema,
  );

  /// The wishes table, also used by tests with an in-memory database.
  static Future<void> createSchema(Database db, [int? version]) => db.execute('''
    CREATE TABLE wishes (
      user_id TEXT NOT NULL,
      id TEXT NOT NULL,
      text TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      released INTEGER NOT NULL DEFAULT 0,
      released_at INTEGER,
      is_synced INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (user_id, id)
    )
  ''');

  Future<Database> _openFor(String userId) async =>
      _databases[userId] ??= await _open();

  /// All the wishes of the account, newest first.
  Future<List<Wish>> all(String userId) async {
    final rows = await (await _openFor(userId)).query(
      'wishes',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return [
      for (final row in rows)
        Wish(
          id: row['id']! as String,
          text: row['text']! as String,
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            row['created_at']! as int,
          ),
          released: (row['released']! as int) == 1,
          releasedAt: (row['released_at'] as int?) != null
              ? DateTime.fromMillisecondsSinceEpoch(row['released_at']! as int)
              : null,
        ),
    ];
  }

  /// Saves a wish, new or changed, and marks it as not synced yet.
  Future<void> upsert(String userId, Wish wish) async {
    await (await _openFor(userId)).insert('wishes', {
      'user_id': userId,
      'id': wish.id,
      'text': wish.text,
      'created_at': wish.createdAt.millisecondsSinceEpoch,
      'released': wish.released ? 1 : 0,
      'released_at': wish.releasedAt?.millisecondsSinceEpoch,
      'is_synced': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> delete(String userId, String id) async {
    await (await _openFor(userId)).delete(
      'wishes',
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, id],
    );
  }

  /// The wishes that still have to reach Firestore.
  Future<List<Wish>> notSynced(String userId) async {
    final rows = await (await _openFor(userId)).query(
      'wishes',
      where: 'user_id = ? AND is_synced = 0',
      whereArgs: [userId],
    );
    return [
      for (final row in rows)
        Wish(
          id: row['id']! as String,
          text: row['text']! as String,
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            row['created_at']! as int,
          ),
          released: (row['released']! as int) == 1,
          releasedAt: (row['released_at'] as int?) != null
              ? DateTime.fromMillisecondsSinceEpoch(row['released_at']! as int)
              : null,
        ),
    ];
  }

  Future<void> markSynced(String userId, String id) async {
    await (await _openFor(userId)).update(
      'wishes',
      {'is_synced': 1},
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, id],
    );
  }
}
