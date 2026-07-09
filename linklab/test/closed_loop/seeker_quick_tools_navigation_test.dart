@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linklab/screens/ai_chat/demo_ai_chat_screen.dart';
import 'package:linklab/screens/home/seeker_home_screen.dart';

import 'test_harness.dart';

void main() {
  test('图片未附带文字时仍按快捷工具场景生成明确请求', () {
    expect(
      DemoAIChatToolMode.ocr.imageOnlyPrompt,
      contains('图片里的文字'),
    );
    expect(
      DemoAIChatToolMode.color.imageOnlyPrompt,
      contains('主要颜色'),
    );
    expect(DemoAIChatToolMode.chat.imageOnlyPrompt, contains('描述'));
  });

  testWidgets('三张快捷工具卡分别进入正确场景且保留输入意图', (tester) async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);
    await pumpDemoShell(tester, home: const SeekerHomeScreen());

    await tester.tap(find.text('文字识别'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    var screen = tester.widget<DemoAIChatScreen>(
      find.byType(DemoAIChatScreen),
    );
    expect(screen.title, 'AI文字识别');
    expect(screen.introMessage, contains('上传一张图片'));
    expect(screen.initialPrompt, '帮我读一下这个说明书');
    expect(screen.quickPrompts, isNotEmpty);
    expect(screen.toolMode, DemoAIChatToolMode.ocr);
    var input = tester.widget<EditableText>(find.byType(EditableText).first);
    expect(input.controller.text, '帮我读一下这个说明书');
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('颜色识别'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    screen = tester.widget<DemoAIChatScreen>(
      find.byType(DemoAIChatScreen),
    );
    expect(screen.title, 'AI颜色识别');
    expect(screen.introMessage, contains('确认衣服、包装或物品颜色'));
    expect(screen.initialPrompt, '这件衣服是什么颜色');
    expect(screen.quickPrompts, isNotEmpty);
    expect(screen.toolMode, DemoAIChatToolMode.color);
    input = tester.widget<EditableText>(find.byType(EditableText).first);
    expect(input.controller.text, '这件衣服是什么颜色');
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('AI 对话'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    screen = tester.widget<DemoAIChatScreen>(
      find.byType(DemoAIChatScreen),
    );
    expect(screen.title, 'AI智能对话');
    expect(screen.initialPrompt, isNull);
    expect(screen.quickPrompts, contains('布洛芬是什么药？'));
    expect(screen.toolMode, DemoAIChatToolMode.chat);
    input = tester.widget<EditableText>(find.byType(EditableText).first);
    expect(input.controller.text, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
