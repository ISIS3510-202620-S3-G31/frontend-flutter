import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/models/cookie_model.dart';
import 'package:frontend_flutter/data/repositories/cookie_repository.dart';
import 'package:frontend_flutter/data/services/local/cookie_dao.dart';
import 'package:frontend_flutter/data/services/local/cookie_image_store.dart';
import 'package:frontend_flutter/data/services/local/cookie_memory_cache.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'cookie_fakes.dart';

void main() {
  sqfliteFfiInit();

  late Directory folder;
  late CookieDao dao;
  late CookieImageStore images;
  late FakeCookieRemote cloud;
  late FakeConnectivity network;
  late FakeSyncPreferences preferences;
  late DateTime clock;

  setUp(() {
    folder = Directory.systemTemp.createTempSync('cookie_sync_test');
    dao = CookieDao(factory: databaseFactoryFfi, folder: folder.path);
    images = CookieImageStore(folder: Directory('${folder.path}/images'));
    cloud = FakeCookieRemote();
    network = FakeConnectivity(online: false);
    preferences = FakeSyncPreferences();
    clock = DateTime(2026, 11, 26, 10);
  });

  final created = <CookieRepository>[];

  tearDown(() async {
    for (final repo in created) {
      await repo.whenIdle();
    }
    created.clear();
    await dao.close();
    folder.deleteSync(recursive: true);
  });

  CookieRepository repository() => _track(
    created,
    CookieRepository(
      dao: dao,
      images: images,
      memory: CookieMemoryCache(),
      remote: cloud,
      connectivity: network,
      syncPreferences: preferences,
      currentUserId: () => 'ana',
      now: () => clock,
    ),
  );

  Uint8List jpeg([int value = 7]) => Uint8List.fromList(List.filled(32, value));

  /// A cookie created on the account's other phone, already in the cloud.
  CookieModel fromOtherPhone(String id, String title, {int createdAt = 1}) =>
      CookieModel(
        id: id,
        userId: 'ana',
        title: title,
        text: 'from the other phone',
        createdAt: createdAt,
        updatedAt: createdAt,
        isSynced: true,
      );

  test('offline, a cookie waits on the phone; online, it uploads', () async {
    final repo = repository();
    final created = await repo.create(title: 'A', text: 't', photo: jpeg());
    expect((await repo.sync()).offline, isTrue);
    expect(cloud.docs, isEmpty);

    network.online = true;
    final report = await repo.sync();

    expect(report.allBackedUp, isTrue);
    final id = created.cookie.id;
    expect(cloud.calls, ['image $id', 'doc $id']);
    expect(cloud.docs[id]!.remoteImageUrl, isNotNull);
    final saved = (await repo.cookies()).single;
    expect(saved.isSynced, isTrue);
    expect(saved.remoteImageUrl, cloud.docs[id]!.remoteImageUrl);
  });

  test('a lost connection halfway leaves the rest waiting', () async {
    final repo = repository();
    await repo.create(title: 'A', text: 't');
    network.online = true;
    cloud.failNext = true;

    final report = await repo.sync();
    expect(report.failed, isTrue);
    expect(report.pending, 1);
    expect((await repo.cookies()).single.isSynced, isFalse);

    expect((await repo.sync()).allBackedUp, isTrue);
  });

  test('eating offline uploads the new state later', () async {
    network.online = true;
    final repo = repository();
    final id = (await repo.create(title: 'A', text: 't')).cookie.id;
    await repo.sync();

    network.online = false;
    await repo.eat(id);
    network.online = true;
    await repo.sync();

    expect(cloud.docs[id]!.state, CookieState.eaten);
  });

  test('a delete made offline reaches the cloud later', () async {
    network.online = true;
    final repo = repository();
    final id = (await repo.create(
      title: 'A',
      text: 't',
      photo: jpeg(),
    )).cookie.id;
    await repo.sync();
    expect(cloud.images, contains(id));

    network.online = false;
    await repo.eat(id);
    await repo.deleteForever(id);
    expect(cloud.docs, contains(id));

    network.online = true;
    await repo.sync();
    expect(cloud.docs, isNot(contains(id)));
    expect(cloud.images, isNot(contains(id)));
  });

  test('a refresh brings the cookies of the other phone', () async {
    cloud.docs['x'] = fromOtherPhone('x', 'Trip');
    network.online = true;
    final repo = repository();

    final report = await repo.refreshFromCloud();

    expect(report.arrived, 1);
    final arrived = (await repo.cookies()).single;
    expect(arrived.title, 'Trip');
    expect(arrived.isSynced, isTrue);
  });

  test('a cookie deleted on the other phone leaves this one', () async {
    network.online = true;
    final repo = repository();
    final id = (await repo.create(title: 'A', text: 't')).cookie.id;
    await repo.sync();

    cloud.docs.remove(id);
    await repo.refreshFromCloud();

    expect(await repo.cookies(), isEmpty);
  });

  test('a cookie created offline is not taken for a deleted one', () async {
    final repo = repository();
    await repo.create(title: 'Not uploaded yet', text: 't');
    network.online = true;
    cloud.failNext = false;
    await repo.refreshFromCloud();
    expect(await repo.cookies(), hasLength(1));
  });

  test('the same title on two phones: the newer one gets -1', () async {
    final repo = repository();
    clock = DateTime(2026, 11, 26, 9);
    await repo.create(title: 'Mi grado', text: 'this phone, earlier');
    final otherId = 'other-phone';
    cloud.docs[otherId] = fromOtherPhone(
      otherId,
      'Mi grado',
      createdAt: DateTime(2026, 11, 26, 10).millisecondsSinceEpoch,
    );
    network.online = true;

    final report = await repo.refreshFromCloud();

    expect(report.renamed, [('Mi grado', 'Mi grado-1')]);
    final titles = {for (final c in await repo.cookies()) c.id: c.title};
    expect(titles[otherId], 'Mi grado-1');
    expect(titles.values, contains('Mi grado'));
  });

  test('last write wins: a later change on the other phone wins', () async {
    network.online = true;
    final repo = repository();
    final id = (await repo.create(title: 'A', text: 't')).cookie.id;
    await repo.sync();

    final later = cloud.docs[id]!;
    cloud.docs[id] = CookieModel.fromFirestore(id, {
      ...later.toFirestore(),
      'state': 'EATEN',
      'updatedAt': later.updatedAt + 1000,
    });
    await repo.refreshFromCloud();

    expect((await repo.cookies()).single.state, CookieState.eaten);
  });

  test('a new phone offline knows its cookies are in the cloud', () async {
    final repo = repository();
    expect((await repo.refreshFromCloud()).neverDownloaded, isTrue);

    network.online = true;
    await repo.refreshFromCloud();
    network.online = false;
    expect((await repo.refreshFromCloud()).neverDownloaded, isFalse);
  });

  test("today's photos download in parallel; one failure stops none", () async {
    cloud.docs['a'] = fromOtherPhone('a', 'A');
    cloud.docs['b'] = fromOtherPhone('b', 'B');
    for (final id in ['a', 'b']) {
      cloud.docs[id] = CookieModel.fromFirestore(id, {
        ...cloud.docs[id]!.toFirestore(),
        'hasImage': true,
        'imageUrl': 'https://storage.example/$id.jpg',
      });
      cloud.images[id] = jpeg();
    }
    cloud.failingDownloads.add('a');
    network.online = true;
    final repo = repository();
    await repo.refreshFromCloud();

    final arrived = await repo.prefetchToday(await repo.cookies());

    expect(arrived, 1);
    final byId = {for (final c in await repo.cookies()) c.id: c};
    expect(byId['b']!.hasLocalImage, isTrue);
    expect(byId['a']!.hasLocalImage, isFalse);
  });
}

CookieRepository _track(List<CookieRepository> created, CookieRepository repo) {
  created.add(repo);
  return repo;
}
