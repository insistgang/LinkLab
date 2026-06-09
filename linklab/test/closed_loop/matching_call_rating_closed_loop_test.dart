@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:linklab/screens/call/demo_matching_screen.dart';

import 'test_harness.dart';

void main() {
  testWidgets('匹配到通話評價閉環會寫回 connected 和 completed 狀態', (tester) async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);

    await pumpDemoShell(tester, home: const DemoMatchingScreen());

    final matchingHistory = readLocalHelpHistoryModels();
    expect(matchingHistory.first.status, 'matching');

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.bySemanticsLabel('結束通話按鈕'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('通話中'), findsOneWidget);

    final connectedHistory = readLocalHelpHistoryModels();
    expect(connectedHistory.first.status, 'connected');

    await tester.tap(find.bySemanticsLabel('結束通話按鈕'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('爲這次幫助評分'), findsOneWidget);

    await tester.tap(find.byTooltip('評分5星'));
    await tester.pump();
    await tester.tap(find.text('提交評價'));
    await tester.pumpAndSettle();

    expect(find.text('共感 LinkAble'), findsWidgets);
    expect(find.text('點擊啓動SOS緊急求助'), findsOneWidget);

    final completedHistory = readLocalHelpHistoryModels();
    expect(completedHistory.first.status, 'completed');
    expect(completedHistory.first.seekerRating, 5);
    expect(completedHistory.first.aiResponse?['stage'], 'completed');
  });
}
