import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linklab/config/app_config.dart';
import 'package:linklab/main.dart' as app_entry;
import 'package:linklab/screens/auth/login_screen.dart';
import 'package:linklab/screens/auth/preference_screen.dart';
import 'package:linklab/screens/home/home_screen.dart';
import 'package:linklab/services/app_session_service.dart';
import 'package:linklab/services/local_storage.dart';

void main() {
  testWidgets('默認初始化鎖定 Demo 主線並啓用演示員會話', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await app_entry.initializeLinkLabApp(
      enableAuthAutoRefresh: false,
      enableRealAIFromEnvironment: false,
    );
    await tester.pumpWidget(app_entry.buildLinkLabApp());
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(AppConfig.demoMode, isTrue);
    expect(AppConfig.isRealMode, isFalse);
    expect(AppConfig.presenterMode, isTrue);
    expect(AppConfig.supabaseInitialized, isFalse);
    expect(FeatureFlags.enableSupabaseAuth, isFalse);
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
    expect(find.text('讓幫助真實發生\n連接每一次需要'), findsOneWidget);
    expect(find.text('歡迎使用'), findsNothing);
    expect(find.text('郵箱登錄'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('缺少 Supabase 配置時 fallback 到 DemoMode', () {
    AppConfig.configureFromEnvironment(
      const {},
      enablePresenterSessionOnFallback: false,
    );

    expect(AppConfig.demoMode, isTrue);
    expect(AppConfig.isRealMode, isFalse);
    expect(AppConfig.hasSupabaseConfig, isFalse);
    expect(AppConfig.presenterMode, isFalse);
    expect(FeatureFlags.enableDatabaseSync, isFalse);
    expect(FeatureFlags.enableSupabaseAuth, isFalse);
    expect(FeatureFlags.enableWebRTC, isFalse);
    expect(FeatureFlags.enableRealAI, isFalse);
  });

  test('真實 AI 只有 .env 顯式開關時啓用，且不要求切出 DemoMode', () {
    AppConfig.configureFromEnvironment(const {
      'LINKABLE_ENABLE_REAL_AI': 'true',
    }, enablePresenterSessionOnFallback: false);

    expect(AppConfig.demoMode, isTrue);
    expect(FeatureFlags.enableRealAI, isTrue);

    AppConfig.configureCompetitionDemoDefaults(enablePresenterSession: false);
    expect(FeatureFlags.enableRealAI, isFalse);
  });

  testWidgets('DemoMode 登錄頁保留手機號主入口與郵箱入口', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    AppConfig.configureCompetitionDemoDefaults(enablePresenterSession: false);
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );
    await tester.pumpAndSettle();

    expect(AppConfig.demoMode, isTrue);
    expect(find.text('手機號登錄'), findsOneWidget);
    expect(find.text('首次使用'), findsOneWidget);
    expect(find.text('郵箱登錄'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('DemoMode 郵箱登錄可走本地 fallback 建立會話', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    AppConfig.configureCompetitionDemoDefaults(enablePresenterSession: false);
    await LocalStorage().initialize();

    // ignore: deprecated_member_use
    final outcome = await AppSessionService.instance.loginWithEmailPassword(
      email: 'demo@example.com',
      password: '123456',
    );

    expect(outcome.signedIn, isTrue);
    expect(outcome.message, contains('本地演示賬號'));
    // ignore: deprecated_member_use
    expect(AppSessionService.instance.isLoggedIn, isTrue);
    // ignore: deprecated_member_use
    expect(AppSessionService.instance.currentUser?.phone, 'demo@example.com');
  });

  testWidgets('登錄頁在窄屏和 200% 字體下不出現橫向溢出', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    AppConfig.configureCompetitionDemoDefaults(enablePresenterSession: false);
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: LoginScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('手機號登錄'), findsOneWidget);
    expect(find.text('郵箱登錄'), findsOneWidget);
    expect(find.text('首次使用'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('無障礙偏好編輯頁首屏直接顯示設置內容', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    AppConfig.configureCompetitionDemoDefaults(enablePresenterSession: false);
    tester.view.physicalSize = const Size(500, 934);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.4)),
            child: PreferenceScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('無障礙偏好'), findsOneWidget);
    expect(find.text('編輯無障礙偏好'), findsOneWidget);
    expect(find.text('觸覺反饋'), findsOneWidget);
    expect(find.text('自動朗讀結果'), findsOneWidget);
    expect(find.text('保存設置'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('登錄後首頁支持讀屏語義與 200% 字體縮放', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(475, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: HomeScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('讓幫助真實發生\n連接每一次需要'), findsOneWidget);
      expect(
        find.bySemanticsLabel('LinkAble 白色手形標誌，象徵連接每一次需要'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('我需要出行幫助，進入 AI 求助主線'), findsOneWidget);
      expect(find.bySemanticsLabel('我想成爲志願者，查看待幫助列表'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
}
