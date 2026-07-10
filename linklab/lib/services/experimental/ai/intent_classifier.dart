import 'ai_service.dart';

/// 意图分类器
/// 负责识别用户输入的意图类型
class IntentClassifier {
  /// 关键词映射表
  static final Map<IntentType, List<String>> _intentKeywords = {
    IntentType.textRecognition: [
      '文字', '字', '文本', '内容', '写了什么', '是什么字',
      'read', 'text', 'word', 'character',
    ],
    IntentType.objectRecognition: [
      '什么', '东西', '物体', '物品', '这是什么', '那是什么',
      'object', 'thing', 'what is this', 'what is that',
    ],
    IntentType.colorRecognition: [
      '颜色', '色', '什么颜色', '什么色', '颜色的',
      'color', 'colour', 'what color',
    ],
    IntentType.currencyRecognition: [
      '钱', '钞票', '纸币', '面额', '多少', '多少钱',
      'money', 'cash', 'bill', 'currency', 'how much',
    ],
    IntentType.translation: [
      '翻译', '英文', '中文', '什么意思', '怎么说',
      'translate', 'translation', 'meaning', 'mean',
    ],
    IntentType.navigation: [
      '导航', '怎么走', '去哪里', '路线', '方向', '怎么走',
      'navigate', 'navigation', 'direction', 'route', 'way to',
    ],
    IntentType.sceneDescription: [
      '环境', '周围', '场景', '前面', '附近', '有什么',
      'environment', 'scene', 'surrounding', 'around', 'what is around',
    ],
    IntentType.medicineConfirmation: [
      '药', '药品', '吃药', '用量', '剂量', '怎么吃', '服用',
      'medicine', 'drug', 'pill', 'medication', 'dosage',
    ],
    IntentType.medicalConsultation: [
      '病', '症状', '不舒服', '疼', '痛', '医院', '医生',
      'sick', 'ill', 'pain', 'hurt', 'hospital', 'doctor', 'symptom',
    ],
    IntentType.emotionalSupport: [
      '难过', '伤心', '孤独', '害怕', '担心', '焦虑', '抑郁',
      'sad', 'lonely', 'scared', 'worried', 'anxious', 'depressed',
    ],
    IntentType.emergency: [
      '救命', 'help', 'emergency', '危险', 'fire', '着火',
    ],
  };

  /// 分类意图
  /// 返回识别到的意图类型和置信度
  IntentClassification classify(String input, {String? imageUrl}) {
    final lowerInput = input.toLowerCase();

    // 1. 紧急意图优先检测
    final emergencyCheck = _checkEmergencyIntent(lowerInput);
    if (emergencyCheck != null) {
      return emergencyCheck;
    }

    // 2. 如果有图片，分析是否涉及视觉识别类意图
    if (imageUrl != null) {
      final visualIntent = _classifyVisualIntent(lowerInput);
      if (visualIntent != null) {
        return visualIntent;
      }
    }

    // 3. 基于关键词匹配
    final keywordIntent = _classifyByKeywords(lowerInput);
    if (keywordIntent.confidence > 0.5) {
      return keywordIntent;
    }

    // 4. 默认返回通用对话
    return IntentClassification(
      intent: IntentType.generalChat,
      confidence: 0.3,
    );
  }

  /// 检测紧急意图
  IntentClassification? _checkEmergencyIntent(String input) {
    final emergencyWords = [
      '救命', 'help me', 'emergency', '报警', '救护车', 'ambulance',
      '着火了', 'fire', '杀人', '抢劫', 'robbery', 'kill',
    ];

    for (final word in emergencyWords) {
      if (input.contains(word.toLowerCase())) {
        return IntentClassification(
          intent: IntentType.emergency,
          confidence: 0.95,
        );
      }
    }
    return null;
  }

  /// 分类视觉相关意图
  IntentClassification? _classifyVisualIntent(String input) {
    // 颜色识别
    if (_intentKeywords[IntentType.colorRecognition]!.any(
      (k) => input.contains(k.toLowerCase()),
    )) {
      return IntentClassification(
        intent: IntentType.colorRecognition,
        confidence: 0.9,
      );
    }

    // 文字识别
    if (_intentKeywords[IntentType.textRecognition]!.any(
      (k) => input.contains(k.toLowerCase()),
    )) {
      return IntentClassification(
        intent: IntentType.textRecognition,
        confidence: 0.85,
      );
    }

    // 钞票识别
    if (_intentKeywords[IntentType.currencyRecognition]!.any(
      (k) => input.contains(k.toLowerCase()),
    )) {
      return IntentClassification(
        intent: IntentType.currencyRecognition,
        confidence: 0.85,
      );
    }

    // 物体识别（最通用）
    if (_intentKeywords[IntentType.objectRecognition]!.any(
      (k) => input.contains(k.toLowerCase()),
    )) {
      return IntentClassification(
        intent: IntentType.objectRecognition,
        confidence: 0.8,
      );
    }

    // 场景描述
    if (_intentKeywords[IntentType.sceneDescription]!.any(
      (k) => input.contains(k.toLowerCase()),
    )) {
      return IntentClassification(
        intent: IntentType.sceneDescription,
        confidence: 0.8,
      );
    }

    return null;
  }

  /// 基于关键词分类
  IntentClassification _classifyByKeywords(String input) {
    final scores = <IntentType, double>{};

    for (final entry in _intentKeywords.entries) {
      final intent = entry.key;
      final keywords = entry.value;

      int matchCount = 0;
      for (final keyword in keywords) {
        if (input.contains(keyword.toLowerCase())) {
          matchCount++;
        }
      }

      if (matchCount > 0) {
        // 计算置信度：匹配数 / 总关键词数
        scores[intent] = matchCount / keywords.length;
      }
    }

    if (scores.isEmpty) {
      return IntentClassification(
        intent: IntentType.generalChat,
        confidence: 0.0,
      );
    }

    // 找出得分最高的意图
    final bestMatch = scores.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    return IntentClassification(
      intent: bestMatch.key,
      confidence: bestMatch.value.clamp(0.0, 1.0),
    );
  }

  /// 判断是否需要转人工
  static bool needsHumanHandoff(IntentType intent, double confidence) {
    // 医疗相关场景必须转人工
    if (intent == IntentType.medicalConsultation ||
        intent == IntentType.medicineConfirmation) {
      return true;
    }

    // 情感陪伴优先转人工
    if (intent == IntentType.emotionalSupport) {
      return true;
    }

    // 紧急场景触发SOS流程
    if (intent == IntentType.emergency) {
      return true;
    }

    // 置信度低的场景建议转人工
    if (confidence < 0.5) {
      return true;
    }

    return false;
  }
}

/// 意图分类结果
class IntentClassification {
  final IntentType intent;
  final double confidence;

  const IntentClassification({
    required this.intent,
    required this.confidence,
  });
}
