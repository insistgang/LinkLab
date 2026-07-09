import 'ai_service.dart';

/// 真实意图分类器
/// 使用NLP规则引擎支持12种意图分类
/// 支持上下文感知和紧急度判断
class RealIntentClassifier {
  /// 单例实例
  static final RealIntentClassifier _instance = RealIntentClassifier._internal();
  factory RealIntentClassifier() => _instance;
  RealIntentClassifier._internal();

  // ==================== 意图关键词库 ====================

  /// 文字识别意图关键词
  static final List<String> _textRecognitionKeywords = [
    // 中文
    '文字', '字', '文本', '内容', '写了什么', '是什么字', '读一下', '念一下',
    '这写的什么', '上面写的', '纸上写的', '标签', '说明书', '菜单', '路牌',
    '招牌', '广告牌', '通知', '公告', '短信', '微信', '消息',
    // 英文
    'read', 'text', 'word', 'character', 'what does it say',
    'ocr', 'document', 'label', 'sign', 'menu', 'message',
  ];

  /// 物体识别意图关键词
  static final List<String> _objectRecognitionKeywords = [
    // 中文
    '什么', '东西', '物体', '物品', '这是什么', '那是什么', '手里拿的是什么',
    '面前是什么', '地上有什么', '桌上有什么', '这是啥', '那是个啥',
    '瓶子', '盒子', '袋子', '杯子', '手机', '钥匙', '钱包', '眼镜',
    // 英文
    'object', 'thing', 'what is this', 'what is that', 'item',
    'bottle', 'box', 'bag', 'cup', 'phone', 'key', 'wallet', 'glasses',
  ];

  /// 颜色识别意图关键词
  static final List<String> _colorRecognitionKeywords = [
    // 中文
    '颜色', '色', '什么颜色', '什么色', '颜色的', '这个是什么色',
    '衣服颜色', '裤子颜色', '裙子颜色', '这是什么颜色', '那个是什么颜色',
    // 英文
    'color', 'colour', 'what color', 'what colour', 'shade', 'hue',
  ];

  /// 钞票识别意图关键词
  static final List<String> _currencyRecognitionKeywords = [
    // 中文
    '钱', '钞票', '纸币', '面额', '多少钱', '这是多少钱', '多少元',
    '一百', '五十', '二十', '十块', '五块', '一块', '人民币', '美元',
    '欧元', '日元', '港币', '零钱', '整钱',
    // 英文
    'money', 'cash', 'bill', 'currency', 'how much', 'dollar', 'euro',
    'yen', 'pound', 'banknote', 'note',
  ];

  /// 翻译意图关键词
  static final List<String> _translationKeywords = [
    // 中文
    '翻译', '英文', '中文', '什么意思', '怎么说', '怎么读', '用英语怎么说',
    '这个词什么意思', '这句话什么意思', '外语', '外文', '外国话',
    // 英文
    'translate', 'translation', 'meaning', 'mean', 'what does it mean',
    'how to say', 'in english', 'foreign language',
  ];

  /// 导航意图关键词
  static final List<String> _navigationKeywords = [
    // 中文
    '导航', '怎么走', '去哪里', '路线', '方向', '怎么走', '往哪走',
    '怎么去', '附近', '周边', '附近有什么', '最近的', '在哪', '位置',
    '地铁', '公交', '打车', '步行', '开车', '骑车',
    // 英文
    'navigate', 'navigation', 'direction', 'route', 'way to', 'how to get',
    'where is', 'nearby', 'location', 'address', 'go to',
  ];

  /// 场景描述意图关键词
  static final List<String> _sceneDescriptionKeywords = [
    // 中文
    '环境', '周围', '场景', '前面', '附近', '有什么', '前面有什么',
    '周围有什么', '附近有什么', '这是哪', '什么地方', '在哪里',
    '描述一下', '给我描述', '告诉我周围', '我看不见', '帮我看看',
    // 英文
    'environment', 'scene', 'surrounding', 'around', 'what is around',
    'describe', 'where am i', 'what do you see', 'help me see',
  ];

