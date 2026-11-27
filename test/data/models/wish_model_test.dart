import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/models/wish_model.dart';

void main() {
  test('a new wish is held (unreleased) and trimmed', () {
    final wish = Wish.create('  fly with the lanterns  ');
    expect(wish.text, 'fly with the lanterns');
    expect(wish.released, isFalse);
    expect(wish.releasedAt, isNull);
    expect(wish.id, isNotEmpty);
  });

  test('the text is capped at 280 characters', () {
    final wish = Wish.create('a' * 400);
    expect(wish.text.length, Wish.maxLength);
    expect(Wish.limitText('ab' * 200).length, Wish.maxLength);
  });

  test('the map round trip keeps every field', () {
    final releasedAt = DateTime(2026, 11, 27, 22, 15);
    final wish = Wish(
      id: 'w1',
      text: 'more time with family',
      createdAt: DateTime(2026, 11, 27, 21, 40),
      released: true,
      releasedAt: releasedAt,
    );
    final back = Wish.fromMap('w1', wish.toMap());
    expect(back, wish);
    expect(back.releasedAt, releasedAt);
  });

  test('copyWith releases a wish and keeps the rest', () {
    final wish = Wish.create('a wish', createdAt: DateTime(2026, 11, 27));
    final at = DateTime(2026, 11, 27, 23);
    final released = wish.copyWith(released: true, releasedAt: at);
    expect(released.released, isTrue);
    expect(released.releasedAt, at);
    expect(released.id, wish.id);
    expect(released.text, wish.text);
  });
}
