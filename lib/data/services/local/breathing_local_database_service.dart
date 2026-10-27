import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../models/breathing_music_model.dart';

class BreathingLocalDatabaseService {
  BreathingLocalDatabaseService({Database? database}) : _db = database;

  Database? _db;
  final Map<String, BreathingMusicTrack> _inMemoryFallback = {};
  final Map<String, String> _inMemorySettingsFallback = {};
  bool _useFallback = false;

  Future<Database?> _getDatabase() async {
    if (_useFallback) return null;
    if (_db != null && _db!.isOpen) return _db;

    try {
      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, 'breathing_music.db');
      _db = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE breathing_tracks (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              artist TEXT NOT NULL,
              audio_url TEXT NOT NULL,
              duration INTEGER NOT NULL,
              cached_file_path TEXT,
              is_cached INTEGER NOT NULL DEFAULT 0,
              last_played_at INTEGER
            )
          ''');

          await db.execute('''
            CREATE TABLE breathing_music_settings (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
        },
      );
      return _db;
    } catch (_) {
      _useFallback = true;
      return null;
    }
  }

  /// Inserts or updates multiple tracks.
  Future<void> saveTracks(List<BreathingMusicTrack> tracks) async {
    final db = await _getDatabase();
    if (db == null) {
      for (final track in tracks) {
        _inMemoryFallback[track.id] = track;
      }
      return;
    }

    final batch = db.batch();
    for (final track in tracks) {
      batch.insert(
        'breathing_tracks',
        track.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Retrieves all persisted tracks.
  Future<List<BreathingMusicTrack>> getTracks() async {
    final db = await _getDatabase();
    if (db == null) {
      return _inMemoryFallback.values.toList();
    }

    final maps = await db.query(
      'breathing_tracks',
      orderBy: 'is_cached DESC, last_played_at DESC',
    );
    return maps.map((map) => BreathingMusicTrack.fromMap(map)).toList();
  }

  /// Retrieves a single track by its ID.
  Future<BreathingMusicTrack?> getTrack(String id) async {
    final db = await _getDatabase();
    if (db == null) {
      return _inMemoryFallback[id];
    }

    final maps = await db.query(
      'breathing_tracks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BreathingMusicTrack.fromMap(maps.first);
  }

  /// Updates the cached status and file path of a track.
  Future<void> updateTrackCacheStatus(
    String id, {
    required bool isCached,
    String? cachedFilePath,
  }) async {
    final db = await _getDatabase();
    if (db == null) {
      final existing = _inMemoryFallback[id];
      if (existing != null) {
        _inMemoryFallback[id] = existing.copyWith(
          isCached: isCached,
          cachedFilePath: cachedFilePath,
        );
      }
      return;
    }

    await db.update(
      'breathing_tracks',
      {'is_cached': isCached ? 1 : 0, 'cached_file_path': cachedFilePath},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Records the timestamp when a track was played.
  Future<void> recordTrackPlayed(String id) async {
    final now = DateTime.now();
    final db = await _getDatabase();
    if (db == null) {
      final existing = _inMemoryFallback[id];
      if (existing != null) {
        _inMemoryFallback[id] = existing.copyWith(lastPlayedAt: now);
      }
      return;
    }

    await db.update(
      'breathing_tracks',
      {'last_played_at': now.millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Gets the selected track ID from settings.
  Future<String?> getSelectedTrackId() async {
    final db = await _getDatabase();
    if (db == null) {
      return _inMemorySettingsFallback['selected_track_id'];
    }

    final result = await db.query(
      'breathing_music_settings',
      where: 'key = ?',
      whereArgs: ['selected_track_id'],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }

  /// Sets the selected track ID in settings.
  Future<void> setSelectedTrackId(String id) async {
    final db = await _getDatabase();
    if (db == null) {
      _inMemorySettingsFallback['selected_track_id'] = id;
      return;
    }

    await db.insert('breathing_music_settings', {
      'key': 'selected_track_id',
      'value': id,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Gets whether music playback is enabled.
  Future<bool> isMusicEnabled() async {
    final db = await _getDatabase();
    if (db == null) {
      return _inMemorySettingsFallback['music_enabled'] != 'false';
    }

    final result = await db.query(
      'breathing_music_settings',
      where: 'key = ?',
      whereArgs: ['music_enabled'],
      limit: 1,
    );
    if (result.isEmpty) return true;
    return result.first['value'] != 'false';
  }

  /// Sets whether music playback is enabled.
  Future<void> setMusicEnabled(bool enabled) async {
    final db = await _getDatabase();
    if (db == null) {
      _inMemorySettingsFallback['music_enabled'] = enabled.toString();
      return;
    }

    await db.insert('breathing_music_settings', {
      'key': 'music_enabled',
      'value': enabled.toString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Closes database connection.
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
