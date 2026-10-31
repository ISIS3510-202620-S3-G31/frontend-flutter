import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/models/recommendation_model.dart';
import 'package:frontend_flutter/data/models/tool_model.dart';
import 'package:frontend_flutter/ui/home/widgets/recommendation_section.dart';

void main() {
  const breathing = ToolItem(
    id: 'breathing',
    title: 'Custom breathing',
    description: 'Build the rhythm that fits you.',
    iconAsset: 'assets/icons/ic_tool_breathing.svg',
    category: ToolCategory.calmDown,
  );
  const scream = ToolItem(
    id: 'scream',
    title: 'Scream tank',
    description: 'Let it all out in a safe space.',
    iconAsset: 'assets/icons/ic_tool_scream.svg',
    category: ToolCategory.release,
  );

  const personal = Recommendation(
    tool: breathing,
    reason: 'You felt tense today.',
  );
  const fromWeather = Recommendation(
    tool: scream,
    reason: 'Cold day outside.',
  );

  var opened = 0;
  var openedWeather = 0;
  var surprised = 0;

  setUp(() {
    opened = 0;
    openedWeather = 0;
    surprised = 0;
  });

  Future<void> show(
    WidgetTester tester, {
    Recommendation? recommendation,
    Recommendation? weatherRecommendation,
    bool isLoading = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecommendationSection(
            recommendation: recommendation,
            weatherRecommendation: weatherRecommendation,
            isLoading: isLoading,
            onOpen: () => opened++,
            onOpenWeather: () => openedWeather++,
            onSurpriseMe: () => surprised++,
          ),
        ),
      ),
    );
    // The loading card pulses forever, and pumpAndSettle waits for every
    // animation to end, so it would hang instead of failing.
    if (isLoading) {
      await tester.pump();
    } else {
      await tester.pumpAndSettle();
    }
  }

  testWidgets('shows the suggested tool and the surprise card', (tester) async {
    await show(tester, recommendation: personal);

    expect(find.text("Today's Recommendations"), findsOneWidget);
    expect(find.text('SUGGESTED FOR TODAY'), findsOneWidget);
    expect(find.text('Custom breathing'), findsOneWidget);
    expect(find.text('You felt tense today.'), findsOneWidget);
    expect(find.text('SURPRISE TOOL'), findsOneWidget);
    expect(find.text('Leave it to chance'), findsOneWidget);
  });

  testWidgets('shows the weather suggestion next to the personal one', (
    tester,
  ) async {
    await show(
      tester,
      recommendation: personal,
      weatherRecommendation: fromWeather,
    );

    expect(find.text('SUGGESTED FOR TODAY'), findsOneWidget);
    expect(find.text('BECAUSE OF THE WEATHER'), findsOneWidget);
    expect(find.text('Cold day outside.'), findsOneWidget);
  });

  testWidgets('says nothing about the weather when it has no opinion', (
    tester,
  ) async {
    await show(tester, recommendation: personal);

    expect(find.text('BECAUSE OF THE WEATHER'), findsNothing);
  });

  testWidgets('a placeholder holds the gap while loading', (tester) async {
    await show(tester, isLoading: true);

    expect(find.byType(RecommendationLoadingCard), findsOneWidget);
    expect(find.text('Custom breathing'), findsNothing);
    // Chance never has to wait for the recommendation to arrive.
    expect(find.text('Leave it to chance'), findsOneWidget);
  });

  testWidgets('no placeholder once the recommendation is in', (tester) async {
    await show(tester, recommendation: personal);

    expect(find.byType(RecommendationLoadingCard), findsNothing);
  });

  testWidgets('each card calls its own action', (tester) async {
    await show(
      tester,
      recommendation: personal,
      weatherRecommendation: fromWeather,
    );

    await tester.tap(find.text('Custom breathing'));
    expect([opened, openedWeather, surprised], [1, 0, 0]);

    await tester.tap(find.text('Scream tank'));
    expect([opened, openedWeather, surprised], [1, 1, 0]);

    await tester.tap(find.text('Leave it to chance'));
    expect([opened, openedWeather, surprised], [1, 1, 1]);
  });
}
