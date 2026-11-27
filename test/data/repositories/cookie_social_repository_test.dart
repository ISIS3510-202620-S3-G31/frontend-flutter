import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/models/cookie_social_models.dart';
import 'package:frontend_flutter/data/repositories/cookie_repository.dart';
import 'package:frontend_flutter/data/repositories/cookie_social_repository.dart';
import 'package:frontend_flutter/data/services/local/cookie_dao.dart';
import 'package:frontend_flutter/data/services/local/cookie_image_store.dart';
import 'package:frontend_flutter/data/services/local/cookie_memory_cache.dart';
import 'package:frontend_flutter/data/services/remote/cookie_social_remote_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'cookie_fakes.dart';

/// Friends and gifts in the backend, in memory.
class FakeSocialRemote implements CookieSocialRemoteService {
  final usernames = <String, String>{};
  final profiles = <String, PublicProfile>{};
  final gifts = <String, Gift>{};
  final giftImages = <String, Uint8List>{};
  final giftImageMetadata = <String, Map<String, String>>{};
  final requests = <FriendRequest>[];
  final calls = <String>[];

  /// Uids whose owner blocked the current user: the rules refuse.
  final blockedBy = <String>{};
  bool failDeletes = false;
  bool failCreateGift = false;

  @override
  Future<PublicProfile?> myProfile(String uid) async => profiles[uid];

  @override
  Future<bool> activate(String uid, String username) async {
    final owner = usernames[username];
    if (owner != null) return owner == uid;
    usernames[username] = uid;
    profiles[uid] = PublicProfile(uid: uid, username: username);
    return true;
  }

  @override
  Future<String?> uidOf(String username) async => usernames[username];

  @override
  Future<void> sendRequest(FriendRequest request) async {
    if (blockedBy.contains(request.to)) throw const SocialRefusedException();
    requests.add(request);
  }

  @override
  Future<void> uploadGiftImage(Gift gift, Uint8List jpeg) async {
    calls.add('image ${gift.shareId}');
    giftImages[gift.shareId] = jpeg;
    giftImageMetadata[gift.shareId] = {'from': gift.from, 'to': gift.to};
  }

  @override
  Future<void> createGift(Gift gift) async {
    if (failCreateGift) throw const ConnectionLostException();
    calls.add('doc ${gift.shareId}');
    gifts[gift.shareId] = gift;
  }

  @override
  Future<bool> deleteGiftIfExists(String shareId) async {
    if (failDeletes) throw const ConnectionLostException();
    return gifts.remove(shareId) != null;
  }

  @override
  Future<void> deleteGiftImage(String shareId) async {
    if (failDeletes) throw const ConnectionLostException();
    giftImages.remove(shareId);
  }

  @override
  Future<Uint8List?> downloadGiftImage(String shareId) async =>
      giftImages[shareId];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  sqfliteFfiInit();

  late Directory folder;
  late CookieDao dao;
  late FakeSocialRemote remote;
  late CookieRepository cookies;

  setUp(() {
    folder = Directory.systemTemp.createTempSync('cookie_social_test');
    dao = CookieDao(factory: databaseFactoryFfi, folder: folder.path);
    remote = FakeSocialRemote();
    cookies = CookieRepository(
      dao: dao,
      images: CookieImageStore(folder: Directory('${folder.path}/images')),
      memory: CookieMemoryCache(),
      connectivity: FakeConnectivity(online: false),
      currentUserId: () => 'ana',
      now: () => DateTime(2026, 11, 26, 10),
    );
  });

  tearDown(() async {
    await cookies.whenIdle();
    await dao.close();
    folder.deleteSync(recursive: true);
  });

  CookieSocialRepository social() => CookieSocialRepository(
    cookies: cookies,
    remote: remote,
    now: () => DateTime(2026, 11, 26, 10),
  );

  Gift giftFor(String shareId, {String title = 'Trip', bool photo = true}) =>
      Gift(
        shareId: shareId,
        from: 'luis',
        fromUsername: 'luis',
        to: 'ana',
        title: title,
        text: 'Remember this?',
        hasImage: photo,
        sentAt: 1,
        expiresAt: DateTime(2026, 12, 1).millisecondsSinceEpoch,
      );

  Uint8List jpeg() => Uint8List.fromList(List.filled(16, 3));

  test('an accepted gift becomes one of my cookies, with its photo', () async {
    remote.gifts['g1'] = giftFor('g1');
    remote.giftImages['g1'] = jpeg();

    final accepted = await social().acceptGift(remote.gifts['g1']!);

    expect(accepted.finished, isTrue);
    final cookie = (await cookies.cookies()).single;
    expect(cookie.id, 'g1');
    expect(cookie.receivedFrom, 'luis');
    expect(cookie.isActive, isTrue);
    expect(cookie.isSynced, isFalse);
    expect(await cookies.photoOf(cookie), jpeg());
    expect(remote.gifts, isEmpty);
    expect(remote.giftImages, isEmpty);
  });

