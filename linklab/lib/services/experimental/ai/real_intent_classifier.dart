import 'ai_service.dart';

/// 真實意圖分類器
/// 使用NLP規則引擎支持12種意圖分類
/// 支持上下文感知和緊急度判斷
class RealIntentClassifier {
  /// 單例實例
  static final RealIntentClassifier _instance = RealIntentClassifier._internal();
  factory RealIntentClassifier() => _instance;
  RealIntentClassifier._internal();

  // ==================== 意圖關鍵詞庫 ====================

  /// 文字識別意圖關鍵詞
  static final List<String> _textRecognitionKeywords = [
    // 中文
    '文字', '字', '文本', '內容', '寫了什麼', '是什麼字', '讀一下', '念一下',
    '這寫的什麼', '上面寫的', '紙上寫的', '標籤', '說明書', '菜單', '路牌',
    '招牌', '廣告牌', '通知', '公告', '短信', '微信', '消息',
    // 英文
    'read', 'text', 'word', 'character', 'what does it say',
    'ocr', 'document', 'label', 'sign', 'menu', 'message',
  ];

  /// 物體識別意圖關鍵詞
  static final List<String> _objectRecognitionKeywords = [
    // 中文
    '什麼', '東西', '物體', '物品', '這是什麼', '那是什麼', '手裏拿的是什麼',
    '面前是什麼', '地上有什麼', '桌上有什麼', '這是啥', '那是個啥',
    '瓶子', '盒子', '袋子', '杯子', '手機', '鑰匙', '錢包', '眼鏡',
    // 英文
    'object', 'thing', 'what is this', 'what is that', 'item',
    'bottle', 'box', 'bag', 'cup', 'phone', 'key', 'wallet', 'glasses',
  ];

  /// 顏色識別意圖關鍵詞
  static final List<String> _colorRecognitionKeywords = [
    // 中文
    '顏色', '色', '什麼顏色', '什麼色', '顏色的', '這個是什麼色',
    '衣服顏色', '褲子顏色', '裙子顏色', '這是什麼顏色', '那個是什麼顏色',
    // 英文
    'color', 'colour', 'what color', 'what colour', 'shade', 'hue',
  ];

  /// 鈔票識別意圖關鍵詞
  static final List<String> _currencyRecognitionKeywords = [
    // 中文
    '錢', '鈔票', '紙幣', '面額', '多少錢', '這是多少錢', '多少元',
    '一百', '五十', '二十', '十塊', '五塊', '一塊', '人民幣', '美元',
    '歐元', '日元', '港幣', '零錢', '整錢',
    // 英文
    'money', 'cash', 'bill', 'currency', 'how much', 'dollar', 'euro',
    'yen', 'pound', 'banknote', 'note',
  ];

  /// 翻譯意圖關鍵詞
  static final List<String> _translationKeywords = [
    // 中文
    '翻譯', '英文', '中文', '什麼意思', '怎麼說', '怎麼讀', '用英語怎麼說',
    '這個詞什麼意思', '這句話什麼意思', '外語', '外文', '外國話',
    // 英文
    'translate', 'translation', 'meaning', 'mean', 'what does it mean',
    'how to say', 'in english', 'foreign language',
  ];

  /// 導航意圖關鍵詞
  static final List<String> _navigationKeywords = [
    // 中文
    '導航', '怎麼走', '去哪裏', '路線', '方向', '怎麼走', '往哪走',
    '怎麼去', '附近', '周邊', '附近有什麼', '最近的', '在哪', '位置',
    '地鐵', '公交', '打車', '步行', '開車', '騎車',
    // 英文
    'navigate', 'navigation', 'direction', 'route', 'way to', 'how to get',
    'where is', 'nearby', 'location', 'address', 'go to',
  ];

  /// 場景描述意圖關鍵詞
  static final List<String> _sceneDescriptionKeywords = [
    // 中文
    '環境', '周圍', '場景', '前面', '附近', '有什麼', '前面有什麼',
    '周圍有什麼', '附近有什麼', '這是哪', '什麼地方', '在哪裏',
    '描述一下', '給我描述', '告訴我周圍', '我看不見', '幫我看看',
    // 英文
    'environment', 'scene', 'surrounding', 'around', 'what is around',
    'describe', 'where am i', 'what do you see', 'help me see',
  ];

