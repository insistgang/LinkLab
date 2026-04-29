@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linklab/services/app_session_service.dart';

import 'test_harness.dart';

void main() {
  testWidgets('主题切换无需刷新即可立即更新当前页面色板', (tester) async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);
    await pumpLinkLabDemoApp(tester);

    final titleFinder = find.text('共感 LinkAble').first;

    Color? readTitleColor() {
      return tester.widget<Text>(titleFinder).style?.color;
    }

    expect(AppSessionService.instance.isDayStageMode, isTrue);
    expect(readTitleColor(), const Color(0xFF071006));
    expect(find.bySemanticsLabel('切换到深夜模式').first, findsOneWidget);

    await tester.tap(find.bySemanticsLabel('切换到深夜模式').first);
    await tester.pumpAndSettle();

    expect(AppSessionService.instance.isDayStageMode, isFalse);
    expect(readTitleColor(), const Color(0xFFF4F8EC));
    expect(find.bySemanticsLabel('切换到日间模式').first, findsOneWidget);

    await tester.tap(find.bySemanticsLabel('切换到日间模式').first);
    await tester.pumpAndSettle();

    expect(AppSessionService.instance.isDayStageMode, isTrue);
    expect(readTitleColor(), const Color(0xFF071006));
  });
}
