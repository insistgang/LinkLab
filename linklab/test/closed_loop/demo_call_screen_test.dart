@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linklab/config/app_config.dart';
import 'package:linklab/demo_flow/demo_help_request_tracker.dart';
import 'package:linklab/models/demo_match_request.dart';
import 'package:linklab/models/help_request_status.dart';
import 'package:linklab/models/user_model.dart';
import 'package:linklab/providers/demo_help_request_flow_provider.dart';
import 'package:linklab/providers/demo_matching_flow_provider.dart';
import 'package:linklab/screens/call/demo_call_screen.dart';
import 'package:linklab/services/app_session_service.dart';
import 'package:linklab/services/demo/demo_data_loader.dart';
import 'package:linklab/services/demo_call_service.dart' as legacy_demo;
import 'package:linklab/services/local_storage.dart';

void main() {
  const hospitalRequest = DemoMatchRequest(
    requestId: 'call_screen_hospital',
    queryText: '我在醫院找不到科室，需要真人幫忙',
    requestType: 'hospital_navigation',
    urgencyLevel: 'medium',
  );

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    AppConfig.demoMode = true;
    AppConfig.configureCompetitionDemoDefaults(enablePresenterSession: false);
    await DemoDataLoader.initialize();

    final storage = LocalStorage();
    await storage.initialize();

    final session = AppSessionService.instance;
    if (!session.isInitialized) {
      await session.initialize();
    }
  });

  Future<void> acceptDemoVolunteer(ProviderContainer container) async {
    await container
        .read(demoHelpRequestFlowProvider.notifier)
        .enterMatching(
          intent: hospitalRequest.queryText,
          type: hospitalRequest.requestType,
          urgency: hospitalRequest.urgencyLevel,
        );
    await container
        .read(demoMatchingFlowProvider.notifier)
        .start(request: hospitalRequest);
    await container
        .read(demoMatchingFlowProvider.notifier)
        .acceptCurrentCandidate();
  }

  testWidgets('匹配接單後進入 call screen，不崩潰並顯示已接單志願者', (tester) async {
    await _prepareSignedInCallEnvironment();
    final container = ProviderContainer();
    await acceptDemoVolunteer(container);
    final activeName = container
        .read(demoMatchingFlowProvider)
        .activeVolunteerName;

    await _pumpCallScreen(tester, container: container);
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('實時語音協助'), findsOneWidget);
    expect(find.text(activeName!), findsWidgets);
    expect(find.text('志願者已接單'), findsWidgets);
    expect(find.text('通話中'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('active volunteer 缺失時顯示 fallback 志願者', (tester) async {
    await _prepareSignedInCallEnvironment();
    final container = ProviderContainer();

    await _pumpCallScreen(tester, container: container);
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('林同學'), findsWidgets);
    expect(find.text('當前使用演示志願者繼續通話流程。'), findsOneWidget);
    expect(find.text('通話中'), findsWidgets);
  });

  testWidgets('志願者端通話頁顯示求助用戶，不再顯示已接單志願者卡片', (tester) async {
    await _prepareVolunteerCallEnvironment();
    final container = ProviderContainer();
    await container
        .read(demoHelpRequestFlowProvider.notifier)
        .enterMatching(
          intent: '用戶9012：緊急！迷路了。天黑了找不到回家的路，需要緊急幫助',
          type: 'sos',
          urgency: 'emergency',
        );

    await _pumpCallScreen(tester, container: container);
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('已連接求助用戶'), findsWidgets);
    expect(find.text('用戶9012'), findsOneWidget);
    expect(find.text('緊急！迷路了'), findsOneWidget);
    expect(find.textContaining('天黑了找不到回家的路'), findsWidgets);
    expect(find.text('已接單志願者'), findsNothing);
    expect(find.text('志願者已接單'), findsNothing);
  });

  testWidgets('靜音和免提按鈕狀態切換', (tester) async {
    await _prepareSignedInCallEnvironment();
    final container = ProviderContainer();
    await acceptDemoVolunteer(container);
    await _pumpCallScreen(tester, container: container);
    await tester.pump(const Duration(milliseconds: 150));

    await _tapVisible(tester, '靜音');
    expect(find.text('取消靜音'), findsOneWidget);

    await _tapVisible(tester, '關閉免提');
    expect(find.text('免提'), findsOneWidget);
  });

  testWidgets('結束通話後 help_request 進入 completed 並進入評分頁', (tester) async {
    await _prepareSignedInCallEnvironment();
    final container = ProviderContainer();
    await acceptDemoVolunteer(container);
    await _pumpCallScreen(tester, container: container);
    await tester.pump(const Duration(milliseconds: 150));

    await _tapVisible(tester, '結束通話');
    await tester.pump(const Duration(milliseconds: 450));

    expect(
      container.read(demoHelpRequestFlowProvider).status,
      HelpRequestStatus.completed,
    );
    expect(find.text('幫助已完成'), findsOneWidget);
    expect(find.text('爲這次幫助評分'), findsOneWidget);
  });

  testWidgets('模擬掉線後進入 reconnecting，模擬恢復後回到 connected', (tester) async {
    await _prepareSignedInCallEnvironment();
    final container = ProviderContainer();
    await acceptDemoVolunteer(container);
    await _pumpCallScreen(tester, container: container);
    await tester.pump(const Duration(milliseconds: 150));

    await _tapVisible(tester, '模擬掉線');
    expect(find.text('正在嘗試恢復連接'), findsWidgets);

    await _tapVisible(tester, '模擬恢復');
    expect(find.text('通話中'), findsWidgets);
    expect(
      container.read(demoHelpRequestFlowProvider).status,
      HelpRequestStatus.connected,
    );
  });

  testWidgets('模擬重連失敗後 help_request 回到 matching', (tester) async {
    await _prepareSignedInCallEnvironment();
    final container = ProviderContainer();
    await acceptDemoVolunteer(container);
    await _pumpCallScreen(tester, container: container);
    await tester.pump(const Duration(milliseconds: 150));

    await _tapVisible(tester, '模擬掉線');
    await _tapVisible(tester, '模擬重連失敗');

    expect(find.text('連接失敗，正在回到匹配'), findsWidgets);
    expect(
      container.read(demoHelpRequestFlowProvider).status,
      HelpRequestStatus.matching,
    );
  });

  testWidgets('reconnecting 時點擊結束通話不會崩潰', (tester) async {
    await _prepareSignedInCallEnvironment();
    final container = ProviderContainer();
    await acceptDemoVolunteer(container);
    await _pumpCallScreen(tester, container: container);
    await tester.pump(const Duration(milliseconds: 150));

    await _tapVisible(tester, '模擬掉線');
    await _tapVisible(tester, '結束通話');
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.text('幫助已完成'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('默認不初始化真實 WebRTC，也不請求真實麥克風權限', (tester) async {
    await _prepareSignedInCallEnvironment();
    final container = ProviderContainer();

    await _pumpCallScreen(tester, container: container);
    await tester.pump(const Duration(milliseconds: 150));

    expect(AppConfig.demoMode, isTrue);
    expect(FeatureFlags.enableWebRTC, isFalse);
    expect(find.textContaining('不建立真實 WebRTC'), findsWidgets);
    expect(find.textContaining('不請求真實麥克風權限'), findsWidgets);
  });

  testWidgets('通話頁關鍵按鈕具備 Semantics', (tester) async {
    await _prepareSignedInCallEnvironment();
    final container = ProviderContainer();
    await acceptDemoVolunteer(container);
    final semantics = tester.ensureSemantics();
    try {
      await _pumpCallScreen(tester, container: container);
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.bySemanticsLabel(RegExp('靜音按鈕')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('關閉免提按鈕')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('結束通話按鈕')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('模擬掉線按鈕')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('模擬恢復按鈕')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('模擬重連失敗按鈕')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('舉報和安全提示按鈕')), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('200% textScaleFactor 下通話頁 smoke test 不出現主要 overflow', (
    tester,
  ) async {
    await _prepareSignedInCallEnvironment();
    final container = ProviderContainer();
    await acceptDemoVolunteer(container);

    await _pumpCallScreen(tester, container: container, textScale: 2.0);
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('實時語音協助'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _prepareSignedInCallEnvironment() async {
  AppConfig.demoMode = true;
  AppConfig.configureCompetitionDemoDefaults(enablePresenterSession: false);

  final storage = LocalStorage();
  await storage.initialize();
  await storage.clearAll();

  legacy_demo.DemoCallService().reset();
  legacy_demo.DemoMatchingService().cancelMatching();
  legacy_demo.DemoSOSService().cancelSOS();
  await DemoHelpRequestTracker.clearCurrentRequest();

  await AppSessionService.instance.completeOnboarding(
    phone: '13800138000',
    role: 'seeker',
    disabilityTypes: const ['visual'],
    preferences: const AccessibilityPreferences(),
  );
  await storage.clearHelpHistory();
  await DemoHelpRequestTracker.clearCurrentRequest();
}

Future<void> _prepareVolunteerCallEnvironment() async {
  AppConfig.demoMode = true;
  AppConfig.configureCompetitionDemoDefaults(enablePresenterSession: false);

  final storage = LocalStorage();
  await storage.initialize();
  await storage.clearAll();

  legacy_demo.DemoCallService().reset();
  legacy_demo.DemoMatchingService().cancelMatching();
  legacy_demo.DemoSOSService().cancelSOS();
  await DemoHelpRequestTracker.clearCurrentRequest();

  await AppSessionService.instance.completeOnboarding(
    phone: '13900139000',
    role: 'volunteer',
    disabilityTypes: const [],
    preferences: const AccessibilityPreferences(),
  );
  await storage.clearHelpHistory();
  await DemoHelpRequestTracker.clearCurrentRequest();
}

Future<void> _pumpCallScreen(
  WidgetTester tester, {
  required ProviderContainer container,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = const Size(1280, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
    container.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: const DemoCallScreen(
            autoConnectDelay: Duration(milliseconds: 80),
            trackDuration: false,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _tapVisible(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 120));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 120));
}
