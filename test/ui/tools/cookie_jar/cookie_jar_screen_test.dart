import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/data/models/cookie_model.dart';
import 'package:frontend_flutter/data/repositories/cookie_repository.dart';
import 'package:frontend_flutter/ui/core/theme/app_theme.dart';
import 'package:frontend_flutter/ui/tools/cookie_jar/view_model/cookie_jar_view_model.dart';
import 'package:frontend_flutter/ui/tools/cookie_jar/widgets/cookie_jar_screen.dart';

/// The cookies this account has, without sqflite or Firebase.
class FakeCookieRepository extends CookieRepository {
  FakeCookieRepository(this.stored) : super(currentUserId: () => 'ana');

  final List<CookieModel> stored;
  final eatenIds = <String>[];
  final returnedIds = <String>[];

  @override
  Stream<List<CookieModel>> watchCookies() => Stream.value(stored);

  @override
  Future<Uint8List?> photoOf(CookieModel cookie) async => null;

  @override
  Future<void> markOpened(String cookieId) async {}

  @override
  Future<void> enforceImageBudget(List<CookieModel> today) async {}

  @override
  Future<CookieModel> eat(String cookieId) async {
    eatenIds.add(cookieId);
    return stored.firstWhere((c) => c.id == cookieId);
  }

  @override
  Future<CookieModel> returnToJar(String cookieId) async {
    returnedIds.add(cookieId);
    return stored.firstWhere((c) => c.id == cookieId);
  }
}

CookieModel cookie(int n, {CookieState state = CookieState.active}) =>
    CookieModel(
      id: 'cookie-$n',
      userId: 'ana',
      title: 'Cookie $n',
      text: 'Memory number $n',
      state: state,
    );

Future<FakeCookieRepository> pumpJar(
  WidgetTester tester,
  List<CookieModel> cookies,
) async {
  final repository = FakeCookieRepository(cookies);
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: CookieJarScreen(
        viewModel: CookieJarViewModel(repository: repository),
      ),
    ),
  );
  await tester.pump();
  return repository;
}

void main() {
  testWidgets('the jar draws at most 10 cookies', (tester) async {
    await pumpJar(tester, [for (var n = 1; n <= 15; n++) cookie(n)]);

    final drawn = find.byWidgetPredicate(
      (w) => w is Semantics && (w.properties.label ?? '').startsWith('Cookie '),
    );
    expect(drawn, findsNWidgets(10));
    expect(find.text('All my cookies (15)'), findsOneWidget);
  });

  testWidgets('an empty jar invites to create the first cookie', (
    tester,
  ) async {
    await pumpJar(tester, []);
    expect(find.textContaining('Add your first cookie'), findsOneWidget);
  });

  testWidgets('eating a cookie offers Undo, which returns it to the jar', (
    tester,
  ) async {
    final repository = await pumpJar(tester, [cookie(1)]);

    await tester.tap(find.bySemanticsLabel('Cookie 1'));
    await tester.pumpAndSettle();
    expect(find.text('Memory number 1'), findsOneWidget);

    await tester.tap(find.text('Eat 🍪'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
    expect(repository.eatenIds, ['cookie-1']);
    expect(find.text('Cookie eaten 🍪'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(repository.returnedIds, ['cookie-1']);
  });

  testWidgets('the list sheet splits the jar and the eaten history', (
    tester,
  ) async {
    await pumpJar(tester, [
      cookie(1),
      cookie(2),
      cookie(3, state: CookieState.eaten),
    ]);

    await tester.tap(find.text('All my cookies (3)'));
    await tester.pumpAndSettle();
    expect(find.text('In the jar (2)'), findsOneWidget);
    expect(find.text('Eaten (1)'), findsOneWidget);

    await tester.tap(find.text('Eaten (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Cookie 3'), findsOneWidget);
    expect(find.byTooltip('Delete forever'), findsOneWidget);
  });
}
