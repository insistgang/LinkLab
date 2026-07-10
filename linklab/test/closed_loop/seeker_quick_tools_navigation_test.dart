@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linklab/screens/ai_chat/demo_ai_chat_screen.dart';
import 'package:linklab/screens/home/seeker_home_screen.dart';

import 'test_harness.dart';

void main() {
  test('图片未附带文字时仍按快捷工具场景生成明确请求', () {
    expect(DemoAIChatToolMode.ocr.imageOnlyPrompt, contains('图片里的文字'));
    expect(DemoAIChatToolMode.color.imageOnlyPrompt, contains('主要颜色'));
    expect(DemoAIChatToolMode.chat.imageOnlyPrompt, contains('描述'));
  });

  testWidgets('三张快捷工具卡分别进入正确场景且保留输入意图', (tester) async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);
    await pumpDemoShell(tester, home: const SeekerHomeScreen());

    await tester.tap(find.text('文字识别'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    var screen = tester.widget<DemoAIChatScreen>(find.byType(DemoAIChatScreen));
    expect(screen.title, 'AI文字识别');
    expect(screen.introMessage, contains('上传一张图片'));
    expect(screen.initialPrompt, isNull);
    expect(screen.quickPrompts, isNotEmpty);
    expect(screen.toolMode, DemoAIChatToolMode.ocr);
    var input = tester.widget<EditableText>(find.byType(EditableText).first);
    expect(input.controller.text, isEmpty);
    expect(find.text('拍照识别文字'), findsOneWidget);
    Navigator.of(tester.element(find.byType(DemoAIChatScreen))).pop();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('颜色识别'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    screen = tester.widget<DemoAIChatScreen>(find.byType(DemoAIChatScreen));
    expect(screen.title, 'AI颜色识别');
    expect(screen.introMessage, contains('确认衣服、包装或物品颜色'));
    expect(screen.initialPrompt, isNull);
    expect(screen.quickPrompts, isNotEmpty);
    expect(screen.toolMode, DemoAIChatToolMode.color);
    input = tester.widget<EditableText>(find.byType(EditableText).first);
    expect(input.controller.text, isEmpty);
    expect(find.text('拍照识别颜色'), findsOneWidget);
    Navigator.of(tester.element(find.byType(DemoAIChatScreen))).pop();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('AI 对话'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    screen = tester.widget<DemoAIChatScreen>(find.byType(DemoAIChatScreen));
    expect(screen.title, 'AI智能对话');
    expect(screen.initialPrompt, isNull);
    expect(screen.quickPrompts, contains('布洛芬是什么药？'));
    expect(screen.toolMode, DemoAIChatToolMode.chat);
    input = tester.widget<EditableText>(find.byType(EditableText).first);
    expect(input.controller.text, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('键盘弹出时快捷工具标题和主要内容仍保持可见', (tester) async {
    tester.view.physicalSize = const Size(1164, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 220);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DemoAIChatScreen(
            title: 'AI文字识别',
            introMessage: '请上传图片，我会读取其中的文字。',
            toolMode: DemoAIChatToolMode.ocr,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('AI文字识别').hitTestable(), findsOneWidget);
    expect(find.text('拍照识别文字').hitTestable(), findsOneWidget);
    final inputBottom = tester.getBottomRight(find.byType(TextField)).dy;
    expect(inputBottom, lessThanOrEqualTo(568 - 220));
    expect(tester.takeException(), isNull);
  });

  testWidgets('桌面窄内容区中三个快捷问题无需横向滑动即可操作', (tester) async {
    tester.view.physicalSize = const Size(1164, 770);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const prompts = ['帮我读一下这个说明书', '帮我看一下菜单写了什么', '读一下公交站牌内容'];

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DemoAIChatScreen(
            title: 'AI智能对话',
            introMessage: '直接输入你想了解的问题。',
            quickPrompts: prompts,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    for (final prompt in prompts) {
      expect(find.text(prompt).hitTestable(), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('200% 大字与窄屏下所有快捷问题均完整可见', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const prompts = ['帮我读一下这个说明书', '帮我看一下菜单写了什么', '读一下公交站牌内容'];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData.fromView(
              tester.view,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: const DemoAIChatScreen(
              title: 'AI智能对话',
              introMessage: '直接输入你想了解的问题。',
              quickPrompts: prompts,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    for (final prompt in prompts) {
      final promptFinder = find.text(prompt);
      expect(promptFinder.hitTestable(), findsOneWidget);
      final paragraph = tester.renderObject<RenderParagraph>(promptFinder);
      expect(
        paragraph.didExceedMaxLines,
        isFalse,
        reason: '快捷问题不应被单行截断：$prompt',
      );
    }
    expect(tester.takeException(), isNull);
  });
}
