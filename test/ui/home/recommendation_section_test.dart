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

  var opened = 0;
  var surprised = 0;

  setUp(() {
    opened = 0;
    surprised = 0;
  });

  Future<void> show(WidgetTester tester, Recommendation? recommendation) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecommendationSection(
            recommendation: recommendation,
            onOpen: () => opened++,
            onSurpriseMe: () => surprised++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the suggested tool and the surprise card', (tester) async {
    await show(
      tester,
      const Recommendation(tool: breathing, reason: 'You felt tense today.'),
    );

    expect(find.text("Today's Recommendations"), findsOneWidget);
    expect(find.text('SUGGESTED FOR TODAY'), findsOneWidget);
    expect(find.text('Custom breathing'), findsOneWidget);
    expect(find.text('You felt tense today.'), findsOneWidget);
    expect(find.text('SURPRISE TOOL'), findsOneWidget);
    expect(find.text('Leave it to chance'), findsOneWidget);
  });

  testWidgets('surprise stays available while loading', (tester) async {
    await show(tester, null);

    expect(find.text('SUGGESTED FOR TODAY'), findsNothing);
    expect(find.text('Leave it to chance'), findsOneWidget);
  });

  testWidgets('each card calls its own action', (tester) async {
    await show(
      tester,
      const Recommendation(tool: breathing, reason: 'You felt tense today.'),
    );

    await tester.tap(find.text('Custom breathing'));
    expect([opened, surprised], [1, 0]);

    await tester.tap(find.text('Leave it to chance'));
    expect([opened, surprised], [1, 1]);
  });
}
