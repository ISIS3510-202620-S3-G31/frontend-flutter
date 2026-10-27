import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/models/check_in_model.dart';
import 'package:frontend_flutter/data/models/tool_session_model.dart';
import 'package:frontend_flutter/ui/stats/view_model/stats_view_model.dart';

import 'fake_stats_repository.dart';

void main() {
  // A Wednesday, so the week has days before and after it.
  final today = DateTime(2026, 10, 28, 12);
  DateTime now() => today;

  StatsViewModel viewModelWith(FakeStatsRepository repository) =>
      StatsViewModel(repository: repository, now: now);

  group('a brand new user', () {
    test('has nothing to show and no numbers made up for them', () async {
      final viewModel = viewModelWith(FakeStatsRepository());

      await viewModel.load();

      expect(viewModel.isEmpty, isTrue);
      expect(viewModel.weekCheckIns, 0);
      expect(viewModel.topFeeling, isNull);
      expect(viewModel.week, everyElement(isNull));
      expect(viewModel.toolShares, isEmpty);
      expect(viewModel.insights, isEmpty);
      expect(viewModel.loading, isFalse);
    });

    test('shows its own check-ins even with no tool finished', () async {
      final viewModel = viewModelWith(
        FakeStatsRepository(
          checkIns: [
            CheckIn(
              emotions: const [Emotion.sadness],
              intensity: 3,
              timestamp: today,
            ),
          ],
        ),
      );

      await viewModel.load();

      expect(viewModel.isEmpty, isFalse);
      expect(viewModel.weekCheckIns, 1);
      expect(viewModel.toolShares, isEmpty);
    });
  });

  group('a user with history', () {
    late StatsViewModel viewModel;

    setUp(() {
      viewModel = viewModelWith(
        FakeStatsRepository(
          checkIns: [
            // Monday and Tuesday of this week, plus one last week.
            CheckIn(
              emotions: const [Emotion.anger],
              intensity: 4,
              timestamp: DateTime(2026, 10, 26, 9),
            ),
            CheckIn(
              emotions: const [Emotion.anger],
              intensity: 2,
              timestamp: DateTime(2026, 10, 27, 20),
            ),
            CheckIn(
              emotions: const [Emotion.happiness],
              intensity: 5,
              timestamp: DateTime(2026, 10, 20, 9),
            ),
          ],
          sessions: [
            ToolSession(
              toolId: 'breathing',
              startedAt: DateTime(2026, 10, 26, 10),
              durationSeconds: 300,
            ),
            ToolSession(
              toolId: 'breathing',
              startedAt: DateTime(2026, 10, 27, 10),
              durationSeconds: 300,
            ),
            ToolSession(
              toolId: 'jar',
              startedAt: DateTime(2026, 10, 27, 11),
              durationSeconds: 120,
            ),
          ],
        ),
      );
    });

    test('counts only this week in the summary', () async {
      await viewModel.load();

      expect(viewModel.isEmpty, isFalse);
      expect(viewModel.weekCheckIns, 2);
      expect(viewModel.topFeeling, Emotion.anger);
    });

    test('puts each day of the week in its own place', () async {
      await viewModel.load();

      expect(viewModel.week[0]?.emotion, Emotion.anger);
      expect(viewModel.week[0]?.intensity, 4);
      expect(viewModel.week[1]?.intensity, 2);
      // Wednesday onwards has no check-in yet.
      expect(viewModel.week.sublist(2), everyElement(isNull));
    });

    test('shares the tools by use and they add up to 100', () async {
      await viewModel.load();

      expect(viewModel.toolShares.first.percent, 67);
      expect(
        viewModel.toolShares.fold<int>(0, (sum, s) => sum + s.percent),
        100,
      );
    });
  });
}