  /// 藥品確認意圖關鍵詞
  static final List<String> _medicineConfirmationKeywords = [
    // 中文
    '藥', '藥品', '喫藥', '用量', '劑量', '怎麼喫', '服用', '用法',
    '這個藥', '那種藥', '藥片', '膠囊', '顆粒', '口服液', '藥水',
    '一天幾次', '一次幾粒', '飯前喫', '飯後喫', '睡前喫', '隨餐喫',
    '處方藥', '非處方藥', 'OTC', '國藥準字',
    // 英文
    'medicine', 'drug', 'pill', 'medication', 'dosage', 'how to take',
    'prescription', 'tablet', 'capsule', 'dose', 'pharmacy',
  ];

  /// 醫療問診意圖關鍵詞
  static final List<String> _medicalConsultationKeywords = [
    // 中文
    '病', '症狀', '不舒服', '疼', '痛', '醫院', '醫生', '看病',
    '發燒', '感冒', '咳嗽', '拉肚子', '頭暈', '噁心', '嘔吐',
    '胸悶', '心慌', '血壓', '血糖', '過敏', '傷口', '出血',
    '骨折', '扭傷', '燙傷', '割傷', '我需要醫生', '叫救護車',
    // 英文
    'sick', 'ill', 'pain', 'hurt', 'hospital', 'doctor', 'symptom',
    'fever', 'cold', 'cough', 'dizzy', 'nausea', 'emergency',
    'ambulance', 'medical help', 'not feeling well',
  ];

  /// 情感陪伴意圖關鍵詞
  static final List<String> _emotionalSupportKeywords = [
    // 中文
    '難過', '傷心', '孤獨', '害怕', '擔心', '焦慮', '抑鬱', '煩',
    '想哭', '沒人理解', '好難受', '心裏不舒服', '壓力大', '失眠',
    '想找人聊聊', '陪我說說話', '我好累', '不想活了', '活着沒意思',
    // 英文
    'sad', 'lonely', 'scared', 'worried', 'anxious', 'depressed',
    'upset', 'cry', 'stressed', 'insomnia', 'talk to me', 'tired',
    'hopeless', 'suicide', 'end it all',
  ];

  /// 緊急求助意圖關鍵詞
  static final List<String> _emergencyKeywords = [
    // 中文
    '救命', 'help', 'emergency', '救救我', '報警', '救護車', '120',
    '着火了', 'fire', '火災', '119', '警察', '110', '殺人', '搶劫',
    '小偷', '有人打我', '被打了', '襲擊', '危險', '快不行了',
    '心臟病發作', '心梗', '中風', '昏迷', '大出血', '窒息', '溺水',
    // 英文
    'help me', 'emergency', 'call police', 'call ambulance',
    'fire', 'heart attack', 'stroke', 'unconscious', 'bleeding',
    'dying', 'dying', 'robbery', 'attack', 'danger',
  ];

  /// 通用對話意圖關鍵詞
  static final List<String> _generalChatKeywords = [
    // 中文
    '你好', '您好', 'hello', 'hi', '在嗎', '有人嗎', '謝謝', '感謝',
    '再見', '拜拜', 'bye', '好的', '知道了', '明白', '不懂', '再說一遍',
    '能做什麼', '功能', '幫助', '怎麼用', '你是誰', '叫什麼名字',
    // 英文
    'hello', 'hi', 'thank you', 'thanks', 'goodbye', 'bye',
    'what can you do', 'help', 'who are you', 'what is your name',
  ];

  // ==================== 否定詞庫 ====================

  /// 否定詞 - 用於排除誤觸發
  static final List<String> _negationWords = [
    '沒有', '不是', '別', '不要', '沒', '無', '非', '勿',
    'not', 'no', 'don\'t', 'doesn\'t', 'didn\'t', 'wasn\'t',
    'isn\'t', 'aren\'t', 'won\'t', 'wouldn\'t', 'couldn\'t',
  ];

