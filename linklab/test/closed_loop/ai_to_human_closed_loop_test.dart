@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'package:linklab/screens/ai_chat/demo_ai_chat_screen.dart';

import 'test_harness.dart';

void main() {
  testWidgets('AI 对话识别 need_human 后进入匹配页，并写入 matching 状态', (tester) async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);

    await pumpDemoShell(
      tester,
      home: const DemoAIChatScreen(
        initialPrompt: '这个问题太复杂了，我需要更可靠的人工协助',
        autoSendInitialPrompt: true,
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('需要人工帮助？'), findsOneWidget);

    final processingHistory = readLocalHelpHistoryModels();
    expect(processingHistory.first.status, 'ai_processing');

    await tester.tap(find.text('连接志愿者'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('取消匹配'), findsOneWidget);

    final matchingHistory = readLocalHelpHistoryModels();
    expect(matchingHistory.first.status, 'matching');
    expect(matchingHistory.first.intent, contains('志愿者'));

    await tester.scrollUntilVisible(
      find.text('取消匹配'),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('取消匹配'), warnIfMissed: false);
    await tester.pumpAndSettle();
  });
}
