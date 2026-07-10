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

    final ocr = await ai.process('查看示例药品说明书');
    expect(ocr.success, isTrue);
    expect(ocr.text, contains('示例识别结果'));
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

  test('没有图片时普通读说明书请求不会猜测具体药名和剂量', () async {
    await prepareEmptyDemoEnvironment();
    final facade = AgentServiceFacade();

    final response = await facade.processInput(text: '帮我读一下这个说明书');

    expect(response.canResolveByAi, isTrue);
    expect(response.answerText, anyOf(contains('拍照'), contains('相册')));
    expect(response.answerText, isNot(contains('阿莫西林')));
    expect(response.answerText, isNot(contains('成人每次服用2粒')));
  });

  test('小问答会返回与文字、场景和颜色问题对应的内容', () async {
    await prepareEmptyDemoEnvironment();
    final facade = AgentServiceFacade();

    final cases =
        <({String prompt, List<String> expectedAll, String? unexpected})>[
          (
            prompt: '查看示例药品说明书',
            expectedAll: ['示例识别结果', '阿莫西林'],
            unexpected: null,
          ),
          (
            prompt: '查看示例菜单内容',
            expectedAll: ['示例识别结果', '红烧肉'],
            unexpected: '阿莫西林',
          ),
          (
            prompt: '查看示例公交站牌',
            expectedAll: ['示例识别结果', '101路'],
            unexpected: '阿莫西林',
          ),
          (prompt: '我面前现在是什么样子', expectedAll: ['城市街道'], unexpected: '不能稳定判断'),
          (prompt: '这个物体的主色调是什么', expectedAll: ['深蓝色'], unexpected: '不能稳定判断'),
          (prompt: '帮我分辨这两个颜色', expectedAll: ['深蓝色', '暖橙色'], unexpected: null),
        ];

    for (final entry in cases) {
      final response = await facade.processInput(text: entry.prompt);
      expect(response.canResolveByAi, isTrue, reason: entry.prompt);
      for (final expected in entry.expectedAll) {
        expect(response.answerText, contains(expected), reason: entry.prompt);
      }
      if (entry.unexpected case final unexpected?) {
        expect(
          response.answerText,
          isNot(contains(unexpected)),
          reason: entry.prompt,
        );
      }
    }
  });

  test('F1 AI Agent 本地 demo 支持 AGENTS.md 要求的 9 类意图', () async {
    await prepareEmptyDemoEnvironment();
    final ai = DemoAIService();

    final cases = <({String prompt, DemoAiIntent intent, String containsText})>[
      (
        prompt: '查看示例药品说明书',
        intent: DemoAiIntent.ocrText,
        containsText: '示例识别结果',
      ),
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

  test('普通问候不会触发志愿者匹配', () async {
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

  test('简单药品问答可直接展示，具体用药仍保留安全边界', () async {
    await prepareEmptyDemoEnvironment();

    final ai = DemoAIService();
    final medicine = await ai.process('布洛芬是什么药？');
    expect(medicine.success, isTrue);
    expect(medicine.text, contains('解热镇痛药'));
    expect(medicine.data?['simpleMedicineQa'], isTrue);
    expect(medicine.data?['nextStatus'], isNull);

    final facade = AgentServiceFacade();
    final response = await facade.processInput(text: '药盒有效期怎么看？');
    expect(response.nextAction, 'answer');
    expect(response.canResolveByAi, isTrue);
    expect(response.safetyFlags, contains('not_medical_diagnosis'));
    expect(response.answerText, contains('有效期'));
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

  test('Agent facade 在 DemoMode 保持本地确定响应，不被真实 API 配置污染', () async {
    await prepareEmptyDemoEnvironment();
    final facade = AgentServiceFacade();
    final stopwatch = Stopwatch()..start();

    final sos = await facade.processInput(text: '救命，我胸口痛，刚刚摔倒了');
    expect(sos.urgency, 'emergency');
    expect(sos.nextAction, 'trigger_sos');
    expect(sos.answerText, contains('紧急模式'));

    final human = await facade.processInput(text: '这个问题太复杂了，我需要真人志愿者帮助');
    expect(human.nextAction, 'match_volunteer');
    expect(human.canResolveByAi, isFalse);
    expect(human.handoffReason, isNotNull);

    stopwatch.stop();
    expect(
      stopwatch.elapsed,
      lessThan(const Duration(seconds: 2)),
      reason: 'DemoMode 首次响应不能被真实大模型请求拖慢',
    );
  });

  test('真实 AI 开启时 SOS 和转人工仍由本地安全规则优先分流', () async {
    await prepareEmptyDemoEnvironment();
    AppConfig.configureFromEnvironment(const {
      'LINKABLE_ENABLE_REAL_AI': 'true',
    }, enablePresenterSessionOnFallback: false);

    final facade = AgentServiceFacade();
    final stopwatch = Stopwatch()..start();

    final sos = await facade.processInput(text: '救命，我胸口痛，刚刚摔倒了');
    expect(sos.urgency, 'emergency');
    expect(sos.nextAction, 'trigger_sos');
    expect(sos.canResolveByAi, isFalse);
    expect(sos.answerText, contains('紧急模式'));

    final human = await facade.processInput(text: '这个问题太复杂了，我需要真人志愿者帮助');
    expect(human.nextAction, 'match_volunteer');
    expect(human.canResolveByAi, isFalse);
    expect(human.handoffReason, isNotNull);

    stopwatch.stop();
    expect(
      stopwatch.elapsed,
      lessThan(const Duration(seconds: 2)),
      reason: 'SOS 和转人工不能等待真实大模型返回',
    );
  });
}
