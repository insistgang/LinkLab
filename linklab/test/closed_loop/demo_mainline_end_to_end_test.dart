@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'test_harness.dart';

void main() {
  testWidgets('Demo 主線可從首頁閉環返回並在歷史中可見', (tester) async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);

    await pumpLinkLabDemoApp(tester);
    expect(find.text('讓幫助真實發生\n連接每一次需要'), findsOneWidget);

    await tester.tap(find.text('我需要出行幫助'));
    await tester.pumpAndSettle();
    expect(find.text('共感 LinkAble'), findsWidgets);
    expect(find.text('首頁'), findsOneWidget);
    expect(find.text('AI助手'), findsOneWidget);
    expect(find.text('社羣'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);

    expect(
      find.byKey(const ValueKey('seeker_sos_hold_button')),
      findsOneWidget,
    );
    expect(find.text('點擊啓動SOS緊急求助'), findsOneWidget);

    await tester.tap(find.text('AI助手').last);
    await tester.pumpAndSettle();
    expect(find.text('AI助手'), findsWidgets);

    await tester.enterText(
      find.byType(EditableText).first,
      '這個問題太複雜了，我需要更可靠的人工協助',
    );
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('需要人工幫助？'), findsOneWidget);
    await tester.tap(find.text('連接志願者'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('取消匹配'), findsOneWidget);

    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(seconds: 1));
      if (find.bySemanticsLabel('結束通話按鈕').evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.bySemanticsLabel('結束通話按鈕'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('結束通話按鈕'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('爲這次幫助評分'), findsOneWidget);

    await tester.tap(find.byTooltip('評分5星'));
    await tester.pump();
    await tester.enterText(find.byType(EditableText).first, '謝謝你幫我確認現場環境');
    await tester.tap(find.text('提交評價'));
    await tester.pumpAndSettle();

    expect(find.text('共感 LinkAble'), findsWidgets);
    expect(find.text('點擊啓動SOS緊急求助'), findsOneWidget);

    final history = readLocalHelpHistoryModels();
    expect(history.first.status, 'completed');
    expect(history.first.seekerRating, 5);
    expect(history.first.intent, contains('志願者'));
  });
}
