import '../../models/wish_model.dart';

/// The wish lists held in memory, on top of the sqflite [WishDao], so the
/// Rapunzel screens do not re-query the database on every build.
class WishMemoryCache {
  WishMemoryCache({
    this.ttl = const Duration(minutes: 10),
    this.maxUsers = defaultMaxUsers,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static final shared = WishMemoryCache();

  /// How many accounts may hold a cached list at once.
  static const defaultMaxUsers = 3;

  final Duration ttl;
  final int maxUsers;
  final DateTime Function() _now;

  final _entries = <String, _Entry>{};

  /// How many accounts have a list cached right now.
  int get length => _entries.length;

  /// The cached wishes of [userId], or null on a miss. A hit makes the account the most recently used; an expired entry is dropped.
  List<Wish>? get(String userId) {
    final entry = _entries.remove(userId);
    if (entry == null) return null;
    if (_now().difference(entry.savedAt) >= ttl) return null;
    _entries[userId] = entry;
    return entry.wishes;
  }

  List<Wish> put(String userId, List<Wish> wishes) {
    _entries.remove(userId);
    final stored = List<Wish>.unmodifiable(wishes);
    _entries[userId] = _Entry(stored, _now());
    while (_entries.length > maxUsers) {
      _entries.remove(_entries.keys.first);
    }
    return stored;
  }

  /// Forgets the cached list of [userId]; call on any wish change.
  void invalidate(String userId) => _entries.remove(userId);

  /// Forgets every cached list, on sign-out.
  void clear() => _entries.clear();
}

class _Entry {
  const _Entry(this.wishes, this.savedAt);

  final List<Wish> wishes;
  final DateTime savedAt;
}
