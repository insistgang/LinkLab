@Tags(['demo', 'closed-loop'])
library;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linklab/config/app_config.dart';
import 'package:linklab/models/demo_ai_intent.dart';
import 'package:linklab/models/help_request_status.dart';
import 'package:linklab/providers/demo_help_request_flow_provider.dart';
import 'package:linklab/services/demo/demo_ai_service.dart';
import 'package:linklab/services/demo/demo_data_loader.dart';
import 'package:linklab/services/facades/agent_service_facade.dart';

import 'test_harness.dart';

void main() {
  test('demo_data 資源路徑存在並可被 loader 讀取', () async {
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

  test('無真實 API key 時 AI demo fallback 覆蓋 OCR、場景、轉人工、SOS', () async {
    await prepareEmptyDemoEnvironment();
    final ai = DemoAIService();

    final ocr = await ai.process('幫我讀藥品盒說明書');
    expect(ocr.success, isTrue);
    expect(ocr.text, contains('阿莫西林'));

    final scene = await ai.process('我面前是什麼，描述周圍環境');
    expect(scene.success, isTrue);
    expect(scene.data?['scenario'], isNotNull);

    final human = await ai.process('我在醫院找不到科室，需要人幫忙');
    expect(human.success, isTrue);
    expect(human.data?['intent'], 'need_human');
    expect(human.data?['nextStatus'], 'matching');

    final sos = await ai.process('救命，我摔倒了，有點暈倒');
    expect(sos.success, isTrue);
    expect(sos.data?['action'], 'sos_triggered');
  });

  test('F1 AI Agent 本地 demo 支持 AGENTS.md 要求的 9 類意圖', () async {
    await prepareEmptyDemoEnvironment();
    final ai = DemoAIService();

    final cases = <({String prompt, DemoAiIntent intent, String containsText})>[
      (prompt: '幫我讀藥品盒說明書', intent: DemoAiIntent.ocrText, containsText: '阿莫西林'),
      (
        prompt: '我面前是什麼，前面有什麼畫面',
        intent: DemoAiIntent.sceneDescription,
        containsText: '前方',
      ),
      (
        prompt: '這件衣服是什麼顏色',
        intent: DemoAiIntent.colorRecognition,
        containsText: '深藍',
      ),
      (
        prompt: '這張人民幣鈔票是多少錢，幫我看面額',
        intent: DemoAiIntent.moneyRecognition,
        containsText: '20 元',
      ),
      (
        prompt: '外賣電話我聽不清，幫我說一句並轉譯',
        intent: DemoAiIntent.translation,
        containsText: '取件碼',
      ),
      (
        prompt: '周圍環境安全嗎，有沒有障礙物',
        intent: DemoAiIntent.environmentDescription,
        containsText: '障礙物',
      ),
      (
        prompt: '去掛號科室和電梯怎麼走',
        intent: DemoAiIntent.navigation,
        containsText: '轉人工',
      ),
      (
        prompt: '這個藥一次幾片，用法和禁忌是什麼',
        intent: DemoAiIntent.medicationCheck,
        containsText: '不做醫療診斷',
      ),
      (
        prompt: '救命，我胸口痛，剛剛摔倒了',
        intent: DemoAiIntent.emergency,
        containsText: '緊急模式',
      ),
    ];

    for (final entry in cases) {
      final result = await ai.process(entry.prompt);
      expect(result.success, isTrue, reason: entry.prompt);
      expect(result.data?['demoIntent'], entry.intent.wireName);
      expect(result.text, contains(entry.containsText));
    }
  });

  test('導航和高風險請求會標記轉人工 matching，不直接冒充已解決', () async {
    await prepareEmptyDemoEnvironment();
    final ai = DemoAIService();

    final navigation = await ai.process('我在醫院找不到科室，需要人幫忙');
    expect(navigation.success, isTrue);
    expect(navigation.data?['intent'], DemoAiIntent.needHuman.wireName);
    expect(navigation.data?['nextStatus'], HelpRequestStatus.matching.wireName);
    expect(navigation.text, contains('志願者'));
  });

  test('普通問候不會觸發志願者匹配', () async {
    await prepareEmptyDemoEnvironment();

    final ai = DemoAIService();
    final greeting = await ai.process('你好');
    expect(greeting.success, isTrue);
    expect(greeting.text, contains('AI 助手'));
    expect(greeting.data?['nextStatus'], isNull);
    expect(greeting.data?['requiresHumanFallback'], isNull);

    final facade = AgentServiceFacade();
    final response = await facade.processInput(text: '你好');
    expect(response.nextAction, 'answer');
    expect(response.canResolveByAi, isTrue);
    expect(response.handoffReason, isNull);
    expect(response.answerText, contains('AI 助手'));
  });

  test('簡單藥品問答可直接展示，具體用藥仍保留安全邊界', () async {
    await prepareEmptyDemoEnvironment();

    final ai = DemoAIService();
    final medicine = await ai.process('布洛芬是什麼藥？');
    expect(medicine.success, isTrue);
    expect(medicine.text, contains('解熱鎮痛藥'));
    expect(medicine.data?['simpleMedicineQa'], isTrue);
    expect(medicine.data?['nextStatus'], isNull);

    final facade = AgentServiceFacade();
    final response = await facade.processInput(text: '藥盒有效期怎麼看？');
    expect(response.nextAction, 'answer');
    expect(response.canResolveByAi, isTrue);
    expect(response.safetyFlags, contains('not_medical_diagnosis'));
    expect(response.answerText, contains('有效期'));
  });

  test('藥品三輪上下文可從說明書讀取進入轉人工確認', () async {
    await prepareSignedInDemoEnvironment(clearHelpHistory: true);
    final ai = DemoAIService();

    final first = await ai.process('幫我讀藥品盒');
    expect(first.success, isTrue);
    expect(first.data?['demoIntent'], DemoAiIntent.ocrText.wireName);

    final history = <Map<String, String>>[
      {'role': 'user', 'content': '幫我讀藥品盒'},
      {'role': 'assistant', 'content': first.text},
    ];

    final second = await ai.process('一次喫幾片？', history: history);
    expect(second.success, isTrue);
    expect(second.data?['demoIntent'], DemoAiIntent.medicationCheck.wireName);
    expect(second.text, contains('醫生或藥師'));

    history.addAll([
      {'role': 'user', 'content': '一次喫幾片？'},
      {'role': 'assistant', 'content': second.text},
    ]);

    final third = await ai.process('能幫我找人確認嗎？', history: history);
    expect(third.success, isTrue);
    expect(third.data?['intent'], DemoAiIntent.needHuman.wireName);
    expect(third.data?['contextIntent'], DemoAiIntent.medicationCheck.wireName);
    expect(third.data?['nextStatus'], HelpRequestStatus.matching.wireName);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(demoHelpRequestFlowProvider.notifier);
    await controller.startAiProcessing(intent: '能幫我找人確認嗎？');
    await controller.enterMatching(intent: '連接真人志願者：藥品說明需要人工確認');
    expect(
      container.read(demoHelpRequestFlowProvider).status,
      HelpRequestStatus.matching,
    );
  });

  test('Agent facade 在 DemoMode 保持本地確定響應，不被真實 API 配置污染', () async {
    await prepareEmptyDemoEnvironment();
    final facade = AgentServiceFacade();
    final stopwatch = Stopwatch()..start();

    final sos = await facade.processInput(text: '救命，我胸口痛，剛剛摔倒了');
    expect(sos.urgency, 'emergency');
    expect(sos.nextAction, 'trigger_sos');
    expect(sos.answerText, contains('緊急模式'));

    final human = await facade.processInput(text: '這個問題太複雜了，我需要真人志願者幫助');
    expect(human.nextAction, 'match_volunteer');
    expect(human.canResolveByAi, isFalse);
    expect(human.handoffReason, isNotNull);

    stopwatch.stop();
    expect(
      stopwatch.elapsed,
      lessThan(const Duration(seconds: 2)),
      reason: 'DemoMode 首次響應不能被真實大模型請求拖慢',
    );
  });

  test('真實 AI 開啓時 SOS 和轉人工仍由本地安全規則優先分流', () async {
    await prepareEmptyDemoEnvironment();
    AppConfig.configureFromEnvironment(const {
      'LINKABLE_ENABLE_REAL_AI': 'true',
    }, enablePresenterSessionOnFallback: false);

    final facade = AgentServiceFacade();
    final stopwatch = Stopwatch()..start();

    final sos = await facade.processInput(text: '救命，我胸口痛，剛剛摔倒了');
    expect(sos.urgency, 'emergency');
    expect(sos.nextAction, 'trigger_sos');
    expect(sos.canResolveByAi, isFalse);
    expect(sos.answerText, contains('緊急模式'));

    final human = await facade.processInput(text: '這個問題太複雜了，我需要真人志願者幫助');
    expect(human.nextAction, 'match_volunteer');
    expect(human.canResolveByAi, isFalse);
    expect(human.handoffReason, isNotNull);

    stopwatch.stop();
    expect(
      stopwatch.elapsed,
      lessThan(const Duration(seconds: 2)),
      reason: 'SOS 和轉人工不能等待真實大模型返回',
    );
  });
}
