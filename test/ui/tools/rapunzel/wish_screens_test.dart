import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/models/wish_model.dart';
import 'package:frontend_flutter/ui/tools/rapunzel/view_model/wish_editor_view_model.dart';
import 'package:frontend_flutter/ui/tools/rapunzel/view_model/wish_list_view_model.dart';
import 'package:frontend_flutter/ui/tools/rapunzel/widgets/wish_editor_screen.dart';
import 'package:frontend_flutter/ui/tools/rapunzel/widgets/wish_list_screen.dart';

import 'rapunzel_fakes.dart';

void main() {
  testWidgets('the list shows every wish and deleting asks first', (
    tester,
  ) async {
    final repository = FakeWishRepository(stored: [w1, w2]);
    final vm = WishListViewModel(repository: repository);
    await tester.pumpWidget(MaterialApp(home: WishListScreen(viewModel: vm)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('All my wishes'), findsOneWidget);
    expect(find.text('wish w1'), findsOneWidget);
    expect(find.text('wish w2'), findsOneWidget);

    // Delete the first row (w1): the dialog must appear before anything is
    // deleted.
    await tester.tap(find.byTooltip('Delete wish').first);
    await tester.pumpAndSettle();

    expect(find.text('Delete this wish?'), findsOneWidget);
    expect(repository.deletedIds, isEmpty);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(repository.deletedIds, [w1.id]);
    expect(find.text('wish w1'), findsNothing);
    expect(find.text('wish w2'), findsOneWidget);

    vm.dispose();
  });

  testWidgets('cancelling the delete keeps the wish', (tester) async {
    final repository = FakeWishRepository(stored: [w1]);
    final vm = WishListViewModel(repository: repository);
    await tester.pumpWidget(MaterialApp(home: WishListScreen(viewModel: vm)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byTooltip('Delete wish'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(repository.deletedIds, isEmpty);
    expect(find.text('wish w1'), findsOneWidget);

    vm.dispose();
  });

  testWidgets('the empty list offers to write the first wish', (tester) async {
    final repository = FakeWishRepository();
    final vm = WishListViewModel(repository: repository);
    await tester.pumpWidget(MaterialApp(home: WishListScreen(viewModel: vm)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text("You haven't written any wishes yet."), findsOneWidget);
    expect(find.text('Write a wish'), findsOneWidget);

    vm.dispose();
  });

  testWidgets('the editor saves a new wish with the counter running', (
    tester,
  ) async {
    final repository = FakeWishRepository();
    final vm = WishEditorViewModel(repository: repository);
    await tester.pumpWidget(
      MaterialApp(home: WishEditorScreen(viewModel: vm)),
    );
    await tester.pump();

    expect(find.text('Write a wish'), findsOneWidget);
    final button = find.ancestor(
      of: find.text('Save and light the lantern'),
      matching: find.byType(FilledButton),
    );
    // Blank text: the save button is off.
    expect(tester.widget<FilledButton>(button).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'fly to the moon');
    await tester.pump();
    expect(find.text('15/${Wish.maxLength}'), findsOneWidget);
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);

    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(repository.savedTexts, ['fly to the moon']);

    vm.dispose();
  });

  testWidgets('the editor edits an existing wish', (tester) async {
    final repository = FakeWishRepository(stored: [w2]);
    final vm = WishEditorViewModel(repository: repository, editing: w2);
    await tester.pumpWidget(
      MaterialApp(home: WishEditorScreen(viewModel: vm)),
    );
    await tester.pump();

    expect(find.text('Edit wish'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
    expect(find.text('wish w2'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'changed my mind');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(repository.updatedIds, [w2.id]);
    expect(repository.savedTexts, isEmpty);
    expect((await repository.wishes()).single.text, 'changed my mind');

    vm.dispose();
  });
}
