import 'dart:math';

import '../../config/app_config.dart';
import '../../core/utils/logger.dart';
import '../../models/agent_input_model.dart';
import '../../models/agent_response_model.dart';
import '../../models/ai_result_model.dart';
import '../../models/demo_ai_intent.dart';
import 'demo_data_loader.dart';

/// AI服務類型
enum AIServiceType {
  ocr, // 文字識別
  sceneDescription, // 場景描述
  colorRecognition, // 顏色識別
  chat, // 對話
  intentDetection, // 意圖識別
  emergency, // 緊急檢測
}

class _DemoIntentResolution {
  const _DemoIntentResolution(this.intent, {this.contextIntent, this.reason});

  final DemoAiIntent intent;
  final DemoAiIntent? contextIntent;
  final String? reason;
}

/// 演示版AI服務
/// 用於替代真實的AI API調用
class DemoAIService {
  static final DemoAIService _instance = DemoAIService._internal();
  factory DemoAIService() => _instance;
  DemoAIService._internal();

  final _random = Random();

  bool get _demoFallbackEnabled =>
      AppConfig.shouldUseDemoFallback(feature: 'DemoAIService');

  AIResult get _demoModeDisabledResult =>
      AIResult.error('DemoAIService 當前未啓用 Demo fallback');

  /// 模擬處理延遲
  Future<void> _simulateDelay({int minMs = 250, int maxMs = 800}) async {
    final safeMax = maxMs <= minMs ? minMs + 1 : maxMs;
    final delay = minMs + _random.nextInt(safeMax - minMs);
    await Future.delayed(Duration(milliseconds: delay));
  }

  /// OCR文字識別
  Future<AIResult> recognizeText(String imagePath) async {
    if (!_demoFallbackEnabled) return _demoModeDisabledResult;
    await _simulateDelay();

    final scenarios = DemoDataLoader.getOCRScenarios();
    if (scenarios.isEmpty) {
      AppLogger.warning('OCR demo 數據爲空，使用內置降級文案');
      return _fixedResult(
        DemoAiIntent.ocrText,
        '我可以讀出文字內容。當前資源未加載，演示降級爲：這是藥品盒/通知單讀取結果，請複覈關鍵信息，也可以轉人工確認。',
        extra: {'fallback': true},
      );
    }

    final scenario = scenarios.firstWhere(
      (item) => '${item['scenario']}${item['imageDescription']}'.contains('藥'),
      orElse: () => scenarios.first,
    );
    final summary =
        scenario['summary'] as String? ?? '我識別到一段文字，但內容不完整。請複覈圖片，也可以轉人工確認。';

    return _fixedResult(
      DemoAiIntent.ocrText,
      '$summary 請複覈藥名、劑量和有效期；不確定時可以轉人工確認。',
      extra: {
        'recognizedText': scenario['recognizedText'],
        'scenario': scenario['scenario'],
        'confidence': 0.95,
      },
    );
  }

  /// 場景描述
  Future<AIResult> describeScene(String imagePath) async {
    if (!_demoFallbackEnabled) return _demoModeDisabledResult;
    await _simulateDelay(minMs: 350, maxMs: 900);

    final descriptions = DemoDataLoader.getSceneDescriptions();
    if (descriptions.isEmpty) {
      AppLogger.warning('場景描述 demo 數據爲空，使用內置降級文案');
      return _fixedResult(
        DemoAiIntent.sceneDescription,
        '我看到前方環境較開闊，右側像是櫃檯或門口，地面基本平整。請慢速前進，必要時轉人工陪同。',
        extra: {'fallback': true},
      );
    }

    final description = descriptions.firstWhere(
      (item) => '${item['scenario']}${item['description']}'.contains('街道'),
      orElse: () => descriptions.first,
    );
    final descriptionText =
        description['description'] as String? ??
        '我看到前方有通行空間，但畫面信息不完整。請慢速前進，也可以轉人工確認。';

    return _fixedResult(
      DemoAiIntent.sceneDescription,
      '$descriptionText 請慢速前進，遇到臺階、門口或櫃檯時建議停下複覈。',
      extra: {'scenario': description['scenario'], 'confidence': 0.92},
    );
  }

