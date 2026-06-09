import 'dart:async';
import 'dart:math';
import 'ai_service.dart';

/// 真實緊急關鍵詞檢測器
/// F8 緊急關鍵詞檢測的核心實現
/// 支持本地關鍵詞庫、語音情緒分析、5秒倒計時確認
class RealEmergencyDetector {
  /// 單例實例
  static final RealEmergencyDetector _instance = RealEmergencyDetector._internal();
  factory RealEmergencyDetector() => _instance;
  RealEmergencyDetector._internal();

  // ==================== 觸發詞庫 ====================

  /// 危急級別觸發詞 - 立即觸發SOS，無需確認
  /// 這些詞彙表示生命危險或嚴重緊急情況
  static final List<String> _criticalKeywords = [
    // 中文危急詞
    '救命', '救救我', '快救命', '要死了', '不行了', '快不行了',
    '殺人', '搶劫', '着火', '火災', '快燒起來了',
    '心臟病發作', '心梗', '心肌梗死', '中風', '腦溢血',
    '昏迷', '暈倒了', '不省人事', '沒呼吸了', '斷氣了',
    '大出血', '大量出血', '血流不止', '嚴重受傷', '重傷',
    '窒息', '喘不過氣', '溺水', '快淹死了', '觸電', '電到了',
    '跳樓', '自殺', '割腕', '上吊', '喝藥', '中毒',
    '被人追殺', '有人要殺我', '綁架', '劫持', '恐怖襲擊',
    // 英文危急詞
    'help me', 'emergency', 'dying', 'heart attack', 'stroke',
    'unconscious', 'not breathing', 'severe bleeding', 'choking',
    'drowning', 'electrocuted', 'suicide', 'jumping off',
    'kidnapped', 'hostage', 'terrorist attack',
  ];

  /// 緊急級別觸發詞 - 5秒倒計時確認
  /// 這些詞彙表示需要幫助，但需要二次確認避免誤報
  static final List<String> _urgentKeywords = [
    // 中文緊急詞
    '摔倒', '跌倒', '滑倒', '摔倒了', '爬不起來',
    '出血', '流血', '受傷了', '疼', '痛', '好痛', '痛死了',
    '頭暈', '頭很暈', '天旋地轉', '站不穩', '噁心', '想吐',
    '呼吸困難', '喘不上氣', '胸悶', '心慌', '心跳很快',
    '過敏', '休克', '暈厥', '眼前發黑',
    '被困', '鎖住了', '出不去', '打不開門', '電梯停了',
    '迷路', '找不到路', '不知道在哪', '完全迷路了',
    '有人打我', '被打了', '被欺負', '襲擊', '搶劫', '小偷',
    '危險', '有危險', '害怕', '恐慌', '快瘋了', '受不了了',
    '快幫我', '快來人', '需要幫忙', '幫幫我', '求助',
    // 英文緊急詞
    'fell down', 'slipped', 'can\'t get up', 'bleeding', 'hurt',
    'pain', 'dizzy', 'faint', 'breathing difficulty', 'allergy',
    'trapped', 'locked', 'lost', 'can\'t find way', 'attacked',
    'danger', 'scared', 'panic', 'help needed', 'assistance',
  ];

  /// 情緒緊急詞 - 結合情緒分析使用
  /// 這些詞彙表示情緒危機，需要特別關注
  static final List<String> _emotionalCrisisKeywords = [
    // 中文情緒危機詞
    '不想活了', '活着沒意思', '生不如死', '想死', '不想做人了',
    '絕望', '徹底絕望', '沒有希望', '看不到希望', '走投無路',
    '沒人幫我', '沒人管我', '被拋棄了', '孤獨死了', '好孤獨',
    '快崩潰了', '精神崩潰', '受不了', '撐不住了', '堅持不下去了',
    '自殘', '想傷害自己', '不想喫飯', '一直哭', '睡不着',
    // 英文情緒危機詞
    'don\'t want to live', 'no point living', 'end it all',
    'hopeless', 'desperate', 'no one cares', 'abandoned',
    'breaking down', 'can\'t take it', 'self harm', 'cutting',
  ];

  /// 否定詞 - 用於排除誤觸發
  static final List<String> _negationWords = [
    '沒有', '不是', '別', '不要', '沒', '無', '非', '勿',
    'not', 'no', 'don\'t', 'doesn\'t', 'didn\'t', 'wasn\'t',
    'isn\'t', 'aren\'t', 'won\'t', 'wouldn\'t', 'couldn\'t',
    'haven\'t', 'hasn\'t', 'never',
  ];

