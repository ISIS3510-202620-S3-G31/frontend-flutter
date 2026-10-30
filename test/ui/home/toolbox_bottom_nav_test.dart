import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/ui/home/view_model/tool_hub_view_model.dart';
import 'package:frontend_flutter/ui/home/widgets/toolbox_bottom_nav.dart';

void main() {
  final tapped = <HomeTab>[];

  setUp(tapped.clear);

  Future<void> show(WidgetTester tester, HomeTab selected) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: ToolboxBottomNav(
            selectedTab: selected,
            onTabSelected: tapped.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<String> iconsOf(WidgetTester tester) => [
    for (final svg in tester.widgetList<SvgPicture>(find.byType(SvgPicture)))
      (svg.bytesLoader as SvgAssetLoader).assetName,
  ];

  testWidgets('shows the four tabs left to right', (tester) async {
    await show(tester, HomeTab.home);

    final labels = [
      for (final text in tester.widgetList<Text>(find.byType(Text))) text.data,
    ];
    expect(labels, ['Stats', 'Home', 'Tools', 'Profile']);
  });

  testWidgets('home is a house, tools keeps the toolbox', (tester) async {
    await show(tester, HomeTab.home);

    expect(iconsOf(tester), [
      'assets/icons/ic_stats.svg',
      'assets/icons/ic_home.svg',
      'assets/icons/ic_tools.svg',
      'assets/icons/ic_profile.svg',
    ]);
  });

  testWidgets('home and tools are separate destinations', (tester) async {
    await show(tester, HomeTab.home);

    await tester.tap(find.text('Tools'));
    await tester.tap(find.text('Stats'));
    await tester.tap(find.text('Home'));

    expect(tapped, [HomeTab.tools, HomeTab.stats, HomeTab.home]);
  });
}
