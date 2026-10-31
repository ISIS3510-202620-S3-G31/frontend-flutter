import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

/// Photos taken on another device, kept only while they fit in a budget.
///
/// They live in the system cache directory, so Android itself can reclaim the
/// space and "Clear cache" wipes them: losing one costs a download, never the
/// user's data. Photos taken on this phone are not kept here, because until
/// they upload this phone holds the only copy of them.
///
/// Entries are dropped least-recently-seen first. Reading one marks it as seen
/// by rewriting its modified time, so the order survives restarts without an
/// index: the file system is the index.
class PhotoCache {
  PhotoCache({Directory? folder, int? maxBytes, DateTime Function()? now})
    : _customFolder = folder,
      maxBytes = maxBytes ?? defaultMaxBytes,
      _now = now ?? DateTime.now;

  /// Per account: around ten photos, this week plus the previous one.
  static const defaultMaxBytes = 20 * 1024 * 1024;

  static final _dayFormat = DateFormat('yyyy-MM-dd');

  /// Set in tests; otherwise the system cache directory.
  final Directory? _customFolder;
  final DateTime Function() _now;

  /// How much of the disk one account's cached photos may take.
  final int maxBytes;

  Future<Directory> _root() async {
    final folder =
        _customFolder ??
        Directory('${(await getTemporaryDirectory()).path}/photo_cache');
    await folder.create(recursive: true);
    return folder;
  }

  /// One folder per user, so two accounts on the same phone never meet.
  Future<File> _fileFor(String userId, DateTime day) async =>
      File('${(await _root()).path}/$userId/${_dayFormat.format(day)}.jpg');

  /// The cached photo of [day], or null when this phone does not have it.
  ///
  /// A hit counts as a use and renews the entry.
  Future<File?> photoFor(String userId, DateTime day) async {
    final file = await _fileFor(userId, day);
    if (!await file.exists()) return null;
    await file.setLastModified(_now());
    return file;
  }

  /// Stores a photo downloaded from Firebase and makes room for it.
  Future<File> save(String userId, DateTime day, List<int> bytes) async {
    final file = await _fileFor(userId, day);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    await file.setLastModified(_now());
    await _evict(userId, keep: file.path);
    return file;
  }

  /// Forgets everything cached for [userId], on sign-out.
  Future<void> forget(String userId) async {
    final folder = Directory('${(await _root()).path}/$userId');
    if (await folder.exists()) await folder.delete(recursive: true);
  }

  /// What [userId]'s cached photos take up right now.
  Future<int> bytesUsed(String userId) async =>
      _totalOf(await _entries(userId));

  static int _totalOf(List<_Entry> entries) =>
      entries.fold(0, (sum, entry) => sum + entry.stat.size);

  /// Drops [userId]'s least recently seen photos until the rest fit in
  /// [maxBytes]. Each account gets its own budget, so one of them browsing a
  /// lot never costs the other its cache.
  ///
  /// [keep] is never dropped: evicting the photo the user just asked for would
  /// only force the app to download it again.
  Future<void> _evict(String userId, {String? keep}) async {
    final entries = await _entries(userId);
    var used = _totalOf(entries);
    if (used <= maxBytes) return;
    entries.sort((a, b) => a.stat.modified.compareTo(b.stat.modified));
    for (final entry in entries) {
      if (used <= maxBytes) return;
      if (entry.file.path == keep) continue;
      used -= entry.stat.size;
      await entry.file.delete();
    }
  }

  Future<List<_Entry>> _entries(String userId) async {
    final folder = Directory('${(await _root()).path}/$userId');
    if (!await folder.exists()) return [];
    final entries = <_Entry>[];
    await for (final found in folder.list()) {
      if (found is File) entries.add(_Entry(found, await found.stat()));
    }
    return entries;
  }
}

class _Entry {
  const _Entry(this.file, this.stat);

  final File file;
  final FileStat stat;
}
