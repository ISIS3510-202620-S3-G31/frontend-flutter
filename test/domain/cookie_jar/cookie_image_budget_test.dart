import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/domain/cookie_jar/cookie_image_budget.dart';

void main() {
  StoredCookieImage image(
    String id, {
    int bytes = 100,
    int openedAt = 0,
    bool synced = true,
  }) => StoredCookieImage(
    cookieId: id,
    bytes: bytes,
    lastOpenedAt: openedAt,
    isSynced: synced,
  );

  test('nothing leaves while everything fits', () {
    final images = [image('a'), image('b')];
    expect(CookieImageBudget.toEvict(images, limit: 200), isEmpty);
  });

  test('the least recently opened photo leaves first, not the oldest', () {
    final images = [
      image('opened-yesterday', openedAt: 50),
      image('opened-last-month', openedAt: 10),
      image('opened-today', openedAt: 90),
    ];
    expect(CookieImageBudget.toEvict(images, limit: 200), [
      'opened-last-month',
    ]);
  });

  test('evicts as many as needed to fit', () {
    final images = [
      image('a', openedAt: 1),
      image('b', openedAt: 2),
      image('c', openedAt: 3),
      image('d', openedAt: 4),
    ];
    expect(CookieImageBudget.toEvict(images, limit: 150), ['a', 'b', 'c']);
  });

  test('a photo that did not upload yet is never evicted', () {
    final images = [
      image('only-on-this-phone', openedAt: 1, synced: false),
      image('in-the-cloud', openedAt: 2),
    ];
    expect(CookieImageBudget.toEvict(images, limit: 100), ['in-the-cloud']);
  });

  test("today's cookies are never evicted", () {
    final images = [image('today', openedAt: 1), image('other', openedAt: 2)];
    expect(
      CookieImageBudget.toEvict(images, limit: 100, protectedIds: {'today'}),
      ['other'],
    );
  });
}
