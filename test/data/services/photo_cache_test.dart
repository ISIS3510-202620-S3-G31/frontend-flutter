import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/services/local/photo_cache.dart';

void main() {
  late Directory folder;
  late DateTime clock;

  setUp(() {
    folder = Directory.systemTemp.createTempSync('photo_cache_test');
    clock = DateTime(2026, 10, 30, 12);
  });

  tearDown(() => folder.deleteSync(recursive: true));

  PhotoCache cacheOf({int maxBytes = 300}) =>
      PhotoCache(folder: folder, maxBytes: maxBytes, now: () => clock);

  /// Photos are stand-ins: what matters is their size, not their content.
  List<int> photo(int bytes) => List.filled(bytes, 0);

  DateTime day(int d) => DateTime(2026, 10, d);

  test('a day this phone never downloaded is a miss', () async {
    expect(await cacheOf().photoFor('ana', day(26)), isNull);
  });

  test('a saved photo comes back', () async {
    final cache = cacheOf();
    await cache.save('ana', day(26), photo(100));

    final found = await cache.photoFor('ana', day(26));
    expect(found, isNotNull);
    expect(await found!.length(), 100);
  });

  test('two accounts on one phone never see each other', () async {
    final cache = cacheOf();
    await cache.save('ana', day(26), photo(100));

    expect(await cache.photoFor('luis', day(26)), isNull);
  });

  test('drops the least recently seen first', () async {
    final cache = cacheOf(maxBytes: 300);
    for (final d in [26, 27, 28]) {
      await cache.save('ana', day(d), photo(100));
      clock = clock.add(const Duration(minutes: 1));
    }

    // Looking at the oldest one renews it, so the next one in line is Oct 27.
    await cache.photoFor('ana', day(26));
    clock = clock.add(const Duration(minutes: 1));

    await cache.save('ana', day(29), photo(100));

    expect(await cache.photoFor('ana', day(27)), isNull);
    expect(await cache.photoFor('ana', day(26)), isNotNull);
    expect(await cache.photoFor('ana', day(28)), isNotNull);
    expect(await cache.photoFor('ana', day(29)), isNotNull);
  });

  test('stays inside the budget', () async {
    final cache = cacheOf(maxBytes: 250);
    for (final d in [26, 27, 28, 29, 30]) {
      await cache.save('ana', day(d), photo(100));
      clock = clock.add(const Duration(minutes: 1));
    }

    expect(await cache.bytesUsed('ana'), lessThanOrEqualTo(250));
  });

  test('each account gets its own budget', () async {
    final cache = cacheOf(maxBytes: 250);
    for (final d in [26, 27]) {
      await cache.save('ana', day(d), photo(100));
      clock = clock.add(const Duration(minutes: 1));
    }

    // Filling Luis's cache must not cost Ana hers.
    for (final d in [26, 27, 28]) {
      await cache.save('luis', day(d), photo(100));
      clock = clock.add(const Duration(minutes: 1));
    }

    expect(await cache.photoFor('ana', day(26)), isNotNull);
    expect(await cache.photoFor('ana', day(27)), isNotNull);
    expect(await cache.photoFor('luis', day(26)), isNull);
  });

  test('the photo just downloaded is never the one dropped', () async {
    final cache = cacheOf(maxBytes: 150);
    await cache.save('ana', day(26), photo(100));
    clock = clock.add(const Duration(minutes: 1));
    await cache.save('ana', day(27), photo(100));

    expect(await cache.photoFor('ana', day(27)), isNotNull);
  });

  test('signing out forgets that account only', () async {
    final cache = cacheOf();
    await cache.save('ana', day(26), photo(100));
    await cache.save('luis', day(26), photo(100));

    await cache.forget('ana');

    expect(await cache.photoFor('ana', day(26)), isNull);
    expect(await cache.photoFor('luis', day(26)), isNotNull);
  });
}
