import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';


class PhotoDao {
  static final _dayFormat = DateFormat('yyyy-MM-dd');

  final Map<String, Database> _databases = {};

  Future<Database> _open(String userId) async =>
      _databases[userId] ??= await openDatabase(
        join(await getDatabasesPath(), 'photo_of_the_day_$userId.db'),
        version: 1,
        onCreate: (db, version) => db.execute(
          'CREATE TABLE photos (day TEXT PRIMARY KEY, is_synced INTEGER NOT NULL)',
        ),
      );

  Future<void> insert(String userId, DateTime day) async {
    final db = await _open(userId);
    await db.insert('photos', {
      'day': _dayFormat.format(day),
      'is_synced': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Set<DateTime>> daysBetween(
    String userId,
    DateTime first,
    DateTime last,
  ) async {
    final db = await _open(userId);
    final rows = await db.query(
      'photos',
      columns: ['day'],
      where: 'day BETWEEN ? AND ?',
      whereArgs: [_dayFormat.format(first), _dayFormat.format(last)],
    );
    return {for (final row in rows) DateTime.parse(row['day']! as String)};
  }

  Future<List<DateTime>> notSyncedDays(String userId) async {
    final db = await _open(userId);
    final rows = await db.query(
      'photos',
      columns: ['day'],
      where: 'is_synced = 0',
    );
    return [for (final row in rows) DateTime.parse(row['day']! as String)];
  }

  Future<void> markSynced(String userId, DateTime day) async {
    final db = await _open(userId);
    await db.update(
      'photos',
      {'is_synced': 1},
      where: 'day = ?',
      whereArgs: [_dayFormat.format(day)],
    );
  }
}
