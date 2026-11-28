import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/domain/cookie_jar/cookie_social_rules.dart';

void main() {
  test('only 18 or older gets friends; an unknown age does not', () {
    expect(CookieSocialRules.isAdult(18), isTrue);
    expect(CookieSocialRules.isAdult(17), isFalse);
    expect(CookieSocialRules.isAdult(13), isFalse);
    expect(CookieSocialRules.isAdult(null), isFalse);
  });

  test('usernames are stored lowercase without the @', () {
    expect(CookieSocialRules.normalizeUsername(' @David_F '), 'david_f');
  });

  test('a username has 3-20 letters, numbers, _ or .', () {
    expect(CookieSocialRules.usernameError('ana'), isNull);
    expect(CookieSocialRules.usernameError('an'), isNotNull);
    expect(CookieSocialRules.usernameError('a' * 21), isNotNull);
    expect(CookieSocialRules.usernameError('ana maria'), isNotNull);
    expect(CookieSocialRules.usernameError('ana-maria'), isNotNull);
    expect(CookieSocialRules.usernameError('@Ana.M_2'), isNull);
  });

  test('a request id is fixed, so a retry never duplicates it', () {
    expect(CookieSocialRules.requestId('a', 'b'), 'a_b');
  });

  test('both friends reach the same friendship id', () {
    expect(
      CookieSocialRules.friendshipId('zoe', 'ana'),
      CookieSocialRules.friendshipId('ana', 'zoe'),
    );
    expect(CookieSocialRules.friendshipId('zoe', 'ana'), 'ana_zoe');
  });

  test('a gift expires when its time is up', () {
    final now = DateTime(2026, 11, 26);
    final ms = now.millisecondsSinceEpoch;
    expect(CookieSocialRules.isExpired(ms - 1, now), isTrue);
    expect(CookieSocialRules.isExpired(ms + 1, now), isFalse);
  });
}