  /// 药品确认意图关键词
  static final List<String> _medicineConfirmationKeywords = [
    // 中文
    '药', '药品', '吃药', '用量', '剂量', '怎么吃', '服用', '用法',
    '这个药', '那种药', '药片', '胶囊', '颗粒', '口服液', '药水',
    '一天几次', '一次几粒', '饭前吃', '饭后吃', '睡前吃', '随餐吃',
    '处方药', '非处方药', 'OTC', '国药准字',
    // 英文
    'medicine', 'drug', 'pill', 'medication', 'dosage', 'how to take',
    'prescription', 'tablet', 'capsule', 'dose', 'pharmacy',
  ];

  /// 医疗问诊意图关键词
  static final List<String> _medicalConsultationKeywords = [
    // 中文
    '病', '症状', '不舒服', '疼', '痛', '医院', '医生', '看病',
    '发烧', '感冒', '咳嗽', '拉肚子', '头晕', '𫫇心', '呕吐',
    '胸闷', '心慌', '血压', '血糖', '过敏', '伤口', '出血',
    '骨折', '扭伤', '烫伤', '割伤', '我需要医生', '叫救护车',
    // 英文
    'sick', 'ill', 'pain', 'hurt', 'hospital', 'doctor', 'symptom',
    'fever', 'cold', 'cough', 'dizzy', 'nausea', 'emergency',
    'ambulance', 'medical help', 'not feeling well',
  ];

  /// 情感陪伴意图关键词
  static final List<String> _emotionalSupportKeywords = [
    // 中文
    '难过', '伤心', '孤独', '害怕', '担心', '焦虑', '抑郁', '烦',
    '想哭', '没人理解', '好难受', '心里不舒服', '压力大', '失眠',
    '想找人聊聊', '陪我说说话', '我好累', '不想活了', '活着没意思',
    // 英文
    'sad', 'lonely', 'scared', 'worried', 'anxious', 'depressed',
    'upset', 'cry', 'stressed', 'insomnia', 'talk to me', 'tired',
    'hopeless', 'suicide', 'end it all',
  ];

  /// 紧急求助意图关键词
  static final List<String> _emergencyKeywords = [
    // 中文
    '救命', 'help', 'emergency', '救救我', '报警', '救护车', '120',
    '着火了', 'fire', '火灾', '119', '警察', '110', '杀人', '抢劫',
    '小偷', '有人打我', '被打了', '袭击', '危险', '快不行了',
    '心脏病发作', '心梗', '中风', '昏迷', '大出血', '窒息', '溺水',
    // 英文
    'help me', 'emergency', 'call police', 'call ambulance',
    'fire', 'heart attack', 'stroke', 'unconscious', 'bleeding',
    'dying', 'dying', 'robbery', 'attack', 'danger',
  ];

  /// 通用对话意图关键词
  static final List<String> _generalChatKeywords = [
    // 中文
    '你好', '您好', 'hello', 'hi', '在吗', '有人吗', '谢谢', '感谢',
    '再见', '拜拜', 'bye', '好的', '知道了', '明白', '不懂', '再说一遍',
    '能做什么', '功能', '帮助', '怎么用', '你是谁', '叫什么名字',
    // 英文
    'hello', 'hi', 'thank you', 'thanks', 'goodbye', 'bye',
    'what can you do', 'help', 'who are you', 'what is your name',
  ];

  // ==================== 否定词库 ====================

  /// 否定词 - 用于排除误触发
  static final List<String> _negationWords = [
    '没有', '不是', '别', '不要', '没', '无', '非', '勿',
    'not', 'no', 'don\'t', 'doesn\'t', 'didn\'t', 'wasn\'t',
    'isn\'t', 'aren\'t', 'won\'t', 'wouldn\'t', 'couldn\'t',
  ];

  // ==================== 上下文模式 ====================

  /// 多轮对话上下文
  final Map<String, IntentContext> _contexts = {};

  /// 获取或创建上下文
  IntentContext _getContext(String sessionId) {
    return _contexts.putIfAbsent(sessionId, () => IntentContext());
  }

  /// 清除上下文
  void clearContext(String sessionId) {
    _contexts.remove(sessionId);
  }

  // ==================== 核心分类方法 ====================

