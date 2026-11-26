import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/fortune_card_model.dart';
import '../models/fortune_model.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/fortune_card_renderer.dart';
import '../services/fortune_share_service.dart';
import '../services/local/fortune_cache.dart';
import '../services/local/fortune_cards_dao.dart';
import '../services/local/fortune_chances_storage.dart';
import '../services/local/fortune_favorites_dao.dart';
import '../services/remote/fortune_api_service.dart';
import '../services/remote/fortune_remote_service.dart';

/// The Fortune Cookie's data. The phone is the source of truth: the APIs only
/// refill the deck, and nothing the user sees waits for them when it can be
/// avoided.
class FortuneRepository {
  FortuneRepository({
    FortuneCache? cache,
    FortuneChancesStorage? chances,
    FortuneFavoritesDao? favorites,
    FortuneCardsDao? cards,
    FortuneCardRenderer? renderer,
    FortuneShareService? share,
    FortuneApiService? api,
    FortuneRemoteService? remote,
    ConnectivityChecker? connectivity,
    String? Function()? currentUserId,
  }) : _cache = cache ?? FortuneCache(),
       _chances = chances ?? FortuneChancesStorage(),
       _favorites = favorites ?? FortuneFavoritesDao(),
       _cards = cards ?? FortuneCardsDao(),
       _renderer = renderer ?? const FortuneCardRenderer(),
       _share = share ?? const FortuneShareService(),
       _api = api ?? FortuneApiService(),
       _remote = remote ?? FortuneRemoteService(),
       _connectivity = connectivity ?? ConnectivityService(),
       _currentUserId = currentUserId ?? (() => AuthService().currentUserId);

  static const tableSize = 3;

  /// Whose chances and recents these are when nobody is signed in, as in the
  /// Kotlin app.
  static const localUser = 'local_user';

  final FortuneCache _cache;
  final FortuneChancesStorage _chances;
  final FortuneFavoritesDao _favorites;
  final FortuneCardsDao _cards;
  final FortuneCardRenderer _renderer;
  final FortuneShareService _share;
  final FortuneApiService _api;
  final FortuneRemoteService _remote;
  final ConnectivityChecker _connectivity;
  final String? Function() _currentUserId;

  /// The ids of the kept fortunes, so every heart on screen is answered from
  /// memory instead of a query.
  final Set<int> _keptIds = {};
  String? _keptIdsOwner;

  /// One upload at a time: the screen and a returning connection can both
  /// ask for it.
  Future<void>? _syncing;

  String get _userId => _currentUserId() ?? localUser;

  Future<int> chancesLeft() => _chances.chancesLeft(_userId);

  Future<List<Fortune>> recents() => _cache.recents(_userId);

  /// What the account keeps, newest first. Also refreshes the hearts.
  Future<List<Fortune>> favorites() async {
    final userId = _userId;
    final kept = await _favorites.favorites(userId);
    _keptIdsOwner = userId;
    _keptIds
      ..clear()
      ..addAll(kept.map((fortune) => fortune.id));
    return kept;
  }

  /// Answered from memory once [favorites] has run for this account.
  bool isKept(int id) => _keptIdsOwner == _userId && _keptIds.contains(id);

  /// Keeps [fortune], or lets it go if it was kept. Returns whether it is kept
  /// now. Saved on the phone at once; Firestore gets it when it can.
  Future<bool> toggleKept(Fortune fortune) async {
    final userId = _userId;
    // The hearts in memory must belong to this account before one flips.
    if (_keptIdsOwner != userId) await favorites();
    final keep = !isKept(fortune.id);
    if (keep) {
      await _favorites.keep(userId, fortune.copyWith(savedAt: DateTime.now()));
      _keptIds.add(fortune.id);
    } else {
      await _favorites.markRemoved(userId, fortune.id);
      _keptIds.remove(fortune.id);
    }
    return keep;
  }

  /// Brings the phone and the account together: sends what changed here and
  /// takes what changed on another phone. Kept fortunes, shared cards,
  /// today's count and the recents each go on their own, so one failing does
  /// not hold back the others. Without a connection or a signed-in account it
  /// does nothing, and everything stays pending for the next time.
  Future<void> sync() =>
      _syncing ??= _sync().whenComplete(() => _syncing = null);

