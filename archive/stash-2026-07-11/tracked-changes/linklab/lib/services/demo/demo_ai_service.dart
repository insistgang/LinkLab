import 'dart:math';

import '../../config/app_config.dart';
import '../../core/utils/logger.dart';
import '../../models/agent_input_model.dart';
import '../../models/agent_response_model.dart';
import '../../models/ai_result_model.dart';
import '../../models/demo_ai_intent.dart';
import 'demo_data_loader.dart';

/// AI服务类型
enum AIServiceType {
  ocr, // 文字识别
  sceneDescription, // 场景描述
  colorRecognition, // 颜色识别
  chat, // 对话
  intentDetection, // 意图识别
  emergency, // 紧急检测
}

class _DemoIntentResolution {
  const _DemoIntentResolution(this.intent, {this.contextIntent, this.reason});

  final DemoAiIntent intent;
  final DemoAiIntent? contextIntent;
  final String? reason;
}

/// 演示版AI服务
/// 用于替代真实的AI API调用
class DemoAIService {
  static final DemoAIService _instance = DemoAIService._internal();
  factory DemoAIService() => _instance;
  DemoAIService._internal();

  final _random = Random();

  bool get _demoFallbackEnabled =>
      AppConfig.shouldUseDemoFallback(feature: 'DemoAIService');

  AIResult get _demoModeDisabledResult =>
      AIResult.error('DemoAIService 当前未启用 Demo fallback');

  /// 模拟处理延迟
  Future<void> _simulateDelay({int minMs = 250, int maxMs = 800}) async {
    final safeMax = maxMs <= minMs ? minMs + 1 : maxMs;
    final delay = minMs + _random.nextInt(safeMax - minMs);
    await Future.delayed(Duration(milliseconds: delay));
  }

  /// OCR文字识别
  Future<AIResult> recognizeText(String imagePath) async {
    if (!_demoFallbackEnabled) return _demoModeDisabledResult;
    await _simulateDelay();

    final scenarios = DemoDataLoader.getOCRScenarios();
    if (scenarios.isEmpty) {
      AppLogger.warning('OCR demo 数据为空，使用内置降级文案');
      return _fixedResult(
        DemoAiIntent.ocrText,
        '我可以读出文字内容。当前资源未加载，演示降级为：这是药品盒/通知单读取结果，请复核关键信息，也可以转人工确认。',
        extra: {'fallback': true},
      );
    }

    final scenario = scenarios.firstWhere(
      (item) => '${item['scenario']}${item['imageDescription']}'.contains('药'),
      orElse: () => scenarios.first,
    );
    final summary =
        scenario['summary'] as String? ?? '我识别到一段文字，但内容不完整。请复核图片，也可以转人工确认。';

    return _fixedResult(
      DemoAiIntent.ocrText,
      '$summary 请复核药名、剂量和有效期；不确定时可以转人工确认。',
      extra: {
        'recognizedText': scenario['recognizedText'],
        'scenario': scenario['scenario'],
        'confidence': 0.95,
      },
    );
  }

  /// 场景描述
  Future<AIResult> describeScene(String imagePath) async {
    if (!_demoFallbackEnabled) return _demoModeDisabledResult;
    await _simulateDelay(minMs: 350, maxMs: 900);

    final descriptions = DemoDataLoader.getSceneDescriptions();
    if (descriptions.isEmpty) {
      AppLogger.warning('场景描述 demo 数据为空，使用内置降级文案');
      return _fixedResult(
        DemoAiIntent.sceneDescription,
        '我看到前方环境较开阔，右侧像是柜台或门口，地面基本平整。请慢速前进，必要时转人工陪同。',
        extra: {'fallback': true},
      );
    }

    final description = descriptions.firstWhere(
      (item) => '${item['scenario']}${item['description']}'.contains('街道'),
      orElse: () => descriptions.first,
    );
    final descriptionText =
        description['description'] as String? ??
        '我看到前方有通行空间，但画面信息不完整。请慢速前进，也可以转人工确认。';

    return _fixedResult(
      DemoAiIntent.sceneDescription,
      '$descriptionText 请慢速前进，遇到台阶、门口或柜台时建议停下复核。',
      extra: {'scenario': description['scenario'], 'confidence': 0.92},
    );
  }

