import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/screens/custom_breathing/custom_breathing_screen.dart';

void main() {
  testWidgets('CustomBreathingScreen renders all components matching the mockup',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CustomBreathingScreen(),
      ),
    );

    // Initial render
    await tester.pump();

    // Verify Title and Subtitle
    expect(find.text('Custom breathing'), findsOneWidget);
    expect(find.text('Build your own rhythm'), findsOneWidget);

    // Verify Pattern Selector options
    expect(find.text('2-step'), findsOneWidget);
    expect(find.text('3-step'), findsOneWidget);
    expect(find.text('4-7-8'), findsOneWidget);

    // Verify TimerCard state
    expect(find.text('Running'), findsOneWidget);
    expect(find.text('Breathe in'), findsOneWidget);

    // Verify Steppers for 3-step pattern
    expect(find.text('Inhale'), findsOneWidget);
    expect(find.text('Hold'), findsOneWidget);
    expect(find.text('Exhale'), findsOneWidget);

    // Verify Duration Pills
    expect(find.text('2 min'), findsOneWidget);
    expect(find.text('5 min'), findsOneWidget);
    expect(find.text('10 min'), findsOneWidget);

    // Test switching to 2-step pattern (should hide 'Hold')
    await tester.tap(find.text('2-step'));
    await tester.pump();
    expect(find.text('Hold'), findsNothing);

    // Switch back to 3-step
    await tester.tap(find.text('3-step'));
    await tester.pump();
    expect(find.text('Hold'), findsOneWidget);

    // Test pause toggle
    await tester.tap(find.bySemanticsLabel('Pause the session'));
    await tester.pump();
    expect(find.text('Paused'), findsOneWidget);
  });
}
