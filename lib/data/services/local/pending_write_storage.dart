import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../models/pending_write_model.dart';


/// [WeatherLocalStorageService].
class PendingWriteStorage {
  PendingWriteStorage({Database? database}) : _db = database;

  Database? _db;
  bool _useFallback = false;
  final Map<String, PendingWrite> _inMemoryFallback = {};

  Future<Database?> _getDatabase() async {
    if (_useFallback) return null;
    if (_db != null && _db!.isOpen) return _db;
    try {
      _db = await openDatabase(
        p.join(await getDatabasesPath(), 'pending_writes.db'),
        version: 1,
        onCreate: (db, version) => db.execute('''
          CREATE TABLE pending_writes (
            path TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            data TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        '''),
      );
      return _db;
    } catch (_) {
      _useFallback = true;
      return null;
    }
  }

  /// Saving the same path again replaces it: only the latest version is sent.
  Future<void> add(PendingWrite write) async {
    final db = await _getDatabase();
    if (db == null) {
      _inMemoryFallback[write.path] = write;
      return;
    }
    await db.insert('pending_writes', {
      'path': write.path,
      'user_id': write.userId,
      'data': jsonEncode(write.data),
      'created_at': write.createdAt.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// The user's waiting writes, oldest first.
  Future<List<PendingWrite>> pendingFor(String userId) async {
    final db = await _getDatabase();
    if (db == null) {
      return _inMemoryFallback.values
          .where((write) => write.userId == userId)
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    final rows = await db.query(
      'pending_writes',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );
    return [
      for (final row in rows)
        PendingWrite(
          path: row['path'] as String,
          userId: row['user_id'] as String,
          data: jsonDecode(row['data'] as String) as Map<String, Object?>,
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            row['created_at'] as int,
          ),
        ),
    ];
  }

  Future<void> remove(String path) async {
    final db = await _getDatabase();
    if (db == null) {
      _inMemoryFallback.remove(path);
      return;
    }
    await db.delete('pending_writes', where: 'path = ?', whereArgs: [path]);
  }
}
