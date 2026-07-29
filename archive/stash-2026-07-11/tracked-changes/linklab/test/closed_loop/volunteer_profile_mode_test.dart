@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

void main() {
  testWidgets('志愿者入口进入我的页时显示志愿者身份', (tester) async {
    await prepareSignedInDemoEnvironment();

    await pumpLinkLabDemoApp(tester);
    await tester.tap(find.text('我想成为志愿者'));
    await tester.pumpAndSettle();

    expect(find.text('待帮助'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();

    expect(find.text('志愿者模式'), findsOneWidget);
    expect(find.text('志愿者资料'), findsWidgets);
    expect(find.text('志愿者模式已就绪'), findsOneWidget);
    expect(find.text('求助者模式'), findsNothing);
  });
}
