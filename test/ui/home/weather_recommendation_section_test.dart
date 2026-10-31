import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:frontend_flutter/data/models/recommendation_model.dart';

import 'package:frontend_flutter/data/models/tool_model.dart';

import 'package:frontend_flutter/ui/home/widgets/recommendation_section.dart';

import 'package:frontend_flutter/ui/home/widgets/weather_recommendation_section.dart';

void main() {
  const scream = ToolItem(
    id: 'scream',
    title: 'Scream tank',
    description: 'Let it all out in a safe space.',
    iconAsset: 'assets/icons/ic_tool_scream.svg',
    category: ToolCategory.release,
  );

  const fromWeather = Recommendation(
    tool: scream,
    reason: 'Cold day outside.',
  );

  var opened = 0;

  setUp(() {
    opened = 0;
  });

  Future<void> show(
    WidgetTester tester, {
    Recommendation? weatherRecommendation,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeatherRecommendationSection(
            weatherRecommendation: weatherRecommendation,
            onOpen: () => opened++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the weather pick under its own heading', (tester) async {
    await show(tester, weatherRecommendation: fromWeather);

    expect(find.text('Weather pick'), findsOneWidget);
    expect(find.text('BECAUSE OF THE WEATHER'), findsOneWidget);
    expect(find.text('Scream tank'), findsOneWidget);
    expect(find.text('Cold day outside.'), findsOneWidget);
    // The weather pick is not part of the normal recommendations section.
    expect(find.text("Today's Recommendations"), findsNothing);
  });

  testWidgets('shows nothing when there is no weather recommendation', (tester) async {
    await show(tester);

    expect(find.byType(RecommendationCard), findsNothing);
    expect(find.text('BECAUSE OF THE WEATHER'), findsNothing);
  });

  testWidgets('the card calls its own action', (tester) async {
    await show(tester, weatherRecommendation: fromWeather);

    await tester.tap(find.text('Scream tank'));
    expect(opened, 1);
  });
}