  /// 顏色識別
  Future<AIResult> recognizeColor(String imagePath) async {
    if (!_demoFallbackEnabled) return _demoModeDisabledResult;
    await _simulateDelay(minMs: 250, maxMs: 650);

    final colors = DemoDataLoader.getColorRecognitions();
    if (colors.isEmpty) {
      AppLogger.warning('顏色識別 demo 數據爲空，使用內置降級文案');
      return _fixedResult(
        DemoAiIntent.colorRecognition,
        '我識別到主體顏色偏深藍，適合用於衣物、藥盒或指示牌顏色確認。光線會影響判斷，請複覈。',
        extra: {'fallback': true},
      );
    }

    final color = colors.firstWhere(
      (item) => '${item['description']}${item['dominantColor']}'.contains('藍'),
      orElse: () => colors.first,
    );
    final colorText = color['description'] as String? ?? '主體顏色偏深色。光線會影響判斷，請複覈。';

    return _fixedResult(
      DemoAiIntent.colorRecognition,
      '$colorText 如果用於服藥、出行指示或付款，請再請身邊人或志願者複覈。',
      extra: {
        'dominantColor': color['dominantColor'],
        'colorHex': color['colorHex'],
      },
    );
  }

  /// 對話回覆
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
      '$response 如果你願意，我可以幫你轉接真人志願者繼續處理。',
      requiresHumanFallback: true,
      extra: {'legacyIntent': legacyIntent, 'confidence': 0.72},
    );
  }

  /// 意圖識別
  Future<AIResult> detectIntent(
    String input, {
    List<Map<String, String>>? history,
  }) async {
    if (!_demoFallbackEnabled) return _demoModeDisabledResult;
    await _simulateDelay(minMs: 80, maxMs: 180);

    final resolution = _detectDemoIntent(input, history: history);

    return AIResult.success(
      '意圖識別完成',
      data: {
        'intent': resolution.intent.wireName,
        'demoIntent': resolution.intent.wireName,
        'contextIntent': resolution.contextIntent?.wireName,
        'confidence': 0.90,
      },
    );
  }

  /// 緊急檢測
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
      '未檢測到緊急情況',
      data: {'isEmergency': false, 'urgencyLevel': 'normal'},
    );
  }

  /// 綜合AI處理（根據輸入自動選擇服務）
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
          '我識別到畫面中有一些常見物體。物體識別可能受光線和角度影響，請確認是否正確。',
          extra: {'confidence': 0.88},
        );
      case DemoAiIntent.colorRecognition:
        return recognizeColor(imagePath ?? 'demo-color');
      case DemoAiIntent.moneyRecognition:
        await _simulateDelay(minMs: 220, maxMs: 520);
        return _fixedResult(
          DemoAiIntent.moneyRecognition,
          '我模擬識別到這像是一張 20 元人民幣紙幣。面額識別可能受光線影響，請用收款設備、觸摸特徵或轉人工複覈。',
          extra: {'amount': 20, 'currency': 'CNY', 'confidence': 0.91},
        );
      case DemoAiIntent.translation:
        await _simulateDelay(minMs: 220, maxMs: 520);
        return _fixedResult(
          DemoAiIntent.translation,
          '轉譯演示：我會把你的意思整理成短句：“您好，我聽不清電話內容，請用文字告訴我取件碼或外賣位置。” 可轉人工協助溝通。',
          extra: {'source': 'hearing_accessibility_demo', 'confidence': 0.89},
        );
      case DemoAiIntent.environmentDescription:
        await _simulateDelay(minMs: 220, maxMs: 620);
        return _fixedResult(
          DemoAiIntent.environmentDescription,
          '周圍環境提示：前方通道基本可走，右前方可能有人流，腳下請留意障礙物和臺階。若要繼續移動，建議轉人工陪同確認。',
          requiresHumanFallback: true,
          extra: {'riskLevel': 'medium', 'confidence': 0.88},
        );
      case DemoAiIntent.navigation:
        await _simulateDelay(minMs: 220, maxMs: 620);
        return _fixedResult(
          DemoAiIntent.navigation,
          '方向提示：請先停在原地，確認你要去的地點。醫院科室、出口、電梯等複雜動線建議轉人工陪同，我可以馬上爲你找志願者。',
          requiresHumanFallback: true,
          extra: {'riskLevel': 'high', 'confidence': 0.90},
        );
      case DemoAiIntent.medicationCheck:
        await _simulateDelay(minMs: 220, maxMs: 620);
        return _fixedResult(
          DemoAiIntent.medicationCheck,
          '根據剛纔識別到的藥品說明，我只能幫你讀取藥名、劑量、用法和禁忌提醒，不做醫療診斷。一次喫幾片請以說明書、醫生或藥師建議爲準，可轉人工確認。',
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
            ? '可以，我將爲你轉接附近具備藥品說明協助經驗的志願者。本 Demo 只進入 Mock 匹配，不會連接真實外部服務。'
            : '這個需求需要真人確認，我將爲你轉接附近志願者繼續協助。本 Demo 會進入本地匹配流程。';
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
        return _fixedResult(
          DemoAiIntent.fallback,
          '這個問題我還不能穩定判斷。你可以換個說法，或直接轉人工找志願者繼續處理。',
          requiresHumanFallback: true,
          extra: {'confidence': 0.58},
        );
    }
  }

  AIResult _emergencyResult() {
    return _fixedResult(
      DemoAiIntent.emergency,
      '已進入緊急模式，可在 10 秒內撤銷。演示版只啓動 SOS Mock，不會真實報警、發短信或推送。',
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
      '藥',
      '藥品盒',
      '說明書',
      '阿莫西林',
      '布洛芬',
      '劑量',
      '用法',
    ]);
  }

  /// 流式對話（模擬）
  Stream<String> chatStream(String userMessage) async* {
    if (!_demoFallbackEnabled) {
      yield 'DemoAIService 當前未啓用 Demo fallback';
      return;
    }

    final response = await chat(userMessage);

    if (!response.success) {
      yield '抱歉，處理出錯了';
      return;
    }

    // 模擬流式輸出，逐字顯示
    final text = response.text;
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      yield buffer.toString();
      await Future.delayed(Duration(milliseconds: 30 + _random.nextInt(50)));
    }
  }

  // ===== 新增：標準化 Agent 接口（符合 AGENTS.md §5.3 / §5.4） =====

  /// 處理標準化 AgentInput，返回 AgentResponse
  Future<AgentResponse> processRequest(AgentInput input) async {
    if (!_demoFallbackEnabled) {
      return AgentResponse.fromDemoResult(
        requestId: input.requestId,
        demoIntent: DemoAiIntent.fallback,
        answerText: 'DemoAIService 當前未啓用 Demo fallback',
      );
    }

    // 根據 input 類型調用舊方法
    final AIResult result;
    if (input.imageUri != null) {
      result = await process(
        input.text ?? '',
        imagePath: input.imageUri,
      );
    } else {
      result = await process(input.text ?? '');
    }

    // 提取 intent
    final intentName = result.data?['intent'] as String? ?? 'fallback';
    final intent = DemoAiIntent.fromWireName(intentName);

    // 計算 confidence（簡單規則：精確匹配=0.95, 模糊匹配=0.75, 未知=0.45）
    final double confidence;
    if (intent == DemoAiIntent.fallback) {
      confidence = 0.45;
    } else if (result.data?['fallback'] == true) {
      confidence = 0.75;
    } else {
      confidence = 0.95;
    }

    // 構建 AgentResponse
    return AgentResponse.fromDemoResult(
      requestId: input.requestId,
      demoIntent: intent,
      answerText: result.text,
      extra: {
        ...?result.data,
        'confidence': confidence,
      },
    );
  }
}

