import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/services/wish_sky_layout.dart';

void main() {
  test('the same seed gives the same sky', () {
    final first = buildSkyLayout(lanternCount: 12, seed: 42);
    final second = buildSkyLayout(lanternCount: 12, seed: 42);
    expect(second.lanternSlots, first.lanternSlots);
    expect(
      second.stars.map((star) => star.position),
      first.stars.map((star) => star.position),
    );
  });

  test('another seed moves the sky', () {
    final first = buildSkyLayout(lanternCount: 12, seed: 42);
    final second = buildSkyLayout(lanternCount: 12, seed: 7);
    expect(second.lanternSlots, isNot(first.lanternSlots));
  });

  test('one slot per lantern, all inside the sky and away from the held one', () {
    final layout = buildSkyLayout(lanternCount: 25, seed: 3);
    expect(layout.lanternSlots, hasLength(25));
    for (final slot in layout.lanternSlots) {
      expect(slot.dx, inInclusiveRange(0.08, 0.92));
      expect(slot.dy, inInclusiveRange(0.06, 0.7));
    }
    expect(layout.stars, hasLength(90));
  });

  test('no lanterns means no slots, the stars stay', () {
    final layout = buildSkyLayout(lanternCount: 0, seed: 1);
    expect(layout.lanternSlots, isEmpty);
    expect(layout.stars, isNotEmpty);
  });

  test('the isolate returns what the plain function computes', () async {
    final fromIsolate = await const WishSkyLayout().generate(
      lanternCount: 8,
      seed: 99,
    );
    final direct = buildSkyLayout(lanternCount: 8, seed: 99);
    expect(fromIsolate.lanternSlots, direct.lanternSlots);
    expect(fromIsolate.stars.length, direct.stars.length);
  });
}
