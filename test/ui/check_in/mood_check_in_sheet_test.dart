import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/models/check_in_model.dart';
import 'package:frontend_flutter/ui/check_in/view_model/check_in_view_model.dart';
import 'package:frontend_flutter/ui/check_in/widgets/mood_check_in_sheet.dart';

import 'fakes.dart';

void main() {
  late FakeCheckInRepository repository;

  Future<void> show(WidgetTester tester, {bool canDictate = false}) async {
    repository = FakeCheckInRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MoodCheckInSheet(
            viewModel: CheckInViewModel(
              repository: repository,
              speech: FakeSpeechRecognitionService(available: canDictate),
              microphone: FakeMicrophoneService(),
              network: FakeNetworkConnectivityService(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows only the title, no date and no prose', (tester) async {
    await show(tester);

    expect(find.text('Check-in'), findsOneWidget);
    expect(find.text('Mood Check-In'), findsNothing);
    expect(find.text('How are you feeling?'), findsNothing);
    expect(find.text('Pick one or more.'), findsNothing);
    expect(find.text('Barely'), findsNothing);
    expect(find.text('A lot'), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('keeps the emotions, the strength and the note', (tester) async {
    await show(tester);

    expect(find.text('How strong is it?'), findsOneWidget);
    expect(find.text('3/5'), findsOneWidget);
    expect(find.text('Add a note (optional)'), findsOneWidget);
    expect(find.text('Happiness'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('cannot save until an emotion is picked', (tester) async {
    await show(tester);

    final button = find.widgetWithText(FilledButton, 'Save check-in');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);

    await tester.tap(find.text('Anger'));
    await tester.pump();

    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
  });

  testWidgets('saves what the user picked', (tester) async {
    await show(tester);

    await tester.tap(find.text('Sadness'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'A long day.');
    await tester.tap(find.widgetWithText(FilledButton, 'Save check-in'));
    await tester.pump();

    expect(repository.saved?.emotions, [Emotion.sadness]);
    expect(repository.saved?.intensity, 3);
    expect(repository.saved?.note, 'A long day.');
  });

  testWidgets('the mic button is hidden when the phone cannot dictate', (
    tester,
  ) async {
    await show(tester);

    expect(find.byIcon(Icons.mic_none), findsNothing);
    expect(find.byIcon(Icons.mic), findsNothing);
  });

  testWidgets('the mic button shows when the phone can dictate', (
    tester,
  ) async {
    await show(tester, canDictate: true);

    expect(find.byIcon(Icons.mic_none), findsOneWidget);
  });
}
