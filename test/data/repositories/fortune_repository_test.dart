import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/models/fortune_model.dart';
import 'package:frontend_flutter/data/repositories/fortune_repository.dart';
import 'package:frontend_flutter/data/services/connectivity_service.dart';
import 'package:frontend_flutter/data/services/local/fortune_cache.dart';
import 'package:frontend_flutter/data/services/local/fortune_chances_storage.dart';
import 'package:frontend_flutter/data/services/remote/fortune_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeApi extends FortuneApiService {
  _FakeApi(this.answer);

  List<Fortune> answer;
  int calls = 0;

  @override
  Future<List<Fortune>> fetchTwoAndTwo() async {
    calls++;
    return answer;
  }
}

class _Online implements ConnectivityChecker {
  _Online(this.online);

  bool online;

  @override
  Future<bool> isOnline() async => online;
}

class _Seeds extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => throw UnimplementedError();

  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      '[{"quote": "Seed one."}, {"quote": "Seed two."}, {"quote": "Seed three."}]';
}

List<Fortune> _fortunes(String prefix, int count) => [
  for (var i = 0; i < count; i++) Fortune(quote: '$prefix $i'),
];

void main() {
  late Directory folder;
  late _FakeApi api;
  late _Online connectivity;
  late String? userId;
  var today = DateTime(2026, 11, 26, 9);

  FortuneRepository repository() => FortuneRepository(
    cache: FortuneCache(folder: folder, assets: _Seeds()),
    chances: FortuneChancesStorage(now: () => today),
    api: api,
    connectivity: connectivity,
    currentUserId: () => userId,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    folder = await Directory.systemTemp.createTemp('fortune_test');
    api = _FakeApi(_fortunes('Downloaded', 4));
    connectivity = _Online(true);
    userId = 'ana';
    today = DateTime(2026, 11, 26, 9);
  });

  tearDown(() => folder.delete(recursive: true));

  group('the table', () {
    test(
      'downloads when the phone has too few phrases, and keeps them',
      () async {
        final table = await repository().table();

        expect(api.calls, 1);
        expect(table, hasLength(3));
        expect(table.every((c) => c.source == FortuneSource.internet), isTrue);
      },
    );

    test('with three phrases on the phone the network is not used', () async {
      await repository().table();
      final second = await repository().table();

      expect(api.calls, 1);
      expect(second.every((c) => c.source == FortuneSource.phone), isTrue);
    });

    test(
      'offline with nothing saved, the app\'s own phrases fill it',
      () async {
        connectivity.online = false;

        final table = await repository().table();

        expect(api.calls, 0, reason: 'no point waiting for the timeouts');
        expect(table, hasLength(3));
        expect(table.every((c) => c.source == FortuneSource.builtIn), isTrue);
        expect(table.every((c) => c.isOffline), isTrue);
      },
    );

    test('offline, saved phrases come first and seeds fill the gaps', () async {
      api.answer = _fortunes('Saved', 1);
      await repository().table();
      connectivity.online = false;

      final table = await repository().table();

      expect(table.first.source, FortuneSource.phone);
      expect(
        table.skip(1).every((c) => c.source == FortuneSource.builtIn),
        isTrue,
      );
    });
  });

  group('opening a cookie', () {
    test(
      'spends a chance, leaves the deck and becomes the latest recent',
      () async {
        final repo = repository();
        final cookie = (await repo.table()).first;

        final opened = await repo.open(cookie);

        expect(opened!.remainingChances, 4);
        expect(await repo.chancesLeft(), 4);
        expect((await repo.recents()).first.id, cookie.fortune.id);
        final next = await repo.table();
        expect(
          next.map((c) => c.fortune.id),
          isNot(contains(cookie.fortune.id)),
        );
      },
    );

    test('there are five a day, and a new day brings them back', () async {
      final repo = repository();
      for (var i = 0; i < 5; i++) {
        expect(await repo.open((await repo.table()).first), isNotNull);
      }

      expect(await repo.chancesLeft(), 0);
      expect(await repo.open((await repo.table()).first), isNull);

      today = DateTime(2026, 11, 27, 0, 1);
      expect(await repo.chancesLeft(), 5);
    });

    test('only the last five opened are kept, newest first', () async {
      api.answer = _fortunes('Downloaded', 8);
      final repo = repository();
      today = DateTime(2026, 11, 26);
      final opened = <int>[];
      for (var i = 0; i < 7; i++) {
        if (i == 5) today = DateTime(2026, 11, 27);
        final cookie = (await repo.table()).first;
        await repo.open(cookie);
        opened.add(cookie.fortune.id);
      }

      final recents = await repo.recents();

      expect(recents.map((f) => f.id), opened.reversed.take(5));
    });

    test('each account has its own chances and recents', () async {
      final repo = repository();
      await repo.open((await repo.table()).first);

      userId = 'luis';

      expect(await repo.chancesLeft(), 5);
      expect(await repo.recents(), isEmpty);
    });
  });
}
