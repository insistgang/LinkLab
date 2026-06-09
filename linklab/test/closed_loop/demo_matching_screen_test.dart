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

  testWidgets('匹配頁能加載 Top 5 候選人並過濾離線志願者', (tester) async {
    await _prepareSignedInMatchingEnvironment();
    final container = await _pumpMatchingScreen(tester);

    expect(find.text('Top 5 志願者候選'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('候選志願者第 [1-5] 名')), findsNWidgets(5));
    expect(container.read(demoMatchingFlowProvider).candidates.length, 5);
    expect(find.textContaining('林夏'), findsWidgets);
    expect(find.textContaining('醫院導診'), findsWidgets);
    expect(find.textContaining('米'), findsWidgets);
    expect(find.textContaining('信譽'), findsWidgets);
    expect(find.textContaining('幫助'), findsWidgets);
    expect(find.textContaining('預計'), findsWidgets);
    expect(find.textContaining('匹配'), findsWidgets);
    expect(find.textContaining('孫悅'), findsNothing);
    expect(find.textContaining('鄭濤'), findsNothing);
  });

  testWidgets('點擊模擬接單後 help_request 進入 connected，且重複接單不會切換 active volunteer', (
    tester,
  ) async {
    await _prepareSignedInMatchingEnvironment();
    final container = await _pumpMatchingScreen(tester);

    await _tapVisible(tester, '模擬接單');
    await tester.pump(const Duration(milliseconds: 250));

    final matchingState = container.read(demoMatchingFlowProvider);
    final helpState = container.read(demoHelpRequestFlowProvider);
    expect(matchingState.phase, DemoMatchingUiPhase.accepted);
    expect(matchingState.activeVolunteerId, isNotNull);
    expect(helpState.status, HelpRequestStatus.connected);
    expect(find.text('志願者已接單'), findsWidgets);
    expect(find.text('進入通話'), findsOneWidget);

    final activeVolunteerId = matchingState.activeVolunteerId;
    await container
        .read(demoMatchingFlowProvider.notifier)
        .acceptCurrentCandidate();
    expect(
      container.read(demoMatchingFlowProvider).activeVolunteerId,
      activeVolunteerId,
    );
  });

  testWidgets('點擊取消求助後 help_request 進入 cancelled', (tester) async {
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
    expect(find.text('用戶已取消'), findsWidgets);
    expect(find.text('取消求助'), findsOneWidget);
  });

  testWidgets('點擊模擬無人接單後 help_request 進入 expired', (tester) async {
    await _prepareSignedInMatchingEnvironment();
    final container = await _pumpMatchingScreen(tester);

    await _tapVisible(tester, '模擬無人接單');
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      container.read(demoMatchingFlowProvider).phase,
      DemoMatchingUiPhase.expired,
    );
    expect(
      container.read(demoHelpRequestFlowProvider).status,
      HelpRequestStatus.expired,
    );
    expect(find.text('無人接單，稍後再試'), findsWidgets);
  });

  testWidgets('點擊拒接或超時後嘗試下一位候選人', (tester) async {
    await _prepareSignedInMatchingEnvironment();
    final container = await _pumpMatchingScreen(tester);
    final firstVolunteerId = container
        .read(demoMatchingFlowProvider)
        .currentCandidate
        ?.volunteer
        .id;

    await _tapVisible(tester, '模擬拒接 / 超時');
    await tester.pump(const Duration(milliseconds: 250));

    final state = container.read(demoMatchingFlowProvider);
    expect(state.currentCandidateIndex, 1);
    expect(state.currentCandidate?.volunteer.id, isNot(firstVolunteerId));
    expect(state.statusMessage, contains('第 2 位'));
    expect(find.text('上一位暫時無法接聽，正在嘗試下一位'), findsOneWidget);
  });

  testWidgets('Top 5 數據缺失時顯示降級文案', (tester) async {
    await _prepareSignedInMatchingEnvironment();
    await _pumpMatchingScreen(
      tester,
      overrides: [
        demoMatchingEngineProvider.overrideWithValue(
          _EmptyMatchingEngineService(),
        ),
      ],
    );

    expect(find.textContaining('當前沒有可用志願者'), findsWidgets);
    expect(find.textContaining('回到 AI 助手繼續描述問題'), findsWidgets);
  });

  testWidgets('匹配頁關鍵按鈕和候選卡片具備 Semantics', (tester) async {
    await _prepareSignedInMatchingEnvironment();
    final semantics = tester.ensureSemantics();
    try {
      await _pumpMatchingScreen(tester);

      expect(find.bySemanticsLabel(RegExp('候選志願者第 1 名')), findsOneWidget);
      await tester.ensureVisible(find.text('取消匹配'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.bySemanticsLabel(RegExp('取消求助')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('模擬接單')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('模擬拒接或超時')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('重新匹配')), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('200% 字體縮放下匹配頁 smoke test 不出現主要 overflow', (tester) async {
    await _prepareSignedInMatchingEnvironment();
    await _pumpMatchingScreen(tester, textScale: 2.0);

    expect(find.text('Top 5 志願者候選'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('默認不接真實定位、推送、Supabase 或 WebRTC', (tester) async {
    await _prepareSignedInMatchingEnvironment();
    await _pumpMatchingScreen(tester);

    expect(AppConfig.demoMode, isTrue);
    expect(FeatureFlags.enableLocationService, isFalse);
    expect(FeatureFlags.enablePushNotification, isFalse);
    expect(FeatureFlags.enableDatabaseSync, isFalse);
    expect(FeatureFlags.enableWebRTC, isFalse);
    expect(find.textContaining('不依賴真實定位'), findsWidgets);
    expect(find.textContaining('無真實推送'), findsOneWidget);
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
    return DemoMatchResponse.empty('測試：demo_volunteers.json 暫時不可用');
  }
}