  Future<void> _sync() async {
    final userId = _currentUserId();
    if (userId == null || !await _connectivity.isOnline()) return;
    await _step('Favorites', () => _syncFavorites(userId));
    await _step('Cards', () => _syncCards(userId));
    await _step("Today's cookies", () => _syncDaily(userId));
    await _step('Recents', () => _syncRecents(userId));
  }

  /// The connection dropped or the cloud took too long: what is left stays
  /// pending on the phone.
  Future<void> _step(String what, Future<void> Function() run) async {
    try {
      await run();
    } on Exception catch (error) {
      debugPrint('[Fortune] $what stay pending: $error');
    }
  }

  Future<void> _syncFavorites(String userId) async {
    for (final change in await _favorites.pending(userId)) {
      final id = change.fortune.id;
      if (change.removed) {
        await _remote.remove(userId, id);
        await _favorites.delete(userId, id);
      } else {
        await _remote.keep(userId, change.fortune);
        await _favorites.markSynced(userId, id);
      }
    }
    await _favorites.addFromAccount(userId, await _remote.favorites(userId));
  }

  /// Uploads new cards and deletes removed ones, then downloads the cards
  /// shared on another phone that this one does not have.
  Future<void> _syncCards(String userId) async {
    for (final change in await _cards.pending(userId)) {
      final card = change.card;
      if (change.removed) {
        await _remote.removeCard(userId, card.cookieId);
        await _cards.delete(userId, card.cookieId);
        continue;
      }
      final file = File(card.localPath);
      if (!await file.exists()) continue;
      await _remote.uploadCard(
        userId,
        cookieId: card.cookieId,
        quote: card.quote,
        savedAt: card.savedAt,
        png: await file.readAsBytes(),
      );
      await _cards.markSynced(userId, card.cookieId);
    }

    final known = await _cards.knownIds(userId);
    for (final remote in await _remote.cards(userId)) {
      if (known.contains(remote.cookieId)) continue;
      final png = await _remote.downloadCard(userId, remote.cookieId);
      if (png == null) continue;
      final file = await _share.keepCopy(userId, remote.cookieId, png);
      await _cards.save(
        userId,
        FortuneCard(
          cookieId: remote.cookieId,
          quote: remote.quote,
          localPath: file.path,
          savedAt: remote.savedAt,
        ),
        synced: true,
      );
    }
  }

  /// Takes the larger of today's two counts, here and in the account, and
  /// sends this phone's when it is the larger or has not gone up yet.
  Future<void> _syncDaily(String userId) async {
    final day = _chances.today();
    final remote = await _remote.usedOn(userId, day);
    await _chances.raiseUsedToday(userId, remote);
    final local = await _chances.usedToday(userId);
    if (local > remote || await _chances.isPending(userId)) {
      await _remote.raiseUsed(userId, day, local);
    }
    await _chances.markSent(userId);
  }

  /// The five most recently opened, on either phone, kept on both.
  Future<void> _syncRecents(String userId) async {
    final remote = await _remote.recents(userId);
    final local = await _cache.recents(userId);
    final newest = <int, Fortune>{};
    for (final fortune in [...local, ...remote]) {
      final seen = newest[fortune.id];
      if (seen == null || fortune.savedAt.isAfter(seen.savedAt)) {
        newest[fortune.id] = fortune;
      }
    }
    final merged =
        (newest.values.toList()..sort((a, b) => b.savedAt.compareTo(a.savedAt)))
            .take(FortuneCache.recentCapacity)
            .toList();
    await _cache.setRecents(userId, merged);
    if (!listEquals(
      merged.map((f) => f.id).toList(),
      remote.map((f) => f.id).toList(),
    )) {
      await _remote.setRecents(userId, merged);
    }
  }

