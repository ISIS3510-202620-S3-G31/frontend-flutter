import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/ui/tools/rapunzel/view_model/rapunzel_sky_view_model.dart';

import 'rapunzel_fakes.dart';

void main() {
  test('load holds the newest unreleased wish as the lit foreground', () async {
    final vm = viewModel(FakeWishRepository(stored: [w3, w2, w1]));
    await vm.load();

    expect(vm.foreground, w3);
    expect(vm.isLit(w1), isTrue, reason: 'released wishes are lit');
    expect(vm.isLit(w2), isFalse);
    expect(
      vm.backgroundLanterns.map((entry) => entry.$1.id),
      ['w2', 'w1'],
      reason: 'the foreground lantern is not in the background',
    );
    expect(vm.motionOf(w3.id), LanternMotion.bobbing);
  });

  test('the number of concurrent animations never passes the cap', () async {
    final vm = viewModel(
      FakeWishRepository(stored: [w1, wish('w4', released: true), wish('w5', released: true), wish('w6', released: true), wish('w7', released: true)]),
      maxConcurrentAnimations: 2,
    );
    await vm.load();

    expect(vm.activeAnimationCount, 2);
    expect(vm.motionOf(w1.id), LanternMotion.bobbing);
    expect(vm.motionOf('w4'), LanternMotion.bobbing);
    expect(vm.motionOf('w5'), isNull, reason: 'beyond the cap: drawn static');
  });

  test('tapping a lit lantern reads its wish', () async {
    final vm = viewModel(FakeWishRepository(stored: [w1]));
    await vm.load();

    final result = vm.tapAt(slotPixel(0), skySize);

    expect(result, LanternTap.read);
    expect(vm.reading, w1);
  });

  test('tapping an unlit lantern lights it first, then opens the text', () async {
    // w3 is held in the foreground, w2 floats unlit in the background.
    final vm = viewModel(FakeWishRepository(stored: [w3, w2]));
    await vm.load();

    final result = vm.tapAt(slotPixel(0), skySize);

    expect(result, LanternTap.lighting);
    expect(vm.motionOf(w2.id), LanternMotion.lighting);
    expect(vm.reading, isNull, reason: 'the text opens when the flame is lit');

    vm.completeLighting(w2.id);

    expect(vm.isLit(w2), isTrue);
    expect(vm.reading, w2);
    expect(vm.motionOf(w2.id), isNull, reason: 'the lighting slot is freed');
  });

  test('at the cap an unlit lantern lights without animation and still reads', () async {
    // One slot, taken by the foreground lantern.
    final vm = viewModel(
      FakeWishRepository(stored: [w3, w2]),
      maxConcurrentAnimations: 1,
    );
    await vm.load();

    final result = vm.tapAt(slotPixel(0), skySize);

    expect(result, LanternTap.read);
    expect(vm.isLit(w2), isTrue);
    expect(vm.reading, w2);
    expect(vm.activeAnimationCount, 1);
  });

  test('tapping the held lantern reads it, tapping empty sky does nothing', () async {
    final vm = viewModel(FakeWishRepository(stored: [w3, w1]));
    await vm.load();

    expect(
      vm.tapAt(
        Offset(
          RapunzelSkyViewModel.foregroundSlot.dx * skySize.width,
          RapunzelSkyViewModel.foregroundSlot.dy * skySize.height,
        ),
        skySize,
      ),
      LanternTap.read,
    );
    expect(vm.reading, w3);

    vm.closeReading();
    expect(vm.tapAt(const Offset(30, 700), skySize), LanternTap.none);
    expect(vm.reading, isNull);
  });

  test('a fast upward swipe releases the held lantern, a slow one does not', () async {
    final vm = viewModel(FakeWishRepository(stored: [w3, w2, w1]));
    await vm.load();

    expect(vm.onVerticalDragEnd(-100), isFalse);
    expect(vm.onVerticalDragEnd(-1200), isTrue);
    expect(vm.motionOf(w3.id), LanternMotion.releasing);
    expect(vm.activeAnimationCount, lessThanOrEqualTo(vm.maxConcurrentAnimations));

    await vm.completeRelease();

    expect(vm.foreground, w2, reason: 'the next unreleased wish is held now');
    expect(vm.isLit(w3), isTrue, reason: 'a released lantern is lit');
    expect(vm.motionOf(w3.id), isNot(LanternMotion.releasing));
  });

  test('releasing with no wish held does nothing', () async {
    final vm = viewModel(FakeWishRepository(stored: [w1]));
    await vm.load();

    expect(vm.foreground, isNull);
    expect(vm.onVerticalDragEnd(-2000), isFalse);
  });

  test('the release reaches the repository and reports when offline', () async {
    final repository = FakeWishRepository(stored: [w3, w1]);
    final vm = viewModel(repository);
    await vm.load();
    repository.goOffline();
    await pumpEventQueue();
    expect(vm.isOffline, isTrue);
    expect(vm.takeMessage(), isNotNull, reason: 'the offline snackbar fires');
    expect(vm.takeMessage(), isNull, reason: 'the message is taken once');

    vm.onVerticalDragEnd(-1500);
    await vm.completeRelease();

    expect(repository.releasedIds, [w3.id]);
    expect(vm.foreground, isNull);
    expect(vm.takeMessage(), contains('back online'));
  });
}
