@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linklab/screens/ai_chat/demo_ai_chat_screen.dart';

import 'test_harness.dart';

void main() {
  testWidgets('AI 助手 Tab 內嵌版顯示歡迎消息和輸入欄', (tester) async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(495, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: DemoAIChatScreen(embeddedInTab: true)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('AI助手'), findsOneWidget);
    expect(find.textContaining('您好！我是 AI 助手'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('發送消息')), findsOneWidget);
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });
}
