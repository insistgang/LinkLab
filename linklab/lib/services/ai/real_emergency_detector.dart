import 'dart:async';
import 'dart:math';
import 'ai_service.dart';

/// 真实紧急关键词检测器
/// F8 紧急关键词检测的核心实现
/// 支持本地关键词库、语音情绪分析、5秒倒计时确认
class RealEmergencyDetector {
  /// 单例实例
  static final RealEmergencyDetector _instance = RealEmergencyDetector._internal();
  factory RealEmergencyDetector() => _instance;
  RealEmergencyDetector._internal();

  // ==================== 触发词库 ====================

  /// 危急级别触发词 - 立即触发SOS，无需确认
  /// 这些词汇表示生命危险或严重紧急情况
  static final List<String> _criticalKeywords = [
    // 中文危急词
    '救命', '救救我', '快救命', '要死了', '不行了', '快不行了',
    '杀人', '抢劫', '着火', '火灾', '快烧起来了',
    '心脏病发作', '心梗', '心肌梗死', '中风', '脑溢血',
    '昏迷', '晕倒了', '不省人事', '没呼吸了', '断气了',
    '大出血', '大量出血', '血流不止', '严重受伤', '重伤',
    '窒息', '喘不过气', '溺水', '快淹死了', '触电', '电到了',
    '跳楼', '自杀', '割腕', '上吊', '喝药', '中毒',
    '被人追杀', '有人要杀我', '绑架', '劫持', '恐怖袭击',
    // 英文危急词
    'help me', 'emergency', 'dying', 'heart attack', 'stroke',
    'unconscious', 'not breathing', 'severe bleeding', 'choking',
    'drowning', 'electrocuted', 'suicide', 'jumping off',
    'kidnapped', 'hostage', 'terrorist attack',
  ];

  /// 紧急级别触发词 - 5秒倒计时确认
  /// 这些词汇表示需要帮助，但需要二次确认避免误报
  static final List<String> _urgentKeywords = [
    // 中文紧急词
    '摔倒', '跌倒', '滑倒', '摔倒了', '爬不起来',
    '出血', '流血', '受伤了', '疼', '痛', '好痛', '痛死了',
    '头晕', '头很晕', '天旋地转', '站不稳', '恶心', '想吐',
    '呼吸困难', '喘不上气', '胸闷', '心慌', '心跳很快',
    '过敏', '休克', '晕厥', '眼前发黑',
    '被困', '锁住了', '出不去', '打不开门', '电梯停了',
    '迷路', '找不到路', '不知道在哪', '完全迷路了',
    '有人打我', '被打了', '被欺负', '袭击', '抢劫', '小偷',
    '危险', '有危险', '害怕', '恐慌', '快疯了', '受不了了',
    '快帮我', '快来人', '需要帮忙', '帮帮我', '求助',
    // 英文紧急词
    'fell down', 'slipped', 'can\'t get up', 'bleeding', 'hurt',
    'pain', 'dizzy', 'faint', 'breathing difficulty', 'allergy',
    'trapped', 'locked', 'lost', 'can\'t find way', 'attacked',
    'danger', 'scared', 'panic', 'help needed', 'assistance',
  ];

  /// 情绪紧急词 - 结合情绪分析使用
  /// 这些词汇表示情绪危机，需要特别关注
  static final List<String> _emotionalCrisisKeywords = [
    // 中文情绪危机词
    '不想活了', '活着没意思', '生不如死', '想死', '不想做人了',
    '绝望', '彻底绝望', '没有希望', '看不到希望', '走投无路',
    '没人帮我', '没人管我', '被抛弃了', '孤独死了', '好孤独',
    '快崩溃了', '精神崩溃', '受不了', '撑不住了', '坚持不下去了',
    '自残', '想伤害自己', '不想吃饭', '一直哭', '睡不着',
    // 英文情绪危机词
    'don\'t want to live', 'no point living', 'end it all',
    'hopeless', 'desperate', 'no one cares', 'abandoned',
    'breaking down', 'can\'t take it', 'self harm', 'cutting',
  ];

