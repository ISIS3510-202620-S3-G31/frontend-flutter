import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/models/check_in_model.dart';
import 'package:frontend_flutter/data/models/tool_session_model.dart';
import 'package:frontend_flutter/ui/stats/view_model/stats_view_model.dart';
import 'package:frontend_flutter/ui/stats/widgets/stats_screen.dart';
import 'package:frontend_flutter/ui/stats/widgets/tools_frequency_chart.dart';
import 'package:frontend_flutter/ui/stats/widgets/weekly_emotion_chart.dart';

import 'fake_stats_repository.dart';

void main() {
  final today = DateTime(2026, 10, 28, 12);

  Future<void> show(WidgetTester tester, FakeStatsRepository repository) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatsScreen(
            onOpenToolbox: () {},
            viewModel: StatsViewModel(repository: repository, now: () => today),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a user with no history sees no charts at all', (tester) async {
    await show(tester, FakeStatsRepository());

    expect(find.text('Nothing to show yet'), findsOneWidget);
    expect(find.byType(WeeklyEmotionChart), findsNothing);
    expect(find.byType(ToolsFrequencyChart), findsNothing);
    expect(find.text('Top Feeling'), findsNothing);
    expect(find.text('Check in now'), findsOneWidget);
  });

  testWidgets('a user with history sees the charts', (tester) async {
    await show(
      tester,
      FakeStatsRepository(
        checkIns: [
          CheckIn(
            emotions: const [Emotion.happiness],
            intensity: 4,
            timestamp: DateTime(2026, 10, 27, 9),
          ),
        ],
        sessions: [
          ToolSession(
            toolId: 'breathing',
            startedAt: DateTime(2026, 10, 27, 10),
            durationSeconds: 300,
          ),
        ],
      ),
    );

    expect(find.text('Nothing to show yet'), findsNothing);
    expect(find.byType(WeeklyEmotionChart), findsOneWidget);
    expect(find.byType(ToolsFrequencyChart), findsOneWidget);
    expect(find.text('Happiness'), findsOneWidget);
  });
}
