import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/ui/tools/cookie_jar/widgets/cookie_jar_drawing.dart';

import 'cookie_jar_screen_test.dart';

void main() {
  setUp(() {
    JarPainter.paints = 0;
    CookiePainter.paints = 0;
  });

  void report(String what) {
    // ignore: avoid_print
    print(
      '[repaint] $what: JarPainter.paint x${JarPainter.paints}, '
      'CookiePainter.paint x${CookiePainter.paints}',
    );
  }

  testWidgets('a ripple on one cookie does not repaint the jar', (
    tester,
  ) async {
    await pumpJar(tester, [for (var n = 1; n <= 10; n++) cookie(n)]);
    await tester.pumpAndSettle();
    JarPainter.paints = 0;
    CookiePainter.paints = 0;

    final gesture = await tester.startGesture(
      tester.getCenter(find.bySemanticsLabel('Cookie 5')),
    );
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.cancel();
    await tester.pumpAndSettle();
    report('20-frame ripple on one cookie');

    expect(JarPainter.paints, 0);
    expect(CookiePainter.paints, lessThanOrEqualTo(1));
  });

  testWidgets('a Snackbar sliding in does not repaint the jar', (tester) async {
    await pumpJar(tester, [for (var n = 1; n <= 10; n++) cookie(n)]);
    await tester.pumpAndSettle();
    JarPainter.paints = 0;
    CookiePainter.paints = 0;

    ScaffoldMessenger.of(
      tester.element(find.byType(CookieJarDrawing)),
    ).showSnackBar(const SnackBar(content: Text('Cookie eaten 🍪')));
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    report('20-frame Snackbar entrance');

    expect(JarPainter.paints, 0);
    expect(CookiePainter.paints, 0);
  });
}