  /// 分类意图
  /// [input] 用户输入
  /// [sessionId] 会话ID（用于上下文）
  /// [imageUrl] 图片URL（用于视觉意图判断）
  IntentClassification classify(
    String input, {
    String? sessionId,
    String? imageUrl,
  }) {
    final lowerInput = input.toLowerCase().trim();

    // 1. 紧急意图优先检测（最高优先级）
    final emergencyResult = _checkEmergencyIntent(lowerInput);
    if (emergencyResult != null) {
      return emergencyResult;
    }

    // 2. 上下文感知分类
    if (sessionId != null) {
      final contextResult = _classifyWithContext(lowerInput, sessionId);
      if (contextResult != null) {
        return contextResult;
      }
    }

    // 3. 视觉相关意图（如果有图片）
    if (imageUrl != null) {
      final visualResult = _classifyVisualIntent(lowerInput);
      if (visualResult != null) {
        return visualResult;
      }
    }

    // 4. 基于关键词匹配
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

    // 6. 默认返回通用对话
    return IntentClassification(
      intent: IntentType.generalChat,
      confidence: 0.3,
      reason: '未匹配到特定意图',
    );
  }

  /// 检测紧急意图
  IntentClassification? _checkEmergencyIntent(String input) {
    // 危急级别 - 立即触发
    for (final keyword in _emergencyKeywords) {
      if (input.contains(keyword.toLowerCase())) {
        // 检查否定词
        if (_hasNegationBefore(input, keyword)) {
          continue;
        }
        return IntentClassification(
          intent: IntentType.emergency,
          confidence: 0.95,
          reason: '检测到紧急关键词: $keyword',
          urgency: UrgencyLevel.emergency,
        );
      }
    }
    return null;
  }

  /// 上下文感知分类
  IntentClassification? _classifyWithContext(String input, String sessionId) {
    final context = _getContext(sessionId);

    // 如果上一轮是视觉识别意图，且用户说"再来一张"、"再拍一张"等
    if (context.lastIntent != null &&
        _isVisualIntent(context.lastIntent!) &&
        _isContinuationRequest(input)) {
      return IntentClassification(
        intent: context.lastIntent!,
        confidence: 0.85,
        reason: '上下文延续: ${context.lastIntent}',
      );
    }

    // 追问模式
    if (context.lastIntent == IntentType.sceneDescription &&
        _isFollowUpQuestion(input)) {
      return IntentClassification(
        intent: IntentType.sceneDescription,
        confidence: 0.8,
        reason: '场景描述追问',
      );
    }

    return null;
  }

  /// 分类视觉相关意图
  IntentClassification? _classifyVisualIntent(String input) {
    // 按优先级排序

    // 1. 颜色识别（最具体）
    if (_containsAny(input, _colorRecognitionKeywords)) {
      return IntentClassification(
        intent: IntentType.colorRecognition,
        confidence: 0.9,
        reason: '颜色识别关键词匹配',
      );
    }

    // 2. 钞票识别
    if (_containsAny(input, _currencyRecognitionKeywords)) {
      return IntentClassification(
        intent: IntentType.currencyRecognition,
        confidence: 0.85,
        reason: '钞票识别关键词匹配',
      );
    }

    // 3. 文字识别
    if (_containsAny(input, _textRecognitionKeywords)) {
      return IntentClassification(
        intent: IntentType.textRecognition,
        confidence: 0.85,
        reason: '文字识别关键词匹配',
      );
    }

    // 4. 场景描述
    if (_containsAny(input, _sceneDescriptionKeywords)) {
      return IntentClassification(
        intent: IntentType.sceneDescription,
        confidence: 0.8,
        reason: '场景描述关键词匹配',
      );
    }

    // 5. 物体识别（最通用）
    if (_containsAny(input, _objectRecognitionKeywords)) {
      return IntentClassification(
        intent: IntentType.objectRecognition,
        confidence: 0.75,
        reason: '物体识别关键词匹配',
      );
    }

    return null;
  }

  /// 基于关键词分类
  IntentClassification _classifyByKeywords(String input) {
    final scores = <IntentType, double>{};

    // 计算各意图的匹配分数
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

    // 找出得分最高的意图
    final bestMatch = scores.entries.reduce((a, b) =>
        a.value > b.value ? a : b);

    if (bestMatch.value > 0) {
      return IntentClassification(
        intent: bestMatch.key,
        confidence: bestMatch.value.clamp(0.0, 1.0),
        reason: '关键词匹配得分: ${bestMatch.value.toStringAsFixed(2)}',
      );
    }

    return IntentClassification(
      intent: IntentType.generalChat,
      confidence: 0.0,
      reason: '无关键词匹配',
    );
  }

