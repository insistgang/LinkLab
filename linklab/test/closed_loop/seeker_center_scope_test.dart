@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:linklab/screens/user_center/seeker_center_screen.dart';

import 'test_harness.dart';

void main() {
  testWidgets('求助者中心默认只暴露 MVP 允许的档案与状态回看', (tester) async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);

    await pumpDemoShell(tester, home: const SeekerCenterScreen());

    expect(find.text('帮助档案'), findsOneWidget);
    expect(find.text('求助状态'), findsOneWidget);

    expect(find.text('异步留言'), findsNothing);
    expect(find.text('安心积分'), findsNothing);
    expect(find.text('常用志愿者'), findsNothing);
    expect(find.text('偏好设置'), findsNothing);
  });
}