  /// 颜色识别
  Future<AIResult> recognizeColor(String imagePath) async {
    if (!_demoFallbackEnabled) return _demoModeDisabledResult;
    await _simulateDelay(minMs: 250, maxMs: 650);

    final colors = DemoDataLoader.getColorRecognitions();
    if (colors.isEmpty) {
      AppLogger.warning('颜色识别 demo 数据为空，使用内置降级文案');
      return _fixedResult(
        DemoAiIntent.colorRecognition,
        '我识别到主体颜色偏深蓝，适合用于衣物、药盒或指示牌颜色确认。光线会影响判断，请复核。',
        extra: {'fallback': true},
      );
    }

    final color = colors.firstWhere(
      (item) => '${item['description']}${item['dominantColor']}'.contains('蓝'),
      orElse: () => colors.first,
    );
    final colorText = color['description'] as String? ?? '主体颜色偏深色。光线会影响判断，请复核。';

    return _fixedResult(
      DemoAiIntent.colorRecognition,
      '$colorText 如果用于服药、出行指示或付款，请再请身边人或志愿者复核。',
      extra: {
        'dominantColor': color['dominantColor'],
        'colorHex': color['colorHex'],
      },
    );
  }

  /// 对话回覆
  Future<AIResult> chat(
    String userMessage, {
    List<Map<String, String>>? history,
  }) async {
    if (!_demoFallbackEnabled) return _demoModeDisabledResult;
    await _simulateDelay(minMs: 250, maxMs: 700);

    final intent = _detectDemoIntent(userMessage, history: history);
    if (intent.intent != DemoAiIntent.fallback) {
      return _buildIntentResult(userMessage, intent, history: history);
    }

    final legacyIntent = DemoDataLoader.detectIntent(userMessage);
    final response = DemoDataLoader.getChatResponseByIntent(legacyIntent);

    return _fixedResult(
      DemoAiIntent.fallback,
      '$response 如果你愿意，我可以帮你转接真人志愿者继续处理。',
      requiresHumanFallback: true,
      extra: {'legacyIntent': legacyIntent, 'confidence': 0.72},
    );
  }

  /// 意图识别
  Future<AIResult> detectIntent(
    String input, {
    List<Map<String, String>>? history,
  }) async {
    if (!_demoFallbackEnabled) return _demoModeDisabledResult;
    await _simulateDelay(minMs: 80, maxMs: 180);

    final resolution = _detectDemoIntent(input, history: history);

    return AIResult.success(
      '意图识别完成',
      data: {
        'intent': resolution.intent.wireName,
        'demoIntent': resolution.intent.wireName,
        'contextIntent': resolution.contextIntent?.wireName,
        'confidence': 0.90,
      },
    );
  }

  /// 紧急检测
  Future<AIResult> detectEmergency(String input) async {
    if (!_demoFallbackEnabled) return _demoModeDisabledResult;
    await _simulateDelay(minMs: 80, maxMs: 180);

    final normalizedInput = _normalize(input);
    final isEmergency =
        DemoDataLoader.detectEmergency(input) ||
        _matchesAny(normalizedInput, _emergencyKeywords);

    if (isEmergency) {
      return _emergencyResult();
    }

    return AIResult.success(
      '未检测到紧急情况',
      data: {'isEmergency': false, 'urgencyLevel': 'normal'},
    );
  }

  /// 综合AI处理（根据输入自动选择服务）
  Future<AIResult> process(
    String input, {
    String? imagePath,
    List<Map<String, String>>? history,
  }) async {
    if (!_demoFallbackEnabled) return _demoModeDisabledResult;

    final resolution = _detectDemoIntent(
      input,
      imagePath: imagePath,
      history: history,
    );
    AppLogger.info('Demo AI intent recognized: ${resolution.intent.wireName}');
    return _buildIntentResult(
      input,
      resolution,
      imagePath: imagePath,
      history: history,
    );
  }

