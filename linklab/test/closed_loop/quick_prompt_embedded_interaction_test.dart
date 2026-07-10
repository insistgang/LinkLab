@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linklab/screens/ai_chat/demo_ai_chat_screen.dart';

import 'test_harness.dart';

void main() {
  testWidgets('内嵌对话发送后的紧凑快捷提问在低高度大字下可用', (tester) async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const prompts = ['帮我读一下这个说明书', '布洛芬是什么药？', '药盒有效期怎么看？', '我需要真人志愿者帮助'];

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

    final promptFinder = find.text('药盒有效期怎么看？');
    await tester.ensureVisible(promptFinder);
    await tester.pump();
    await tester.tap(promptFinder);
    await tester.pump(const Duration(seconds: 2));

    final history = readLocalHelpHistoryModels();
    expect(history, isNotEmpty);
    expect(history.first.intent, '药盒有效期怎么看？');
    expect(find.text('快捷提问'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final firstPrompt = find.text(prompts.first);
    await tester.ensureVisible(firstPrompt);
    await tester.pump();
    expect(firstPrompt.hitTestable(), findsOneWidget);
  });
}
