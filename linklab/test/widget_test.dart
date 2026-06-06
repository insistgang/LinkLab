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
  testWidgets('默认初始化锁定 Demo 主线并启用演示员会话', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await app_entry.initializeLinkLabApp(enableAuthAutoRefresh: false);
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
    expect(find.text('让帮助真实发生\n连接每一次需要'), findsOneWidget);
    expect(find.text('欢迎使用'), findsNothing);
    expect(find.text('邮箱登录'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('缺少 Supabase 配置时 fallback 到 DemoMode', () {
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

  testWidgets('DemoMode 登录页保留手机号主入口与邮箱入口', (tester) async {
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
    expect(find.text('手机号登录'), findsOneWidget);
    expect(find.text('首次使用'), findsOneWidget);
    expect(find.text('邮箱登录'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('DemoMode 邮箱登录可走本地 fallback 建立会话', () async {
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
    expect(outcome.message, contains('本地演示账号'));
    // ignore: deprecated_member_use
    expect(AppSessionService.instance.isLoggedIn, isTrue);
    // ignore: deprecated_member_use
    expect(AppSessionService.instance.currentUser?.phone, 'demo@example.com');
  });

  testWidgets('登录页在窄屏和 200% 字体下不出现横向溢出', (tester) async {
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

    expect(find.text('手机号登录'), findsOneWidget);
    expect(find.text('邮箱登录'), findsOneWidget);
    expect(find.text('首次使用'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('无障碍偏好编辑页首屏直接显示设置内容', (tester) async {
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

    expect(find.text('无障碍偏好'), findsOneWidget);
    expect(find.text('编辑无障碍偏好'), findsOneWidget);
    expect(find.text('触觉反馈'), findsOneWidget);
    expect(find.text('自动朗读结果'), findsOneWidget);
    expect(find.text('保存设置'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('登录后首页支持读屏语义与 200% 字体缩放', (tester) async {
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

      expect(find.text('让帮助真实发生\n连接每一次需要'), findsOneWidget);
      expect(
        find.bySemanticsLabel('LinkAble 白色手形标志，象征连接每一次需要'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('我需要出行帮助，进入 AI 求助主线'), findsOneWidget);
      expect(find.bySemanticsLabel('我想成为志愿者，查看待帮助列表'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
}
