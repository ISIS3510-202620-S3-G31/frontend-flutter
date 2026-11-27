import '../../data/models/cookie_model.dart';

/// Rules of the jar itself: how many cookies it draws and which ones come out
/// today.

abstract final class CookieJarRules {
  static const capacity = 10;


  static List<CookieModel> dailyPick(
    List<CookieModel> cookies, {
    required String userId,
    required String dayKey,
  }) {
    final daySeed = _mix(_javaHashCode('$userId|$dayKey'));
    int scoreOf(CookieModel cookie) =>
        _mix(daySeed ^ _mix(_javaHashCode(cookie.id)));

    final active = cookies.where((cookie) => cookie.isActive).toList()
      ..sort((a, b) {
        final byScore = scoreOf(a).compareTo(scoreOf(b));
        return byScore != 0 ? byScore : a.id.compareTo(b.id);
      });
    return active.take(capacity).toList();
  }


  static int _javaHashCode(String text) {
    var hash = 0;
    for (final unit in text.codeUnits) {
      hash = (31 * hash + unit) & 0xFFFFFFFF;
    }
    return hash >= 0x80000000 ? hash - 0x100000000 : hash;
  }


  static int _mix(int value) {
    var z = value + -0x61c8864680b583eb;
    z = (z ^ (z >>> 30)) * -0x40a7b892e31b1a47;
    z = (z ^ (z >>> 27)) * -0x6b2fb644ecceee15;
    return z ^ (z >>> 31);
  }
}
