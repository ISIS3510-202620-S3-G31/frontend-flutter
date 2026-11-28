import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/models/pending_write_model.dart';
import 'package:frontend_flutter/data/models/wish_model.dart';
import 'package:frontend_flutter/data/repositories/offline_sync_repository.dart';
import 'package:frontend_flutter/data/repositories/wish_repository.dart';
import 'package:frontend_flutter/data/services/auth_service.dart';
import 'package:frontend_flutter/data/services/connectivity_service.dart';
import 'package:frontend_flutter/data/services/local/pending_write_storage.dart';
import 'package:frontend_flutter/data/services/local/wish_dao.dart';
import 'package:frontend_flutter/data/services/local/wish_memory_cache.dart';
import 'package:frontend_flutter/data/services/remote/analytics_firestore_service.dart';
import 'package:frontend_flutter/data/services/remote/pending_write_firestore_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FakeAuth extends AuthService {
  FakeAuth(this.userId);

  final String? userId;

  @override
  String? get currentUserId => userId;
}

class FakeConnectivity extends ConnectivityService {
  FakeConnectivity({this.online = true});

  bool online;

  final _changes = StreamController<bool>.broadcast();

  @override
  Future<bool> isOnline() async => online;

  @override
  Stream<bool> get onlineChanges => _changes.stream;

  void emit(bool value) => _changes.add(value);
}

class FakeAnalytics extends AnalyticsFirestoreService {
  final List<Map<String, Object?>> events = [];

  @override
  Future<String> create(String userId, Map<String, Object?> event) async {
    events.add(event);
    return 'event-${events.length}';
  }
}

class FakeRemote extends PendingWriteFirestoreService {
  final Map<String, Map<String, Object?>> docs = {};
  final List<String> deleted = [];

  @override
  Future<void> set(String path, Map<String, Object?> data) async {
    docs[path] = data;
  }

  @override
  Future<void> delete(String path) async {
    deleted.add(path);
    docs.remove(path);
  }
}

/// Counts the `all` reads, so tests can tell a sqflite query from a cache hit.
class CountingWishDao extends WishDao {
  CountingWishDao({super.open});

  int reads = 0;

  @override
  Future<List<Wish>> all(String userId) async {
    reads++;
    return super.all(userId);
  }
}

/// Keeps the queue in a map instead of sqflite.
class FakePendingWrites extends PendingWriteStorage {
  final Map<String, PendingWrite> writes = {};

  @override
  Future<void> add(PendingWrite write) async => writes[write.path] = write;

  @override
  Future<List<PendingWrite>> pendingFor(String userId) async => [
    for (final write in writes.values)
      if (write.userId == userId) write,
  ];

  @override
  Future<void> remove(String path) async => writes.remove(path);
}