  DemoAiIntent resolveIntent(
    String input, {
    String? imagePath,
    List<Map<String, String>>? history,
  }) {
    return _detectDemoIntent(
      input,
      imagePath: imagePath,
      history: history,
    ).intent;
  }

  _DemoIntentResolution _detectDemoIntent(
    String input, {
    String? imagePath,
    List<Map<String, String>>? history,
  }) {
    final normalizedInput = _normalize(input);
    final hasMedicationContext = _historyMentionsMedication(history);

    if (_matchesAny(normalizedInput, _emergencyKeywords) ||
        DemoDataLoader.detectEmergency(input)) {
      return const _DemoIntentResolution(DemoAiIntent.emergency);
    }

    if (_matchesAny(normalizedInput, _humanKeywords)) {
      return _DemoIntentResolution(
        DemoAiIntent.needHuman,
        contextIntent: hasMedicationContext
            ? DemoAiIntent.medicationCheck
            : DemoAiIntent.navigation,
        reason: 'explicit_human_request',
      );
    }

    if (_matchesAny(normalizedInput, _greetingKeywords)) {
      return const _DemoIntentResolution(
        DemoAiIntent.fallback,
        reason: 'small_talk_greeting',
      );
    }

    if (imagePath != null) {
      if (_matchesAny(normalizedInput, _colorKeywords)) {
        return const _DemoIntentResolution(DemoAiIntent.colorRecognition);
      }
      if (_matchesAny(normalizedInput, _ocrKeywords)) {
        return const _DemoIntentResolution(DemoAiIntent.ocrText);
      }
      if (_matchesAny(normalizedInput, _environmentKeywords)) {
        return const _DemoIntentResolution(DemoAiIntent.environmentDescription);
      }
      return const _DemoIntentResolution(DemoAiIntent.sceneDescription);
    }

    if (_matchesAny(normalizedInput, _medicationKeywords) ||
        (hasMedicationContext &&
            _matchesAny(normalizedInput, _dosageFollowUpKeywords))) {
      return const _DemoIntentResolution(DemoAiIntent.medicationCheck);
    }

    if (_matchesAny(normalizedInput, _colorKeywords)) {
      return const _DemoIntentResolution(DemoAiIntent.colorRecognition);
    }

    if (_matchesAny(normalizedInput, _moneyKeywords)) {
      return const _DemoIntentResolution(DemoAiIntent.moneyRecognition);
    }

    if (_matchesAny(normalizedInput, _simpleMedicineQaKeywords)) {
      return const _DemoIntentResolution(
        DemoAiIntent.medicationCheck,
        reason: 'simple_medicine_qa',
      );
    }

    if (_matchesAny(normalizedInput, _translationKeywords)) {
      return const _DemoIntentResolution(DemoAiIntent.translation);
    }

    if (_matchesAny(normalizedInput, _navigationKeywords)) {
      return const _DemoIntentResolution(DemoAiIntent.navigation);
    }

    if (_matchesAny(normalizedInput, _ocrKeywords)) {
      return const _DemoIntentResolution(DemoAiIntent.ocrText);
    }

    if (_matchesAny(normalizedInput, _sceneKeywords)) {
      return const _DemoIntentResolution(DemoAiIntent.sceneDescription);
    }

    if (_matchesAny(normalizedInput, _environmentKeywords)) {
      return const _DemoIntentResolution(DemoAiIntent.environmentDescription);
    }

    return const _DemoIntentResolution(DemoAiIntent.fallback);
  }

