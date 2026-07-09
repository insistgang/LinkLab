@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:linklab/models/user_model.dart';
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

    await session.completeOnboarding(
      phone: '13800138000',
      role: 'seeker',
      disabilityTypes: const ['visual'],
      preferences: const AccessibilityPreferences(),
    );
    await pumpLinkLabDemoApp(tester);

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