  /// 上下文排除詞 - 表示非緊急場景
  static final List<String> _contextExclusionWords = [
    '電影', '電視劇', '小說', '故事', '新聞', '聽說', '聽說有人',
    '聽說有', '好像', '可能', '也許', '大概', '應該',
    'movie', 'tv show', 'novel', 'story', 'news', 'heard',
    'maybe', 'probably', 'might', 'seems',
  ];

  // ==================== 情緒分析參數 ====================

  /// 情緒緊急度閾值
  static const double _emotionalUrgencyThreshold = 0.7;

  /// 語音特徵參數（用於情緒分析）
  static const double _highPitchThreshold = 300; // Hz
  static const double _fastSpeechThreshold = 200; // 字/分鐘
  static const double _loudVolumeThreshold = 0.8; // 歸一化音量

  // ==================== 狀態管理 ====================

  /// 回調函數
  EmergencyCallback? _onEmergencyDetected;
  EmergencyCallback? _onUrgentDetected;
  EmergencyCallback? _onConfirmationRequired;
  EmergencyCallback? _onEmotionalCrisis;

  /// 檢測狀態
  bool _isListening = false;
  Timer? _confirmationTimer;
  String? _pendingEmergencyText;
  String? _pendingTriggerWord;
  UrgencyLevel? _pendingLevel;

  /// 倒計時剩餘秒數
  int _countdownSeconds = 0;

  /// 檢測歷史（用於分析模式）
  final List<EmergencyDetectionRecord> _detectionHistory = [];

  /// 自定義觸發詞
  final Map<UrgencyLevel, List<String>> _customKeywords = {
    UrgencyLevel.emergency: [],
    UrgencyLevel.urgent: [],
  };

  // ==================== 公共方法 ====================

  /// 設置回調
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

  /// 開始監聽
  void startListening() {
    _isListening = true;
    _cancelConfirmation();
  }

  /// 停止監聽
  void stopListening() {
    _isListening = false;
    _cancelConfirmation();
  }

