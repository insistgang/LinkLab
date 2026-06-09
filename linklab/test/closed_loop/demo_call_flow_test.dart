@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linklab/config/app_config.dart';
import 'package:linklab/models/demo_match_request.dart';
import 'package:linklab/models/help_request_status.dart';
import 'package:linklab/providers/demo_call_flow_provider.dart';
import 'package:linklab/providers/demo_help_request_flow_provider.dart';
import 'package:linklab/providers/demo_matching_flow_provider.dart';

import 'test_harness.dart';

void main() {
  const hospitalRequest = DemoMatchRequest(
    requestId: 'call_flow_hospital',
    queryText: '我在醫院找不到科室，需要真人幫忙',
    requestType: 'hospital_navigation',
    urgencyLevel: 'medium',
  );

  Future<ProviderContainer> createConnectedMatchingContainer() async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

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

    return container;
  }

  test('Demo Call 從 F9 active volunteer 讀取已接單志願者', () async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);
    final container = await createConnectedMatchingContainer();
    final matchingState = container.read(demoMatchingFlowProvider);
    final activeName = matchingState.activeVolunteerName;

    await container
        .read(demoCallFlowProvider.notifier)
        .start(autoConnect: false);

    final state = container.read(demoCallFlowProvider);
    expect(state.phase, DemoCallUiPhase.connecting);
    expect(state.volunteer.nickname, activeName);
    expect(state.volunteer.reason, isNotEmpty);
    expect(
      container.read(demoHelpRequestFlowProvider).status,
      HelpRequestStatus.connected,
    );

    container.read(demoCallFlowProvider.notifier).connectNow();
    expect(
      container.read(demoCallFlowProvider).phase,
      DemoCallUiPhase.connected,
    );
  });

  test('active volunteer 缺失時使用林同學 fallback', () async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(demoCallFlowProvider.notifier)
        .start(autoConnect: false);

    final state = container.read(demoCallFlowProvider);
    expect(state.volunteer.nickname, '林同學');
    expect(state.volunteer.isFallback, isTrue);
    expect(state.phase, DemoCallUiPhase.connecting);
  });

  test('connecting 可以進入 connected，靜音和免提狀態可切換', () async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);
    final container = await createConnectedMatchingContainer();

    await container
        .read(demoCallFlowProvider.notifier)
        .start(autoConnect: false);
    container.read(demoCallFlowProvider.notifier).connectNow();
    container.read(demoCallFlowProvider.notifier).toggleMute();
    container.read(demoCallFlowProvider.notifier).toggleSpeaker();

    final state = container.read(demoCallFlowProvider);
    expect(state.phase, DemoCallUiPhase.connected);
    expect(state.isMuted, isTrue);
    expect(state.isSpeakerOn, isFalse);
  });

  test('正常結束通話後 help_request 進入 completed，重複結束不寫壞狀態', () async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);
    final container = await createConnectedMatchingContainer();

    await container
        .read(demoCallFlowProvider.notifier)
        .start(autoConnect: false);
    container.read(demoCallFlowProvider.notifier).connectNow();
    await container.read(demoCallFlowProvider.notifier).completeCall();
    await container.read(demoCallFlowProvider.notifier).completeCall();

    expect(container.read(demoCallFlowProvider).phase, DemoCallUiPhase.ended);
    expect(
      container.read(demoHelpRequestFlowProvider).status,
      HelpRequestStatus.completed,
    );
  });

  test('模擬掉線後恢復，help_request 保持 connected', () async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);
    final container = await createConnectedMatchingContainer();

    await container
        .read(demoCallFlowProvider.notifier)
        .start(autoConnect: false);
    container.read(demoCallFlowProvider.notifier).connectNow();
    container.read(demoCallFlowProvider.notifier).simulateDisconnect();
    expect(
      container.read(demoCallFlowProvider).phase,
      DemoCallUiPhase.reconnecting,
    );

    container.read(demoCallFlowProvider.notifier).restoreConnection();
    expect(
      container.read(demoCallFlowProvider).phase,
      DemoCallUiPhase.connected,
    );
    expect(
      container.read(demoHelpRequestFlowProvider).status,
      HelpRequestStatus.connected,
    );
  });

  test('模擬重連失敗後 help_request 回到 matching', () async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);
    final container = await createConnectedMatchingContainer();

    await container
        .read(demoCallFlowProvider.notifier)
        .start(autoConnect: false);
    container.read(demoCallFlowProvider.notifier).connectNow();
    container.read(demoCallFlowProvider.notifier).simulateDisconnect();
    await container.read(demoCallFlowProvider.notifier).failReconnect();

    expect(container.read(demoCallFlowProvider).phase, DemoCallUiPhase.failed);
    expect(
      container.read(demoHelpRequestFlowProvider).status,
      HelpRequestStatus.matching,
    );
  });

  test('reconnecting 時結束通話不崩潰，並完成 help_request', () async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);
    final container = await createConnectedMatchingContainer();

    await container
        .read(demoCallFlowProvider.notifier)
        .start(autoConnect: false);
    container.read(demoCallFlowProvider.notifier).connectNow();
    container.read(demoCallFlowProvider.notifier).simulateDisconnect();
    await container.read(demoCallFlowProvider.notifier).completeCall();

    expect(container.read(demoCallFlowProvider).phase, DemoCallUiPhase.ended);
    expect(
      container.read(demoHelpRequestFlowProvider).status,
      HelpRequestStatus.completed,
    );
  });

  test('競賽版默認不初始化真實 WebRTC 或外部服務', () async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);

    expect(AppConfig.demoMode, isTrue);
    expect(FeatureFlags.enableWebRTC, isFalse);
    expect(FeatureFlags.enableDatabaseSync, isFalse);
    expect(FeatureFlags.enablePushNotification, isFalse);
  });
}