  /// 否定词 - 用于排除误触发
  static final List<String> _negationWords = [
    '没有', '不是', '别', '不要', '没', '无', '非', '勿',
    'not', 'no', 'don\'t', 'doesn\'t', 'didn\'t', 'wasn\'t',
    'isn\'t', 'aren\'t', 'won\'t', 'wouldn\'t', 'couldn\'t',
    'haven\'t', 'hasn\'t', 'never',
  ];

  /// 上下文排除词 - 表示非紧急场景
  static final List<String> _contextExclusionWords = [
    '电影', '电视剧', '小说', '故事', '新闻', '听说', '听说有人',
    '听说有', '好像', '可能', '也许', '大概', '应该',
    'movie', 'tv show', 'novel', 'story', 'news', 'heard',
    'maybe', 'probably', 'might', 'seems',
  ];

  // ==================== 情绪分析参数 ====================

  /// 情绪紧急度阈值
  static const double _emotionalUrgencyThreshold = 0.7;

  /// 语音特征参数（用于情绪分析）
  static const double _highPitchThreshold = 300; // Hz
  static const double _fastSpeechThreshold = 200; // 字/分钟
  static const double _loudVolumeThreshold = 0.8; // 归一化音量

  // ==================== 状态管理 ====================

  /// 回调函数
  EmergencyCallback? _onEmergencyDetected;
  EmergencyCallback? _onUrgentDetected;
  EmergencyCallback? _onConfirmationRequired;
  EmergencyCallback? _onEmotionalCrisis;

  /// 检测状态
  bool _isListening = false;
  Timer? _confirmationTimer;
  String? _pendingEmergencyText;
  String? _pendingTriggerWord;
  UrgencyLevel? _pendingLevel;

  /// 倒计时剩余秒数
  int _countdownSeconds = 0;

  /// 检测历史（用于分析模式）
  final List<EmergencyDetectionRecord> _detectionHistory = [];

  /// 自定义触发词
  final Map<UrgencyLevel, List<String>> _customKeywords = {
    UrgencyLevel.emergency: [],
    UrgencyLevel.urgent: [],
  };

  // ==================== 公共方法 ====================

  /// 设置回调
  void setCallbacks({
    EmergencyCallback? onEmergency,
    EmergencyCallback? onUrgent,
    EmergencyCallback? onConfirmation,
    EmergencyCallback? onEmotionalCrisis,
  }) {
    _onEmergencyDetected = onEmergency;
    _onUrgentDetected = onUrgent;
    _onConfirmationRequired = onConfirmation;
    _onEmotionalCrisis = onEmotionalCrisis;
  }

  /// 开始监听
  void startListening() {
    _isListening = true;
    _cancelConfirmation();
  }

  /// 停止监听
  void stopListening() {
    _isListening = false;
    _cancelConfirmation();
  }

  /// 检测文本
  EmergencyDetectionResult detect(String text, {VoiceFeatures? voiceFeatures}) {
    if (!_isListening) {
      return EmergencyDetectionResult(
        isEmergency: false,
        level: UrgencyLevel.normal,
      );
    }

    final lowerText = text.toLowerCase();

    // 1. 检查上下文排除（降低误报）
    if (_hasContextExclusion(lowerText)) {
      return EmergencyDetectionResult(
        isEmergency: false,
        level: UrgencyLevel.normal,
        note: '上下文排除：非紧急场景',
      );
    }

    // 2. 检查危急级别（最高优先级）
    final criticalCheck = _checkCriticalKeywords(lowerText);
    if (criticalCheck != null) {
      _recordDetection(text, criticalCheck);
      return criticalCheck;
    }

    // 3. 检查情绪危机
    final emotionalCheck = _checkEmotionalCrisis(lowerText, voiceFeatures);
    if (emotionalCheck != null) {
      _recordDetection(text, emotionalCheck);
      return emotionalCheck;
    }

    // 4. 检查紧急级别（需要确认）
    final urgentCheck = _checkUrgentKeywords(lowerText);
    if (urgentCheck != null) {
      // 检查否定词
      if (!_hasNegationBefore(lowerText, urgentCheck.triggerWord!)) {
        _startConfirmation(text, urgentCheck.triggerWord!, urgentCheck.level);
        _recordDetection(text, urgentCheck);
        return urgentCheck;
      }
    }

    // 5. 情绪分析（基于语音特征）
    if (voiceFeatures != null) {
      final emotionCheck = _analyzeVoiceEmotion(voiceFeatures);
      if (emotionCheck != null) {
        _recordDetection(text, emotionCheck);
        return emotionCheck;
      }
    }

    return EmergencyDetectionResult(
      isEmergency: false,
      level: UrgencyLevel.normal,
    );
  }

