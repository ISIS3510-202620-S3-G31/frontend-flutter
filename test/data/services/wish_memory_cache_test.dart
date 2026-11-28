import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/models/wish_model.dart';
import 'package:frontend_flutter/data/services/local/wish_memory_cache.dart';

Wish wish(String id) =>
    Wish.create('wish $id', id: id, createdAt: DateTime(2026, 11, 27, 12));

void main() {
  late DateTime clock;
  late WishMemoryCache cache;

  setUp(() {
    clock = DateTime(2026, 11, 27, 12);
    cache = WishMemoryCache(now: () => clock);
  });

  test('a miss is null', () {
    expect(cache.get('ana'), isNull);
  });

  test('a stored list comes back as the same instance on every read', () {
    cache.put('ana', [wish('a')]);

    final first = cache.get('ana');
    expect(first, isNotNull);
    expect(cache.get('ana'), same(first));
    expect(first, [wish('a')]);
  });

  test('the cached list cannot be changed from outside', () {
    final source = [wish('a')];
    cache.put('ana', source);
    source.add(wish('b'));

    final cached = cache.get('ana');
    expect(cached, hasLength(1));
    expect(() => cached!.add(wish('c')), throwsUnsupportedError);
  });

  test('a list is still served until the ttl passes, then it expires', () {
    cache.put('ana', [wish('a')]);

    clock = clock.add(const Duration(minutes: 9));
    expect(cache.get('ana'), isNotNull);

    clock = clock.add(const Duration(minutes: 1));
    expect(cache.get('ana'), isNull);
    expect(cache.length, 0, reason: 'the expired entry is dropped, not kept');
  });

  test('when full, the least recently used account leaves first', () {
    final small = WishMemoryCache(maxUsers: 2, now: () => clock)
      ..put('ana', [wish('a')])
      ..put('ben', [wish('b')]);
    small.get('ana'); // ana is now the most recently used
    small.put('cid', [wish('c')]);

    expect(small.get('ben'), isNull);
    expect(small.get('ana'), isNotNull);
    expect(small.get('cid'), isNotNull);
    expect(small.length, 2);
  });

  test('invalidate forgets only the account it is called for', () {
    cache
      ..put('ana', [wish('a')])
      ..put('ben', [wish('b')]);

    cache.invalidate('ana');

    expect(cache.get('ana'), isNull);
    expect(cache.get('ben'), isNotNull);
  });

  test('clear forgets every account', () {
    cache
      ..put('ana', [wish('a')])
      ..put('ben', [wish('b')]);

    cache.clear();

    expect(cache.get('ana'), isNull);
    expect(cache.get('ben'), isNull);
    expect(cache.length, 0);
  });
}