  /// The cards the account shared, newest first, leaving out any whose image
  /// is gone from the app's folder.
  Future<List<FortuneCard>> cards() async {
    final userId = _userId;
    final cards = <FortuneCard>[];
    for (final card in await _cards.cards(userId)) {
      if (await File(card.localPath).exists()) {
        cards.add(card);
      } else {
        // Lost from the app's folder (the user cleared its data): the cloud
        // copy brings it back on the next sync.
        await _cards.delete(userId, card.cookieId);
      }
    }
    return cards;
  }

  /// The card of [fortune]: drawn the first time it is shared, reused after
  /// that. A new one is also saved to the phone's gallery.
  Future<({FortuneCard card, bool isNew})> cardFor(Fortune fortune) async {
    final userId = _userId;
    final saved = await _cards.card(userId, fortune.id);
    if (saved != null && await File(saved.localPath).exists()) {
      return (card: saved, isNew: false);
    }
    final day = saved?.savedAt ?? DateTime.now();
    final png = await _renderer.render(fortune, day);
    final file = await _share.keepCopy(userId, fortune.id, png);
    try {
      await _share.saveToGallery(png, fortune.id);
    } on Exception catch (error) {
      // Without the gallery the card can still be shared from the app.
      debugPrint('[Fortune] Could not save to the gallery: $error');
    }
    final card = FortuneCard(
      cookieId: fortune.id,
      quote: fortune.quote,
      localPath: file.path,
      savedAt: day,
    );
    await _cards.save(userId, card);
    return (card: card, isNew: true);
  }

  Future<void> openShareSheet(FortuneCard card) =>
      _share.openShareSheet(card.localPath);

  /// Takes the card out of the Shared list and deletes the app's copy. The
  /// cloud forgets it on the next sync; the copy in the gallery belongs to the
  /// user and stays.
  Future<void> removeCard(FortuneCard card) async {
    await _cards.markRemoved(_userId, card.cookieId);
    final file = File(card.localPath);
    if (await file.exists()) await file.delete();
  }

  /// True each time the connection comes back, to send what is pending.
  Stream<bool> get onlineChanges => switch (_connectivity) {
    final ConnectivityService service => service.onlineChanges,
    _ => const Stream.empty(),
  };

  /// The three cookies of the table.
  ///
  /// Cache falling back to network: with three phrases already on the phone
  /// the APIs are not called at all. Otherwise four new ones are downloaded
  /// and kept, and if that is not possible either, the phrases that come
  /// with the app fill the gaps.
  Future<List<TableFortune>> table() async {
    final deck = await _cache.deck();
    if (deck.length >= tableSize) {
      return [
        for (final fortune in deck.take(tableSize))
          TableFortune(fortune, FortuneSource.phone, isOffline: false),
      ];
    }

    // Asking with no connection would only wait for the timeouts.
    final fresh = await _connectivity.isOnline()
        ? await _api.fetchTwoAndTwo()
        : <Fortune>[];
    final isOffline = fresh.isEmpty;
    if (!isOffline) await _cache.addToDeck(fresh);

    final freshIds = {for (final fortune in fresh) fortune.id};
    final table = [
      for (final fortune in (await _cache.deck()).take(tableSize))
        TableFortune(
          fortune,
          freshIds.contains(fortune.id)
              ? FortuneSource.internet
              : FortuneSource.phone,
          isOffline: isOffline,
        ),
    ];
    final seeds = (await _cache.seeds())..shuffle();
    for (final seed in seeds) {
      if (table.length >= tableSize) break;
      if (table.every((cookie) => cookie.fortune.quote != seed.quote)) {
        table.add(
          TableFortune(seed, FortuneSource.builtIn, isOffline: isOffline),
        );
      }
    }
    return table;
  }

  /// Opens [cookie]: spends one of today's chances, takes its phrase out of
  /// the deck and puts it first among the recents. Null when there are no
  /// chances left.
  Future<OpenedFortune?> open(TableFortune cookie) async {
    final userId = _userId;
    if (await _chances.chancesLeft(userId) <= 0) return null;
    final remaining = await _chances.spendOne(userId);
    final fortune = cookie.fortune.copyWith(savedAt: DateTime.now());
    await _cache.removeFromDeck(fortune.id);
    await _cache.addRecent(userId, fortune);
    return OpenedFortune(fortune, remaining);
  }
}
