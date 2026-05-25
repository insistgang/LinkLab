@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:linklab/screens/call/demo_matching_screen.dart';

import 'test_harness.dart';

void main() {
  testWidgets('匹配到通话评价闭环会写回 connected 和 completed 状态', (tester) async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);

    await pumpDemoShell(tester, home: const DemoMatchingScreen());

    final matchingHistory = readLocalHelpHistoryModels();
    expect(matchingHistory.first.status, 'matching');

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.bySemanticsLabel('结束通话按钮'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.textContaining('通话中'), findsOneWidget);

    final connectedHistory = readLocalHelpHistoryModels();
    expect(connectedHistory.first.status, 'connected');

    await tester.tap(find.bySemanticsLabel('结束通话按钮'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('为这次帮助评分'), findsOneWidget);

    await tester.tap(find.byTooltip('评分5星'));
    await tester.pump();
    await tester.tap(find.text('提交评价'));
    await tester.pumpAndSettle();

    expect(find.text('共感 LinkAble'), findsWidgets);
    expect(find.text('长按求助'), findsOneWidget);

    final completedHistory = readLocalHelpHistoryModels();
    expect(completedHistory.first.status, 'completed');
    expect(completedHistory.first.seekerRating, 5);
    expect(completedHistory.first.aiResponse?['stage'], 'completed');
  });
}