  // ==================== 上下文模式 ====================

  /// 多輪對話上下文
  final Map<String, IntentContext> _contexts = {};

  /// 獲取或創建上下文
  IntentContext _getContext(String sessionId) {
    return _contexts.putIfAbsent(sessionId, () => IntentContext());
  }

  /// 清除上下文
  void clearContext(String sessionId) {
    _contexts.remove(sessionId);
  }

  // ==================== 核心分類方法 ====================

  /// 分類意圖
  /// [input] 用戶輸入
  /// [sessionId] 會話ID（用於上下文）
  /// [imageUrl] 圖片URL（用於視覺意圖判斷）
  IntentClassification classify(
    String input, {
    String? sessionId,
    String? imageUrl,
  }) {
    final lowerInput = input.toLowerCase().trim();

    // 1. 緊急意圖優先檢測（最高優先級）
    final emergencyResult = _checkEmergencyIntent(lowerInput);
    if (emergencyResult != null) {
      return emergencyResult;
    }

    // 2. 上下文感知分類
    if (sessionId != null) {
      final contextResult = _classifyWithContext(lowerInput, sessionId);
      if (contextResult != null) {
        return contextResult;
      }
    }

    // 3. 視覺相關意圖（如果有圖片）
    if (imageUrl != null) {
      final visualResult = _classifyVisualIntent(lowerInput);
      if (visualResult != null) {
        return visualResult;
      }
    }

    // 4. 基於關鍵詞匹配
    final keywordResult = _classifyByKeywords(lowerInput);
    if (keywordResult.confidence > 0.6) {
      _updateContext(sessionId, keywordResult.intent);
      return keywordResult;
    }

    // 5. 模糊匹配
    final fuzzyResult = _fuzzyClassify(lowerInput);
    if (fuzzyResult.confidence > 0.4) {
      _updateContext(sessionId, fuzzyResult.intent);
      return fuzzyResult;
    }

    // 6. 默認返回通用對話
    return IntentClassification(
      intent: IntentType.generalChat,
      confidence: 0.3,
      reason: '未匹配到特定意圖',
    );
  }

  /// 檢測緊急意圖
  IntentClassification? _checkEmergencyIntent(String input) {
    // 危急級別 - 立即觸發
    for (final keyword in _emergencyKeywords) {
      if (input.contains(keyword.toLowerCase())) {
        // 檢查否定詞
        if (_hasNegationBefore(input, keyword)) {
          continue;
        }
        return IntentClassification(
          intent: IntentType.emergency,
          confidence: 0.95,
          reason: '檢測到緊急關鍵詞: $keyword',
          urgency: UrgencyLevel.emergency,
        );
      }
    }
    return null;
  }

  /// 上下文感知分類
  IntentClassification? _classifyWithContext(String input, String sessionId) {
    final context = _getContext(sessionId);

    // 如果上一輪是視覺識別意圖，且用戶說"再來一張"、"再拍一張"等
    if (context.lastIntent != null &&
        _isVisualIntent(context.lastIntent!) &&
        _isContinuationRequest(input)) {
      return IntentClassification(
        intent: context.lastIntent!,
        confidence: 0.85,
        reason: '上下文延續: ${context.lastIntent}',
      );
    }

    // 追問模式
    if (context.lastIntent == IntentType.sceneDescription &&
        _isFollowUpQuestion(input)) {
      return IntentClassification(
        intent: IntentType.sceneDescription,
        confidence: 0.8,
        reason: '場景描述追問',
      );
    }

    return null;
  }

