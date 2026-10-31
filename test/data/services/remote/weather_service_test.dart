import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/services/remote/weather_service.dart';

/// The clock the service reads with, so the test knows the expected readAt.
final readAt = DateTime(2026, 10, 30, 12);

WeatherService serviceFor(String baseUrl, {Duration? timeLimit}) =>
    WeatherService(
      baseUrl: baseUrl,
      now: () => readAt,
      timeLimit: timeLimit ?? const Duration(seconds: 5),
    );

Future<HttpServer> startServer(
  FutureOr<void> Function(HttpRequest request) handler,
) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen(handler);
  return server;
}

String baseUrlOf(HttpServer server) =>
    'http://${InternetAddress.loopbackIPv4.address}:${server.port}/v1/forecast';

void main() {
  test('reads and parses the weather through a background isolate', () async {
    Uri? seenUri;
    final server = await startServer((request) async {
      seenUri = request.uri;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'current': {
            'temperature_2m': 18.4,
            'precipitation': 1.5,
            'weather_code': 61,
            'is_day': 1,
          },
        }),
      );
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));

    final service = serviceFor(baseUrlOf(server));
    addTearDown(service.close);
    final weather = await service.currentWeather(
      latitude: 4.6097,
      longitude: -74.0817,
    );

    expect(weather.temperatureC, 18.4);
    expect(weather.precipitationMm, 1.5);
    expect(weather.weatherCode, 61);
    expect(weather.isDay, isTrue);
    // readAt was computed in the calling isolate and crossed into the
    // background one with the request.
    expect(weather.readAt, readAt);
    expect(seenUri?.queryParameters['latitude'], '4.61');
    expect(seenUri?.queryParameters['longitude'], '-74.08');
    expect(
      seenUri?.queryParameters['current'],
      'temperature_2m,precipitation,weather_code,is_day',
    );
  });

  test('a non-200 answer is unavailable', () async {
    final server = await startServer((request) async {
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));

    await expectLater(
      serviceFor(
        baseUrlOf(server),
      ).currentWeather(latitude: 4.6, longitude: -74),
      throwsA(
        isA<WeatherException>().having(
          (e) => e.failure,
          'failure',
          WeatherFailure.unavailable,
        ),
      ),
    );
  });

  test('no connection is offline', () async {
    // Bind and close, so the port refuses connections.
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    await server.close(force: true);

    await expectLater(
      serviceFor(
        'http://127.0.0.1:$port/v1/forecast',
      ).currentWeather(latitude: 4.6, longitude: -74),
      throwsA(
        isA<WeatherException>().having(
          (e) => e.failure,
          'failure',
          WeatherFailure.offline,
        ),
      ),
    );
  });

  test('a slow answer times out as unavailable', () async {
    final server = await startServer((request) {
      // Accepts the connection and never answers.
    });
    addTearDown(() => server.close(force: true));

    await expectLater(
      serviceFor(
        baseUrlOf(server),
        timeLimit: const Duration(milliseconds: 100),
      ).currentWeather(latitude: 4.6, longitude: -74),
      throwsA(
        isA<WeatherException>()
            .having((e) => e.failure, 'failure', WeatherFailure.unavailable)
            .having((e) => e.message, 'message', contains('too long')),
      ),
    );
  });

  test('an unreadable answer is unavailable', () async {
    final server = await startServer((request) async {
      request.response.write('not json');
      await request.response.close();
    });
    addTearDown(() => server.close(force: true));

    await expectLater(
      serviceFor(
        baseUrlOf(server),
      ).currentWeather(latitude: 4.6, longitude: -74),
      throwsA(
        isA<WeatherException>().having(
          (e) => e.failure,
          'failure',
          WeatherFailure.unavailable,
        ),
      ),
    );
  });
}
