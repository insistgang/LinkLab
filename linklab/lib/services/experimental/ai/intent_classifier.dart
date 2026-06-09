import 'ai_service.dart';

/// 意圖分類器
/// 負責識別用戶輸入的意圖類型
class IntentClassifier {
  /// 關鍵詞映射表
  static final Map<IntentType, List<String>> _intentKeywords = {
    IntentType.textRecognition: [
      '文字', '字', '文本', '內容', '寫了什麼', '是什麼字',
      'read', 'text', 'word', 'character',
    ],
    IntentType.objectRecognition: [
      '什麼', '東西', '物體', '物品', '這是什麼', '那是什麼',
      'object', 'thing', 'what is this', 'what is that',
    ],
    IntentType.colorRecognition: [
      '顏色', '色', '什麼顏色', '什麼色', '顏色的',
      'color', 'colour', 'what color',
    ],
    IntentType.currencyRecognition: [
      '錢', '鈔票', '紙幣', '面額', '多少', '多少錢',
      'money', 'cash', 'bill', 'currency', 'how much',
    ],
    IntentType.translation: [
      '翻譯', '英文', '中文', '什麼意思', '怎麼說',
      'translate', 'translation', 'meaning', 'mean',
    ],
    IntentType.navigation: [
      '導航', '怎麼走', '去哪裏', '路線', '方向', '怎麼走',
      'navigate', 'navigation', 'direction', 'route', 'way to',
    ],
    IntentType.sceneDescription: [
      '環境', '周圍', '場景', '前面', '附近', '有什麼',
      'environment', 'scene', 'surrounding', 'around', 'what is around',
    ],
    IntentType.medicineConfirmation: [
      '藥', '藥品', '喫藥', '用量', '劑量', '怎麼喫', '服用',
      'medicine', 'drug', 'pill', 'medication', 'dosage',
    ],
    IntentType.medicalConsultation: [
      '病', '症狀', '不舒服', '疼', '痛', '醫院', '醫生',
      'sick', 'ill', 'pain', 'hurt', 'hospital', 'doctor', 'symptom',
    ],
    IntentType.emotionalSupport: [
      '難過', '傷心', '孤獨', '害怕', '擔心', '焦慮', '抑鬱',
      'sad', 'lonely', 'scared', 'worried', 'anxious', 'depressed',
    ],
    IntentType.emergency: [
      '救命', 'help', 'emergency', '危險', 'fire', '着火',
    ],
  };

  /// 分類意圖
  /// 返回識別到的意圖類型和置信度
  IntentClassification classify(String input, {String? imageUrl}) {
    final lowerInput = input.toLowerCase();

    // 1. 緊急意圖優先檢測
    final emergencyCheck = _checkEmergencyIntent(lowerInput);
    if (emergencyCheck != null) {
      return emergencyCheck;
    }

    // 2. 如果有圖片，分析是否涉及視覺識別類意圖
    if (imageUrl != null) {
      final visualIntent = _classifyVisualIntent(lowerInput);
      if (visualIntent != null) {
        return visualIntent;
      }
    }

    // 3. 基於關鍵詞匹配
    final keywordIntent = _classifyByKeywords(lowerInput);
    if (keywordIntent.confidence > 0.5) {
      return keywordIntent;
    }

    // 4. 默認返回通用對話
    return IntentClassification(
      intent: IntentType.generalChat,
      confidence: 0.3,
    );
  }

  /// 檢測緊急意圖
  IntentClassification? _checkEmergencyIntent(String input) {
    final emergencyWords = [
      '救命', 'help me', 'emergency', '報警', '救護車', 'ambulance',
      '着火了', 'fire', '殺人', '搶劫', 'robbery', 'kill',
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

  /// 分類視覺相關意圖
  IntentClassification? _classifyVisualIntent(String input) {
    // 顏色識別
    if (_intentKeywords[IntentType.colorRecognition]!.any(
      (k) => input.contains(k.toLowerCase()),
    )) {
      return IntentClassification(
        intent: IntentType.colorRecognition,
        confidence: 0.9,
      );
    }

    // 文字識別
    if (_intentKeywords[IntentType.textRecognition]!.any(
      (k) => input.contains(k.toLowerCase()),
    )) {
      return IntentClassification(
        intent: IntentType.textRecognition,
        confidence: 0.85,
      );
    }

    // 鈔票識別
    if (_intentKeywords[IntentType.currencyRecognition]!.any(
      (k) => input.contains(k.toLowerCase()),
    )) {
      return IntentClassification(
        intent: IntentType.currencyRecognition,
        confidence: 0.85,
      );
    }

    // 物體識別（最通用）
    if (_intentKeywords[IntentType.objectRecognition]!.any(
      (k) => input.contains(k.toLowerCase()),
    )) {
      return IntentClassification(
        intent: IntentType.objectRecognition,
        confidence: 0.8,
      );
    }

    // 場景描述
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

  /// 基於關鍵詞分類
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
        // 計算置信度：匹配數 / 總關鍵詞數
        scores[intent] = matchCount / keywords.length;
      }
    }

    if (scores.isEmpty) {
      return IntentClassification(
        intent: IntentType.generalChat,
        confidence: 0.0,
      );
    }

    // 找出得分最高的意圖
    final bestMatch = scores.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    return IntentClassification(
      intent: bestMatch.key,
      confidence: bestMatch.value.clamp(0.0, 1.0),
    );
  }

  /// 判斷是否需要轉人工
  static bool needsHumanHandoff(IntentType intent, double confidence) {
    // 醫療相關場景必須轉人工
    if (intent == IntentType.medicalConsultation ||
        intent == IntentType.medicineConfirmation) {
      return true;
    }

    // 情感陪伴優先轉人工
    if (intent == IntentType.emotionalSupport) {
      return true;
    }

    // 緊急場景觸發SOS流程
    if (intent == IntentType.emergency) {
      return true;
    }

    // 置信度低的場景建議轉人工
    if (confidence < 0.5) {
      return true;
    }

    return false;
  }
}

/// 意圖分類結果
class IntentClassification {
  final IntentType intent;
  final double confidence;

  const IntentClassification({
    required this.intent,
    required this.confidence,
  });
}
