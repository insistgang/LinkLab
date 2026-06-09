@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:linklab/models/user_model.dart';
import 'package:linklab/services/app_session_service.dart';
import 'package:linklab/services/local_storage.dart';

import 'test_harness.dart';

void main() {
  testWidgets('啓動/登錄閉環：初始化、首次引導與偏好持久化可用', (tester) async {
    await prepareEmptyDemoEnvironment();
    final session = AppSessionService.instance;

    expect(session.isLoggedIn, isFalse);
    expect(session.isFirstLaunch, isTrue);

    await pumpLinkLabDemoApp(tester);
    expect(find.text('歡迎來到共感LinkAble'), findsOneWidget);

    await session.completeOnboarding(
      phone: '13800138000',
      role: 'seeker',
      disabilityTypes: const ['visual'],
      preferences: const AccessibilityPreferences(),
    );
    await pumpLinkLabDemoApp(tester);

    expect(find.text('讓幫助真實發生\n連接每一次需要'), findsOneWidget);
    expect(find.text('我需要出行幫助'), findsOneWidget);
    expect(find.text('我想成爲志願者'), findsOneWidget);
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
