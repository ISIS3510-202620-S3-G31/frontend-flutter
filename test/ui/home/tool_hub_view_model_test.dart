import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/models/check_in_model.dart';
import 'package:frontend_flutter/data/models/recommendation_model.dart';
import 'package:frontend_flutter/data/models/tool_session_model.dart';
import 'package:frontend_flutter/data/repositories/analytics_repository.dart';
import 'package:frontend_flutter/data/repositories/recommendation_log_repository.dart';
import 'package:frontend_flutter/data/repositories/stats_repository.dart';
import 'package:frontend_flutter/ui/home/view_model/tool_hub_view_model.dart';

/// The user's history, which a test can change between two loads.
class _FakeStatsRepository implements StatsRepository {
  List<CheckIn> checkIns = [];
  List<ToolSession> sessions = [];

  /// When set, the next read waits for it, like a slow network.
  Completer<void>? slowRead;

  @override
  Future<StatsData> dataSince(DateTime from) async {
    // Taken now, so a later change does not leak into this read.
    final data = StatsData(checkIns: [...checkIns], sessions: [...sessions]);
    final wait = slowRead;
    slowRead = null;
    if (wait != null) await wait.future;
    return data;
  }
}

/// Keeps what the view model logged for BQ3 instead of sending it.
class _FakeRecommendationLog implements RecommendationLogRepository {
  final shown = <({String toolId, String strategy})>[];
  final opened = <String>[];

  @override
  String logShown(Recommendation recommendation, {required String strategy}) {
    shown.add((toolId: recommendation.tool.id, strategy: strategy));
    return 'rec-${shown.length}';
  }

  @override
  void logOpened(String id, {required String toolId}) => opened.add(id);
}

/// Screen views are not what these tests look at.
class _FakeAnalyticsRepository implements AnalyticsRepository {
  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {}

  // The home view model uses nothing else.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final now = DateTime(2026, 10, 30, 9);

  late _FakeStatsRepository stats;
  late _FakeRecommendationLog log;

  setUp(() {
    stats = _FakeStatsRepository();
    log = _FakeRecommendationLog();
  });

  ToolHubViewModel newViewModel({Set<String>? openableToolIds}) =>
      ToolHubViewModel(
        statsRepository: stats,
        analytics: _FakeAnalyticsRepository(),
        recommendationLog: log,
        openableToolIds: openableToolIds,
        now: () => now,
      );

  CheckIn checkInOf(Emotion emotion) => CheckIn(
    emotions: [emotion],
    intensity: 3,
    timestamp: now.subtract(const Duration(hours: 1)),
  );

  test('a new user gets the starter tool, logged once', () async {
    final viewModel = newViewModel();

    await viewModel.loadRecommendation();

    expect(viewModel.recommendation?.tool.id, 'breathing');
    expect(log.shown, [(toolId: 'breathing', strategy: 'Default')]);
  });

  test("today's check-in decides the tool and says which feeling", () async {
    stats.checkIns = [checkInOf(Emotion.anger)];
    final viewModel = newViewModel();

    await viewModel.loadRecommendation();

    expect(viewModel.recommendation?.tool.id, 'scream');
    expect(viewModel.recommendation?.emotion, Emotion.anger);
    expect(log.shown, [(toolId: 'scream', strategy: 'Mood based')]);
  });

  test('a check-in saved after the first pick changes it', () async {
    final viewModel = newViewModel();
    await viewModel.loadRecommendation();

    stats.checkIns = [checkInOf(Emotion.fear)];
    await viewModel.loadRecommendation();

    // Same tool, but now it comes from the check-in, so it is a new record.
    expect(viewModel.recommendation?.reason, contains('fear'));
    expect(log.shown, [
      (toolId: 'breathing', strategy: 'Default'),
      (toolId: 'breathing', strategy: 'Mood based'),
    ]);
  });

  test('reloading with nothing new does not count the pick twice', () async {
    final viewModel = newViewModel();

    await viewModel.loadRecommendation();
    await viewModel.loadRecommendation();

    expect(log.shown, hasLength(1));
  });

  test('never recommends a tool that cannot be opened yet', () async {
    // Anger points to Scream tank and Tear it up, and neither can open here.
    stats.checkIns = [checkInOf(Emotion.anger)];
    final viewModel = newViewModel(openableToolIds: {'breathing', 'photo'});

    await viewModel.loadRecommendation();

    expect(viewModel.recommendation?.tool.id, 'breathing');
    expect(log.shown, [(toolId: 'breathing', strategy: 'Default')]);
  });

  test('an older, slower load does not undo a newer pick', () async {
    final slow = Completer<void>();
    stats.slowRead = slow;
    final viewModel = newViewModel();

    // Reads the history before the check-in and gets stuck on the network.
    final first = viewModel.loadRecommendation();
    stats.checkIns = [checkInOf(Emotion.anger)];
    // Reads it after the check-in and answers first.
    await viewModel.loadRecommendation();
    slow.complete();
    await first;

    expect(viewModel.recommendation?.tool.id, 'scream');
    expect(log.shown, [(toolId: 'scream', strategy: 'Mood based')]);
  });

  test('only the first tap on the recommendation counts as opened', () async {
    final viewModel = newViewModel();
    await viewModel.loadRecommendation();

    viewModel.openRecommendation();
    viewModel.openRecommendation();

    expect(log.opened, ['rec-1']);
  });

  test('coming back to the home tab picks again', () async {
    final viewModel = newViewModel();
    await viewModel.loadRecommendation();

    viewModel.selectTab(HomeTab.stats);
    stats.checkIns = [checkInOf(Emotion.happiness)];
    viewModel.selectTab(HomeTab.home);
    // Lets the reload that selectTab started finish.
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.recommendation?.tool.id, 'photo');
  });
}