  /// 分類視覺相關意圖
  IntentClassification? _classifyVisualIntent(String input) {
    // 按優先級排序

    // 1. 顏色識別（最具體）
    if (_containsAny(input, _colorRecognitionKeywords)) {
      return IntentClassification(
        intent: IntentType.colorRecognition,
        confidence: 0.9,
        reason: '顏色識別關鍵詞匹配',
      );
    }

    // 2. 鈔票識別
    if (_containsAny(input, _currencyRecognitionKeywords)) {
      return IntentClassification(
        intent: IntentType.currencyRecognition,
        confidence: 0.85,
        reason: '鈔票識別關鍵詞匹配',
      );
    }

    // 3. 文字識別
    if (_containsAny(input, _textRecognitionKeywords)) {
      return IntentClassification(
        intent: IntentType.textRecognition,
        confidence: 0.85,
        reason: '文字識別關鍵詞匹配',
      );
    }

    // 4. 場景描述
    if (_containsAny(input, _sceneDescriptionKeywords)) {
      return IntentClassification(
        intent: IntentType.sceneDescription,
        confidence: 0.8,
        reason: '場景描述關鍵詞匹配',
      );
    }

    // 5. 物體識別（最通用）
    if (_containsAny(input, _objectRecognitionKeywords)) {
      return IntentClassification(
        intent: IntentType.objectRecognition,
        confidence: 0.75,
        reason: '物體識別關鍵詞匹配',
      );
    }

    return null;
  }

  /// 基於關鍵詞分類
  IntentClassification _classifyByKeywords(String input) {
    final scores = <IntentType, double>{};

    // 計算各意圖的匹配分數
    scores[IntentType.textRecognition] =
        _calculateScore(input, _textRecognitionKeywords);
    scores[IntentType.objectRecognition] =
        _calculateScore(input, _objectRecognitionKeywords);
    scores[IntentType.colorRecognition] =
        _calculateScore(input, _colorRecognitionKeywords);
    scores[IntentType.currencyRecognition] =
        _calculateScore(input, _currencyRecognitionKeywords);
    scores[IntentType.translation] =
        _calculateScore(input, _translationKeywords);
    scores[IntentType.navigation] =
        _calculateScore(input, _navigationKeywords);
    scores[IntentType.sceneDescription] =
        _calculateScore(input, _sceneDescriptionKeywords);
    scores[IntentType.medicineConfirmation] =
        _calculateScore(input, _medicineConfirmationKeywords);
    scores[IntentType.medicalConsultation] =
        _calculateScore(input, _medicalConsultationKeywords);
    scores[IntentType.emotionalSupport] =
        _calculateScore(input, _emotionalSupportKeywords);
    scores[IntentType.generalChat] =
        _calculateScore(input, _generalChatKeywords);

    // 找出得分最高的意圖
    final bestMatch = scores.entries.reduce((a, b) =>
        a.value > b.value ? a : b);

    if (bestMatch.value > 0) {
      return IntentClassification(
        intent: bestMatch.key,
        confidence: bestMatch.value.clamp(0.0, 1.0),
        reason: '關鍵詞匹配得分: ${bestMatch.value.toStringAsFixed(2)}',
      );
    }

    return IntentClassification(
      intent: IntentType.generalChat,
      confidence: 0.0,
      reason: '無關鍵詞匹配',
    );
  }

  /// 模糊分類
  IntentClassification _fuzzyClassify(String input) {
    // 基於語義相似度的簡單實現
    // 實際項目中可以使用詞向量或語義模型

    // 醫療相關
    if (input.contains('身體') ||
        input.contains('健康') ||
        input.contains('檢查')) {
      return IntentClassification(
        intent: IntentType.medicalConsultation,
        confidence: 0.5,
        reason: '模糊匹配: 醫療相關',
      );
    }

    // 導航相關
    if (input.contains('去') || input.contains('到') || input.contains('找')) {
      return IntentClassification(
        intent: IntentType.navigation,
        confidence: 0.45,
        reason: '模糊匹配: 導航相關',
      );
    }

    return IntentClassification(
      intent: IntentType.generalChat,
      confidence: 0.3,
      reason: '模糊匹配失敗',
    );
  }

  // ==================== 輔助方法 ====================

