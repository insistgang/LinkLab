@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:linklab/screens/ai_chat/demo_ai_chat_screen.dart';

import 'test_harness.dart';

void main() {
  testWidgets('AI 對話識別 need_human 後進入匹配頁，並寫入 matching 狀態', (tester) async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);

    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DemoAIChatScreen(
            initialPrompt: '這個問題太複雜了，我需要更可靠的人工協助',
            autoSendInitialPrompt: true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('需要人工幫助？'), findsOneWidget);

    final processingHistory = readLocalHelpHistoryModels();
    expect(processingHistory.first.status, 'ai_processing');

    await tester.tap(find.text('連接志願者'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('取消匹配'), findsOneWidget);

    final matchingHistory = readLocalHelpHistoryModels();
    expect(matchingHistory.first.status, 'matching');
    expect(matchingHistory.first.intent, contains('志願者'));

    await tester.scrollUntilVisible(
      find.text('取消匹配'),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('取消匹配'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  });
}
