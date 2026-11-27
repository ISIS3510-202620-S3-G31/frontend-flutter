import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/models/fortune_card_model.dart';
import 'package:frontend_flutter/data/models/fortune_model.dart';
import 'package:frontend_flutter/data/repositories/fortune_repository.dart';
import 'package:frontend_flutter/data/services/connectivity_service.dart';
import 'package:frontend_flutter/data/services/fortune_share_service.dart';
import 'package:frontend_flutter/data/services/local/fortune_cache.dart';
import 'package:frontend_flutter/data/services/local/fortune_cards_dao.dart';
import 'package:frontend_flutter/data/services/local/fortune_chances_storage.dart';
import 'package:frontend_flutter/data/services/local/fortune_database.dart';
import 'package:frontend_flutter/data/services/local/fortune_favorites_dao.dart';
import 'package:frontend_flutter/data/services/remote/fortune_remote_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The account in the cloud: Firestore and Storage, per user.
class _FakeCloud implements FortuneRemoteService {
  final Map<String, Map<int, Fortune>> favorites_ = {};
  final Map<String, Map<int, ({RemoteFortuneCard card, Uint8List png})>>
  cards_ = {};
  final Map<String, Map<String, int>> used = {};
  final Map<String, List<Fortune>> recents_ = {};
  bool fail = false;

  void _check() {
    if (fail) throw const SocketException('no network');
  }

  @override
  Duration get timeLimit => Duration.zero;

  @override
  Future<void> keep(String userId, Fortune fortune) async {
    _check();
    favorites_.putIfAbsent(userId, () => {})[fortune.id] = fortune;
  }

  @override
  Future<void> remove(String userId, int id) async {
    _check();
    favorites_[userId]?.remove(id);
  }

  @override
  Future<List<Fortune>> favorites(String userId) async {
    _check();
    return [...?favorites_[userId]?.values];
  }

  @override
  Future<void> uploadCard(
    String userId, {
    required int cookieId,
    required String quote,
    required DateTime savedAt,
    required Uint8List png,
  }) async {
    _check();
    cards_.putIfAbsent(userId, () => {})[cookieId] = (
      card: (
        cookieId: cookieId,
        quote: quote,
        imageUrl: 'https://storage/card_$cookieId.png',
        savedAt: savedAt,
      ),
      png: png,
    );
  }

  @override
  Future<void> removeCard(String userId, int cookieId) async {
    _check();
    cards_[userId]?.remove(cookieId);
  }

  @override
  Future<List<RemoteFortuneCard>> cards(String userId) async {
    _check();
    return [...?cards_[userId]?.values.map((entry) => entry.card)];
  }

  @override
  Future<Uint8List?> downloadCard(String userId, int cookieId) async {
    _check();
    return cards_[userId]?[cookieId]?.png;
  }

  @override
  Future<int> usedOn(String userId, String day) async {
    _check();
    return used[userId]?[day] ?? 0;
  }

  @override
  Future<void> raiseUsed(String userId, String day, int count) async {
    _check();
    final days = used.putIfAbsent(userId, () => {});
    if (count > (days[day] ?? 0)) days[day] = count;
  }

  @override
  Future<List<Fortune>> recents(String userId) async {
    _check();
    return [...?recents_[userId]];
  }

  @override
  Future<void> setRecents(String userId, List<Fortune> recents) async {
    _check();
    recents_[userId] = [...recents];
  }
}

class _Online implements ConnectivityChecker {
  bool online = true;

  @override
  Future<bool> isOnline() async => online;
}

/// Keeps the app's copies in a temporary folder instead of the documents.
class _TempShare extends FortuneShareService {
  _TempShare(this.folder);

  final Directory folder;

  @override
  Future<File> keepCopy(String userId, int cookieId, Uint8List png) async {
    final file = File('${folder.path}/${userId}_card_$cookieId.png');
    await file.writeAsBytes(png);
    return file;
  }
}