  Future<AIResult> _buildIntentResult(
    String input,
    _DemoIntentResolution resolution, {
    String? imagePath,
    List<Map<String, String>>? history,
  }) async {
    switch (resolution.intent) {
      case DemoAiIntent.ocrText:
        return recognizeText(imagePath ?? 'demo-text');
      case DemoAiIntent.sceneDescription:
        return describeScene(imagePath ?? 'demo-scene');
      case DemoAiIntent.objectIdentify:
        await _simulateDelay(minMs: 220, maxMs: 520);
        return _fixedResult(
          DemoAiIntent.objectIdentify,
          '我识别到画面中有一些常见物体。物体识别可能受光线和角度影响，请确认是否正确。',
          extra: {'confidence': 0.88},
        );
      case DemoAiIntent.colorRecognition:
        return recognizeColor(imagePath ?? 'demo-color');
      case DemoAiIntent.moneyRecognition:
        await _simulateDelay(minMs: 220, maxMs: 520);
        return _fixedResult(
          DemoAiIntent.moneyRecognition,
          '我模拟识别到这像是一张 20 元人民币纸币。面额识别可能受光线影响，请用收款设备、触摸特征或转人工复核。',
          extra: {'amount': 20, 'currency': 'CNY', 'confidence': 0.91},
        );
      case DemoAiIntent.translation:
        await _simulateDelay(minMs: 220, maxMs: 520);
        return _fixedResult(
          DemoAiIntent.translation,
          '转译演示：我会把你的意思整理成短句：“您好，我听不清电话内容，请用文字告诉我取件码或外卖位置。” 可转人工协助沟通。',
          extra: {'source': 'hearing_accessibility_demo', 'confidence': 0.89},
        );
      case DemoAiIntent.environmentDescription:
        await _simulateDelay(minMs: 220, maxMs: 620);
        return _fixedResult(
          DemoAiIntent.environmentDescription,
          '周围环境提示：前方通道基本可走，右前方可能有人流，脚下请留意障碍物和台阶。若要继续移动，建议转人工陪同确认。',
          requiresHumanFallback: true,
          extra: {'riskLevel': 'medium', 'confidence': 0.88},
        );
      case DemoAiIntent.navigation:
        await _simulateDelay(minMs: 220, maxMs: 620);
        return _fixedResult(
          DemoAiIntent.navigation,
          '方向提示：请先停在原地，确认你要去的地点。医院科室、出口、电梯等复杂动线建议转人工陪同，我可以马上为你找志愿者。',
          requiresHumanFallback: true,
          extra: {'riskLevel': 'high', 'confidence': 0.90},
        );
      case DemoAiIntent.medicationCheck:
        await _simulateDelay(minMs: 220, maxMs: 620);
        if (resolution.reason == 'simple_medicine_qa') {
          return _fixedResult(
            DemoAiIntent.medicationCheck,
            _simpleMedicineAnswer(input),
            extra: {
              'simpleMedicineQa': true,
              'confidence': 0.86,
              'safetyNotice': 'not_medical_diagnosis',
            },
          );
        }
        return _fixedResult(
          DemoAiIntent.medicationCheck,
          '根据刚才识别到的药品说明，我只能帮你读取药名、剂量、用法和禁忌提醒，不做医疗诊断。一次吃几片请以说明书、医生或药师建议为准，可转人工确认。',
          requiresHumanFallback: true,
          extra: {
            'safetyNotice': 'not_medical_diagnosis',
            'hasMedicationContext': _historyMentionsMedication(history),
            'confidence': 0.90,
          },
        );
      case DemoAiIntent.emergency:
        await _simulateDelay(minMs: 120, maxMs: 260);
        return _emergencyResult();
      case DemoAiIntent.needHuman:
        await _simulateDelay(minMs: 180, maxMs: 420);
        final contextIntent = resolution.contextIntent;
        final text = contextIntent == DemoAiIntent.medicationCheck
            ? '可以，我将为你转接附近具备药品说明协助经验的志愿者。本 Demo 只进入 Mock 匹配，不会连接真实外部服务。'
            : '这个需求需要真人确认，我将为你转接附近志愿者继续协助。本 Demo 会进入本地匹配流程。';
        return _fixedResult(
          DemoAiIntent.needHuman,
          text,
          requiresHumanFallback: true,
          extra: {
            'contextIntent': contextIntent?.wireName,
            'reason': resolution.reason,
          },
        );
      case DemoAiIntent.fallback:
        await _simulateDelay(minMs: 180, maxMs: 420);
        if (resolution.reason == 'small_talk_greeting') {
          return _fixedResult(
            DemoAiIntent.fallback,
            '你好，我是 LinkAble 的 AI 助手。你可以告诉我需要读文字、看图片、找路，或直接说“转人工”。',
            extra: {
              'confidence': 0.88,
              'smallTalk': true,
              'nextAction': 'answer',
            },
          );
        }
        return _fixedResult(
          DemoAiIntent.fallback,
          '这个问题我还不能稳定判断。你可以换个说法，或点击转人工复核。',
          extra: {'confidence': 0.58},
        );
    }
  }