  test('if the network drops after saving, the gift is safe here', () async {
    remote.gifts['g1'] = giftFor('g1', photo: false);
    remote.failDeletes = true;
    final repo = social();

    final accepted = await repo.acceptGift(remote.gifts['g1']!);

    expect(accepted.finished, isFalse);
    expect(await repo.isAccepted(remote.gifts['g1']!), isTrue);
    remote.failDeletes = false;
    await repo.acceptGift(remote.gifts['g1']!);
    expect(await cookies.cookies(), hasLength(1));
    expect(remote.gifts, isEmpty);
  });

  test('a gift whose title I already have gets a suffix', () async {
    await cookies.create(title: 'Trip', text: 'mine');
    remote.gifts['g1'] = giftFor('g1', photo: false);

    final accepted = await social().acceptGift(remote.gifts['g1']!);
    expect(accepted.cookie.title, 'Trip-1');
  });

  test('sending a gift uploads the photo with from/to, then the doc', () async {
    remote.profiles['ana'] = const PublicProfile(uid: 'ana', username: 'ana');
    final mine = (await cookies.create(
      title: 'Grad',
      text: 'Done',
      photo: jpeg(),
    )).cookie;
    final repo = social();

    await repo.sendGift(mine, const Friend(uid: 'luis', username: 'luis'));

    final gift = remote.gifts.values.single;
    expect(remote.calls, ['image ${gift.shareId}', 'doc ${gift.shareId}']);
    expect(remote.giftImageMetadata[gift.shareId], {
      'from': 'ana',
      'to': 'luis',
    });
    expect(gift.fromUsername, 'ana');
    expect(
      gift.expiresAt - gift.sentAt,
      const Duration(days: 7).inMilliseconds,
    );
    final sent = (await repo.sentGifts()).single;
    expect(sent.toUsername, 'luis');
    expect((await cookies.cookies()).single.isActive, isTrue);
  });

  test('a gift that could not be created leaves no orphan photo', () async {
    remote.profiles['ana'] = const PublicProfile(uid: 'ana', username: 'ana');
    remote.failCreateGift = true;
    final mine = (await cookies.create(
      title: 'Grad',
      text: 'Done',
      photo: jpeg(),
    )).cookie;

    await expectLater(
      social().sendGift(mine, const Friend(uid: 'luis', username: 'luis')),
      throwsA(isA<ConnectionLostException>()),
    );
    await pumpEventQueue();
    expect(remote.giftImages, isEmpty);
    expect(await social().sentGifts(), isEmpty);
  });

  test('canceling a gift that is gone says nothing about why', () async {
    final repo = social();
    const gone = SentGift(
      shareId: 'old',
      toUsername: 'luis',
      title: 'Grad',
      sentAt: 1,
    );
    await dao.addSentGift('ana', gone);
    expect(await repo.cancelGift(gone), isFalse);
    expect(await repo.sentGifts(), isEmpty);
  });

  group('friend requests', () {
    setUp(() {
      remote.profiles['ana'] = const PublicProfile(uid: 'ana', username: 'ana');
      remote.usernames['luis'] = 'luis';
      remote.usernames['ana'] = 'ana';
    });

    test('a request goes to the exact username', () async {
      final result = await social().sendRequest('@Luis', currentFriends: []);
      expect(result, SendRequestResult.sent);
      expect(remote.requests.single.fromUsername, 'ana');
      expect(remote.requests.single.to, 'luis');
    });

    test('unknown, myself and blocked all read "no such user"', () async {
      remote.blockedBy.add('luis');
      final repo = social();
      expect(
        await repo.sendRequest('nobody', currentFriends: []),
        SendRequestResult.noSuchUser,
      );
      expect(
        await repo.sendRequest('ana', currentFriends: []),
        SendRequestResult.noSuchUser,
      );
      expect(
        await repo.sendRequest('luis', currentFriends: []),
        SendRequestResult.noSuchUser,
      );
    });

    test('an existing friend is not asked again', () async {
      final result = await social().sendRequest(
        'luis',
        currentFriends: [const Friend(uid: 'luis', username: 'luis')],
      );
      expect(result, SendRequestResult.alreadyFriends);
    });
  });

  test('a taken username is refused', () async {
    remote.usernames['luis'] = 'luis';
    expect(await social().activate('Luis'), isFalse);
    expect(await social().activate('ana_m'), isTrue);
  });
}