void main() {
  sqfliteFfiInit();

  late Database db;
  late Directory folder;
  late _FakeCloud cloud;
  late _Online connectivity;
  late String? userId;
  final today = DateTime(2026, 11, 26, 10);

  FortuneRepository repository() => FortuneRepository(
    cache: FortuneCache(folder: folder),
    chances: FortuneChancesStorage(now: () => today),
    favorites: FortuneFavoritesDao(open: () async => db),
    cards: FortuneCardsDao(open: () async => db),
    share: _TempShare(folder),
    remote: cloud,
    connectivity: connectivity,
    currentUserId: () => userId,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    folder = await Directory.systemTemp.createTemp('fortune_sync');
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: FortuneDatabase.create,
      ),
    );
    cloud = _FakeCloud();
    connectivity = _Online();
    userId = 'ana';
  });

  tearDown(() async {
    await db.close();
    await folder.delete(recursive: true);
  });

  final calm = Fortune(quote: 'Breathe in, breathe out.');
  final bold = Fortune(quote: 'Say yes to something new.');

  group('kept fortunes', () {
    test(
      'keeping works offline and goes up when the connection returns',
      () async {
        final repo = repository();
        connectivity.online = false;

        expect(await repo.toggleKept(calm), isTrue);
        await repo.sync();

        expect(repo.isKept(calm.id), isTrue);
        expect(cloud.favorites_['ana'], isNull, reason: 'nothing went up');

        connectivity.online = true;
        await repo.sync();

        expect(cloud.favorites_['ana']!.keys, [calm.id]);
      },
    );

    test(
      'a fortune let go offline is not brought back by the account',
      () async {
        final repo = repository();
        await repo.toggleKept(calm);
        await repo.sync();

        connectivity.online = false;
        expect(await repo.toggleKept(calm), isFalse);
        connectivity.online = true;
        await repo.sync();

        expect(await repo.favorites(), isEmpty);
        expect(cloud.favorites_['ana'], isEmpty);
      },
    );

    test('what another phone kept shows here too', () async {
      cloud.favorites_['ana'] = {bold.id: bold};

      final repo = repository();
      await repo.sync();

      expect((await repo.favorites()).map((f) => f.id), [bold.id]);
    });

    test('if the cloud fails the change stays pending for next time', () async {
      final repo = repository();
      cloud.fail = true;
      await repo.toggleKept(calm);
      await repo.sync();

      cloud.fail = false;
      await repo.sync();

      expect(cloud.favorites_['ana']!.keys, [calm.id]);
    });

    test('each account keeps its own fortunes', () async {
      final repo = repository();
      await repo.toggleKept(calm);

      userId = 'luis';

      expect(await repo.favorites(), isEmpty);
      expect(repo.isKept(calm.id), isFalse);
    });
  });

  group('shared cards', () {
    Future<FortuneCard> shareOffline(FortuneRepository repo) async {
      final file = File('${folder.path}/made.png');
      await file.writeAsBytes([1, 2, 3]);
      final card = FortuneCard(
        cookieId: calm.id,
        quote: calm.quote,
        localPath: file.path,
        savedAt: today,
      );
      await FortuneCardsDao(open: () async => db).save('ana', card);
      return card;
    }

    test(
      'a card shared offline is uploaded when the connection returns',
      () async {
        final repo = repository();
        await shareOffline(repo);

        await repo.sync();

        expect(cloud.cards_['ana']!.keys, [calm.id]);
        expect(cloud.cards_['ana']![calm.id]!.png, [1, 2, 3]);
      },
    );

    test(
      'a card removed offline is deleted from the cloud, not revived',
      () async {
        final repo = repository();
        final card = await shareOffline(repo);
        await repo.sync();

        connectivity.online = false;
        await repo.removeCard(card);
        expect(await repo.cards(), isEmpty);
        connectivity.online = true;
        await repo.sync();

        expect(cloud.cards_['ana'], isEmpty);
        expect(await repo.cards(), isEmpty);
      },
    );

    test('a card shared on another phone is downloaded here', () async {
      await cloud.uploadCard(
        'ana',
        cookieId: bold.id,
        quote: bold.quote,
        savedAt: today,
        png: Uint8List.fromList([9, 9]),
      );

      final repo = repository();
      await repo.sync();

      final cards = await repo.cards();
      expect(cards.single.quote, bold.quote);
      expect(await File(cards.single.localPath).readAsBytes(), [9, 9]);
    });
  });

  group("today's cookies", () {
    test('cookies opened on another phone are spent here too', () async {
      cloud.used['ana'] = {'2026-11-26': 3};

      final repo = repository();
      await repo.sync();

      expect(await repo.chancesLeft(), 2);
    });

    test('cookies opened offline reach the account later', () async {
      final repo = repository();
      connectivity.online = false;
      await repo.open(
        TableFortune(calm, FortuneSource.builtIn, isOffline: true),
      );
      await repo.open(
        TableFortune(bold, FortuneSource.builtIn, isOffline: true),
      );

      connectivity.online = true;
      await repo.sync();

      expect(cloud.used['ana']!['2026-11-26'], 2);
    });

    test('the larger count wins, so no cookie is ever given back', () async {
      final repo = repository();
      await repo.open(
        TableFortune(calm, FortuneSource.builtIn, isOffline: true),
      );
      cloud.used['ana'] = {'2026-11-26': 4};

      await repo.sync();

      expect(await repo.chancesLeft(), 1);
      expect(cloud.used['ana']!['2026-11-26'], 4);
    });
  });

  group('recent cookies', () {
    test('both phones end with the five newest of either', () async {
      final repo = repository();
      final mine = [
        for (var i = 0; i < 3; i++)
          Fortune(
            quote: 'Mine $i',
            savedAt: today.add(Duration(hours: i)),
          ),
      ];
      final theirs = [
        for (var i = 0; i < 3; i++)
          Fortune(
            quote: 'Theirs $i',
            savedAt: today.add(Duration(minutes: 30 + 60 * i)),
          ),
      ];
      await FortuneCache(folder: folder).setRecents('ana', mine);
      cloud.recents_['ana'] = theirs;

      await repo.sync();

      final expected = [
        // Mine at 0, 1 and 2 h; theirs at 0:30, 1:30 and 2:30. The oldest
        // of all six, Mine 0, is the one left out.
        'Theirs 2', 'Mine 2', 'Theirs 1', 'Mine 1', 'Theirs 0',
      ];
      expect((await repo.recents()).map((f) => f.quote), expected);
      expect(cloud.recents_['ana']!.map((f) => f.quote), expected);
    });
  });
}
