import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/ui/core/widgets/cover_sized_image.dart';

void main() {
  // The photo card on the Redmi Note 11 (2.75x): 948 x 1253 physical pixels.
  const card = Size(948, 1253);

  test('a gallery photo is decoded at the size of the card', () {
    final size = CoverSizedImage.coverSize(1836, 4080, card);

    expect(size.width, 948);
    expect(size.height, 2107);
  });

  test('the decoded photo always covers the card, whatever its shape', () {
    for (final (width, height) in [
      (1836, 4080),
      (2048, 1536),
      (3000, 4000),
      (4000, 3000),
    ]) {
      final size = CoverSizedImage.coverSize(width, height, card);
      expect(size.width, greaterThanOrEqualTo(card.width), reason: '$width');
      expect(size.height, greaterThanOrEqualTo(card.height), reason: '$width');
      // And no larger than needed: one side matches the card.
      expect(
        size.width! <= card.width + 1 || size.height! <= card.height + 1,
        isTrue,
        reason: '$width x $height',
      );
    }
  });

  test('a photo smaller than the card is never scaled up', () {
    final size = CoverSizedImage.coverSize(720, 1280, card);

    expect((size.width, size.height), (720, 1280));
  });
}
