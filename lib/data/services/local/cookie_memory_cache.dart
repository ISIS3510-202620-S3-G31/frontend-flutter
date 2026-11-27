import 'dart:typed_data';


class CookieMemoryCache {
  CookieMemoryCache({this.maxBytes = defaultMaxBytes});


  static const defaultMaxBytes = 16 * 1024 * 1024;

  final int maxBytes;

  final _entries = <String, Uint8List>{};
  int _bytes = 0;

  /// What the cache holds right now, in bytes.
  int get bytes => _bytes;

  int get length => _entries.length;

  /// The photo of [cookieId], or null on a miss. A hit makes it the most recently used
  Uint8List? get(String cookieId) {
    final photo = _entries.remove(cookieId);
    if (photo == null) return null;
    _entries[cookieId] = photo;
    return photo;
  }

  /// Stores a photo and drops the least recently used ones until the rest fit.
  void put(String cookieId, Uint8List photo) {
    remove(cookieId);
    if (photo.length > maxBytes) return;
    _entries[cookieId] = photo;
    _bytes += photo.length;
    while (_bytes > maxBytes) {
      final oldest = _entries.keys.first;
      _bytes -= _entries.remove(oldest)!.length;
    }
  }

  void remove(String cookieId) {
    final photo = _entries.remove(cookieId);
    if (photo != null) _bytes -= photo.length;
  }

  /// On sign-out: the next account must never see these photos.
  void clear() {
    _entries.clear();
    _bytes = 0;
  }
}
