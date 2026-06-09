@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linklab/screens/home/profile_screen.dart';
import 'package:linklab/services/app_session_service.dart';

import 'test_harness.dart';

void main() {
  testWidgets('主題切換無需刷新即可立即更新當前頁面色板', (tester) async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);
    await pumpDemoShell(tester, home: const ProfileScreen());

    final titleFinder = find.text('我的').first;

    Color? readTitleColor() {
      return tester.widget<Text>(titleFinder).style?.color;
    }

    expect(AppSessionService.instance.isDayStageMode, isTrue);
    expect(readTitleColor(), const Color(0xFF071006));
    expect(find.bySemanticsLabel('切換到深夜模式'), findsNothing);

    await tester.ensureVisible(find.text('切換界面模式'));
    await tester.tap(find.text('切換界面模式'));
    await tester.pumpAndSettle();

    expect(AppSessionService.instance.isDayStageMode, isFalse);
    expect(readTitleColor(), const Color(0xFFF0F6FC));
    expect(find.bySemanticsLabel('切換到日間模式'), findsNothing);

    await tester.ensureVisible(find.text('切換界面模式'));
    await tester.tap(find.text('切換界面模式'));
    await tester.pumpAndSettle();

    expect(AppSessionService.instance.isDayStageMode, isTrue);
    expect(readTitleColor(), const Color(0xFF071006));
  });
}
