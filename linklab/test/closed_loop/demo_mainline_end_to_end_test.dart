@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_harness.dart';

void main() {
  testWidgets('Demo 主线可从首页闭环返回并在历史中可见', (tester) async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);

    await pumpLinkLabDemoApp(tester);
    expect(find.textContaining('您好，'), findsOneWidget);

    await tester.tap(find.text('我需要帮助'));
    await tester.pumpAndSettle();
    expect(find.text('AI助手'), findsOneWidget);

    await tester.enterText(
      find.byType(EditableText).first,
      '这个问题太复杂了，我需要更可靠的人工协助',
    );
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('需要人工帮助？'), findsOneWidget);
    await tester.tap(find.text('连接志愿者'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('取消匹配'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.textContaining('通话中'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.call_end));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('为这次帮助评分'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.star_border).at(4));
    await tester.pump();
    await tester.enterText(find.byType(EditableText).first, '谢谢你帮我确认现场环境');
    await tester.tap(find.text('提交评价'));
    await tester.pumpAndSettle();

    expect(find.textContaining('您好，'), findsOneWidget);
    expect(find.text('最近帮助'), findsOneWidget);
    expect(find.text('语音求助'), findsOneWidget);
    expect(find.text('已完成'), findsOneWidget);

    final history = readLocalHelpHistoryModels();
    expect(history.first.status, 'completed');
    expect(history.first.seekerRating, 5);
    expect(history.first.intent, contains('志愿者'));
  });
}
