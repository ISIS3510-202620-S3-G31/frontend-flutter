import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/models/cookie_model.dart';
import 'package:frontend_flutter/data/repositories/cookie_repository.dart';
import 'package:frontend_flutter/data/services/local/cookie_dao.dart';
import 'package:frontend_flutter/data/services/local/cookie_image_store.dart';
import 'package:frontend_flutter/data/services/local/cookie_memory_cache.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late Directory folder;
  late CookieDao dao;
  late CookieImageStore images;
  late CookieMemoryCache memory;
  late String? user;
  late DateTime clock;

  setUp(() {
    folder = Directory.systemTemp.createTempSync('cookie_repository_test');
    dao = CookieDao(factory: databaseFactoryFfi, folder: folder.path);
    images = CookieImageStore(folder: Directory('${folder.path}/images'));
    memory = CookieMemoryCache();
    user = 'ana';
    clock = DateTime(2026, 11, 26, 10);
  });

  tearDown(() async {
    await dao.close();
    folder.deleteSync(recursive: true);
  });

  CookieRepository repository() => CookieRepository(
    dao: dao,
    images: images,
    memory: memory,
    currentUserId: () => user,
    now: () => clock,
  );

  Uint8List jpeg() => Uint8List.fromList(List.filled(64, 7));

  test('a new cookie is saved on the phone, active and not synced', () async {
    final repo = repository();
    final created = await repo.create(title: ' Mi  grado ', text: 'Lo logré');

    expect(created.wasRenamed, isFalse);
    final saved = (await repo.cookies()).single;
    expect(saved.title, 'Mi grado');
    expect(saved.state, CookieState.active);
    expect(saved.isSynced, isFalse);
    expect(saved.hasImage, isFalse);
  });

  test('a repeated title gets a suffix instead of failing', () async {
    final repo = repository();
    await repo.create(title: 'Mi grado', text: 'uno');
    final second = await repo.create(title: 'mí GRADO', text: 'dos');

    expect(second.wasRenamed, isTrue);
    expect(second.cookie.title, 'mí GRADO-1');
    expect(await repo.finalTitleFor('Mi grado'), 'Mi grado-2');
  });

  test('a broken rule is reported, not saved', () async {
    final repo = repository();
    expect(
      () => repo.create(title: '   ', text: 'text'),
      throwsA(isA<CookieRuleException>()),
    );
  });

  test('the photo is kept in a private file and in memory', () async {
    final repo = repository();
    final created = await repo.create(title: 'Foto', text: 't', photo: jpeg());

    final cookie = created.cookie;
    expect(cookie.hasLocalImage, isTrue);
    expect(await images.read(cookie.localImagePath!), jpeg());
    expect(memory.get(cookie.id), isNotNull);

    memory.clear();
    expect(await repo.photoOf(cookie), jpeg());
  });

  test('eat and return to jar change the state, never delete', () async {
    final repo = repository();
    final id = (await repo.create(title: 'A', text: 't')).cookie.id;

    await repo.eat(id);
    expect((await repo.cookies()).single.state, CookieState.eaten);

    await repo.returnToJar(id);
    expect((await repo.cookies()).single.state, CookieState.active);
  });

  test('only eaten cookies can be deleted forever', () async {
    final repo = repository();
    final id = (await repo.create(title: 'A', text: 't', photo: jpeg()))
        .cookie
        .id;

    expect(() => repo.deleteForever(id), throwsA(isA<CookieRuleException>()));

    await repo.eat(id);
    final deleted = await repo.deleteForever(id);
    expect(await repo.cookies(), isEmpty);
    expect(await images.read(deleted.localImagePath!), isNull);
    // The title is free again.
    expect(await repo.finalTitleFor('A'), 'A');
  });

  test('watchers hear every change', () async {
    final repo = repository();
    final emitted = <int>[];
    final subscription = repo.watchCookies().listen((c) => emitted.add(c.length));

    Future<void> untilEmitted(int count) async {
      for (var i = 0; i < 500 && emitted.length < count; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }

    await untilEmitted(1);
    await repo.create(title: 'A', text: 't');
    await repo.create(title: 'B', text: 't');
    await untilEmitted(3);

    expect(emitted, [0, 1, 2]);
    await subscription.cancel();
  });

  test('two accounts on one phone never see each other', () async {
    final repo = repository();
    await repo.create(title: 'Ana cookie', text: 't');
    user = 'luis';
    expect(await repo.cookies(), isEmpty);
    expect(await repo.finalTitleFor('Ana cookie'), 'Ana cookie');
  });

  test("today's pick is the same all day", () async {
    final repo = repository();
    for (var n = 1; n <= 12; n++) {
      await repo.create(title: 'Cookie $n', text: 't');
    }
    final all = await repo.cookies();
    final morning = repo.todaysCookies(all).map((c) => c.id).toList();
    clock = DateTime(2026, 11, 26, 23);
    final night = repo.todaysCookies(all).map((c) => c.id).toList();

    expect(morning, hasLength(10));
    expect(night, morning);
  });
}
