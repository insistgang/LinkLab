@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linklab/services/app_session_service.dart';
import 'package:linklab/services/local_storage.dart';

import 'test_harness.dart';

void main() {
  testWidgets('启动/登录闭环：初始化、首次引导与偏好持久化可用', (tester) async {
    await prepareEmptyDemoEnvironment();
    final session = AppSessionService.instance;

    expect(session.isLoggedIn, isFalse);
    expect(session.isFirstLaunch, isTrue);

    await pumpLinkLabDemoApp(tester);
    expect(find.text('欢迎来到共感LinkAble'), findsOneWidget);

    await tester.tap(find.text('跳过'));
    await tester.pumpAndSettle();
    expect(find.text('请输入您的手机号'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).first, '13800138000');
    await tester.tap(find.text('下一步').last);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.textContaining('验证码已发送至'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).first, '123456');
    await tester.tap(find.text('验证'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('选择身份'), findsOneWidget);

    await tester.tap(find.text('我需要帮助'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续').last);
    await tester.pumpAndSettle();
    expect(find.text('请选择您的障碍类型'), findsOneWidget);

    await tester.tap(find.text('视力障碍'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续').last);
    await tester.pumpAndSettle();
    expect(find.text('个性化您的使用体验'), findsOneWidget);

    await tester.tap(find.text('开始使用').last);
    await tester.pumpAndSettle();

    expect(find.text('让帮助真实发生\n连接每一次需要'), findsOneWidget);
    expect(find.text('我需要出行帮助'), findsOneWidget);
    expect(find.text('我想成为志愿者'), findsOneWidget);
    expect(session.isLoggedIn, isTrue);
    expect(session.isFirstLaunch, isFalse);
    expect(session.currentUser?.id, isNotEmpty);
    expect(session.preferences.highContrastMode, isFalse);
    expect(session.preferences.fontScale, 1.0);

    final storedPrefs = LocalStorage().getAccessibilityPrefs();
    expect(storedPrefs['highContrastMode'], isFalse);
    expect(storedPrefs['fontScale'], 1.0);

    final recentHistory = session.getRecentHelpHistory(limit: 3);
    expect(recentHistory.isNotEmpty, isTrue);
    expect(
      recentHistory.any((request) => request.status == 'ai_resolved'),
      isTrue,
    );
  });
}
