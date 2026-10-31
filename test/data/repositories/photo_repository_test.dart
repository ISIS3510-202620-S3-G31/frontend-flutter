import 'dart:io';

import 'package:camera/camera.dart' show XFile;
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/repositories/photo_repository.dart';
import 'package:frontend_flutter/data/services/local/photo_cache.dart';

import 'photo_fakes.dart';

/// Two accounts sharing one phone must never see or upload each other's
/// photos: the bug this guards against showed Ana's photo to Luis, and could
/// upload it to his Firebase folder.
void main() {
  late Directory root;
  late FakeAuth auth;
  late FakeStorage storage;
  late FakeDao dao;
  late FakeRemote remote;
  late FakeConnectivity connectivity;
  late PhotoCache cache;
  late FakeCompressor compressor;
  late PhotoRepository repository;

  final monday = DateTime(2026, 10, 26);
  final week = [for (var i = 0; i < 7; i++) monday.add(Duration(days: i))];

  setUp(() {
    root = Directory.systemTemp.createTempSync('photo_repository_test');
    auth = FakeAuth('ana');
    storage = FakeStorage(root);
    dao = FakeDao();
    remote = FakeRemote();
    connectivity = FakeConnectivity();
    cache = PhotoCache(folder: Directory('${root.path}/cache'));
    compressor = FakeCompressor();
    repository = PhotoRepository(
      storage: storage,
      dao: dao,
      cache: cache,
      remote: remote,
      connectivity: connectivity,
      auth: auth,
      compressor: compressor,
    );
  });

  tearDown(() => root.deleteSync(recursive: true));

  Future<XFile> somePhoto() async {
    final file = File('${root.path}/picked.jpg');
    await file.writeAsString('an image');
    return XFile(file.path);
  }

  test('one account cannot see the photo of another', () async {
    await repository.savePhoto(monday, await somePhoto());

    auth.userId = 'luis';
    expect(await repository.photoOf(monday), isNull);

    auth.userId = 'ana';
    expect(await repository.photoOf(monday), isNotNull);
  });

  test('the week only marks the days of the signed-in account', () async {
    await repository.savePhoto(monday, await somePhoto());

    auth.userId = 'luis';
    expect(await repository.daysWithPhoto(week), isEmpty);

    auth.userId = 'ana';
    expect(await repository.daysWithPhoto(week), {monday});
  });

  test('a photo is only ever uploaded for the account that took it', () async {
    await repository.savePhoto(monday, await somePhoto());

    // Ana's photo is still pending when Luis signs in on the same phone.
    auth.userId = 'luis';
    await repository.uploadPending();
    expect(remote.uploads, isEmpty);

    auth.userId = 'ana';
    await repository.uploadPending();
    expect(remote.uploads, ['ana/2026-10-26']);
  });

  test('a pending photo stays pending while there is no connection', () async {
    await repository.savePhoto(monday, await somePhoto());
    connectivity.online = false;

    expect(await repository.uploadPending(), isFalse);
    expect(remote.uploads, isEmpty);

    connectivity.online = true;
    await repository.uploadPending();
    expect(remote.uploads, ['ana/2026-10-26']);
  });

  test('a day is marked as uploaded only once Firebase confirms', () async {
    await repository.savePhoto(monday, await somePhoto());
    expect(await dao.notSyncedDays('ana'), [monday]);

    await repository.uploadPending();
    expect(await dao.notSyncedDays('ana'), isEmpty);
  });

  group('uploading a smaller copy', () {
    test('what goes up is the compressed copy', () async {
      await repository.savePhoto(monday, await somePhoto());

      await repository.uploadPending();

      expect(compressor.compressed, hasLength(1));
      expect(remote.stored['ana/2026-10-26'], 'small(an image)');
    });

    test('the photo on the phone stays the original', () async {
      await repository.savePhoto(monday, await somePhoto());

      await repository.uploadPending();

      final kept = await repository.photoOf(monday);
      expect(await kept!.file.readAsString(), 'an image');
    });

    test('a photo that cannot be compressed goes up as it is', () async {
      await repository.savePhoto(monday, await somePhoto());
      // Decoders can fail with an Error, not only an Exception.
      compressor.failure = RangeError('damaged file');

      await repository.uploadPending();

      expect(remote.stored['ana/2026-10-26'], 'an image');
      // And it is not left pending forever.
      expect(await dao.notSyncedDays('ana'), isEmpty);
    });
  });

  group('a photo this phone did not take', () {
    final wednesday = DateTime(2026, 10, 28);

    setUp(() => remote.stored['ana/2026-10-28'] = 'from the other phone');

    test('is downloaded and then served from the cache', () async {
      final first = await repository.anyPhotoOf(wednesday);
      expect(first, isNotNull);
      expect(await first!.file.readAsString(), 'from the other phone');
      expect(remote.downloads, ['ana/2026-10-28']);

      // The second look must not cost another download.
      final second = await repository.anyPhotoOf(wednesday);
      expect(second, isNotNull);
      expect(remote.downloads, ['ana/2026-10-28']);
    });

    test('is never downloaded when this phone took it', () async {
      await repository.savePhoto(monday, await somePhoto());

      final found = await repository.anyPhotoOf(monday);
      expect(found, isNotNull);
      expect(remote.downloads, isEmpty);
    });

    test('is not cached under another account', () async {
      await repository.anyPhotoOf(wednesday);

      auth.userId = 'luis';
      expect(await repository.anyPhotoOf(wednesday), isNull);
    });

    test('marks the day in the week even though it is not on this phone', () async {
      expect(await repository.daysWithPhoto(week), {wednesday});
    });

    test('leaves the week showing this phone when the network fails', () async {
      await repository.savePhoto(monday, await somePhoto());
      remote.failure = Exception('no connection');

      expect(await repository.daysWithPhoto(week), {monday});
    });

    test('offline, it gives up at once instead of trying to download', () async {
      connectivity.online = false;

      expect(await repository.anyPhotoOf(wednesday), isNull);
      // Storage would have retried for minutes; it is never even asked.
      expect(remote.downloads, isEmpty);
    });

    test('offline, a photo already cached still shows', () async {
      await repository.anyPhotoOf(wednesday);
      connectivity.online = false;

      expect(await repository.anyPhotoOf(wednesday), isNotNull);
    });

    test('shows nothing rather than failing when it cannot be fetched', () async {
      remote.failure = Exception('no connection');

      expect(await repository.anyPhotoOf(wednesday), isNull);
    });

    test('a day nobody has a photo for stays empty', () async {
      expect(await repository.anyPhotoOf(DateTime(2026, 10, 27)), isNull);
    });
  });

  group('clearing what the shared folder left behind', () {
    test('drops the loose photos and keeps the ones of each account', () async {
      await repository.savePhoto(monday, await somePhoto());
      // A photo from before the split: in the root, belonging to nobody.
      final orphan = File('${root.path}/2026-10-20.jpg');
      await orphan.writeAsString('older image');

      await repository.discardSharedLeftovers();

      expect(await orphan.exists(), isFalse);
      expect(dao.sharedDatabaseDeleted, isTrue);
      expect(await repository.photoOf(monday), isNotNull);
    });

    test('only runs once, since there is nothing left to clear', () async {
      await repository.discardSharedLeftovers();
      await repository.discardSharedLeftovers();

      expect(storage.cleanups, 1);
    });
  });

  group('with nobody signed in', () {
    setUp(() => auth.userId = null);

    test('there is no photo to show', () async {
      expect(await repository.photoOf(monday), isNull);
      expect(await repository.daysWithPhoto(week), isEmpty);
    });

    test('saving is refused instead of landing in a shared folder', () async {
      expect(
        () async => repository.savePhoto(monday, await somePhoto()),
        throwsStateError,
      );
    });
  });
}
