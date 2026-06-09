import 'dart:async';
import 'ai_service.dart';

/// 緊急關鍵詞檢測器
/// F8 緊急關鍵詞檢測的核心實現
/// 本地關鍵詞匹配，支持實時檢測
class EmergencyDetector {
  /// 危急級別觸發詞 - 立即觸發SOS
  static final List<String> _criticalKeywords = [
    '救命',
    'help me',
    'emergency',
    '救救我',
    '殺人',
    '搶劫',
    'robbery',
    'kill',
    'fire',
    '着火了',
    '火災',
    '心臟病發作',
    'heart attack',
    '中風',
    'stroke',
    '昏迷',
    'unconscious',
    '大出血',
    'severe bleeding',
    '窒息',
    'choking',
    '溺水',
    'drowning',
  ];

  /// 緊急級別觸發詞 - 5秒倒計時確認
  static final List<String> _urgentKeywords = [
    '摔倒',
    '跌倒',
    'fell down',
    '滑倒',
    'slipped',
    '出血',
    '流血',
    'bleeding',
    'blood',
    '疼',
    '痛',
    '好痛',
    'pain',
    'hurt',
    '頭暈',
    'dizzy',
    'faint',
    '暈',
    '呼吸困難',
    'breathing',
    '喘不上氣',
    '過敏',
    'allergy',
    '休克',
    'shock',
    '被困',
    'trapped',
    '鎖住了',
    'locked',
    '迷路',
    'lost',
    '找不到路',
    '有人打我',
    '被打了',
    '襲擊',
    'attack',
    '危險',
    'danger',
    '害怕',
    'scared',
    '恐慌',
    'panic',
  ];

  /// 情緒緊急詞 - 結合情緒分析使用
  static final List<String> _emotionalUrgencyKeywords = [
    '不想活了',
    '想死',
    '自殺',
    'suicide',
    '絕望',
    'hopeless',
    '沒人幫我',
    'help me please',
    '快瘋了',
    'going crazy',
  ];

  /// 否定詞 - 用於排除誤觸發
  static final List<String> _negationWords = [
    '沒有',
    '不是',
    '別',
    '不要',
    '沒',
    '無',
    'not',
    'no',
    'don\'t',
    'didn\'t',
    'wasn\'t',
    'isn\'t',
  ];

  /// 回調函數
  EmergencyCallback? _onEmergencyDetected;
  EmergencyCallback? _onUrgentDetected;
  EmergencyCallback? _onConfirmationRequired;

  /// 檢測狀態
  bool _isListening = false;
  Timer? _confirmationTimer;
  String? _pendingEmergencyText;

  /// 設置回調
  void setCallbacks({
    EmergencyCallback? onEmergency,
    EmergencyCallback? onUrgent,
    EmergencyCallback? onConfirmation,
  }) {
    _onEmergencyDetected = onEmergency;
    _onUrgentDetected = onUrgent;
    _onConfirmationRequired = onConfirmation;
  }

  /// 開始監聽
  void startListening() {
    _isListening = true;
  }

  /// 停止監聽
  void stopListening() {
    _isListening = false;
    _cancelConfirmation();
  }

  /// 檢測文本
  EmergencyDetectionResult detect(String text) {
    if (!_isListening) {
      return EmergencyDetectionResult(
        isEmergency: false,
        level: UrgencyLevel.normal,
      );
    }

    final lowerText = text.toLowerCase();

    // 1. 檢查是否包含否定詞（降低誤報）
    final hasNegation = _negationWords.any((word) => lowerText.contains(word));

    // 2. 檢查危急級別
    for (final keyword in _criticalKeywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        // 危急級別即使有否定詞也觸發（如"要救命"）
        _triggerEmergency(text, UrgencyLevel.emergency);
        return EmergencyDetectionResult(
          isEmergency: true,
          level: UrgencyLevel.emergency,
          triggerWord: keyword,
          requiresConfirmation: false,
        );
      }
    }

