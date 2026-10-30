import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

class WeatherService {
  WeatherService({
    HttpClient? httpClient,
    DateTime Function()? now,
    Duration? timeLimit,
  }) : _client = httpClient ?? HttpClient(),
       _now = now ?? DateTime.now,
       timeLimit = timeLimit ?? const Duration(seconds: 8);

  static const _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  static const _currentFields =
      'temperature_2m,precipitation,weather_code,is_day';

  final HttpClient _client;
  final DateTime Function() _now;


  final Duration timeLimit;

  Future<Weather> currentWeather({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl?latitude=${latitude.toStringAsFixed(2)}'
      '&longitude=${longitude.toStringAsFixed(2)}'
      '&current=$_currentFields',
    );
    try {
      final body = await _get(uri).timeout(timeLimit);
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic>) {
        throw const FormatException('Open-Meteo did not answer an object.');
      }
      return Weather.fromOpenMeteoJson(json, readAt: _now());
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
    }
  }

  Future<String> _get(Uri uri) async {
    final request = await _client.getUrl(uri);
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
