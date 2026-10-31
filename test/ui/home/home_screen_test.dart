import 'dart:async';

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

import 'package:frontend_flutter/data/services/remote/weather_service.dart';

import 'package:frontend_flutter/domain/recommendation/tool_recommender.dart';

import 'package:frontend_flutter/ui/home/view_model/tool_hub_view_model.dart';

import 'package:frontend_flutter/ui/home/widgets/home_screen.dart';

class FakeWeatherRepository extends WeatherRepository {
  FakeWeatherRepository(this.reading) : super(service: _NoopFetcher());

  final WeatherReading reading;

  @override
  Future<WeatherReading> currentWeather() async => reading;

  @override
  void dispose() {}
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
  @override
  Future<StatsData> dataSince(DateTime from) async =>
      const StatsData(checkIns: [], sessions: []);
}

class FakeRecommendationLogRepository extends RecommendationLogRepository {
  final List<(String id, String toolId)> taps = [];
  final List<(String id, String toolId)> opens = [];

  @override
  String logShown(Recommendation recommendation, {required String strategy}) =>
      'log';

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
  @override
  String? get currentUserId => 'test-user';

  @override
  Future<UserModel?> getCurrentUserProfile() async => null;
}

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

/// Mild and cloudy, so the weather strategy has no opinion.
Weather get mild => weatherAt(tempC: 20, code: 2);

ToolHubViewModel viewModel(
  WeatherReading reading, {
  FakeRecommendationLogRepository? recommendationLog,
}) => ToolHubViewModel(
  repository: const ToolRepository(),
  statsRepository: FakeStatsRepository(),
  recommender: ToolRecommender(),
  recommendationLog: recommendationLog ?? FakeRecommendationLogRepository(),
  auth: FakeAuthRepository(),
  weather: FakeWeatherRepository(reading),
);

Future<void> showHome(
  WidgetTester tester,
  ToolHubViewModel vm, {
  VoidCallback? onOpenRecommendation,
  VoidCallback? onSurpriseMe,
}) async {
  // Loaded before pumping: HomeScreen reads the view model in its one build,
  // it does not listen to it (the shell above it does).
  await vm.loadRecommendation();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: HomeScreen(
          viewModel: vm,
          onOpenRecommendation: onOpenRecommendation ?? () {},
          onOpenWeatherRecommendation: () {},
          onOpenLastRecommendation: () {},
          onSurpriseMe: onSurpriseMe ?? () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'the weather pick and the personal recommendation are separate sections',
    (tester) async {
      final vm = viewModel(
        WeatherReading(outcome: WeatherOutcome.ready, weather: sunny),
      );

      await showHome(tester, vm);

      expect(find.text('Weather pick'), findsOneWidget);
      expect(find.text('BECAUSE OF THE WEATHER'), findsOneWidget);
      expect(find.text('Photo of the day'), findsOneWidget);
      expect(find.text("Today's Recommendations"), findsOneWidget);
      expect(find.text('SUGGESTED FOR TODAY'), findsOneWidget);
      expect(find.text('Custom breathing'), findsOneWidget);
      expect(find.text('SURPRISE TOOL'), findsOneWidget);
    },
  );

  testWidgets('no weather section when the weather has no opinion', (
    tester,
  ) async {
    final vm = viewModel(
      WeatherReading(outcome: WeatherOutcome.ready, weather: mild),
    );

    await showHome(tester, vm);

    expect(find.text('Weather pick'), findsNothing);
    expect(find.text('BECAUSE OF THE WEATHER'), findsNothing);
    expect(find.text("Today's Recommendations"), findsOneWidget);
  });

  testWidgets('no weather section when the location was refused', (
    tester,
  ) async {
    final vm = viewModel(
      const WeatherReading(outcome: WeatherOutcome.noLocation),
    );

    await showHome(tester, vm);

    expect(find.text('Weather pick'), findsNothing);
    expect(find.text("Today's Recommendations"), findsOneWidget);
  });

  testWidgets('tapping the suggested card logs the recommendation tap', (
    tester,
  ) async {
    final log = FakeRecommendationLogRepository();
    final vm = viewModel(
      WeatherReading(outcome: WeatherOutcome.ready, weather: sunny),
      recommendationLog: log,
    );

    await showHome(tester, vm, onOpenRecommendation: vm.openRecommendation);

    await tester.tap(find.text('Custom breathing'));
    await tester.pump();

    expect(log.taps, hasLength(1));
    expect(log.taps.single.$2, vm.recommendation!.tool.id);
    expect(log.opens, hasLength(1));
  });

  testWidgets('tapping the surprise card logs no recommendation tap', (
    tester,
  ) async {
    final log = FakeRecommendationLogRepository();
    final vm = viewModel(
      WeatherReading(outcome: WeatherOutcome.ready, weather: sunny),
      recommendationLog: log,
    );

    await showHome(tester, vm, onSurpriseMe: () {});

    await tester.tap(find.text('Leave it to chance'));
    await tester.pump();

    expect(log.taps, isEmpty);
    expect(log.opens, isEmpty);
  });
}