  /// 模糊分类
  IntentClassification _fuzzyClassify(String input) {
    // 基于语义相似度的简单实现
    // 实际项目中可以使用词向量或语义模型

    // 医疗相关
    if (input.contains('身体') ||
        input.contains('健康') ||
        input.contains('检查')) {
      return IntentClassification(
        intent: IntentType.medicalConsultation,
        confidence: 0.5,
        reason: '模糊匹配: 医疗相关',
      );
    }

    // 导航相关
    if (input.contains('去') || input.contains('到') || input.contains('找')) {
      return IntentClassification(
        intent: IntentType.navigation,
        confidence: 0.45,
        reason: '模糊匹配: 导航相关',
      );
    }

    return IntentClassification(
      intent: IntentType.generalChat,
      confidence: 0.3,
      reason: '模糊匹配失败',
    );
  }

  // ==================== 辅助方法 ====================

  /// 计算匹配分数
  double _calculateScore(String input, List<String> keywords) {
    int matchCount = 0;
    double totalScore = 0;

    for (final keyword in keywords) {
      if (input.contains(keyword.toLowerCase())) {
        matchCount++;
        // 长关键词权重更高
        totalScore += keyword.length / 10;
      }
    }

    if (matchCount == 0) return 0.0;

    // 归一化分数
    return (totalScore / keywords.length).clamp(0.0, 1.0);
  }

  /// 检查是否包含任意关键词
  bool _containsAny(String input, List<String> keywords) {
    return keywords.any((k) => input.contains(k.toLowerCase()));
  }

  /// 检查否定词
  bool _hasNegationBefore(String input, String keyword) {
    final index = input.indexOf(keyword.toLowerCase());
    if (index <= 0) return false;

    // 检查关键词前5个字符内是否有否定词
    final before = input.substring((index - 5).clamp(0, index), index);
    return _negationWords.any((n) => before.contains(n));
  }

  /// 是否是视觉意图
  bool _isVisualIntent(IntentType intent) {
    return intent == IntentType.textRecognition ||
        intent == IntentType.objectRecognition ||
        intent == IntentType.colorRecognition ||
        intent == IntentType.currencyRecognition ||
        intent == IntentType.sceneDescription;
  }

  /// 是否是延续请求
  bool _isContinuationRequest(String input) {
    final continuationKeywords = [
      '再来', '再拍', '再照', '再识别', '再看', '再读',
      'another', 'again', 'next', 'continue',
    ];
    return continuationKeywords.any((k) => input.contains(k.toLowerCase()));
  }

  /// 是否是追问
  bool _isFollowUpQuestion(String input) {
    final followUpPatterns = [
      '还有', '还有呢', '别的', '其他', '前面', '后面', '左边', '右边',
      '上面', '下面', '里面', '外面', '附近', '旁边',
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

  // ==================== 静态工具方法 ====================

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

  /// 获取意图的中文名称
  static String getIntentName(IntentType intent) {
    switch (intent) {
      case IntentType.textRecognition:
        return '文字识别';
      case IntentType.objectRecognition:
        return '物体识别';
      case IntentType.colorRecognition:
        return '颜色识别';
      case IntentType.currencyRecognition:
        return '钞票识别';
      case IntentType.translation:
        return '翻译';
      case IntentType.navigation:
        return '导航';
      case IntentType.sceneDescription:
        return '场景描述';
      case IntentType.medicineConfirmation:
        return '药品确认';
      case IntentType.medicalConsultation:
        return '医疗问诊';
      case IntentType.emotionalSupport:
        return '情感陪伴';
      case IntentType.emergency:
        return '紧急求助';
      case IntentType.generalChat:
        return '通用对话';
      case IntentType.unknown:
        return '未知意图';
    }
  }

  /// 获取意图的英文名称
  static String getIntentNameEn(IntentType intent) {
    return intent.name;
  }
}

/// 意图分类结果
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

/// 意图上下文
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
