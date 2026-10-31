import '../../models/user_model.dart';


class UserProfileCache {
  UserProfileCache({
    this.ttl = const Duration(minutes: 10),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// One cache for the whole app: every screen makes its own repository.
  static final shared = UserProfileCache();

  final Duration ttl;
  final DateTime Function() _now;

  UserModel? _profile;
  DateTime? _savedAt;

  /// The profile of [uid] while it is younger than [ttl], otherwise null.
  UserModel? get(String uid) {
    final profile = _profile;
    final savedAt = _savedAt;
    if (profile == null || savedAt == null || profile.uid != uid) return null;
    if (_now().difference(savedAt) >= ttl) {
      clear();
      return null;
    }
    return profile;
  }

  void put(UserModel profile) {
    _profile = profile;
    _savedAt = _now();
  }

  void clear() {
    _profile = null;
    _savedAt = null;
  }
}
