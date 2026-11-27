import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/models/cookie_model.dart';
import 'package:frontend_flutter/domain/cookie_jar/cookie_jar_rules.dart';

void main() {
  CookieModel cookie(int n, {CookieState state = CookieState.active}) =>
      CookieModel(
        id: 'cookie-$n',
        userId: 'ana-uid',
        title: 'Cookie $n',
        text: 'Text $n',
        state: state,
      );

  final fifteen = [for (var n = 1; n <= 15; n++) cookie(n)];

  List<String> idsOf(List<CookieModel> cookies) =>
      cookies.map((cookie) => cookie.id).toList();

  List<CookieModel> pick(List<CookieModel> cookies, String day) =>
      CookieJarRules.dailyPick(cookies, userId: 'ana-uid', dayKey: day);

  test('picks exactly the same 10 as the Kotlin app', () {

    expect(idsOf(pick(fifteen, '2026-11-26')), [
      'cookie-8', 'cookie-14', 'cookie-4', 'cookie-13', 'cookie-7',
      'cookie-12', 'cookie-9', 'cookie-10', 'cookie-15', 'cookie-5',
    ]);
    expect(idsOf(pick(fifteen, '2026-11-27')), [
      'cookie-7', 'cookie-2', 'cookie-14', 'cookie-10', 'cookie-6',
      'cookie-3', 'cookie-15', 'cookie-13', 'cookie-1', 'cookie-12',
    ]);
  });

  test('never draws more than 10', () {
    expect(pick(fifteen, '2026-11-26'), hasLength(CookieJarRules.capacity));
  });

  test('with fewer than 10 it draws all of them', () {
    expect(pick(fifteen.take(3).toList(), '2026-11-26'), hasLength(3));
    expect(pick([], '2026-11-26'), isEmpty);
  });

  test('eaten cookies never come out', () {
    final mixed = [
      for (var n = 1; n <= 15; n++)
        cookie(n, state: n.isEven ? CookieState.eaten : CookieState.active),
    ];
    final picked = pick(mixed, '2026-11-26');
    expect(picked.every((cookie) => cookie.isActive), isTrue);
    expect(picked, hasLength(8));
  });

  test('the same day gives the same cookies, in any input order', () {
    final shuffled = fifteen.reversed.toList();
    expect(
      idsOf(pick(shuffled, '2026-11-26')),
      idsOf(pick(fifteen, '2026-11-26')),
    );
  });

  test('eating one cookie does not reshuffle the others', () {
    final before = idsOf(pick(fifteen, '2026-11-26'));
    final eatenId = before.first;
    final after = idsOf(
      pick(fifteen.where((c) => c.id != eatenId).toList(), '2026-11-26'),
    );
    expect(after.take(9), before.skip(1));
  });
}