void main() {
  late Database db;
  late FakeAnalytics analytics;
  late FakeRemote remote;
  late FakeConnectivity connectivity;
  late FakePendingWrites pendingWrites;
  late WishRepository repository;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 1, onCreate: WishDao.createSchema),
    );
    analytics = FakeAnalytics();
    remote = FakeRemote();
    connectivity = FakeConnectivity();
    pendingWrites = FakePendingWrites();
    repository = WishRepository(
      dao: WishDao(open: () async => db),
      auth: FakeAuth('ana'),
      analytics: analytics,
      remote: remote,
      connectivity: connectivity,
      sync: OfflineSyncRepository(
        storage: pendingWrites,
        remote: remote,
        connectivity: connectivity,
        auth: FakeAuth('ana'),
      ),
      cache: WishMemoryCache(),
    );
  });

  /// A repository with its own fresh cache and the [dao] given, so tests can
  /// count the real sqflite reads.
  WishRepository cachedRepository(WishDao dao) => WishRepository(
    dao: dao,
    auth: FakeAuth('ana'),
    analytics: analytics,
    remote: remote,
    connectivity: connectivity,
    sync: OfflineSyncRepository(
      storage: pendingWrites,
      remote: remote,
      connectivity: connectivity,
      auth: FakeAuth('ana'),
    ),
    cache: WishMemoryCache(),
  );

  tearDown(() async => db.close());

  test('a saved wish is in the local database and in Firestore', () async {
    final wish = await repository.save('see the sunrise');

    expect((await repository.wishes()).single.text, 'see the sunrise');
    expect(
      remote.docs['users/ana/wishes/${wish.id}']!['text'],
      'see the sunrise',
    );
    expect(
      analytics.events.single['name'],
      'wish_created',
      reason: 'BQ26 reads the wish_created events',
    );
    expect(pendingWrites.writes, isEmpty, reason: 'online means no queue');
  });

  test('offline the wish is saved locally and queued as a pending write', () async {
    connectivity.online = false;

    await repository.save('rain tomorrow');
    final wish = (await repository.wishes()).single;

    expect(wish.text, 'rain tomorrow');
    final queued = pendingWrites.writes.values.single;
    expect(queued.path, 'users/ana/wishes/${wish.id}');
    expect(queued.data['text'], 'rain tomorrow');
  });

  test('releasing marks the wish released with a time, locally and queued', () async {
    final wish = await repository.save('let go of Tuesday');
    connectivity.online = false;

    final outcome = await repository.release(wish);

    expect(outcome, SaveOutcome.savedOffline);
    final stored = (await repository.wishes()).single;
    expect(stored.released, isTrue);
    expect(stored.releasedAt, isNotNull);
    expect(
      pendingWrites.writes.values.single.data['released'],
      isTrue,
    );
    expect(
      analytics.events.map((event) => event['name']),
      containsAll(['wish_created', 'wish_released']),
    );
    final releasedEvent = analytics.events.last;
    expect(releasedEvent['wish_id'], wish.id);
    expect(releasedEvent['held_seconds'], isA<int>());
  });

  test('updating a wish changes the text locally and in Firestore', () async {
    final wish = await repository.save('first try');

    final outcome = await repository.update(wish, 'second try');

    expect(outcome, SaveOutcome.saved);
    expect((await repository.wishes()).single.text, 'second try');
    expect(
      remote.docs['users/ana/wishes/${wish.id}']!['text'],
      'second try',
    );
    expect(
      analytics.events.map((event) => event['name']),
      contains('wish_edited'),
      reason: 'BQ26 reads the wish_edited events',
    );
    expect(pendingWrites.writes, isEmpty, reason: 'online means no queue');
  });

  test('updating offline keeps the wish locally and queues the new text', () async {
    final wish = await repository.save('first try');
    connectivity.online = false;

    final outcome = await repository.update(wish, 'second try');

    expect(outcome, SaveOutcome.savedOffline);
    expect((await repository.wishes()).single.text, 'second try');
    final queued = pendingWrites.writes.values.single;
    expect(queued.path, 'users/ana/wishes/${wish.id}');
    expect(queued.data['text'], 'second try');
  });

  test('deleting a wish removes it locally and from Firestore, without a queued set', () async {
    final wish = await repository.save('gone soon');
    connectivity.online = false;

    await repository.delete(wish);

    expect(await repository.wishes(), isEmpty);
    expect(remote.deleted, ['users/ana/wishes/${wish.id}']);
    expect(
      analytics.events.map((event) => event['name']),
      contains('wish_deleted'),
    );
    // A queued set would resurrect the wish on the next sync, so the delete
    // must not be in the pending-writes queue.
    expect(pendingWrites.writes, isEmpty);
  });

  test('the four BQ26 events fire with the documented names, in order', () async {
    final wish = await repository.save('one');
    await repository.release(wish);
    await repository.update(wish, 'two');
    await repository.delete(wish);

    expect(
      analytics.events.map((event) => event['name']),
      ['wish_created', 'wish_released', 'wish_edited', 'wish_deleted'],
      reason: 'BQ26 depends on exactly these four event names',
    );
  });

  test('wishes come back newest first', () async {
    await repository.save('first');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repository.save('second');

    final wishes = await repository.wishes();
    expect(wishes.map((wish) => wish.text), ['second', 'first']);
  });

  test('the screens query sqflite once and then the in-memory cache answers', () async {
    final counting = CountingWishDao(open: () async => db);
    final repo = cachedRepository(counting);

    await repo.save('first');
    await repo.save('second');

    final first = await repo.wishes();
    final second = await repo.wishes();
    final third = await repo.wishes();

    expect(counting.reads, 1, reason: 'only the first read reaches sqflite');
    expect(second, same(first));
    expect(third, same(first));
    expect(first.map((wish) => wish.text), ['second', 'first']);
  });

  test('any wish change invalidates the cache', () async {
    final counting = CountingWishDao(open: () async => db);
    final repo = cachedRepository(counting);

    final wish = await repo.save('one');
    await repo.wishes();
    expect(counting.reads, 1);

    await repo.save('two');
    await repo.wishes();
    expect(counting.reads, 2, reason: 'a new wish drops the cached list');

    await repo.update(wish, 'one edited');
    await repo.wishes();
    expect(counting.reads, 3, reason: 'an edit drops the cached list');

    await repo.release(wish);
    await repo.wishes();
    expect(counting.reads, 4, reason: 'a release drops the cached list');

    await repo.delete(wish);
    await repo.wishes();
    expect(counting.reads, 5, reason: 'a delete drops the cached list');
  });

  test('no signed-in user means no wishes and no crash', () async {
    final anonymous = WishRepository(
      dao: WishDao(open: () async => db),
      auth: FakeAuth(null),
      analytics: analytics,
      remote: remote,
      connectivity: connectivity,
    );
    expect(await anonymous.wishes(), isEmpty);
    expect(() => anonymous.save('nope'), throwsA(isA<AuthException>()));
  });
}