  /// 檢測文本
  EmergencyDetectionResult detect(String text, {VoiceFeatures? voiceFeatures}) {
    if (!_isListening) {
      return EmergencyDetectionResult(
        isEmergency: false,
        level: UrgencyLevel.normal,
      );
    }

    final lowerText = text.toLowerCase();

    // 1. 檢查上下文排除（降低誤報）
    if (_hasContextExclusion(lowerText)) {
      return EmergencyDetectionResult(
        isEmergency: false,
        level: UrgencyLevel.normal,
        note: '上下文排除：非緊急場景',
      );
    }

    // 2. 檢查危急級別（最高優先級）
    final criticalCheck = _checkCriticalKeywords(lowerText);
    if (criticalCheck != null) {
      _recordDetection(text, criticalCheck);
      return criticalCheck;
    }

    // 3. 檢查情緒危機
    final emotionalCheck = _checkEmotionalCrisis(lowerText, voiceFeatures);
    if (emotionalCheck != null) {
      _recordDetection(text, emotionalCheck);
      return emotionalCheck;
    }

    // 4. 檢查緊急級別（需要確認）
    final urgentCheck = _checkUrgentKeywords(lowerText);
    if (urgentCheck != null) {
      // 檢查否定詞
      if (!_hasNegationBefore(lowerText, urgentCheck.triggerWord!)) {
        _startConfirmation(text, urgentCheck.triggerWord!, urgentCheck.level);
        _recordDetection(text, urgentCheck);
        return urgentCheck;
      }
    }

    // 5. 情緒分析（基於語音特徵）
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

  /// 批量檢測（用於ASR連續識別）
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

  /// 用戶確認取消緊急狀態
  void cancelEmergency() {
    _cancelConfirmation();
    _pendingEmergencyText = null;
    _pendingTriggerWord = null;
    _pendingLevel = null;
  }

  /// 用戶確認觸發緊急狀態
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

  /// 添加自定義觸發詞
  void addCustomKeywords(List<String> keywords, UrgencyLevel level) {
    _customKeywords[level]?.addAll(keywords);
  }

  /// 移除自定義觸發詞
  void removeCustomKeywords(List<String> keywords, UrgencyLevel level) {
    _customKeywords[level]?.removeWhere((k) => keywords.contains(k));
  }

  /// 清空自定義觸發詞
  void clearCustomKeywords(UrgencyLevel level) {
    _customKeywords[level]?.clear();
  }

  /// 獲取當前確認狀態
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

  /// 獲取檢測歷史
  List<EmergencyDetectionRecord> get detectionHistory =>
      List.unmodifiable(_detectionHistory);

  /// 清空檢測歷史
  void clearHistory() {
    _detectionHistory.clear();
  }

  /// 是否正在監聽
  bool get isListening => _isListening;

  /// 是否正在等待確認
  bool get isWaitingConfirmation => _confirmationTimer != null;

  // ==================== 私有檢測方法 ====================

  /// 檢查危急關鍵詞
  EmergencyDetectionResult? _checkCriticalKeywords(String input) {
    // 檢查內置危急詞
    for (final keyword in _criticalKeywords) {
      if (input.contains(keyword.toLowerCase())) {
        return EmergencyDetectionResult(
          isEmergency: true,
          level: UrgencyLevel.emergency,
          triggerWord: keyword,
          requiresConfirmation: false,
          reason: '檢測到危急關鍵詞',
        );
      }
    }

    // 檢查自定義危急詞
    for (final keyword in _customKeywords[UrgencyLevel.emergency] ?? []) {
      if (input.contains(keyword.toLowerCase())) {
        return EmergencyDetectionResult(
          isEmergency: true,
          level: UrgencyLevel.emergency,
          triggerWord: keyword,
          requiresConfirmation: false,
          reason: '檢測到自定義危急關鍵詞',
        );
      }
    }

    return null;
  }

  /// 檢查緊急關鍵詞
  EmergencyDetectionResult? _checkUrgentKeywords(String input) {
    // 檢查內置緊急詞
    for (final keyword in _urgentKeywords) {
      if (input.contains(keyword.toLowerCase())) {
        return EmergencyDetectionResult(
          isEmergency: true,
          level: UrgencyLevel.urgent,
          triggerWord: keyword,
          requiresConfirmation: true,
          confirmationSeconds: 5,
          reason: '檢測到緊急關鍵詞，需要確認',
        );
      }
    }

    // 檢查自定義緊急詞
    for (final keyword in _customKeywords[UrgencyLevel.urgent] ?? []) {
      if (input.contains(keyword.toLowerCase())) {
        return EmergencyDetectionResult(
          isEmergency: true,
          level: UrgencyLevel.urgent,
          triggerWord: keyword,
          requiresConfirmation: true,
          confirmationSeconds: 5,
          reason: '檢測到自定義緊急關鍵詞，需要確認',
        );
      }
    }

    return null;
  }

  /// 檢查情緒危機
  EmergencyDetectionResult? _checkEmotionalCrisis(
    String input,
    VoiceFeatures? voiceFeatures,
  ) {
    // 檢查情緒危機關鍵詞
    for (final keyword in _emotionalCrisisKeywords) {
      if (input.contains(keyword.toLowerCase())) {
        // 觸發情緒危機回調
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
          reason: '檢測到情緒危機信號',
        );
      }
    }

    return null;
  }

  /// 分析語音情緒
  EmergencyDetectionResult? _analyzeVoiceEmotion(VoiceFeatures features) {
    double urgencyScore = 0;
    final indicators = <String>[];

    // 音調分析（高音調錶示緊張/恐慌）
    if (features.averagePitch > _highPitchThreshold) {
      urgencyScore += 0.3;
      indicators.add('高音調');
    }

    // 語速分析（快語速表示緊急）
    if (features.speechRate > _fastSpeechThreshold) {
      urgencyScore += 0.3;
      indicators.add('快語速');
    }

    // 音量分析（大音量表示情緒激動）
    if (features.volume > _loudVolumeThreshold) {
      urgencyScore += 0.2;
      indicators.add('大音量');
    }

    // 聲音顫抖（如果可用）
    if (features.hasTremor) {
      urgencyScore += 0.2;
      indicators.add('聲音顫抖');
    }

    // 綜合判斷
    if (urgencyScore >= _emotionalUrgencyThreshold) {
      return EmergencyDetectionResult(
        isEmergency: true,
        level: UrgencyLevel.urgent,
        requiresConfirmation: true,
        confirmationSeconds: 5,
        reason: '語音情緒分析: ${indicators.join(', ')}',
      );
    }

    return null;
  }

  // ==================== 輔助方法 ====================

  /// 檢查上下文排除
  bool _hasContextExclusion(String input) {
    return _contextExclusionWords.any((word) => input.contains(word));
  }

  /// 檢查否定詞
  bool _hasNegationBefore(String input, String keyword) {
    final index = input.indexOf(keyword.toLowerCase());
    if (index <= 0) return false;

    // 檢查關鍵詞前10個字符內是否有否定詞
    final before = input.substring((index - 10).clamp(0, index), index);
    return _negationWords.any((n) => before.contains(n));
  }

