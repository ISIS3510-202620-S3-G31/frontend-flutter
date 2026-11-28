abstract final class CookieSocialRules {
  static const minAge = 18;

  /// A pending gift lasts 7 days in the backend.
  static const giftLifetime = Duration(days: 7);

  static final _username = RegExp(r'^[a-z0-9_.]{3,20}$');

  /// Unknown age (an old profile without birth date or age) is not enough.
  static bool isAdult(int? age) => age != null && age >= minAge;

  static String normalizeUsername(String input) {
    final trimmed = input.trim().toLowerCase();
    return trimmed.startsWith('@') ? trimmed.substring(1) : trimmed;
  }

  /// The message to show under the username field, or null when it is good.
  static String? usernameError(String input) {
    final username = normalizeUsername(input);
    if (username.length < 3) return 'At least 3 characters';
    if (username.length > 20) return 'At most 20 characters';
    if (!_username.hasMatch(username)) {
      return 'Only letters, numbers, _ and .';
    }
    return null;
  }

  static String requestId(String fromUid, String toUid) => '${fromUid}_$toUid';

  static String friendshipId(String a, String b) =>
      a.compareTo(b) < 0 ? '${a}_$b' : '${b}_$a';

  static bool isExpired(int expiresAt, DateTime now) =>
      expiresAt <= now.millisecondsSinceEpoch;
}
