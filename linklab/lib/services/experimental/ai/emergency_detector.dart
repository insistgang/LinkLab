import 'dart:async';
import 'ai_service.dart';

/// 紧急关键词检测器
/// F8 紧急关键词检测的核心实现
/// 本地关键词匹配，支持实时检测
class EmergencyDetector {
  /// 危急级别触发词 - 立即触发SOS
  static final List<String> _criticalKeywords = [
    '救命',
    'help me',
    'emergency',
    '救救我',
    '杀人',
    '抢劫',
    'robbery',
    'kill',
    'fire',
    '着火了',
    '火灾',
    '心脏病发作',
    'heart attack',
    '中风',
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

  /// 紧急级别触发词 - 5秒倒计时确认
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
    '头晕',
    'dizzy',
    'faint',
    '晕',
    '呼吸困难',
    'breathing',
    '喘不上气',
    '过敏',
    'allergy',
    '休克',
    'shock',
    '被困',
    'trapped',
    '锁住了',
    'locked',
    '迷路',
    'lost',
    '找不到路',
    '有人打我',
    '被打了',
    '袭击',
    'attack',
    '危险',
    'danger',
    '害怕',
    'scared',
    '恐慌',
    'panic',
  ];

  /// 情绪紧急词 - 结合情绪分析使用
  static final List<String> _emotionalUrgencyKeywords = [
    '不想活了',
    '想死',
    '自杀',
    'suicide',
    '绝望',
    'hopeless',
    '没人帮我',
    'help me please',
    '快疯了',
    'going crazy',
  ];

  /// 否定词 - 用于排除误触发
  static final List<String> _negationWords = [
    '没有',
    '不是',
    '别',
    '不要',
    '没',
    '无',
    'not',
    'no',
    'don\'t',
    'didn\'t',
    'wasn\'t',
    'isn\'t',
  ];

  /// 回调函数
  EmergencyCallback? _onEmergencyDetected;
  EmergencyCallback? _onUrgentDetected;
  EmergencyCallback? _onConfirmationRequired;

  /// 检测状态
  bool _isListening = false;
  Timer? _confirmationTimer;
  String? _pendingEmergencyText;

  /// 设置回调
  void setCallbacks({
    EmergencyCallback? onEmergency,
    EmergencyCallback? onUrgent,
    EmergencyCallback? onConfirmation,
  }) {
    _onEmergencyDetected = onEmergency;
    _onUrgentDetected = onUrgent;
    _onConfirmationRequired = onConfirmation;
  }

  /// 开始监听
  void startListening() {
    _isListening = true;
  }

  /// 停止监听
  void stopListening() {
    _isListening = false;
    _cancelConfirmation();
  }

  /// 检测文本
  EmergencyDetectionResult detect(String text) {
    if (!_isListening) {
      return EmergencyDetectionResult(
        isEmergency: false,
        level: UrgencyLevel.normal,
      );
    }

    final lowerText = text.toLowerCase();

    // 1. 检查是否包含否定词（降低误报）
    final hasNegation = _negationWords.any((word) => lowerText.contains(word));

    // 2. 检查危急级别
    for (final keyword in _criticalKeywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        // 危急级别即使有否定词也触发（如"要救命"）
        _triggerEmergency(text, UrgencyLevel.emergency);
        return EmergencyDetectionResult(
          isEmergency: true,
          level: UrgencyLevel.emergency,
          triggerWord: keyword,
          requiresConfirmation: false,
        );
      }
    }

    // 3. 检查情绪紧急词
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

    // 4. 检查紧急级别（需要确认）
    for (final keyword in _urgentKeywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        // 如果包含否定词，降低紧急度
        if (hasNegation) {
          return EmergencyDetectionResult(
            isEmergency: false,
            level: UrgencyLevel.important,
            triggerWord: keyword,
            note: '检测到否定词，降低紧急度',
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

  /// 触发紧急事件
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

  /// 启动确认倒计时
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

    // 5秒倒计时
    _confirmationTimer = Timer(const Duration(seconds: 5), () {
      // 用户未取消，触发紧急事件
      _triggerEmergency(text, UrgencyLevel.urgent);
      _pendingEmergencyText = null;
    });
  }

  /// 取消确认
  void _cancelConfirmation() {
    _confirmationTimer?.cancel();
    _confirmationTimer = null;
    _pendingEmergencyText = null;
  }

  /// 用户确认取消紧急状态
  void cancelEmergency() {
    _cancelConfirmation();
  }

  /// 用户确认触发紧急状态
  void confirmEmergency() {
    if (_pendingEmergencyText != null) {
      _confirmationTimer?.cancel();
      _triggerEmergency(_pendingEmergencyText!, UrgencyLevel.urgent);
      _pendingEmergencyText = null;
    }
  }

  /// 获取当前确认状态
  ConfirmationStatus? get confirmationStatus {
    if (_confirmationTimer == null || _pendingEmergencyText == null) {
      return null;
    }
    return ConfirmationStatus(
      pendingText: _pendingEmergencyText!,
      remainingSeconds: _confirmationTimer!.isActive ? 5 : 0,
    );
  }

  /// 批量检测（用于ASR连续识别）
  List<EmergencyDetectionResult> detectBatch(List<String> texts) {
    return texts.map((text) => detect(text)).toList();
  }

  /// 添加自定义触发词
  static void addCustomKeywords(List<String> keywords, UrgencyLevel level) {
    // 实际项目中可以持久化到本地存储
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
}

/// 紧急检测结果
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

/// 确认状态
class ConfirmationStatus {
  final String pendingText;
  final int remainingSeconds;

  const ConfirmationStatus({
    required this.pendingText,
    required this.remainingSeconds,
  });
}

/// 紧急检测服务（包装为AIService接口）
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
      responseText = '检测到可能的紧急情况"${result.triggerWord}"，5秒内未取消将自动触发SOS。';
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
      },
    );
  }

  EmergencyDetector get detector => _detector;
}
