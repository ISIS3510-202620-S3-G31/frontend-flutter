import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/models/pending_write_model.dart';
import 'package:frontend_flutter/data/models/tool_feedback_model.dart';
import 'package:frontend_flutter/data/repositories/feedback_repository.dart';
import 'package:frontend_flutter/ui/feedback/view_model/tool_feedback_view_model.dart';
import 'package:frontend_flutter/ui/feedback/widgets/tool_feedback_screen.dart';

/// Keeps what would have been sent to Firestore.
class FakeFeedbackRepository extends FeedbackRepository {
  final saved = <ToolFeedback>[];

  @override
  Future<SaveOutcome> save(ToolFeedback feedback) async {
    saved.add(feedback);
    return SaveOutcome.saved;
  }
}

void main() {
  late FakeFeedbackRepository repository;
  late ToolFeedbackViewModel viewModel;

  setUp(() {
    repository = FakeFeedbackRepository();
    viewModel = ToolFeedbackViewModel(
      toolId: 'photo',
      startedAt: DateTime(2026, 10, 31, 12),
      durationSeconds: 40,
      repository: repository,
    );
  });

  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ToolFeedbackScreen(
          toolId: 'photo',
          toolName: 'Photo of the day',
          startedAt: DateTime(2026, 10, 31, 12),
          durationSeconds: 40,
          viewModel: viewModel,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('asks only for the experience and an optional comment', (
    tester,
  ) async {
    await show(tester);

    expect(find.text('USE EXPERIENCE'), findsOneWidget);
    expect(find.text('COMMENTS'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    // The mood picker and the quick reflection are gone.
    expect(find.text('QUICK REFLECTION'), findsNothing);
    expect(find.text('Calm'), findsNothing);
    expect(find.text('Easy to use'), findsNothing);
  });

  testWidgets('can be saved without writing anything', (tester) async {
    await show(tester);

    await tester.tap(find.text('Save feedback'));
    await tester.pumpAndSettle();

    expect(repository.saved, hasLength(1));
    expect(repository.saved.single.rating, 5);
    expect(repository.saved.single.comment, isEmpty);
  });

  testWidgets('saves the comment the user wrote', (tester) async {
    await show(tester);

    await tester.enterText(find.byType(TextField), '  Loved it  ');
    await tester.tap(find.text('Save feedback'));
    await tester.pumpAndSettle();

    expect(repository.saved.single.comment, 'Loved it');
  });

  test('a saved feedback carries no mood nor tags', () {
    final map = ToolFeedback(
      toolId: 'photo',
      rating: 7,
      startedAt: DateTime(2026, 10, 31),
      durationSeconds: 40,
    ).toMap();

    expect(map.containsKey('mood'), isFalse);
    expect(map.containsKey('tags'), isFalse);
  });
}
