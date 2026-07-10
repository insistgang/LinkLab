@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linklab/config/app_config.dart';
import 'package:linklab/demo_flow/demo_help_request_tracker.dart';
import 'package:linklab/models/demo_match_request.dart';
import 'package:linklab/models/demo_match_result.dart';
import 'package:linklab/models/demo_volunteer.dart';
import 'package:linklab/models/help_request_status.dart';
import 'package:linklab/models/user_model.dart';
import 'package:linklab/providers/demo_help_request_flow_provider.dart';
import 'package:linklab/providers/demo_matching_flow_provider.dart';
import 'package:linklab/providers/demo_services_provider.dart';
import 'package:linklab/screens/call/demo_matching_screen.dart';
import 'package:linklab/services/app_session_service.dart';
import 'package:linklab/services/demo/demo_data_loader.dart';
import 'package:linklab/services/demo/demo_matching_service.dart';
import 'package:linklab/services/demo_call_service.dart' as legacy_demo;
import 'package:linklab/services/local_storage.dart';

void main() {
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

  testWidgets('匹配页能加载 Top 5 候选人并过滤离线志愿者', (tester) async {
    await _prepareSignedInMatchingEnvironment();
    final container = await _pumpMatchingScreen(tester);

    expect(find.text('Top 5 志愿者候选'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('候选志愿者第 [1-5] 名')), findsNWidgets(5));
    expect(container.read(demoMatchingFlowProvider).candidates.length, 5);
    expect(find.textContaining('林夏'), findsWidgets);
    expect(find.textContaining('医院导诊'), findsWidgets);
    expect(find.textContaining('米'), findsWidgets);
    expect(find.textContaining('信誉'), findsWidgets);
    expect(find.textContaining('帮助'), findsWidgets);
    expect(find.textContaining('预计'), findsWidgets);
    expect(find.textContaining('匹配'), findsWidgets);
    expect(find.textContaining('孙悦'), findsNothing);
    expect(find.textContaining('郑涛'), findsNothing);
  });

  testWidgets('点击模拟接单后 help_request 进入 connected，且重复接单不会切换 active volunteer', (
    tester,
  ) async {
    await _prepareSignedInMatchingEnvironment();
    final container = await _pumpMatchingScreen(tester);

    await _tapVisible(tester, '模拟接单');
    await tester.pump(const Duration(milliseconds: 250));

    final matchingState = container.read(demoMatchingFlowProvider);
    final helpState = container.read(demoHelpRequestFlowProvider);
    expect(matchingState.phase, DemoMatchingUiPhase.accepted);
    expect(matchingState.activeVolunteerId, isNotNull);
    expect(helpState.status, HelpRequestStatus.connected);
    expect(find.text('志愿者已接单'), findsWidgets);
    expect(find.text('进入通话'), findsOneWidget);

    final activeVolunteerId = matchingState.activeVolunteerId;
    await container
        .read(demoMatchingFlowProvider.notifier)
        .acceptCurrentCandidate();
    expect(
      container.read(demoMatchingFlowProvider).activeVolunteerId,
      activeVolunteerId,
    );
  });

  testWidgets('点击取消求助后 help_request 进入 cancelled', (tester) async {
    await _prepareSignedInMatchingEnvironment();
    final container = await _pumpMatchingScreen(tester);

    await _tapVisible(tester, '取消匹配');
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      container.read(demoMatchingFlowProvider).phase,
      DemoMatchingUiPhase.cancelled,
    );
    expect(
      container.read(demoHelpRequestFlowProvider).status,
      HelpRequestStatus.cancelled,
    );
    expect(find.text('用户已取消'), findsWidgets);
    expect(find.text('取消求助'), findsOneWidget);
  });

  testWidgets('点击模拟无人接单后 help_request 进入 expired', (tester) async {
    await _prepareSignedInMatchingEnvironment();
    final container = await _pumpMatchingScreen(tester);

    await _tapVisible(tester, '模拟无人接单');
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      container.read(demoMatchingFlowProvider).phase,
      DemoMatchingUiPhase.expired,
    );
    expect(
      container.read(demoHelpRequestFlowProvider).status,
      HelpRequestStatus.expired,
    );
    expect(find.text('无人接单，稍后再试'), findsWidgets);
  });

  testWidgets('点击拒接或超时后尝试下一位候选人', (tester) async {
    await _prepareSignedInMatchingEnvironment();
    final container = await _pumpMatchingScreen(tester);
    final firstVolunteerId = container
        .read(demoMatchingFlowProvider)
        .currentCandidate
        ?.volunteer
        .id;

    await _tapVisible(tester, '模拟拒接 / 超时');
    await tester.pump(const Duration(milliseconds: 250));

    final state = container.read(demoMatchingFlowProvider);
    expect(state.currentCandidateIndex, 1);
    expect(state.currentCandidate?.volunteer.id, isNot(firstVolunteerId));
    expect(state.statusMessage, contains('第 2 位'));
    expect(find.text('上一位暂时无法接听，正在尝试下一位'), findsOneWidget);
  });

  testWidgets('Top 5 数据缺失时显示降级文案', (tester) async {
    await _prepareSignedInMatchingEnvironment();
    await _pumpMatchingScreen(
      tester,
      overrides: [
        demoMatchingEngineProvider.overrideWithValue(
          _EmptyMatchingEngineService(),
        ),
      ],
    );

    expect(find.textContaining('当前没有可用志愿者'), findsWidgets);
    expect(find.textContaining('回到 AI 助手继续描述问题'), findsWidgets);
  });

  testWidgets('匹配页关键按钮和候选卡片具备 Semantics', (tester) async {
    await _prepareSignedInMatchingEnvironment();
    final semantics = tester.ensureSemantics();
    try {
      await _pumpMatchingScreen(tester);

      expect(find.bySemanticsLabel(RegExp('候选志愿者第 1 名')), findsOneWidget);
      await tester.ensureVisible(find.text('取消匹配'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.bySemanticsLabel(RegExp('取消求助')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('模拟接单')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('模拟拒接或超时')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('重新匹配')), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('200% 字体缩放下匹配页 smoke test 不出现主要 overflow', (tester) async {
    await _prepareSignedInMatchingEnvironment();
    await _pumpMatchingScreen(tester, textScale: 2.0);

    expect(find.text('Top 5 志愿者候选'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('默认不接真实定位、推送、Supabase 或 WebRTC', (tester) async {
    await _prepareSignedInMatchingEnvironment();
    await _pumpMatchingScreen(tester);

    expect(AppConfig.demoMode, isTrue);
    expect(FeatureFlags.enableLocationService, isFalse);
    expect(FeatureFlags.enablePushNotification, isFalse);
    expect(FeatureFlags.enableDatabaseSync, isFalse);
    expect(FeatureFlags.enableWebRTC, isFalse);
    expect(find.textContaining('不依赖真实定位'), findsWidgets);
    expect(find.textContaining('无真实推送'), findsOneWidget);
  });
}

Future<void> _prepareSignedInMatchingEnvironment() async {
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

Future<ProviderContainer> _pumpMatchingScreen(
  WidgetTester tester, {
  List<Override> overrides = const <Override>[],
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = const Size(1280, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: const DemoMatchingScreen(autoRunDemo: false),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump(const Duration(milliseconds: 350));

  final context = tester.element(find.byType(DemoMatchingScreen));
  return ProviderScope.containerOf(context);
}

Future<void> _tapVisible(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 250));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 250));
}

class _EmptyMatchingEngineService extends DemoMatchingEngineService {
  @override
  Future<DemoMatchResponse> matchTopVolunteers(
    DemoMatchRequest request, {
    List<DemoVolunteer>? volunteerPool,
  }) async {
    return DemoMatchResponse.empty('测试：demo_volunteers.json 暂时不可用');
  }
}
