@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linklab/screens/ai_chat/demo_ai_chat_screen.dart';

import 'test_harness.dart';

void main() {
  testWidgets('内嵌对话快捷问题在手机大字下保持单行横向滚动', (tester) async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const prompts = ['查看示例药品说明书', '布洛芬是什么药？', '药盒有效期怎么看？', '我需要真人志愿者帮助'];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData.fromView(
              tester.view,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: const DemoAIChatScreen(
              embeddedInTab: true,
              title: 'AI智能对话',
              introMessage: '直接输入你想了解的问题。',
              quickPrompts: prompts,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    final firstPrompt = find.text(prompts.first);
    final firstPromptY = tester.getCenter(firstPrompt).dy;
    for (final prompt in prompts.skip(1)) {
      expect(
        tester.getCenter(find.text(prompt)).dy,
        closeTo(firstPromptY, 0.5),
        reason: '所有快捷问题应保持在同一横排：$prompt',
      );
    }

    final promptFinder = find.text(prompts.last);
    expect(promptFinder.hitTestable(), findsNothing);
    await tester.drag(firstPrompt, const Offset(-900, 0));
    await tester.pump(const Duration(milliseconds: 300));
    expect(promptFinder.hitTestable(), findsOneWidget);

    await tester.tap(promptFinder);
    await tester.pump(const Duration(seconds: 2));

    final history = readLocalHelpHistoryModels();
    expect(history, isNotEmpty);
    expect(history.first.intent, prompts.last);
    expect(find.text('快捷提问'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