  /// 批量检测（用于ASR连续识别）
  List<EmergencyDetectionResult> detectBatch(
    List<String> texts, {
    List<VoiceFeatures>? voiceFeaturesList,
  }) {
    final results = <EmergencyDetectionResult>[];

    for (var i = 0; i < texts.length; i++) {
      final voiceFeatures =
          voiceFeaturesList != null && i < voiceFeaturesList.length
              ? voiceFeaturesList[i]
              : null;
      results.add(detect(texts[i], voiceFeatures: voiceFeatures));
    }

    return results;
  }

  /// 用户确认取消紧急状态
  void cancelEmergency() {
    _cancelConfirmation();
    _pendingEmergencyText = null;
    _pendingTriggerWord = null;
    _pendingLevel = null;
  }

  /// 用户确认触发紧急状态
  void confirmEmergency() {
    if (_pendingEmergencyText != null && _pendingLevel != null) {
      _confirmationTimer?.cancel();

      final event = EmergencyEvent(
        text: _pendingEmergencyText!,
        level: _pendingLevel!,
        timestamp: DateTime.now(),
        triggerWord: _pendingTriggerWord,
      );

      if (_pendingLevel == UrgencyLevel.emergency) {
        _onEmergencyDetected?.call(event);
      } else {
        _onUrgentDetected?.call(event);
      }

      _pendingEmergencyText = null;
      _pendingTriggerWord = null;
      _pendingLevel = null;
    }
  }

  /// 添加自定义触发词
  void addCustomKeywords(List<String> keywords, UrgencyLevel level) {
    _customKeywords[level]?.addAll(keywords);
  }

  /// 移除自定义触发词
  void removeCustomKeywords(List<String> keywords, UrgencyLevel level) {
    _customKeywords[level]?.removeWhere((k) => keywords.contains(k));
  }

  /// 清空自定义触发词
  void clearCustomKeywords(UrgencyLevel level) {
    _customKeywords[level]?.clear();
  }

  /// 获取当前确认状态
  ConfirmationStatus? get confirmationStatus {
    if (_confirmationTimer == null || _pendingEmergencyText == null) {
      return null;
    }
    return ConfirmationStatus(
      pendingText: _pendingEmergencyText!,
      triggerWord: _pendingTriggerWord,
      remainingSeconds: _countdownSeconds,
      level: _pendingLevel!,
    );
  }

  /// 获取检测历史
  List<EmergencyDetectionRecord> get detectionHistory =>
      List.unmodifiable(_detectionHistory);

  /// 清空检测历史
  void clearHistory() {
    _detectionHistory.clear();
  }

  /// 是否正在监听
  bool get isListening => _isListening;

  /// 是否正在等待确认
  bool get isWaitingConfirmation => _confirmationTimer != null;

  // ==================== 私有检测方法 ====================