  AIResult _emergencyResult() {
    return _fixedResult(
      DemoAiIntent.emergency,
      '已进入紧急模式，可在 10 秒内撤销。演示版只启动 SOS Mock，不会真实报警、发短信或推送。',
      isEmergency: true,
      extra: {
        'isEmergency': true,
        'urgencyLevel': 'high',
        'action': 'sos_triggered',
      },
    );
  }

  AIResult _fixedResult(
    DemoAiIntent intent,
    String text, {
    bool requiresHumanFallback = false,
    bool isEmergency = false,
    Map<String, dynamic> extra = const {},
  }) {
    final data = <String, dynamic>{
      'intent': intent == DemoAiIntent.needHuman
          ? DemoAiIntent.needHuman.wireName
          : intent.wireName,
      'demoIntent': intent.wireName,
      'intentLabel': intent.label,
      'canTransferToHuman': !isEmergency,
      if (requiresHumanFallback) ...{
        'requiresHumanFallback': true,
        'nextStatus': 'matching',
      },
      if (isEmergency) ...{'isEmergency': true, 'action': 'sos_triggered'},
      ...extra,
    };
    return AIResult.success(text, data: data);
  }

  String _normalize(String input) {
    return input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
  }

  bool _matchesAny(String input, List<String> keywords) {
    return keywords.any((keyword) => input.contains(_normalize(keyword)));
  }

  bool _historyMentionsMedication(List<Map<String, String>>? history) {
    if (history == null || history.isEmpty) return false;
    final text = _normalize(
      history
          .map((item) => '${item['role'] ?? ''}:${item['content'] ?? ''}')
          .join(' '),
    );
    return _matchesAny(text, const [
      '药',
      '药品盒',
      '说明书',
      '阿莫西林',
      '布洛芬',
      '剂量',
      '用法',
    ]);
  }

  String _simpleMedicineAnswer(String input) {
    final normalized = _normalize(input);
    if (normalized.contains('布洛芬')) {
      return '布洛芬是常见的解热镇痛药，常用于发热、头痛、牙痛或肌肉酸痛。请按药盒说明或医嘱使用；胃病、肾病、孕期或正在用抗凝药时要先问医生或药师。';
    }
    if (normalized.contains('对乙酰氨基酚') ||
        normalized.contains('对乙酰氨基酚') ||
        normalized.contains('扑热息痛') ||
        normalized.contains('扑热息痛')) {
      return '对乙酰氨基酚也叫扑热息痛，是常见退烧止痛成分。重点要避免和多种感冒药重复服用同一成分，并按说明书控制每日总量。';
    }
    if (normalized.contains('感冒药') || normalized.contains('感冒药')) {
      return '感冒药常是复方药，可能同时含退烧、止咳、抗过敏等成分。不要同时吃多种名字不同但成分重复的感冒药；看不清成分时可以拍药盒让我读。';
    }
    if (normalized.contains('有效期') ||
        normalized.contains('过期') ||
        normalized.contains('过期')) {
      return '看药盒有效期时，请找“有效期至”“EXP”或“失效期”。如果已过期、受潮、变色、破损，演示建议不要服用，请谘询药师或更换新药。';
    }
    if (normalized.contains('一起吃') ||
        normalized.contains('一起吃') ||
        normalized.contains('混着吃') ||
        normalized.contains('混着吃')) {
      return '不同药能不能一起吃，要看有效成分是否重复、是否有相互作用，以及你的年龄、疾病和过敏史。我可以帮你读成分表，但是否合用请以医生或药师确认为准。';
    }
    return '我可以做简单药品问答：说明常见药名、成分、有效期位置和阅读注意事项。不确定能不能吃、吃几片或和其他药同用时，请让医生或药师确认。';
  }

