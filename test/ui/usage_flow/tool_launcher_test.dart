import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/models/tool_model.dart';
import 'package:frontend_flutter/data/repositories/analytics_repository.dart';
import 'package:frontend_flutter/ui/usage_flow/tool_launcher.dart';
import 'package:frontend_flutter/ui/usage_flow/view_model/usage_flow_view_model.dart';

/// `implements` because [AnalyticsRepository] is built by a factory.
class FakeAnalytics implements AnalyticsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

void main() {
  const tool = ToolItem(
    id: 'photo',
    title: 'Photo of the day',
    description: 'One photo a day, one new memory.',
    iconAsset: 'assets/icons/ic_tool_photo.svg',
    category: ToolCategory.reflect,
  );

  late DateTime clock;
  late UsageFlowViewModel flow;

  setUp(() {
    clock = DateTime(2026, 10, 31, 12);
    flow = UsageFlowViewModel(
      tool: tool,
      now: () => clock,
      analytics: FakeAnalytics(),
    );
  });

  tearDown(() => flow.dispose());

  Future<void> showHub(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => openTool(
                  context,
                  tool: tool,
                  flow: flow,
                  screen: (_) => const Scaffold(body: Text('THE TOOL')),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('the tap lands on the tool, with nothing in between', (
    tester,
  ) async {
    await showHub(tester);
    await tester.tap(find.text('Open'));

    // The very next frame already belongs to the tool's route.
    await tester.pump();
    expect(find.text('Start'), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text('THE TOOL'), findsOneWidget);
    // Only two routes, counting the hidden one underneath: where the user
    // was, and the tool. The screen that used to sit between them is gone.
    expect(find.byType(Scaffold, skipOffstage: false), findsNWidgets(2));
  });

  testWidgets('leaving straight away goes back to where the user was', (
    tester,
  ) async {
    await showHub(tester);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    clock = clock.add(const Duration(seconds: 3));
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    // Too short to rate: no feedback, no leftover screen, just the hub.
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('THE TOOL'), findsNothing);
    expect(find.byType(Scaffold, skipOffstage: false), findsOneWidget);
  });
}
