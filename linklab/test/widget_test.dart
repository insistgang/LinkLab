import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linklab/config/app_config.dart';
import 'package:linklab/main.dart' as app_entry;
import 'package:linklab/services/app_session_service.dart';

void main() {
  testWidgets('竞赛版默认在 ProviderScope 下启动到 demo 主线', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    await app_entry.initializeCompetitionDemoApp();
    await tester.pumpWidget(app_entry.buildCompetitionDemoApp());
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(AppConfig.demoMode, isTrue);
    expect(AppConfig.isRealMode, isFalse);
    expect(AppConfig.presenterMode, isTrue);
    expect(FeatureFlags.enableWebRTC, isFalse);
    expect(FeatureFlags.enableRealMatching, isFalse);
    expect(FeatureFlags.enablePushNotification, isFalse);
    expect(FeatureFlags.enableRealAI, isFalse);
    expect(FeatureFlags.enableDatabaseSync, isFalse);
    expect(FeatureFlags.enableLocationService, isFalse);
    expect(FeatureFlags.enableRealSMS, isFalse);
    expect(FeatureFlags.enableCommunity, isFalse);
    expect(FeatureFlags.enablePoints, isFalse);
    expect(FeatureFlags.enableBadges, isFalse);
    expect(FeatureFlags.enableSchedule, isFalse);
    expect(FeatureFlags.enableAdminDashboard, isFalse);
    expect(FeatureFlags.enableCallRecording, isFalse);
    expect(AppSessionService.instance.isLoggedIn, isTrue);
    expect(find.textContaining('请输入您的手机号'), findsNothing);
    expect(find.text('首页'), findsWidgets);
    expect(find.text('AI助手'), findsWidgets);
    expect(find.text('社群'), findsWidgets);
    expect(find.text('我的'), findsWidgets);
    expect(find.text('精选故事'), findsWidgets);
    expect(find.text('我的社群'), findsNothing);
    expect(find.text('推荐社群'), findsNothing);
    expect(find.text('群聊'), findsNothing);
    expect(find.text('安心积分'), findsNothing);
    expect(find.text('徽章'), findsNothing);
    expect(find.text('排班'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
