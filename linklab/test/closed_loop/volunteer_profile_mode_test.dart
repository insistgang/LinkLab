@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

void main() {
  testWidgets('志願者入口進入我的頁時顯示志願者身份', (tester) async {
    await prepareSignedInDemoEnvironment();

    await pumpLinkLabDemoApp(tester);
    await tester.tap(find.text('我想成爲志願者'));
    await tester.pumpAndSettle();

    expect(find.text('待幫助'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();

    expect(find.text('志願者模式'), findsOneWidget);
    expect(find.text('志願者資料'), findsWidgets);
    expect(find.text('志願者模式已就緒'), findsOneWidget);
    expect(find.text('求助者模式'), findsNothing);
  });
}