  /// 流式对话（模拟）
  Stream<String> chatStream(String userMessage) async* {
    if (!_demoFallbackEnabled) {
      yield 'DemoAIService 当前未启用 Demo fallback';
      return;
    }

    final response = await chat(userMessage);

    if (!response.success) {
      yield '抱歉，处理出错了';
      return;
    }

    // 模拟流式输出，逐字显示
    final text = response.text;
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      yield buffer.toString();
      await Future.delayed(Duration(milliseconds: 30 + _random.nextInt(50)));
    }
  }

  // ===== 新增：标准化 Agent 接口（符合 AGENTS.md §5.3 / §5.4） =====

  /// 处理标准化 AgentInput，返回 AgentResponse
  Future<AgentResponse> processRequest(AgentInput input) async {
    if (!_demoFallbackEnabled) {
      return AgentResponse.fromDemoResult(
        requestId: input.requestId,
        demoIntent: DemoAiIntent.fallback,
        answerText: 'DemoAIService 当前未启用 Demo fallback',
      );
    }

    // 根据 input 类型调用旧方法
    final AIResult result;
    if (input.imageUri != null) {
      result = await process(input.text ?? '', imagePath: input.imageUri);
    } else {
      result = await process(input.text ?? '');
    }

    // 提取 intent
    final intentName = result.data?['intent'] as String? ?? 'fallback';
    final intent = DemoAiIntent.fromWireName(intentName);

    // 计算 confidence（简单规则：精确匹配=0.95, 模糊匹配=0.75, 未知=0.45）
    final double confidence;
    if (intent == DemoAiIntent.fallback) {
      confidence = 0.45;
    } else if (result.data?['fallback'] == true) {
      confidence = 0.75;
    } else {
      confidence = 0.95;
    }

    // 构建 AgentResponse
    return AgentResponse.fromDemoResult(
      requestId: input.requestId,
      demoIntent: intent,
      answerText: result.text,
      extra: {...?result.data, 'confidence': confidence},
    );
  }
}

const _ocrKeywords = [
  '读一下',
  '帮我读',
  '看不清',
  '文字',
  '说明书',
  '药品盒',
  '通知单',
  '路牌',
  '读药',
  '药盒',
];

const _sceneKeywords = ['我面前是什么', '前面有什么', '帮我看看', '场景', '画面'];

const _colorKeywords = ['什么颜色', '颜色', '红色', '蓝色', '衣服颜色', '药盒颜色'];

const _moneyKeywords = ['多少钱', '面额', '钞票', '纸币', '人民币', '硬币'];

const _translationKeywords = ['翻译', '帮我说', '听不清', '听障', '转译', '外卖电话', '快递电话'];

const _environmentKeywords = ['周围', '环境', '安全', '障碍物', '有没有人', '路况'];

const _navigationKeywords = ['怎么走', '在哪里', '找不到', '科室', '挂号', '出口', '厕所', '电梯'];

const _medicationKeywords = ['怎么吃', '一次几片', '药名', '剂量', '用法', '禁忌'];

const _dosageFollowUpKeywords = ['一次吃几片', '一次几片', '几片', '剂量', '怎么吃'];

const _simpleMedicineQaKeywords = [
  '布洛芬',
  '对乙酰氨基酚',
  '对乙酰氨基酚',
  '扑热息痛',
  '扑热息痛',
  '感冒药',
  '感冒药',
  '退烧药',
  '退烧药',
  '有效期',
  '过期',
  '过期',
  '药品问答',
  '药品问答',
];

const _emergencyKeywords = ['救命', '晕倒', '摔倒', '胸口痛', '迷路了', '我很害怕', '紧急'];

const _greetingKeywords = ['你好', '您好', 'hello', 'hi', '嗨', '哈啰', '在吗', '在么'];

const _humanKeywords = [
  '需要人帮忙',
  '人工协助',
  '真人帮助',
  '真人',
  '志愿者',
  '转人工',
  '找人确认',
  '找人',
  '帮我找人',
  '陪同',
];