  /// 啓動確認倒計時
  void _startConfirmation(String text, String triggerWord, UrgencyLevel level) {
    _cancelConfirmation();

    _pendingEmergencyText = text;
    _pendingTriggerWord = triggerWord;
    _pendingLevel = level;
    _countdownSeconds = 5;

    // 立即觸發確認回調
    _onConfirmationRequired?.call(EmergencyEvent(
      text: text,
      level: level,
      timestamp: DateTime.now(),
      triggerWord: triggerWord,
      confirmationSeconds: _countdownSeconds,
    ));

    // 啓動倒計時
    _confirmationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdownSeconds--;

      if (_countdownSeconds <= 0) {
        // 倒計時結束，自動觸發
        timer.cancel();
        _triggerEmergency(text, level, triggerWord);
        _pendingEmergencyText = null;
        _pendingTriggerWord = null;
        _pendingLevel = null;
      }
    });
  }

  /// 取消確認
  void _cancelConfirmation() {
    _confirmationTimer?.cancel();
    _confirmationTimer = null;
    _countdownSeconds = 0;
  }

  /// 觸發緊急事件
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

  /// 記錄檢測
  void _recordDetection(String text, EmergencyDetectionResult result) {
    _detectionHistory.add(EmergencyDetectionRecord(
      text: text,
      result: result,
      timestamp: DateTime.now(),
    ));

    // 限制歷史記錄數量
    if (_detectionHistory.length > 100) {
      _detectionHistory.removeAt(0);
    }
  }

  // ==================== 靜態工具方法 ====================

  /// 獲取所有內置觸發詞
  static Map<String, List<String>> getAllBuiltinKeywords() {
    return {
      'critical': _criticalKeywords,
      'urgent': _urgentKeywords,
      'emotional': _emotionalCrisisKeywords,
    };
  }

  /// 檢查文本是否包含緊急關鍵詞（靜態方法）
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

  /// 獲取緊急級別描述
  static String getUrgencyLevelDescription(UrgencyLevel level) {
    switch (level) {
      case UrgencyLevel.emergency:
        return '危急 - 立即觸發SOS';
      case UrgencyLevel.urgent:
        return '緊急 - 需要確認';
      case UrgencyLevel.important:
        return '重要 - 優先處理';
      case UrgencyLevel.normal:
        return '普通 - 正常處理';
    }
  }
}

/// 緊急檢測回調類型
typedef EmergencyCallback = void Function(EmergencyEvent event);

/// 緊急事件
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

/// 緊急檢測結果
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

/// 確認狀態
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

/// 語音特徵（用於情緒分析）
class VoiceFeatures {
  /// 平均音調 (Hz)
  final double averagePitch;

  /// 語速 (字/分鐘)
  final double speechRate;

  /// 音量 (0-1)
  final double volume;

  /// 是否有聲音顫抖
  final bool hasTremor;

  /// 能量變化率（表示情緒激動程度）
  final double energyVariance;

  const VoiceFeatures({
    this.averagePitch = 0,
    this.speechRate = 0,
    this.volume = 0,
    this.hasTremor = false,
    this.energyVariance = 0,
  });

  /// 計算緊急度分數
  double calculateUrgencyScore() {
    double score = 0;

    // 音調因素
    if (averagePitch > 300) score += 0.25;

    // 語速因素
    if (speechRate > 200) score += 0.25;

    // 音量因素
    if (volume > 0.8) score += 0.2;

    // 顫抖因素
    if (hasTremor) score += 0.15;

    // 能量變化因素
    if (energyVariance > 0.5) score += 0.15;

    return score.clamp(0.0, 1.0);
  }
}

/// 檢測記錄
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

/// 緊急檢測服務（包裝爲AIService接口）
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
        text: '未檢測到緊急情況',
        intent: IntentType.generalChat,
        urgency: UrgencyLevel.normal,
        confidence: 1.0,
      );
    }

    String responseText;
    if (result.level == UrgencyLevel.emergency) {
      responseText = '檢測到緊急情況"${result.triggerWord}"，正在立即啓動SOS流程！';
    } else if (result.requiresConfirmation) {
      responseText = '檢測到可能的緊急情況"${result.triggerWord}"，${result.confirmationSeconds}秒內未取消將自動觸發SOS。';
    } else {
      responseText = '檢測到緊急信號，請確認是否需要幫助。';
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
