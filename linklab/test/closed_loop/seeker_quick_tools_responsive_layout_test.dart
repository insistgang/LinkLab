@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linklab/screens/home/seeker_home_screen.dart';

import 'test_harness.dart';

void main() {
  testWidgets('412dp 手机与 200% 系统字体下快捷工具标题不按字断行', (tester) async {
    tester.view.physicalSize = const Size(412, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await prepareSignedInDemoEnvironment(clearHelpHistory: true);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData.fromView(
              tester.view,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: const SeekerHomeScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    const labels = ['文字识别', '颜色识别', 'AI 对话'];
    final labelLeftEdges = [
      for (final label in labels) tester.getTopLeft(find.text(label)).dx,
    ];

    for (final leftEdge in labelLeftEdges.skip(1)) {
      expect(
        leftEdge,
        closeTo(labelLeftEdges.first, 0.5),
        reason: '手机窄屏下快捷工具应纵向排列，避免卡片过窄',
      );
    }
    for (final label in labels) {
      expect(
        tester.getSize(find.text(label)).height,
        lessThan(52),
        reason: '$label 应保持单行显示',
      );
    }
    expect(tester.takeException(), isNull);
  });
}