  /// 計算匹配分數
  double _calculateScore(String input, List<String> keywords) {
    int matchCount = 0;
    double totalScore = 0;

    for (final keyword in keywords) {
      if (input.contains(keyword.toLowerCase())) {
        matchCount++;
        // 長關鍵詞權重更高
        totalScore += keyword.length / 10;
      }
    }

    if (matchCount == 0) return 0.0;

    // 歸一化分數
    return (totalScore / keywords.length).clamp(0.0, 1.0);
  }

  /// 檢查是否包含任意關鍵詞
  bool _containsAny(String input, List<String> keywords) {
    return keywords.any((k) => input.contains(k.toLowerCase()));
  }

  /// 檢查否定詞
  bool _hasNegationBefore(String input, String keyword) {
    final index = input.indexOf(keyword.toLowerCase());
    if (index <= 0) return false;

    // 檢查關鍵詞前5個字符內是否有否定詞
    final before = input.substring((index - 5).clamp(0, index), index);
    return _negationWords.any((n) => before.contains(n));
  }

  /// 是否是視覺意圖
  bool _isVisualIntent(IntentType intent) {
    return intent == IntentType.textRecognition ||
        intent == IntentType.objectRecognition ||
        intent == IntentType.colorRecognition ||
        intent == IntentType.currencyRecognition ||
        intent == IntentType.sceneDescription;
  }

  /// 是否是延續請求
  bool _isContinuationRequest(String input) {
    final continuationKeywords = [
      '再來', '再拍', '再照', '再識別', '再看', '再讀',
      'another', 'again', 'next', 'continue',
    ];
    return continuationKeywords.any((k) => input.contains(k.toLowerCase()));
  }

  /// 是否是追問
  bool _isFollowUpQuestion(String input) {
    final followUpPatterns = [
      '還有', '還有呢', '別的', '其他', '前面', '後面', '左邊', '右邊',
      '上面', '下面', '裏面', '外面', '附近', '旁邊',
      'what else', 'anything else', 'more', 'and then',
    ];
    return followUpPatterns.any((p) => input.contains(p.toLowerCase()));
  }

  /// 更新上下文
  void _updateContext(String? sessionId, IntentType intent) {
    if (sessionId == null) return;
    final context = _getContext(sessionId);
    context.lastIntent = intent;
    context.intentHistory.add(intent);
    context.lastUpdateTime = DateTime.now();
  }

  // ==================== 靜態工具方法 ====================

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

  /// 獲取意圖的中文名稱
  static String getIntentName(IntentType intent) {
    switch (intent) {
      case IntentType.textRecognition:
        return '文字識別';
      case IntentType.objectRecognition:
        return '物體識別';
      case IntentType.colorRecognition:
        return '顏色識別';
      case IntentType.currencyRecognition:
        return '鈔票識別';
      case IntentType.translation:
        return '翻譯';
      case IntentType.navigation:
        return '導航';
      case IntentType.sceneDescription:
        return '場景描述';
      case IntentType.medicineConfirmation:
        return '藥品確認';
      case IntentType.medicalConsultation:
        return '醫療問診';
      case IntentType.emotionalSupport:
        return '情感陪伴';
      case IntentType.emergency:
        return '緊急求助';
      case IntentType.generalChat:
        return '通用對話';
      case IntentType.unknown:
        return '未知意圖';
    }
  }

  /// 獲取意圖的英文名稱
  static String getIntentNameEn(IntentType intent) {
    return intent.name;
  }
}

/// 意圖分類結果
class IntentClassification {
  final IntentType intent;
  final double confidence;
  final String? reason;
  final UrgencyLevel urgency;

  const IntentClassification({
    required this.intent,
    required this.confidence,
    this.reason,
    this.urgency = UrgencyLevel.normal,
  });

  @override
  String toString() {
    return 'IntentClassification{intent: ${intent.name}, confidence: $confidence, reason: $reason}';
  }
}

/// 意圖上下文
class IntentContext {
  IntentType? lastIntent;
  final List<IntentType> intentHistory = [];
  DateTime? lastUpdateTime;

  bool get isExpired {
    if (lastUpdateTime == null) return true;
    return DateTime.now().difference(lastUpdateTime!) >
        const Duration(minutes: 5);
  }
}
