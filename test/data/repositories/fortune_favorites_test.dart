import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/models/fortune_model.dart';
import 'package:frontend_flutter/data/repositories/fortune_repository.dart';
import 'package:frontend_flutter/data/services/connectivity_service.dart';
import 'package:frontend_flutter/data/services/local/fortune_cache.dart';
import 'package:frontend_flutter/data/services/local/fortune_database.dart';
import 'package:frontend_flutter/data/services/local/fortune_favorites_dao.dart';
import 'package:frontend_flutter/data/services/remote/fortune_remote_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Firestore's favorite_fortunes collection, per account.
class _FakeRemote implements FortuneRemoteService {
  final Map<String, Map<int, Fortune>> docs = {};
  bool fail = false;

  Map<int, Fortune> _of(String userId) => docs.putIfAbsent(userId, () => {});

  void _check() {
    if (fail) throw const SocketException('no network');
  }

  @override
  Future<void> keep(String userId, Fortune fortune) async {
    _check();
    _of(userId)[fortune.id] = fortune;
  }

  @override
  Future<void> remove(String userId, int id) async {
    _check();
    _of(userId).remove(id);
  }

  @override
  Future<List<Fortune>> favorites(String userId) async {
    _check();
    return _of(userId).values.toList();
  }

  @override
  Duration get timeLimit => Duration.zero;
}

class _Online implements ConnectivityChecker {
  bool online = true;

  @override
  Future<bool> isOnline() async => online;
}

void main() {
  sqfliteFfiInit();

  late Database db;
  late _FakeRemote remote;
  late _Online connectivity;
  late String? userId;

  FortuneRepository repository() => FortuneRepository(
    cache: FortuneCache(folder: Directory.systemTemp),
    favorites: FortuneFavoritesDao(open: () async => db),
    remote: remote,
    connectivity: connectivity,
    currentUserId: () => userId,
  );

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: FortuneDatabase.create,
      ),
    );
    remote = _FakeRemote();
    connectivity = _Online();
    userId = 'ana';
  });

  tearDown(() => db.close());

  final calm = Fortune(quote: 'Breathe in, breathe out.');
  final bold = Fortune(quote: 'Say yes to something new.');

  test(
    'keeping works offline and goes up when the connection returns',
    () async {
      final repo = repository();
      connectivity.online = false;

      expect(await repo.toggleKept(calm), isTrue);
      await repo.sync();

      expect(repo.isKept(calm.id), isTrue);
      expect((await repo.favorites()).single.quote, calm.quote);
      expect(remote.docs['ana'], isNull, reason: 'nothing went up offline');

      connectivity.online = true;
      await repo.sync();

      expect(remote.docs['ana']!.keys, [calm.id]);
    },
  );

  test('a fortune let go offline is not brought back by the account', () async {
    final repo = repository();
    await repo.favorites();
    await repo.toggleKept(calm);
    await repo.sync();

    connectivity.online = false;
    expect(await repo.toggleKept(calm), isFalse);
    expect(await repo.favorites(), isEmpty);

    connectivity.online = true;
    await repo.sync();

    expect(await repo.favorites(), isEmpty);
    expect(remote.docs['ana'], isEmpty);
  });

  test('what another phone kept shows here too', () async {
    remote.docs['ana'] = {bold.id: bold};

    final repo = repository();
    await repo.sync();

    expect((await repo.favorites()).map((f) => f.id), [bold.id]);
  });

  test(
    'if Firestore fails the change stays pending for the next time',
    () async {
      final repo = repository();
      remote.fail = true;
      await repo.toggleKept(calm);
      await repo.sync();

      remote.fail = false;
      await repo.sync();

      expect(remote.docs['ana']!.keys, [calm.id]);
    },
  );

  test('each account keeps its own fortunes', () async {
    final repo = repository();
    await repo.toggleKept(calm);

    userId = 'luis';

    expect(await repo.favorites(), isEmpty);
    expect(repo.isKept(calm.id), isFalse);
  });
}
