import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/models/check_in_model.dart';
import 'package:frontend_flutter/data/repositories/check_in_repository.dart';
import 'package:frontend_flutter/ui/check_in/view_model/check_in_view_model.dart';
import 'package:frontend_flutter/ui/check_in/widgets/mood_check_in_sheet.dart';

/// Keeps what the sheet saves, so no Firebase is needed.
class FakeCheckInRepository implements CheckInRepository {
  CheckIn? saved;

  @override
  Future<void> save(CheckIn checkIn) async => saved = checkIn;

  @override
  Future<CheckIn?> todaysCheckIn() async => saved;

  @override
  Future<List<CheckIn>> since(DateTime from) async => [?saved];
}

void main() {
  late FakeCheckInRepository repository;

  Future<void> show(WidgetTester tester) async {
    repository = FakeCheckInRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MoodCheckInSheet(
            viewModel: CheckInViewModel(repository: repository),
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
}
