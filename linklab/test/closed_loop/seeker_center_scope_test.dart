@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:linklab/screens/user_center/seeker_center_screen.dart';

import 'test_harness.dart';

void main() {
  testWidgets('求助者中心默認只暴露 MVP 允許的檔案與狀態回看', (tester) async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);

    await pumpDemoShell(tester, home: const SeekerCenterScreen());

    expect(find.text('幫助檔案'), findsOneWidget);
    expect(find.text('求助狀態'), findsOneWidget);

    expect(find.text('異步留言'), findsNothing);
    expect(find.text('安心積分'), findsNothing);
    expect(find.text('常用志願者'), findsNothing);
    expect(find.text('偏好設置'), findsNothing);
  });
}