  /// 检查危急关键词
  EmergencyDetectionResult? _checkCriticalKeywords(String input) {
    // 检查内置危急词
    for (final keyword in _criticalKeywords) {
      if (input.contains(keyword.toLowerCase())) {
        return EmergencyDetectionResult(
          isEmergency: true,
          level: UrgencyLevel.emergency,
          triggerWord: keyword,
          requiresConfirmation: false,
          reason: '检测到危急关键词',
        );
      }
    }

    // 检查自定义危急词
    for (final keyword in _customKeywords[UrgencyLevel.emergency] ?? []) {
      if (input.contains(keyword.toLowerCase())) {
        return EmergencyDetectionResult(
          isEmergency: true,
          level: UrgencyLevel.emergency,
          triggerWord: keyword,
          requiresConfirmation: false,
          reason: '检测到自定义危急关键词',
        );
      }
    }

    return null;
  }

  /// 检查紧急关键词
  EmergencyDetectionResult? _checkUrgentKeywords(String input) {
    // 检查内置紧急词
    for (final keyword in _urgentKeywords) {
      if (input.contains(keyword.toLowerCase())) {
        return EmergencyDetectionResult(
          isEmergency: true,
          level: UrgencyLevel.urgent,
          triggerWord: keyword,
          requiresConfirmation: true,
          confirmationSeconds: 5,
          reason: '检测到紧急关键词，需要确认',
        );
      }
    }

    // 检查自定义紧急词
    for (final keyword in _customKeywords[UrgencyLevel.urgent] ?? []) {
      if (input.contains(keyword.toLowerCase())) {
        return EmergencyDetectionResult(
          isEmergency: true,
          level: UrgencyLevel.urgent,
          triggerWord: keyword,
          requiresConfirmation: true,
          confirmationSeconds: 5,
          reason: '检测到自定义紧急关键词，需要确认',
        );
      }
    }

    return null;
  }

  /// 检查情绪危机
  EmergencyDetectionResult? _checkEmotionalCrisis(
    String input,
    VoiceFeatures? voiceFeatures,
  ) {
    // 检查情绪危机关键词
    for (final keyword in _emotionalCrisisKeywords) {
      if (input.contains(keyword.toLowerCase())) {
        // 触发情绪危机回调
        _onEmotionalCrisis?.call(EmergencyEvent(
          text: input,
          level: UrgencyLevel.urgent,
          timestamp: DateTime.now(),
          triggerWord: keyword,
        ));

        return EmergencyDetectionResult(
          isEmergency: true,
          level: UrgencyLevel.urgent,
          triggerWord: keyword,
          requiresConfirmation: true,
          confirmationSeconds: 5,
          reason: '检测到情绪危机信号',
        );
      }
    }

    return null;
  }

  /// 分析语音情绪
  EmergencyDetectionResult? _analyzeVoiceEmotion(VoiceFeatures features) {
    double urgencyScore = 0;
    final indicators = <String>[];

    // 音调分析（高音调表示紧张/恐慌）
    if (features.averagePitch > _highPitchThreshold) {
      urgencyScore += 0.3;
      indicators.add('高音调');
    }

    // 语速分析（快语速表示紧急）
    if (features.speechRate > _fastSpeechThreshold) {
      urgencyScore += 0.3;
      indicators.add('快语速');
    }

    // 音量分析（大音量表示情绪激动）
    if (features.volume > _loudVolumeThreshold) {
      urgencyScore += 0.2;
      indicators.add('大音量');
    }

    // 声音颤抖（如果可用）
    if (features.hasTremor) {
      urgencyScore += 0.2;
      indicators.add('声音颤抖');
    }

    // 综合判断
    if (urgencyScore >= _emotionalUrgencyThreshold) {
      return EmergencyDetectionResult(
        isEmergency: true,
        level: UrgencyLevel.urgent,
        requiresConfirmation: true,
        confirmationSeconds: 5,
        reason: '语音情绪分析: ${indicators.join(', ')}',
      );
    }

    return null;
  }

  // ==================== 辅助方法 ====================

  /// 检查上下文排除
  bool _hasContextExclusion(String input) {
    return _contextExclusionWords.any((word) => input.contains(word));
  }

