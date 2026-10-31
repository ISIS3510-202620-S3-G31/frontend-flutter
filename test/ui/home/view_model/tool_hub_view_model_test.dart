import 'dart:async';
import 'dart:collection';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/models/recommendation_model.dart';
import 'package:frontend_flutter/data/models/user_model.dart';
import 'package:frontend_flutter/data/models/weather_model.dart';
import 'package:frontend_flutter/data/repositories/auth_repository.dart';
import 'package:frontend_flutter/data/repositories/recommendation_log_repository.dart';
import 'package:frontend_flutter/data/repositories/stats_repository.dart';
import 'package:frontend_flutter/data/repositories/tool_repository.dart';
import 'package:frontend_flutter/data/repositories/weather_repository.dart';
import 'package:frontend_flutter/data/services/location_service.dart';
import 'package:frontend_flutter/data/services/remote/weather_service.dart';
import 'package:frontend_flutter/domain/recommendation/tool_recommender.dart';
import 'package:frontend_flutter/ui/home/view_model/tool_hub_view_model.dart';

/// The poll interval the tests run on: long enough to be a timer, short
/// enough to elapse in a fake clock.
const interval = Duration(milliseconds: 100);

/// Answers weather reads from a queue, so a test decides what each tick sees.
class FakeWeatherRepository extends WeatherRepository {
  FakeWeatherRepository() : super(service: _NoopFetcher());

  final Queue<WeatherReading> _readings = Queue();
  int reads = 0;
  bool disposed = false;

  /// While set and not completed, every read waits on it: a read that stays
  /// in flight across ticks.
  Completer<WeatherReading>? hold;

  /// When set, reads fail with it.
  Object? error;

  void enqueue(WeatherReading reading) => _readings.add(reading);

  @override
  Future<WeatherReading> currentWeather() {
    reads++;
    final held = hold;
    if (held != null && !held.isCompleted) return held.future;
    final failure = error;
    if (failure != null) return Future.error(failure);
    if (_readings.isEmpty) {
      return Future.error(Exception('no reading queued'));
    }
    return Future.value(_readings.removeFirst());
  }

  @override
  void dispose() {
    disposed = true;
  }
}

class _NoopFetcher implements WeatherFetcher {
  @override
  Future<Weather> currentWeather({
    required double latitude,
    required double longitude,
  }) => Future.error(Exception('the fake repository answers instead'));

  @override
  void close() {}
}

class FakeStatsRepository extends StatsRepository {
  FakeStatsRepository() : super();

  @override
  Future<StatsData> dataSince(DateTime from) async =>
      const StatsData(checkIns: [], sessions: []);
}

class FakeRecommendationLogRepository extends RecommendationLogRepository {
  FakeRecommendationLogRepository() : super();

  int shown = 0;
  final List<(String id, String toolId)> shownLog = [];
  final List<(String id, String toolId)> taps = [];
  final List<(String id, String toolId)> opens = [];

  @override
  String logShown(Recommendation recommendation, {required String strategy}) {
    shown++;
    final id = 'log-$shown';
    shownLog.add((id, recommendation.tool.id));
    return id;
  }

  @override
  void logOpened(String id, {required String toolId}) {
    opens.add((id, toolId));
  }

  @override
  void logTapped(String id, {required String toolId}) {
    taps.add((id, toolId));
  }
}

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository() : super();

  @override
  Future<UserModel?> getCurrentUserProfile() async => null;
}

WeatherReading ready(Weather weather) =>
    WeatherReading(outcome: WeatherOutcome.ready, weather: weather);

Weather weatherAt({
  required double tempC,
  int code = 0,
  double rainMm = 0,
  bool isDay = true,
}) => Weather(
  temperatureC: tempC,
  precipitationMm: rainMm,
  weatherCode: code,
  isDay: isDay,
  readAt: DateTime(2026, 10, 30, 12),
);

/// Clear and sunny, so the weather strategy picks the photo tool.
Weather get sunny => weatherAt(tempC: 20);

/// Rain, so the weather strategy picks the breathing tool.
Weather get rainy => weatherAt(tempC: 18, code: 61, rainMm: 1.5);

