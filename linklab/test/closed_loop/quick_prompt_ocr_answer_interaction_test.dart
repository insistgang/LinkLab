@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linklab/screens/ai_chat/demo_ai_chat_screen.dart';

import 'test_harness.dart';

void main() {
  testWidgets('文字识别公交站牌快捷问题会返回站牌内容而不是药品内容', (tester) async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);
    tester.view.physicalSize = const Size(1164, 770);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DemoAIChatScreen(
            title: 'AI文字识别',
            introMessage: '请告诉我需要读什么，或者直接上传一张图片。',
            toolMode: DemoAIChatToolMode.ocr,
            quickPrompts: ['查看示例药品说明书', '查看示例菜单内容', '查看示例公交站牌'],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    final prompt = find.text('查看示例公交站牌');
    await tester.ensureVisible(prompt);
    await tester.pump();
    expect(prompt.hitTestable(), findsOneWidget);
    await tester.tap(prompt);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 400));

    final history = readLocalHelpHistoryModels();
    expect(history, isNotEmpty);
    expect(history.first.intent, '查看示例公交站牌');
    final summary = history.first.aiResponse?['summary'] as String? ?? '';
    expect(summary, startsWith('示例识别结果：'));
    expect(summary, contains('101路公交车站牌'));
    expect(summary, isNot(contains('阿莫西林')));
    expect(tester.takeException(), isNull);
  });
}
