@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'test_harness.dart';

void main() {
  testWidgets('Demo 主线可从首页闭环返回并在历史中可见', (tester) async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);

    await pumpLinkLabDemoApp(tester);
    expect(find.text('让帮助真实发生\n连接每一次需要'), findsOneWidget);

    await tester.tap(find.text('我需要出行帮助'));
    await tester.pumpAndSettle();
    expect(find.text('共感 LinkAble'), findsWidgets);
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('AI助手'), findsOneWidget);
    expect(find.text('社群'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);

    expect(
      find.byKey(const ValueKey('seeker_sos_hold_button')),
      findsOneWidget,
    );
    expect(find.text('点击启动SOS紧急求助'), findsOneWidget);

    await tester.tap(find.text('AI助手').last);
    await tester.pumpAndSettle();
    expect(find.text('AI助手'), findsWidgets);

    await tester.enterText(
      find.byType(EditableText).first,
      '这个问题太复杂了，我需要更可靠的人工协助',
    );
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('需要人工帮助？'), findsOneWidget);
    await tester.tap(find.text('连接志愿者'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('取消匹配'), findsOneWidget);

    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(seconds: 1));
      if (find.bySemanticsLabel('结束通话按钮').evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.bySemanticsLabel('结束通话按钮'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('结束通话按钮'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('为这次帮助评分'), findsOneWidget);

    await tester.tap(find.byTooltip('评分5星'));
    await tester.pump();
    await tester.enterText(find.byType(EditableText).first, '谢谢你帮我确认现场环境');
    await tester.tap(find.text('提交评价'));
    await tester.pumpAndSettle();

    expect(find.text('共感 LinkAble'), findsWidgets);
    expect(find.text('点击启动SOS紧急求助'), findsOneWidget);

    final history = readLocalHelpHistoryModels();
    expect(history.first.status, 'completed');
    expect(history.first.seekerRating, 5);
    expect(history.first.intent, contains('志愿者'));
  });
}
