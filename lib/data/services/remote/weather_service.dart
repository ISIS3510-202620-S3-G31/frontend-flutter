import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import '../../models/weather_model.dart';

/// Why the weather could not be read.
enum WeatherFailure {
  /// No connection: asking again once it comes back should work.
  offline,

  /// The service took too long, failed, or answered something unreadable.
  unavailable,
}

class WeatherException implements Exception {
  const WeatherException(this.failure, this.message);

  final WeatherFailure failure;
  final String message;

  @override
  String toString() => 'WeatherException(${failure.name}: $message)';
}

/// What the app needs from a weather API
abstract interface class WeatherFetcher {
  Future<Weather> currentWeather({
    required double latitude,
    required double longitude,
  });

  /// Releases whatever the fetcher holds between reads. Fakes have nothing to release.
  void close();
}

/// Reads the weather from Open-Meteo.
class WeatherService implements WeatherFetcher {
  WeatherService({
    String? baseUrl,
    DateTime Function()? now,
    Duration? timeLimit,
  }) : _baseUrl = baseUrl ?? 'https://api.open-meteo.com/v1/forecast',
       _now = now ?? DateTime.now,
       timeLimit = timeLimit ?? const Duration(seconds: 8);

  static const _currentFields =
      'temperature_2m,precipitation,weather_code,is_day';

  final String _baseUrl;
  final DateTime Function() _now;

  final Duration timeLimit;

  @override
  Future<Weather> currentWeather({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl?latitude=${latitude.toStringAsFixed(2)}'
      '&longitude=${longitude.toStringAsFixed(2)}'
      '&current=$_currentFields',
    );
    // readAt is computed here, in this isolate, so the closure sent to the background isolate captures only sendable values (Uri, Duration, DateTime) and the static [_read].
    final readAt = _now();
    return Isolate.run(
      () => _read(uri, timeLimit, readAt),
      debugName: 'weather-read',
    );
  }

  /// The read itself, executed inside [Isolate.run].
  static Future<Weather> _read(
    Uri uri,
    Duration timeLimit,
    DateTime readAt,
  ) async {
    final client = HttpClient();
    try {
      final body = await _get(client, uri).timeout(timeLimit);
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic>) {
        throw const FormatException('Open-Meteo did not answer an object.');
      }
      return Weather.fromOpenMeteoJson(json, readAt: readAt);
    } on SocketException catch (error) {
      throw WeatherException(WeatherFailure.offline, error.message);
    } on IOException catch (error) {
      throw WeatherException(WeatherFailure.unavailable, '$error');
    } on TimeoutException {
      throw const WeatherException(
        WeatherFailure.unavailable,
        'Open-Meteo took too long to answer.',
      );
    } on FormatException catch (error) {
      throw WeatherException(WeatherFailure.unavailable, error.message);
    } finally {
      client.close();
    }
  }

  /// Nothing is held between reads, each one closes its own client inside its isolate, so there is nothing to release.
  @override
  void close() {}

  static Future<String> _get(HttpClient client, Uri uri) async {
    final request = await client.getUrl(uri);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Open-Meteo answered ${response.statusCode}',
        uri: uri,
      );
    }
    return body;
  }
}
