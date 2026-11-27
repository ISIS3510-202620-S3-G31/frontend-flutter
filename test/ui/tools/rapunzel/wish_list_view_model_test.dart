import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/ui/tools/rapunzel/view_model/wish_list_view_model.dart';

import 'rapunzel_fakes.dart';

void main() {
  test('load brings the wishes newest first and clears the loading flag', () async {
    final repository = FakeWishRepository(stored: [w1, w2, w3]);
    final vm = WishListViewModel(repository: repository);

    expect(vm.isLoading, isTrue);
    await vm.load();

    expect(vm.isLoading, isFalse);
    expect(vm.wishes, [w1, w2, w3]);

    vm.dispose();
  });

  test('deleting asks first and only confirmDelete removes the wish', () async {
    final repository = FakeWishRepository(stored: [w1, w2, w3]);
    final vm = WishListViewModel(repository: repository);
    await vm.load();

    vm.askToDelete(w2);
    expect(vm.wishToDelete, w2);
    expect(repository.deletedIds, isEmpty, reason: 'asking is not deleting');

    vm.cancelDelete();
    expect(vm.wishToDelete, isNull);
    expect(vm.wishes, [w1, w2, w3]);

    vm.askToDelete(w2);
    await vm.confirmDelete();

    expect(repository.deletedIds, [w2.id]);
    expect(vm.wishToDelete, isNull);
    expect(vm.wishes, [w1, w3]);

    vm.dispose();
  });

  test('a failed delete keeps the wish and reports a message', () async {
    final repository = FakeWishRepository(stored: [w1, w2]);
    final vm = WishListViewModel(repository: repository);
    await vm.load();
    repository.failDeletes = true;

    vm.askToDelete(w1);
    await vm.confirmDelete();

    expect(vm.wishes, [w1, w2], reason: 'the wish stays on screen');
    expect(vm.takeMessage(), "We couldn't delete your wish. Please try again.");

    vm.dispose();
  });

  test('the offline flag follows the repository and its changes', () async {
    final repository = FakeWishRepository(stored: [], online: true);
    final vm = WishListViewModel(repository: repository);
    await vm.load();
    expect(vm.isOffline, isFalse);

    repository.goOffline();
    await Future<void>.delayed(Duration.zero);
    expect(vm.isOffline, isTrue);

    vm.dispose();
  });

  test('refresh reloads after the editor changed something', () async {
    final repository = FakeWishRepository(stored: [w1]);
    final vm = WishListViewModel(repository: repository);
    await vm.load();

    await repository.save('a new wish');
    await vm.refresh();

    expect(vm.wishes.length, 2);
    expect(vm.wishes.first.text, 'a new wish');

    vm.dispose();
  });
}
