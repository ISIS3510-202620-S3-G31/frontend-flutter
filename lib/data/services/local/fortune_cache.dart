import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/fortune_model.dart';

/// The phrases the Fortune Cookie keeps on disk, in the system cache folder.
///
/// - The deck: phrases downloaded and not opened yet. While it holds three,
///   the table is set without the network (cache falling back to network).
/// - The recents: the last five opened by each account, least recent out
///   first (LRU), so the screen shows them at once without a request.
///
/// Both can be downloaded again, so they live where Android may clear them.
/// The phrases that come with the app are the last resort, when the deck is
/// empty and there is no connection.
class FortuneCache {
  FortuneCache({Directory? folder, AssetBundle? assets})
    : _customFolder = folder,
      _assets = assets ?? rootBundle;

  /// How many recent phrases each account keeps.
  static const recentCapacity = 5;

  final Directory? _customFolder;
  final AssetBundle _assets;

  /// Writes run one after the other, so two of them never interleave on the
  /// same file.
  Future<void> _writes = Future.value();

  Future<Directory> _folder() async {
    final folder =
        _customFolder ??
        Directory('${(await getTemporaryDirectory()).path}/fortune');
    await folder.create(recursive: true);
    return folder;
  }

  Future<File> _deckFile() async => File('${(await _folder()).path}/deck.json');

  /// One file per account, so two accounts on the same phone never see each
  /// other's phrases.
  Future<File> _recentFile(String userId) async =>
      File('${(await _folder()).path}/recent_$userId.json');

  Future<List<Fortune>> deck() async => _read(await _deckFile());

  /// Adds new phrases at the end of the deck, without repeating any.
  Future<void> addToDeck(List<Fortune> fortunes) =>
      _update(_deckFile(), (deck) {
        final quotes = {for (final fortune in deck) fortune.quote};
        return [
          ...deck,
          for (final fortune in fortunes)
            if (quotes.add(fortune.quote)) fortune,
        ];
      });

  /// Takes out the phrase that was opened; the others wait for next time.
  Future<void> removeFromDeck(int id) => _update(
    _deckFile(),
    (deck) => deck.where((fortune) => fortune.id != id).toList(),
  );

  Future<List<Fortune>> recents(String userId) async =>
      _read(await _recentFile(userId));

  /// Puts [fortune] first among the recents and drops whatever passes five.
  Future<void> addRecent(String userId, Fortune fortune) =>
      _update(_recentFile(userId), (recents) {
        return [
          fortune,
          ...recents.where((recent) => recent.id != fortune.id),
        ].take(recentCapacity).toList();
      });

  /// The phrases that come with the app.
  Future<List<Fortune>> seeds() async {
    final text = await _assets.loadString('assets/data/fortune_seed.json');
    return [
      for (final item in jsonDecode(text) as List<Object?>)
        Fortune.fromJson(item! as Map<String, Object?>),
    ];
  }

  Future<void> _update(
    Future<File> file,
    List<Fortune> Function(List<Fortune> current) change,
  ) {
    final write = _writes.then((_) async {
      final target = await file;
      final next = change(await _read(target));
      await target.writeAsString(
        jsonEncode([for (final fortune in next) fortune.toJson()]),
        flush: true,
      );
    });
    // A failed write must not block the ones after it.
    _writes = write.catchError((_) {});
    return write;
  }

  Future<List<Fortune>> _read(File file) async {
    try {
      if (!await file.exists()) return [];
      return [
        for (final item in jsonDecode(await file.readAsString()) as List)
          Fortune.fromJson(item as Map<String, Object?>),
      ];
    } on FormatException {
      // A damaged file is a cache miss, not an error.
      return [];
    }
  }
}
