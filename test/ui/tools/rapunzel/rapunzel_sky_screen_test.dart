import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/ui/tools/rapunzel/view_model/rapunzel_sky_view_model.dart';
import 'package:frontend_flutter/ui/tools/rapunzel/widgets/rapunzel_sky_screen.dart';

import 'rapunzel_fakes.dart';

/// The sky stage, keyed in the screen.
const skyStage = Key('rapunzel-sky-stage');

Offset skyOrigin(WidgetTester tester) =>
    tester.renderObject<RenderBox>(find.byKey(skyStage)).localToGlobal(Offset.zero);

Size skySizeOf(WidgetTester tester) =>
    tester.renderObject<RenderBox>(find.byKey(skyStage)).size;

void main() {
  testWidgets('the sky renders the held lantern and tapping a lit one reads it', (tester) async {
    final repository = FakeWishRepository(stored: [w3, w1]);
    final vm = viewModel(repository);
    await tester.pumpWidget(MaterialApp(home: RapunzelSkyScreen(viewModel: vm)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text("Rapunzel's lantern"), findsOneWidget);
    expect(find.text('Swipe up to release your lantern'), findsOneWidget);

    // Tap the background lantern of w1 (lit, released): its wish opens.
    final size = skySizeOf(tester);
    final slot = vm.backgroundLanterns.first.$2;
    await tester.tapAt(
      skyOrigin(tester) + Offset(slot.dx * size.width, slot.dy * size.height),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('wish w1'), findsOneWidget);
    expect(find.text('A wish in the sky'), findsOneWidget);
  });

  testWidgets('a swipe up releases the held lantern and it leaves the hand', (tester) async {
    final repository = FakeWishRepository(stored: [w3, w1]);
    final vm = viewModel(repository);
    await tester.pumpWidget(MaterialApp(home: RapunzelSkyScreen(viewModel: vm)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final origin = skyOrigin(tester);
    final size = skySizeOf(tester);
    await tester.flingFrom(
      origin + Offset(size.width / 2, size.height * 0.7),
      const Offset(0, -400),
      2000,
    );
    await tester.pump();
    expect(vm.motionOf(w3.id), LanternMotion.releasing);
    // Let the 2.4 s release animation finish.
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump();

    expect(repository.releasedIds, [w3.id]);
    expect(vm.foreground, isNull);
    expect(find.text('Swipe up to release your lantern'), findsNothing);
  });

  testWidgets('a slow drag does not release the lantern', (tester) async {
    final repository = FakeWishRepository(stored: [w3, w1]);
    final vm = viewModel(repository);
    await tester.pumpWidget(MaterialApp(home: RapunzelSkyScreen(viewModel: vm)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final origin = skyOrigin(tester);
    final size = skySizeOf(tester);
    await tester.flingFrom(
      origin + Offset(size.width / 2, size.height * 0.7),
      const Offset(0, -100),
      300,
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(repository.releasedIds, isEmpty);
    expect(vm.foreground, w3);
    expect(find.text('Swipe up to release your lantern'), findsOneWidget);
  });
}