const _ocrKeywords = [
  '讀一下',
  '幫我讀',
  '看不清',
  '文字',
  '說明書',
  '藥品盒',
  '通知單',
  '路牌',
  '讀藥',
  '藥盒',
];

const _sceneKeywords = ['我面前是什麼', '前面有什麼', '幫我看看', '場景', '畫面'];

const _colorKeywords = ['什麼顏色', '顏色', '紅色', '藍色', '衣服顏色', '藥盒顏色'];

const _moneyKeywords = ['多少錢', '面額', '鈔票', '紙幣', '人民幣', '硬幣'];

const _translationKeywords = ['翻譯', '幫我說', '聽不清', '聽障', '轉譯', '外賣電話', '快遞電話'];

const _environmentKeywords = ['周圍', '環境', '安全', '障礙物', '有沒有人', '路況'];

const _navigationKeywords = ['怎麼走', '在哪裏', '找不到', '科室', '掛號', '出口', '廁所', '電梯'];

const _medicationKeywords = ['怎麼喫', '一次幾片', '藥名', '劑量', '用法', '禁忌'];

const _dosageFollowUpKeywords = ['一次喫幾片', '一次幾片', '幾片', '劑量', '怎麼喫'];

const _emergencyKeywords = ['救命', '暈倒', '摔倒', '胸口痛', '迷路了', '我很害怕', '緊急'];

const _humanKeywords = [
  '需要人幫忙',
  '人工協助',
  '真人幫助',
  '真人',
  '志願者',
  '轉人工',
  '找人確認',
  '找人',
  '幫我找人',
  '陪同',
];
