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
    queryText: '我在医院找不到科室，需要真人帮忙',
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

  testWidgets('匹配接单后进入 call screen，不崩溃并显示已接单志愿者', (tester) async {
    await _prepareSignedInCallEnvironment();
    final container = ProviderContainer();
    await acceptDemoVolunteer(container);
    final activeName = container
        .read(demoMatchingFlowProvider)
        .activeVolunteerName;

    await _pumpCallScreen(tester, container: container);
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('实时语音协助'), findsOneWidget);
    expect(find.text(activeName!), findsWidgets);
    expect(find.text('志愿者已接单'), findsWidgets);
    expect(find.text('通话中'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('active volunteer 缺失时显示 fallback 志愿者', (tester) async {
    await _prepareSignedInCallEnvironment();
    final container = ProviderContainer();

    await _pumpCallScreen(tester, container: container);
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('林同学'), findsWidgets);
    expect(find.text('当前使用演示志愿者继续通话流程。'), findsOneWidget);
    expect(find.text('通话中'), findsWidgets);
  });

  testWidgets('志愿者端通话页显示求助用户，不再显示已接单志愿者卡片', (tester) async {
    await _prepareVolunteerCallEnvironment();
    final container = ProviderContainer();
    await container
        .read(demoHelpRequestFlowProvider.notifier)
        .enterMatching(
          intent: '用户9012：紧急！迷路了。天黑了找不到回家的路，需要紧急帮助',
          type: 'sos',
          urgency: 'emergency',
        );

    await _pumpCallScreen(tester, container: container);
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('已连接求助用户'), findsWidgets);
    expect(find.text('用户9012'), findsOneWidget);
    expect(find.text('紧急！迷路了'), findsOneWidget);
    expect(find.textContaining('天黑了找不到回家的路'), findsWidgets);
    expect(find.text('已接单志愿者'), findsNothing);
    expect(find.text('志愿者已接单'), findsNothing);
  });

  testWidgets('静音和免提按钮状态切换', (tester) async {
    await _prepareSignedInCallEnvironment();
    final container = ProviderContainer();
    await acceptDemoVolunteer(container);
    await _pumpCallScreen(tester, container: container);
    await tester.pump(const Duration(milliseconds: 150));

    await _tapVisible(tester, '静音');
    expect(find.text('取消静音'), findsOneWidget);

    await _tapVisible(tester, '关闭免提');
    expect(find.text('免提'), findsOneWidget);
  });

  testWidgets('结束通话后 help_request 进入 completed 并进入评分页', (tester) async {
    await _prepareSignedInCallEnvironment();
    final container = ProviderContainer();
    await acceptDemoVolunteer(container);
    await _pumpCallScreen(tester, container: container);
    await tester.pump(const Duration(milliseconds: 150));

    await _tapVisible(tester, '结束通话');
    await tester.pump(const Duration(milliseconds: 450));

    expect(
      container.read(demoHelpRequestFlowProvider).status,
      HelpRequestStatus.completed,
    );
    expect(find.text('帮助已完成'), findsOneWidget);
    expect(find.text('为这次帮助评分'), findsOneWidget);
  });

  testWidgets('模拟掉线后进入 reconnecting，模拟恢复后回到 connected', (tester) async {
    await _prepareSignedInCallEnvironment();
    final container = ProviderContainer();
    await acceptDemoVolunteer(container);
    await _pumpCallScreen(tester, container: container);
    await tester.pump(const Duration(milliseconds: 150));

    await _tapVisible(tester, '模拟掉线');
    expect(find.text('正在尝试恢复连接'), findsWidgets);

    await _tapVisible(tester, '模拟恢复');
    expect(find.text('通话中'), findsWidgets);
    expect(
      container.read(demoHelpRequestFlowProvider).status,
      HelpRequestStatus.connected,
    );
  });

  testWidgets('模拟重连失败后 help_request 回到 matching', (tester) async {
    await _prepareSignedInCallEnvironment();
    final container = ProviderContainer();
    await acceptDemoVolunteer(container);
    await _pumpCallScreen(tester, container: container);
    await tester.pump(const Duration(milliseconds: 150));

    await _tapVisible(tester, '模拟掉线');
    await _tapVisible(tester, '模拟重连失败');

    expect(find.text('连接失败，正在回到匹配'), findsWidgets);
    expect(
      container.read(demoHelpRequestFlowProvider).status,
      HelpRequestStatus.matching,
    );
  });

  testWidgets('reconnecting 时点击结束通话不会崩溃', (tester) async {
    await _prepareSignedInCallEnvironment();
    final container = ProviderContainer();
    await acceptDemoVolunteer(container);
    await _pumpCallScreen(tester, container: container);
    await tester.pump(const Duration(milliseconds: 150));

    await _tapVisible(tester, '模拟掉线');
    await _tapVisible(tester, '结束通话');
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.text('帮助已完成'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('默认不初始化真实 WebRTC，也不请求真实麦克风权限', (tester) async {
    await _prepareSignedInCallEnvironment();
    final container = ProviderContainer();

    await _pumpCallScreen(tester, container: container);
    await tester.pump(const Duration(milliseconds: 150));

    expect(AppConfig.demoMode, isTrue);
    expect(FeatureFlags.enableWebRTC, isFalse);
    expect(find.textContaining('不建立真实 WebRTC'), findsWidgets);
    expect(find.textContaining('不请求真实麦克风权限'), findsWidgets);
  });

  testWidgets('通话页关键按钮具备 Semantics', (tester) async {
    await _prepareSignedInCallEnvironment();
    final container = ProviderContainer();
    await acceptDemoVolunteer(container);
    final semantics = tester.ensureSemantics();
    try {
      await _pumpCallScreen(tester, container: container);
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.bySemanticsLabel(RegExp('静音按钮')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('关闭免提按钮')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('结束通话按钮')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('模拟掉线按钮')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('模拟恢复按钮')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('模拟重连失败按钮')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('举报和安全提示按钮')), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('200% textScaleFactor 下通话页 smoke test 不出现主要 overflow', (
    tester,
  ) async {
    await _prepareSignedInCallEnvironment();
    final container = ProviderContainer();
    await acceptDemoVolunteer(container);

    await _pumpCallScreen(tester, container: container, textScale: 2.0);
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('实时语音协助'), findsOneWidget);
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
