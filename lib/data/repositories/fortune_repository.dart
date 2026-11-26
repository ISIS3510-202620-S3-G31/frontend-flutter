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

  /// Sends the pending changes up, then brings what other phones kept.
  /// Without a connection or a signed-in account it does nothing, and the
  /// changes stay pending for the next time.
  Future<void> sync() =>
      _syncing ??= _sync().whenComplete(() => _syncing = null);

  Future<void> _sync() async {
    final userId = _currentUserId();
    if (userId == null || !await _connectivity.isOnline()) return;
    try {
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
    } on Exception catch (error) {
      // The connection dropped or Firestore took too long: what is left stays
      // pending in sqflite.
      debugPrint('[Fortune] Favorites stay pending: $error');
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
  /// one in the gallery belongs to the user and stays.
  Future<void> removeCard(FortuneCard card) async {
    await _cards.delete(_userId, card.cookieId);
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