  /// 检查否定词
  bool _hasNegationBefore(String input, String keyword) {
    final index = input.indexOf(keyword.toLowerCase());
    if (index <= 0) return false;

    // 检查关键词前10个字符内是否有否定词
    final before = input.substring((index - 10).clamp(0, index), index);
    return _negationWords.any((n) => before.contains(n));
  }

  /// 启动确认倒计时
  void _startConfirmation(String text, String triggerWord, UrgencyLevel level) {
    _cancelConfirmation();

    _pendingEmergencyText = text;
    _pendingTriggerWord = triggerWord;
    _pendingLevel = level;
    _countdownSeconds = 5;

    // 立即触发确认回调
    _onConfirmationRequired?.call(EmergencyEvent(
      text: text,
      level: level,
      timestamp: DateTime.now(),
      triggerWord: triggerWord,
      confirmationSeconds: _countdownSeconds,
    ));

    // 启动倒计时
    _confirmationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdownSeconds--;

      if (_countdownSeconds <= 0) {
        // 倒计时结束，自动触发
        timer.cancel();
        _triggerEmergency(text, level, triggerWord);
        _pendingEmergencyText = null;
        _pendingTriggerWord = null;
        _pendingLevel = null;
      }
    });
  }

  /// 取消确认
  void _cancelConfirmation() {
    _confirmationTimer?.cancel();
    _confirmationTimer = null;
    _countdownSeconds = 0;
  }

  /// 触发紧急事件
  void _triggerEmergency(String text, UrgencyLevel level, String? triggerWord) {
    final event = EmergencyEvent(
      text: text,
      level: level,
      timestamp: DateTime.now(),
      triggerWord: triggerWord,
    );

    if (level == UrgencyLevel.emergency) {
      _onEmergencyDetected?.call(event);
    } else {
      _onUrgentDetected?.call(event);
    }
  }

  /// 记录检测
  void _recordDetection(String text, EmergencyDetectionResult result) {
    _detectionHistory.add(EmergencyDetectionRecord(
      text: text,
      result: result,
      timestamp: DateTime.now(),
    ));

    // 限制历史记录数量
    if (_detectionHistory.length > 100) {
      _detectionHistory.removeAt(0);
    }
  }

  // ==================== 静态工具方法 ====================

  /// 获取所有内置触发词
  static Map<String, List<String>> getAllBuiltinKeywords() {
    return {
      'critical': _criticalKeywords,
      'urgent': _urgentKeywords,
      'emotional': _emotionalCrisisKeywords,
    };
  }

  /// 检查文本是否包含紧急关键词（静态方法）
  static bool containsEmergencyKeyword(String text) {
    final lowerText = text.toLowerCase();

    for (final keyword in _criticalKeywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        return true;
      }
    }

    for (final keyword in _urgentKeywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        return true;
      }
    }

    return false;
  }

  /// 获取紧急级别描述
  static String getUrgencyLevelDescription(UrgencyLevel level) {
    switch (level) {
      case UrgencyLevel.emergency:
        return '危急 - 立即触发SOS';
      case UrgencyLevel.urgent:
        return '紧急 - 需要确认';
      case UrgencyLevel.important:
        return '重要 - 优先处理';
      case UrgencyLevel.normal:
        return '普通 - 正常处理';
    }
  }
}

/// 紧急检测回调类型
typedef EmergencyCallback = void Function(EmergencyEvent event);

/// 紧急事件
class EmergencyEvent {
  final String text;
  final UrgencyLevel level;
  final DateTime timestamp;
  final String? triggerWord;
  final int? confirmationSeconds;

  const EmergencyEvent({
    required this.text,
    required this.level,
    required this.timestamp,
    this.triggerWord,
    this.confirmationSeconds,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'level': level.name,
      'timestamp': timestamp.toIso8601String(),
      'triggerWord': triggerWord,
      'confirmationSeconds': confirmationSeconds,
    };
  }
}

