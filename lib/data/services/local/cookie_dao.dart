// here the cookies are saved in SQLite with sqflite.

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/cookie_model.dart';
import '../../models/cookie_social_models.dart';


class CookieDao {
  CookieDao({this._factory, this._folder});

  static const table = 'cookies';

  static const pendingDeletesTable = 'pending_deletes';

  /// Gifts this phone sent, kept only here (see `SentGift`).
  static const sentGiftsTable = 'sent_gifts';

  final DatabaseFactory? _factory;

  final String? _folder;

  final Map<String, Future<Database>> _databases = {};

  Future<Database> _open(String userId) =>
      _databases[userId] ??= _openFresh(userId);

  Future<Database> _openFresh(String userId) async {
    final factory = _factory ?? databaseFactory;
    final folder = _folder ?? await getDatabasesPath();
    final path = join(folder, 'cookie_jar_$userId.db');
    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: _create,
        onUpgrade: _upgrade,
      ),
    );
  }

  static Future<void> _create(Database db, int version) async {
    await _createCookies(db);
    await _createPendingDeletes(db);
    await _createSentGifts(db);
  }

  static Future<void> _upgrade(Database db, int from, int to) async {
    if (from < 2) await _createPendingDeletes(db);
    if (from < 3) await _createSentGifts(db);
  }

  static Future<void> _createSentGifts(Database db) => db.execute('''
    CREATE TABLE $sentGiftsTable (
      share_id TEXT PRIMARY KEY,
      to_username TEXT NOT NULL,
      title TEXT NOT NULL,
      sent_at INTEGER NOT NULL
    )
  ''');

  static Future<void> _createPendingDeletes(Database db) =>
      db.execute('CREATE TABLE $pendingDeletesTable (id TEXT PRIMARY KEY)');

  static Future<void> _createCookies(Database db) => db.execute('''
    CREATE TABLE $table (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      title TEXT NOT NULL,
      title_key TEXT NOT NULL UNIQUE,
      text TEXT NOT NULL,
      state TEXT NOT NULL,
      has_image INTEGER NOT NULL,
      local_image_path TEXT,
      remote_image_url TEXT,
      last_opened_at INTEGER NOT NULL,
      received_from TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      is_synced INTEGER NOT NULL
    )
  ''');

  /// Every cookie, newest first.
  Future<List<CookieModel>> all(String userId) async {
    final db = await _open(userId);
    final rows = await db.query(table, orderBy: 'created_at DESC');
    return rows.map(CookieModel.fromDb).toList();
  }

  Future<CookieModel?> byId(String userId, String id) async {
    final db = await _open(userId);
    final rows = await db.query(table, where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : CookieModel.fromDb(rows.first);
  }

  Future<Set<String>> titleKeys(String userId) async {
    final db = await _open(userId);
    final rows = await db.query(table, columns: ['title_key']);
    return {for (final row in rows) row['title_key']! as String};
  }

  /// Throws a [DatabaseException] when the title already exists.
  Future<void> insert(CookieModel cookie) async {
    final db = await _open(cookie.userId);
    await db.insert(
      table,
      cookie.toDb(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  /// Replaces the row with the same id.
  Future<void> update(CookieModel cookie) async {
    final db = await _open(cookie.userId);
    await db.update(
      table,
      cookie.toDb(),
      where: 'id = ?',
      whereArgs: [cookie.id],
    );
  }

  Future<void> delete(String userId, String id) async {
    final db = await _open(userId);
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  /// Cookies with something still waiting to upload.
  Future<List<CookieModel>> unsynced(String userId) async {
    final db = await _open(userId);
    final rows = await db.query(table, where: 'is_synced = 0');
    return rows.map(CookieModel.fromDb).toList();
  }

  /// Remembers that [id] must be deleted from the cloud.
  Future<void> addPendingDelete(String userId, String id) async {
    final db = await _open(userId);
    await db.insert(pendingDeletesTable, {
      'id': id,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<Set<String>> pendingDeletes(String userId) async {
    final db = await _open(userId);
    final rows = await db.query(pendingDeletesTable);
    return {for (final row in rows) row['id']! as String};
  }

  Future<void> removePendingDelete(String userId, String id) async {
    final db = await _open(userId);
    await db.delete(pendingDeletesTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> addSentGift(String userId, SentGift gift) async {
    final db = await _open(userId);
    await db.insert(
      sentGiftsTable,
      gift.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Newest first.
  Future<List<SentGift>> sentGifts(String userId) async {
    final db = await _open(userId);
    final rows = await db.query(sentGiftsTable, orderBy: 'sent_at DESC');
    return rows.map(SentGift.fromDb).toList();
  }

  Future<void> removeSentGift(String userId, String shareId) async {
    final db = await _open(userId);
    await db.delete(
      sentGiftsTable,
      where: 'share_id = ?',
      whereArgs: [shareId],
    );
  }

  /// Closes every open database, on sign-out and in tests.
  Future<void> close() async {
    final open = _databases.values.toList();
    _databases.clear();
    for (final db in open) {
      await (await db).close();
    }
  }
}
