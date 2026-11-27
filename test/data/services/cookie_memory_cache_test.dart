import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/services/local/cookie_memory_cache.dart';

void main() {
  Uint8List photo(int bytes) => Uint8List(bytes);

  test('a stored photo comes back as the same instance', () {
    final cache = CookieMemoryCache(maxBytes: 300);
    final stored = photo(100);
    cache.put('a', stored);
    expect(identical(cache.get('a'), stored), isTrue);
  });

  test('a miss is null', () {
    expect(CookieMemoryCache().get('nope'), isNull);
  });

  test('when full, the least recently used photo leaves first', () {
    final cache = CookieMemoryCache(maxBytes: 300)
      ..put('a', photo(100))
      ..put('b', photo(100))
      ..put('c', photo(100));
    cache.get('a'); // a is now the most recently used
    cache.put('d', photo(100));

    expect(cache.get('b'), isNull);
    expect(cache.get('a'), isNotNull);
    expect(cache.get('c'), isNotNull);
    expect(cache.get('d'), isNotNull);
    expect(cache.bytes, 300);
  });

  test('replacing a photo does not count its bytes twice', () {
    final cache = CookieMemoryCache(maxBytes: 300)
      ..put('a', photo(100))
      ..put('a', photo(150));
    expect(cache.bytes, 150);
    expect(cache.length, 1);
  });

  test('a photo bigger than the whole cache is not kept', () {
    final cache = CookieMemoryCache(maxBytes: 300)..put('a', photo(100));
    cache.put('huge', photo(400));
    expect(cache.get('huge'), isNull);
    expect(cache.get('a'), isNotNull);
  });

  test('clear forgets everything', () {
    final cache = CookieMemoryCache()..put('a', photo(10));
    cache.clear();
    expect(cache.get('a'), isNull);
    expect(cache.bytes, 0);
  });
}
