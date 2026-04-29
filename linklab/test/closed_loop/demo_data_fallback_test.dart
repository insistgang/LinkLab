@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linklab/models/demo_ai_intent.dart';
import 'package:linklab/models/help_request_status.dart';
import 'package:linklab/providers/demo_help_request_flow_provider.dart';
import 'package:linklab/services/demo/demo_ai_service.dart';
import 'package:linklab/services/demo/demo_data_loader.dart';

import 'test_harness.dart';

void main() {
  test('demo_data 资源路径存在并可被 loader 读取', () async {
    await prepareEmptyDemoEnvironment();

    expect(
      await rootBundle.loadString('assets/demo_data/ai_responses.json'),
      contains('ocrScenarios'),
    );
    expect(
      await rootBundle.loadString('assets/demo_data/volunteers.json'),
      contains('demoVolunteers'),
    );
    expect(
      await rootBundle.loadString('assets/demo_data/help_scenarios.json'),
      contains('demoFlow'),
    );

    expect(DemoDataLoader.getOCRScenarios(), isNotEmpty);
    expect(DemoDataLoader.getSceneDescriptions(), isNotEmpty);
    expect(DemoDataLoader.getDemoVolunteers(), isNotEmpty);
  });

  test('无真实 API key 时 AI demo fallback 覆盖 OCR、场景、转人工、SOS', () async {
    await prepareEmptyDemoEnvironment();
    final ai = DemoAIService();

    final ocr = await ai.process('帮我读药品盒说明书');
    expect(ocr.success, isTrue);
    expect(ocr.text, contains('阿莫西林'));

    final scene = await ai.process('我面前是什么，描述周围环境');
    expect(scene.success, isTrue);
    expect(scene.data?['scenario'], isNotNull);

    final human = await ai.process('我在医院找不到科室，需要人帮忙');
    expect(human.success, isTrue);
    expect(human.data?['intent'], 'need_human');
    expect(human.data?['nextStatus'], 'matching');

    final sos = await ai.process('救命，我摔倒了，有点晕倒');
    expect(sos.success, isTrue);
    expect(sos.data?['action'], 'sos_triggered');
  });

  test('F1 AI Agent 本地 demo 支持 AGENTS.md 要求的 9 类意图', () async {
    await prepareEmptyDemoEnvironment();
    final ai = DemoAIService();

    final cases = <({String prompt, DemoAiIntent intent, String containsText})>[
      (prompt: '帮我读药品盒说明书', intent: DemoAiIntent.ocrText, containsText: '阿莫西林'),
      (
        prompt: '我面前是什么，前面有什么画面',
        intent: DemoAiIntent.sceneDescription,
        containsText: '前方',
      ),
      (
        prompt: '这件衣服是什么颜色',
        intent: DemoAiIntent.colorRecognition,
        containsText: '深蓝',
      ),
      (
        prompt: '这张人民币钞票是多少钱，帮我看面额',
        intent: DemoAiIntent.moneyRecognition,
        containsText: '20 元',
      ),
      (
        prompt: '外卖电话我听不清，帮我说一句并转译',
        intent: DemoAiIntent.translation,
        containsText: '取件码',
      ),
      (
        prompt: '周围环境安全吗，有没有障碍物',
        intent: DemoAiIntent.environmentDescription,
        containsText: '障碍物',
      ),
      (
        prompt: '去挂号科室和电梯怎么走',
        intent: DemoAiIntent.navigation,
        containsText: '转人工',
      ),
      (
        prompt: '这个药一次几片，用法和禁忌是什么',
        intent: DemoAiIntent.medicationCheck,
        containsText: '不做医疗诊断',
      ),
      (
        prompt: '救命，我胸口痛，刚刚摔倒了',
        intent: DemoAiIntent.emergency,
        containsText: '紧急模式',
      ),
    ];

    for (final entry in cases) {
      final result = await ai.process(entry.prompt);
      expect(result.success, isTrue, reason: entry.prompt);
      expect(result.data?['demoIntent'], entry.intent.wireName);
      expect(result.text, contains(entry.containsText));
    }
  });

  test('导航和高风险请求会标记转人工 matching，不直接冒充已解决', () async {
    await prepareEmptyDemoEnvironment();
    final ai = DemoAIService();

    final navigation = await ai.process('我在医院找不到科室，需要人帮忙');
    expect(navigation.success, isTrue);
    expect(navigation.data?['intent'], DemoAiIntent.needHuman.wireName);
    expect(navigation.data?['nextStatus'], HelpRequestStatus.matching.wireName);
    expect(navigation.text, contains('志愿者'));
  });

  test('药品三轮上下文可从说明书读取进入转人工确认', () async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);
    final ai = DemoAIService();

    final first = await ai.process('帮我读药品盒');
    expect(first.success, isTrue);
    expect(first.data?['demoIntent'], DemoAiIntent.ocrText.wireName);

    final history = <Map<String, String>>[
      {'role': 'user', 'content': '帮我读药品盒'},
      {'role': 'assistant', 'content': first.text},
    ];

    final second = await ai.process('一次吃几片？', history: history);
    expect(second.success, isTrue);
    expect(second.data?['demoIntent'], DemoAiIntent.medicationCheck.wireName);
    expect(second.text, contains('医生或药师'));

    history.addAll([
      {'role': 'user', 'content': '一次吃几片？'},
      {'role': 'assistant', 'content': second.text},
    ]);

    final third = await ai.process('能帮我找人确认吗？', history: history);
    expect(third.success, isTrue);
    expect(third.data?['intent'], DemoAiIntent.needHuman.wireName);
    expect(third.data?['contextIntent'], DemoAiIntent.medicationCheck.wireName);
    expect(third.data?['nextStatus'], HelpRequestStatus.matching.wireName);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(demoHelpRequestFlowProvider.notifier);
    await controller.startAiProcessing(intent: '能帮我找人确认吗？');
    await controller.enterMatching(intent: '连接真人志愿者：药品说明需要人工确认');
    expect(
      container.read(demoHelpRequestFlowProvider).status,
      HelpRequestStatus.matching,
    );
  });
}
