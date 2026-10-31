import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../models/weather_model.dart';


abstract interface class WeatherStorage {
  Future<void> saveLastWeather(Weather weather);

  Future<Weather?> lastWeather();
}


class WeatherLocalStorageService implements WeatherStorage {
  WeatherLocalStorageService({Database? database}) : _db = database;

  Database? _db;
  Weather? _inMemoryFallback;
  bool _useFallback = false;

  Future<Database?> _getDatabase() async {
    if (_useFallback) return null;
    if (_db != null && _db!.isOpen) return _db;

    try {
      final dbPath = await getDatabasesPath();
      _db = await openDatabase(
        p.join(dbPath, 'weather.db'),
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE last_weather (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              temperature_c REAL NOT NULL,
              precipitation_mm REAL NOT NULL,
              weather_code INTEGER NOT NULL,
              is_day INTEGER NOT NULL,
              read_at INTEGER NOT NULL
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

  @override
  Future<void> saveLastWeather(Weather weather) async {
    final db = await _getDatabase();
    if (db == null) {
      _inMemoryFallback = weather;
      return;
    }
    await db.insert(
      'last_weather',
      {
        'id': 1,
        'temperature_c': weather.temperatureC,
        'precipitation_mm': weather.precipitationMm,
        'weather_code': weather.weatherCode,
        'is_day': weather.isDay ? 1 : 0,
        'read_at': weather.readAt.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<Weather?> lastWeather() async {
    final db = await _getDatabase();
    if (db == null) return _inMemoryFallback;

    final rows = await db.query('last_weather', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return Weather(
      temperatureC: (row['temperature_c'] as num).toDouble(),
      precipitationMm: (row['precipitation_mm'] as num).toDouble(),
      weatherCode: (row['weather_code'] as num).toInt(),
      isDay: (row['is_day'] as num) != 0,
      readAt: DateTime.fromMillisecondsSinceEpoch(row['read_at'] as int),
    );
  }
}
