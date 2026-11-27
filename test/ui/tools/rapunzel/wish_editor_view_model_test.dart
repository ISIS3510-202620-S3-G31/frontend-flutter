import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/models/pending_write_model.dart';
import 'package:frontend_flutter/data/models/wish_model.dart';
import 'package:frontend_flutter/ui/tools/rapunzel/view_model/wish_editor_view_model.dart';

import 'rapunzel_fakes.dart';

class ThrowingWishRepository extends FakeWishRepository {
  @override
  Future<Wish> save(String text) async => throw Exception('no network');

  @override
  Future<SaveOutcome> update(Wish wish, String newText) async =>
      throw Exception('no network');
}

void main() {
  test('a new wish starts empty and cannot be saved blank', () async {
    final vm = WishEditorViewModel(repository: FakeWishRepository());

    expect(vm.isEditing, isFalse);
    expect(vm.text, isEmpty);
    expect(vm.canSave, isFalse);
    expect(await vm.save(), isFalse);

    vm.dispose();
  });

  test('typing fills the text, capped at the lantern limit', () {
    final vm = WishEditorViewModel(repository: FakeWishRepository());

    vm.onTextChange('  see the sunrise  ');
    expect(vm.text, '  see the sunrise  ');
    expect(vm.canSave, isTrue);

    vm.onTextChange('ab' * 200);
    expect(vm.text.length, Wish.maxLength);

    vm.dispose();
  });

  test('saving a new wish goes to the repository and succeeds', () async {
    final repository = FakeWishRepository();
    final vm = WishEditorViewModel(repository: repository);

    vm.onTextChange('a new wish');
    expect(await vm.save(), isTrue);

    expect(repository.savedTexts, ['a new wish']);
    expect((await repository.wishes()).single.text, 'a new wish');
    expect(vm.errorMessage, isNull);

    vm.dispose();
  });

  test('editing a wish starts with its text and saves through update', () async {
    final repository = FakeWishRepository(stored: [w2]);
    final vm = WishEditorViewModel(repository: repository, editing: w2);

    expect(vm.isEditing, isTrue);
    expect(vm.text, w2.text);

    vm.onTextChange('changed my mind');
    expect(await vm.save(), isTrue);

    expect(repository.updatedIds, [w2.id]);
    expect(repository.savedTexts, isEmpty);
    expect((await repository.wishes()).single.text, 'changed my mind');

    vm.dispose();
  });

  test('a failed save shows an error instead of closing', () async {
    final vm = WishEditorViewModel(repository: ThrowingWishRepository());

    vm.onTextChange('will not save');
    expect(await vm.save(), isFalse);

    expect(vm.errorMessage, "We couldn't save your wish. Please try again.");
    expect(vm.isSaving, isFalse);
    // The text is kept, so the user can retry.
    expect(vm.text, 'will not save');
    expect(vm.canSave, isTrue);

    vm.dispose();
  });

  test('a failed update says update, not save', () async {
    final vm = WishEditorViewModel(
      repository: ThrowingWishRepository(),
      editing: w2,
    );

    vm.onTextChange('will not update');
    expect(await vm.save(), isFalse);

    expect(vm.errorMessage, "We couldn't update your wish. Please try again.");

    vm.dispose();
  });

  test('the offline flag follows the repository', () async {
    final repository = FakeWishRepository(online: false);
    final vm = WishEditorViewModel(repository: repository);
    await vm.loaded;

    expect(vm.isOffline, isTrue);

    vm.dispose();
  });
}