    // 3. 檢查情緒緊急詞
    for (final keyword in _emotionalUrgencyKeywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        _triggerEmergency(text, UrgencyLevel.emergency);
        return EmergencyDetectionResult(
          isEmergency: true,
          level: UrgencyLevel.emergency,
          triggerWord: keyword,
          requiresConfirmation: false,
        );
      }
    }

    // 4. 檢查緊急級別（需要確認）
    for (final keyword in _urgentKeywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        // 如果包含否定詞，降低緊急度
        if (hasNegation) {
          return EmergencyDetectionResult(
            isEmergency: false,
            level: UrgencyLevel.important,
            triggerWord: keyword,
            note: '檢測到否定詞，降低緊急度',
          );
        }

        _startConfirmation(text, keyword);
        return EmergencyDetectionResult(
          isEmergency: true,
          level: UrgencyLevel.urgent,
          triggerWord: keyword,
          requiresConfirmation: true,
          confirmationSeconds: 5,
        );
      }
    }

    return EmergencyDetectionResult(
      isEmergency: false,
      level: UrgencyLevel.normal,
    );
  }

  /// 觸發緊急事件
  void _triggerEmergency(String text, UrgencyLevel level) {
    if (level == UrgencyLevel.emergency) {
      _onEmergencyDetected?.call(EmergencyEvent(
        text: text,
        level: level,
        timestamp: DateTime.now(),
      ));
    } else {
      _onUrgentDetected?.call(EmergencyEvent(
        text: text,
        level: level,
        timestamp: DateTime.now(),
      ));
    }
  }

  /// 啓動確認倒計時
  void _startConfirmation(String text, String triggerWord) {
    _cancelConfirmation();
    _pendingEmergencyText = text;

    _onConfirmationRequired?.call(EmergencyEvent(
      text: text,
      level: UrgencyLevel.urgent,
      timestamp: DateTime.now(),
      triggerWord: triggerWord,
      confirmationSeconds: 5,
    ));

    // 5秒倒計時
    _confirmationTimer = Timer(const Duration(seconds: 5), () {
      // 用戶未取消，觸發緊急事件
      _triggerEmergency(text, UrgencyLevel.urgent);
      _pendingEmergencyText = null;
    });
  }

  /// 取消確認
  void _cancelConfirmation() {
    _confirmationTimer?.cancel();
    _confirmationTimer = null;
    _pendingEmergencyText = null;
  }

  /// 用戶確認取消緊急狀態
  void cancelEmergency() {
    _cancelConfirmation();
  }

  /// 用戶確認觸發緊急狀態
  void confirmEmergency() {
    if (_pendingEmergencyText != null) {
      _confirmationTimer?.cancel();
      _triggerEmergency(_pendingEmergencyText!, UrgencyLevel.urgent);
      _pendingEmergencyText = null;
    }
  }

  /// 獲取當前確認狀態
  ConfirmationStatus? get confirmationStatus {
    if (_confirmationTimer == null || _pendingEmergencyText == null) {
      return null;
    }
    return ConfirmationStatus(
      pendingText: _pendingEmergencyText!,
      remainingSeconds: _confirmationTimer!.isActive ? 5 : 0,
    );
  }

  /// 批量檢測（用於ASR連續識別）
  List<EmergencyDetectionResult> detectBatch(List<String> texts) {
    return texts.map((text) => detect(text)).toList();
  }

  /// 添加自定義觸發詞
  static void addCustomKeywords(List<String> keywords, UrgencyLevel level) {
    // 實際項目中可以持久化到本地存儲
    switch (level) {
      case UrgencyLevel.emergency:
        _criticalKeywords.addAll(keywords);
        break;
      case UrgencyLevel.urgent:
        _urgentKeywords.addAll(keywords);
        break;
      default:
        break;
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
}

/// 緊急檢測結果
class EmergencyDetectionResult {
  final bool isEmergency;
  final UrgencyLevel level;
  final String? triggerWord;
  final bool requiresConfirmation;
  final int? confirmationSeconds;
  final String? note;

  const EmergencyDetectionResult({
    required this.isEmergency,
    required this.level,
    this.triggerWord,
    this.requiresConfirmation = false,
    this.confirmationSeconds,
    this.note,
  });
}

/// 確認狀態
class ConfirmationStatus {
  final String pendingText;
  final int remainingSeconds;

  const ConfirmationStatus({
    required this.pendingText,
    required this.remainingSeconds,
  });
}

/// 緊急檢測服務（包裝爲AIService接口）
class EmergencyDetectionService implements AIService {
  final EmergencyDetector _detector = EmergencyDetector();

  @override
  String get serviceName => 'EmergencyDetectionService';

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
      responseText = '檢測到可能的緊急情況"${result.triggerWord}"，5秒內未取消將自動觸發SOS。';
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
      },
    );
  }

  EmergencyDetector get detector => _detector;
}
