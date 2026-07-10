@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linklab/models/help_request_status.dart';
import 'package:linklab/providers/demo_help_request_flow_provider.dart';
import 'package:linklab/services/demo/demo_ai_service.dart';

import 'test_harness.dart';

void main() {
  test('help_request_status 只有 AGENTS.md 允许的 8 个主状态', () {
    final wireNames = HelpRequestStatus.values
        .map((status) => status.wireName)
        .toList(growable: false);

    expect(wireNames, hasLength(8));
    expect(wireNames, [
      'created',
      'ai_processing',
      'ai_resolved',
      'matching',
      'connected',
      'expired',
      'cancelled',
      'completed',
    ]);
    expect(wireNames, isNot(contains('sos_triggered')));
    expect(wireNames, isNot(contains('sos_active')));
    expect(wireNames, isNot(contains('emergency')));
    expect(
      HelpRequestStatus.fromWireName('sos_triggered'),
      HelpRequestStatus.created,
    );
  });

  test('AGENTS.md help_request 状态机只允许 MVP 主状态转移', () {
    expect(
      HelpRequestStatus.created.canTransitionTo(HelpRequestStatus.aiProcessing),
      isTrue,
    );
    expect(
      HelpRequestStatus.aiProcessing.canTransitionTo(
        HelpRequestStatus.aiResolved,
      ),
      isTrue,
    );
    expect(
      HelpRequestStatus.aiProcessing.canTransitionTo(
        HelpRequestStatus.matching,
      ),
      isTrue,
    );
    expect(
      HelpRequestStatus.matching.canTransitionTo(HelpRequestStatus.connected),
      isTrue,
    );
    expect(
      HelpRequestStatus.matching.canTransitionTo(HelpRequestStatus.expired),
      isTrue,
    );
    expect(
      HelpRequestStatus.connected.canTransitionTo(HelpRequestStatus.completed),
      isTrue,
    );
    expect(
      HelpRequestStatus.connected.canTransitionTo(HelpRequestStatus.matching),
      isTrue,
    );

    expect(
      HelpRequestStatus.created.canTransitionTo(HelpRequestStatus.matching),
      isFalse,
    );
    expect(
      HelpRequestStatus.aiResolved.canTransitionTo(HelpRequestStatus.matching),
      isFalse,
    );
    expect(
      HelpRequestStatus.completed.canTransitionTo(HelpRequestStatus.matching),
      isFalse,
    );
  });

  test('AI 可处理路径：created -> ai_processing -> ai_resolved', () async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(demoHelpRequestFlowProvider.notifier);
    await controller.startAiProcessing(intent: '帮我读药品盒');
    expect(
      container.read(demoHelpRequestFlowProvider).status,
      HelpRequestStatus.aiProcessing,
    );

    final result = await DemoAIService().process('帮我读药品盒');
    expect(result.success, isTrue);
    expect(result.text, contains('阿莫西林'));

    await controller.resolveByAI(summary: result.text);
    final state = container.read(demoHelpRequestFlowProvider);
    expect(state.status, HelpRequestStatus.aiResolved);

    final history = readLocalHelpHistoryModels();
    expect(history.first.status, HelpRequestStatus.aiResolved.wireName);
  });

  test(
    'AI 转人工路径：ai_processing -> matching -> connected -> completed',
    () async {
      await prepareSignedInDemoEnvironment(clearHelpHistory: true);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(demoHelpRequestFlowProvider.notifier);
      await controller.startAiProcessing(intent: '我在医院找不到科室，需要人帮忙');

      final result = await DemoAIService().process('我在医院找不到科室，需要人帮忙');
      expect(result.success, isTrue);
      expect(result.data?['intent'], 'need_human');

      await controller.enterMatching(intent: '我在医院找不到科室，需要人帮忙');
      expect(
        container.read(demoHelpRequestFlowProvider).status,
        HelpRequestStatus.matching,
      );

      await controller.markConnected(
        volunteerId: 'demo_001',
        volunteerName: '张小明',
        volunteerSkills: const ['出行导航'],
      );
      expect(
        container.read(demoHelpRequestFlowProvider).status,
        HelpRequestStatus.connected,
      );

      await controller.markCompleted(durationSeconds: 32, seekerRating: 5);
      expect(
        container.read(demoHelpRequestFlowProvider).status,
        HelpRequestStatus.completed,
      );
    },
  );

  test('匹配取消与过期路径：matching -> cancelled / expired', () async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(demoHelpRequestFlowProvider.notifier);
    await controller.enterMatching(intent: '需要人帮忙');
    await controller.markCancelled(reason: '用户取消匹配');
    expect(
      container.read(demoHelpRequestFlowProvider).status,
      HelpRequestStatus.cancelled,
    );

    controller.reset();
    await controller.enterMatching(intent: '需要人帮忙');
    await controller.markExpired();
    expect(
      container.read(demoHelpRequestFlowProvider).status,
      HelpRequestStatus.expired,
    );
  });

  test('通话掉线 10 秒未恢复可从 connected 回到 matching', () async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(demoHelpRequestFlowProvider.notifier);
    await controller.enterMatching(intent: '需要语音协助');
    await controller.markConnected(
      volunteerId: 'demo_001',
      volunteerName: '张小明',
    );

    await controller.returnToMatchingAfterDisconnect();
    expect(
      container.read(demoHelpRequestFlowProvider).status,
      HelpRequestStatus.matching,
    );
  });

  test('F13 SOS 只使用内部流程标记，不污染 help_request 主状态机', () async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(demoHelpRequestFlowProvider.notifier);
    await controller.startSOSUndoWindow(intent: '救命，我摔倒了');

    final state = container.read(demoHelpRequestFlowProvider);
    expect(state.status, HelpRequestStatus.created);
    expect(state.type, 'sos');
    expect(state.urgency, 'emergency');
    expect(state.message, contains('SOS'));

    final wireNames = HelpRequestStatus.values.map((status) => status.wireName);
    expect(wireNames, isNot(contains('sos_triggered')));
    expect(wireNames, isNot(contains('sos_active')));
  });
}