ToolHubViewModel viewModel(
  FakeWeatherRepository weather, {
  FakeRecommendationLogRepository? recommendationLog,
}) => ToolHubViewModel(
  repository: const ToolRepository(),
  statsRepository: FakeStatsRepository(),
  recommender: ToolRecommender(),
  recommendationLog: recommendationLog ?? FakeRecommendationLogRepository(),
  auth: FakeAuthRepository(),
  weather: weather,
  weatherPollInterval: interval,
);

void main() {
  group('poll interval', () {
    test('sits inside the 30-60 minute window, past the location cache', () {
      final poll = ToolHubViewModel.defaultWeatherPollInterval;
      // The location behind the weather is cached for 30 minutes, so polling
      // faster would only re-read the same place.
      expect(poll, greaterThan(LocationService().freshness));
      expect(poll, greaterThanOrEqualTo(const Duration(minutes: 30)));
      expect(poll, lessThanOrEqualTo(const Duration(minutes: 60)));
    });
  });

  group('polling', () {
    test(
      'the first load reads once, then the timer keeps the weather current',
      () {
        fakeAsync((async) async {
          final rain = rainy;
          final weather = FakeWeatherRepository()
            ..enqueue(ready(sunny))
            ..enqueue(ready(rain));
          final vm = viewModel(weather);

          await vm.loadRecommendation();
          expect(weather.reads, 1);
          expect(vm.weatherRecommendation?.tool.id, 'photo');

          vm.startWeatherPolling();
          async.elapse(interval);
          expect(weather.reads, 2);
          expect(vm.weatherRecommendation?.tool.id, 'breathing');
          expect(vm.weatherReading?.weather, same(rain));
        });
      },
    );

    test('a tick that changes only the temperature does not notify', () {
      fakeAsync((async) {
        final weather = FakeWeatherRepository()
          ..enqueue(ready(sunny))
          ..enqueue(ready(weatherAt(tempC: 25)));
        final vm = viewModel(weather);
        var notifications = 0;
        vm.addListener(() => notifications++);

        vm.startWeatherPolling();
        async.elapse(interval);
        expect(vm.weatherRecommendation?.tool.id, 'photo');
        final afterFirstTick = notifications;

        // Same condition, warmer: the read happens, the card does not flicker.
        async.elapse(interval);
        expect(weather.reads, 2);
        expect(notifications, afterFirstTick);
        expect(vm.weatherRecommendation?.tool.id, 'photo');
      });
    });

    test('a changed condition refreshes the recommendation and notifies', () {
      fakeAsync((async) {
        final weather = FakeWeatherRepository()
          ..enqueue(ready(sunny))
          ..enqueue(ready(rainy));
        final vm = viewModel(weather);
        var notifications = 0;
        vm.addListener(() => notifications++);

        vm.startWeatherPolling();
        async.elapse(interval);
        expect(vm.weatherRecommendation?.tool.id, 'photo');
        final afterFirstTick = notifications;

        async.elapse(interval);
        expect(weather.reads, 2);
        expect(notifications, greaterThan(afterFirstTick));
        expect(vm.weatherRecommendation?.tool.id, 'breathing');
      });
    });

    test('a tick while a read is in flight does not start another read', () {
      fakeAsync((async) {
        final weather = FakeWeatherRepository();
        final hold = Completer<WeatherReading>();
        weather.hold = hold;
        final vm = viewModel(weather);

        vm.startWeatherPolling();
        async.elapse(interval); // tick 1: the read starts and stays in flight
        async.elapse(interval); // tick 2: joins the in-flight read
        expect(weather.reads, 1);

        hold.complete(ready(rainy));
        async.flushMicrotasks();
        expect(weather.reads, 1);
        expect(vm.weatherRecommendation?.tool.id, 'breathing');
      });
    });

    test(
      'a failed read keeps the last known weather and the recommendation',
      () {
        fakeAsync((async) {
          final weather = FakeWeatherRepository()..enqueue(ready(rainy));
          final vm = viewModel(weather);

          vm.startWeatherPolling();
          async.elapse(interval);
          expect(vm.weatherRecommendation?.tool.id, 'breathing');

          // The API is down: the read fails, nothing on screen is cleared.
          weather.error = Exception('network down');
          async.elapse(interval);
          expect(weather.reads, 2);
          expect(vm.weatherRecommendation?.tool.id, 'breathing');
          expect(vm.weatherReading?.outcome, WeatherOutcome.ready);

          // Offline with the last known weather: same condition, no flicker,
          // but the reading says where the weather came from.
          weather.error = null;
          weather.enqueue(
            WeatherReading(outcome: WeatherOutcome.offline, weather: rainy),
          );
          async.elapse(interval);
          expect(weather.reads, 3);
          expect(vm.weatherRecommendation?.tool.id, 'breathing');
          expect(vm.weatherReading?.outcome, WeatherOutcome.offline);
        });
      },
    );

    test('dispose stops the timer', () {
      fakeAsync((async) {
        final weather = FakeWeatherRepository()
          ..enqueue(ready(rainy))
          ..enqueue(ready(rainy))
          ..enqueue(ready(rainy));
        final vm = viewModel(weather);

        vm.startWeatherPolling();
        async.elapse(interval);
        expect(weather.reads, 1);

        vm.dispose();
        async.elapse(interval * 5);
        expect(weather.reads, 1);
        expect(weather.disposed, isTrue);
      });
    });
  });

  group('app lifecycle', () {
    test('polling pauses in the background and resumes on return', () {
      fakeAsync((async) {
        final weather = FakeWeatherRepository()
          ..enqueue(ready(rainy))
          ..enqueue(ready(rainy))
          ..enqueue(ready(rainy));
        final vm = viewModel(weather);

        vm.startWeatherPolling();
        async.elapse(interval);
        expect(weather.reads, 1);

        vm.onAppLifecycleChanged(AppLifecycleState.paused);
        async.elapse(interval * 3);
        expect(weather.reads, 1);

        // Back in the foreground: one read at once, then the timer again.
        vm.onAppLifecycleChanged(AppLifecycleState.resumed);
        async.flushMicrotasks();
        expect(weather.reads, 2);
        async.elapse(interval);
        expect(weather.reads, 3);
      });
    });

    test('resuming without a visible screen does not start polling', () {
      fakeAsync((async) {
        final weather = FakeWeatherRepository()..enqueue(ready(rainy));
        final vm = viewModel(weather);

        vm.onAppLifecycleChanged(AppLifecycleState.paused);
        vm.onAppLifecycleChanged(AppLifecycleState.resumed);
        async.flushMicrotasks();
        async.elapse(interval * 3);
        expect(weather.reads, 0);
      });
    });
  });

  group('recommendation engagement analytics', () {
    test('tapping the recommended card logs a tap tied to its impression', () async {
      final weather = FakeWeatherRepository()..enqueue(ready(sunny));
      final log = FakeRecommendationLogRepository();
      final vm = viewModel(weather, recommendationLog: log);

      await vm.loadRecommendation();
      final recommendation = vm.recommendation;
      expect(recommendation, isNotNull);
      expect(log.shown, greaterThan(0));

      vm.openRecommendation();

      expect(log.taps, hasLength(1));
      expect(log.taps.single.$2, recommendation!.tool.id);
      // The tap points back at the impression that was shown for it.
      expect(log.shownLog.map((e) => e.$1), contains(log.taps.single.$1));
      expect(log.opens, hasLength(1));

      // Tapping the same card again does not log a second tap.
      vm.openRecommendation();
      expect(log.taps, hasLength(1));
    });

    test('tapping the weather card logs its own tap', () async {
      final weather = FakeWeatherRepository()..enqueue(ready(rainy));
      final log = FakeRecommendationLogRepository();
      final vm = viewModel(weather, recommendationLog: log);

      await vm.loadRecommendation();
      final recommendation = vm.weatherRecommendation;
      expect(recommendation, isNotNull);

      vm.openWeatherRecommendation();

      expect(log.taps, hasLength(1));
      expect(log.taps.single.$2, recommendation!.tool.id);
      expect(log.shownLog.map((e) => e.$1), contains(log.taps.single.$1));
    });

    test('a tap before any recommendation was shown logs nothing', () {
      final log = FakeRecommendationLogRepository();
      final vm = viewModel(FakeWeatherRepository(), recommendationLog: log);

      vm.openRecommendation();
      vm.openWeatherRecommendation();

      expect(log.taps, isEmpty);
      expect(log.opens, isEmpty);
    });
  });
}