/// 紧急检测结果
class EmergencyDetectionResult {
  final bool isEmergency;
  final UrgencyLevel level;
  final String? triggerWord;
  final bool requiresConfirmation;
  final int? confirmationSeconds;
  final String? reason;
  final String? note;

  const EmergencyDetectionResult({
    required this.isEmergency,
    required this.level,
    this.triggerWord,
    this.requiresConfirmation = false,
    this.confirmationSeconds,
    this.reason,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'isEmergency': isEmergency,
      'level': level.name,
      'triggerWord': triggerWord,
      'requiresConfirmation': requiresConfirmation,
      'confirmationSeconds': confirmationSeconds,
      'reason': reason,
      'note': note,
    };
  }
}

/// 确认状态
class ConfirmationStatus {
  final String pendingText;
  final String? triggerWord;
  final int remainingSeconds;
  final UrgencyLevel level;

  const ConfirmationStatus({
    required this.pendingText,
    this.triggerWord,
    required this.remainingSeconds,
    required this.level,
  });

  double get progress => remainingSeconds / 5.0;
}

/// 语音特征（用于情绪分析）
class VoiceFeatures {
  /// 平均音调 (Hz)
  final double averagePitch;

  /// 语速 (字/分钟)
  final double speechRate;

  /// 音量 (0-1)
  final double volume;

  /// 是否有声音颤抖
  final bool hasTremor;

  /// 能量变化率（表示情绪激动程度）
  final double energyVariance;

  const VoiceFeatures({
    this.averagePitch = 0,
    this.speechRate = 0,
    this.volume = 0,
    this.hasTremor = false,
    this.energyVariance = 0,
  });

  /// 计算紧急度分数
  double calculateUrgencyScore() {
    double score = 0;

    // 音调因素
    if (averagePitch > 300) score += 0.25;

    // 语速因素
    if (speechRate > 200) score += 0.25;

    // 音量因素
    if (volume > 0.8) score += 0.2;

    // 颤抖因素
    if (hasTremor) score += 0.15;

    // 能量变化因素
    if (energyVariance > 0.5) score += 0.15;

    return score.clamp(0.0, 1.0);
  }
}

/// 检测记录
class EmergencyDetectionRecord {
  final String text;
  final EmergencyDetectionResult result;
  final DateTime timestamp;

  const EmergencyDetectionRecord({
    required this.text,
    required this.result,
    required this.timestamp,
  });
}

/// 紧急检测服务（包装为AIService接口）
class RealEmergencyDetectionService implements AIService {
  final RealEmergencyDetector _detector = RealEmergencyDetector();

  @override
  String get serviceName => 'RealEmergencyDetectionService';

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<AIResponse> process(
    String input, {
    String? imageUrl,
    DialogContext? context,
  }) async {
    final result = _detector.detect(input);

    if (!result.isEmergency) {
      return AIResponse(
        text: '未检测到紧急情况',
        intent: IntentType.generalChat,
        urgency: UrgencyLevel.normal,
        confidence: 1.0,
      );
    }

    String responseText;
    if (result.level == UrgencyLevel.emergency) {
      responseText = '检测到紧急情况"${result.triggerWord}"，正在立即启动SOS流程！';
    } else if (result.requiresConfirmation) {
      responseText = '检测到可能的紧急情况"${result.triggerWord}"，${result.confirmationSeconds}秒内未取消将自动触发SOS。';
    } else {
      responseText = '检测到紧急信号，请确认是否需要帮助。';
    }

    return AIResponse(
      text: responseText,
      intent: IntentType.emergency,
      urgency: result.level,
      needsHuman: true,
      confidence: 0.95,
      extraData: {
        'triggerWord': result.triggerWord,
        'requiresConfirmation': result.requiresConfirmation,
        'confirmationSeconds': result.confirmationSeconds,
        'reason': result.reason,
      },
    );
  }

  RealEmergencyDetector get detector => _detector;
}
