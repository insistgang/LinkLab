import 'ai_service.dart';

/// 紧急度检测器
/// 负责判断用户输入的紧急程度
class UrgencyDetector {
  /// 危急级别关键词
  static final List<String> _emergencyKeywords = [
    '救命', 'help', 'emergency', '救命啊', '救救我',
    '着火了', 'fire', '火灾', '杀人', '抢劫', 'robbery',
    '心脏病', '心梗', '中风', '昏迷', '不省人事',
    '大出血', '大量出血', '严重受伤', '骨折',
    '有人打我', '被打了', '袭击', 'attack',
  ];

  /// 紧急级别关键词
  static final List<String> _urgentKeywords = [
    '快', ' urgent', ' hurry', '赶紧', '马上',
    '摔倒', '跌倒', 'fell down', '滑倒',
    '出血', '流血', 'bleeding', 'blood',
    '疼', '痛', '好痛', 'pain', 'hurt',
    '头晕', 'dizzy', 'faint', '晕',
    '呼吸困难', 'breathing', '喘不上气',
    '过敏', 'allergy', '休克',
    '找不到', '迷路', 'lost', '找不到路',
    '被困', 'trapped', '锁住了',
  ];

  /// 重要级别关键词
  static final List<String> _importantKeywords = [
    '药', '吃药', 'medicine', 'medication',
    '医院', 'hospital', '医生', 'doctor',
    '不舒服', '难受', 'not feeling well',
    '担心', 'worried', 'concerned',
    '重要', 'important', '急事',
    '需要帮忙', 'help needed', 'assistance',
  ];

  /// 情绪紧急词（表示用户情绪焦虑/恐慌）
  static final List<String> _emotionalUrgencyKeywords = [
    '害怕', 'scared', 'afraid', 'fear',
    '恐慌', 'panic', 'terrified',
    '焦虑', 'anxious', 'worried sick',
    '绝望', 'hopeless', 'desperate',
    '快疯了', 'going crazy', 'can\'t take it',
  ];

  /// 检测紧急度
  UrgencyDetectionResult detect(String input, {IntentType? intent}) {
    final lowerInput = input.toLowerCase();

    // 1. 检查危急级别
    if (_containsAny(lowerInput, _emergencyKeywords)) {
      return UrgencyDetectionResult(
        level: UrgencyLevel.emergency,
        confidence: 0.95,
        reason: '检测到危急关键词',
      );
    }

    // 2. 检查紧急级别
    if (_containsAny(lowerInput, _urgentKeywords)) {
      return UrgencyDetectionResult(
        level: UrgencyLevel.urgent,
        confidence: 0.85,
        reason: '检测到紧急关键词',
      );
    }

    // 3. 结合意图判断
    if (intent != null) {
      final intentBasedUrgency = _detectByIntent(intent, lowerInput);
      if (intentBasedUrgency != null) {
        return intentBasedUrgency;
      }
    }

    // 4. 检查重要级别
    if (_containsAny(lowerInput, _importantKeywords)) {
      return UrgencyDetectionResult(
        level: UrgencyLevel.important,
        confidence: 0.7,
        reason: '检测到重要关键词',
      );
    }

    // 5. 检查情绪紧急度
    if (_containsAny(lowerInput, _emotionalUrgencyKeywords)) {
      return UrgencyDetectionResult(
        level: UrgencyLevel.important,
        confidence: 0.65,
        reason: '检测到情绪焦虑',
      );
    }

    // 默认普通级别
    return UrgencyDetectionResult(
      level: UrgencyLevel.normal,
      confidence: 0.9,
      reason: '无紧急信号',
    );
  }

  /// 基于意图检测紧急度
  UrgencyDetectionResult? _detectByIntent(IntentType intent, String input) {
    switch (intent) {
      case IntentType.emergency:
        return UrgencyDetectionResult(
          level: UrgencyLevel.emergency,
          confidence: 0.95,
          reason: '紧急求助意图',
        );
      case IntentType.medicalConsultation:
        // 医疗问诊根据关键词进一步判断
        if (_containsAny(input, ['疼', '痛', '出血', '摔', '晕', 'breathing'])) {
          return UrgencyDetectionResult(
            level: UrgencyLevel.urgent,
            confidence: 0.8,
            reason: '医疗症状紧急',
          );
        }
        return UrgencyDetectionResult(
          level: UrgencyLevel.important,
          confidence: 0.7,
          reason: '医疗咨询',
        );
      case IntentType.medicineConfirmation:
        return UrgencyDetectionResult(
          level: UrgencyLevel.important,
          confidence: 0.75,
          reason: '药品确认',
        );
      case IntentType.navigation:
        // 导航场景如果包含"迷路"等词则提升紧急度
        if (_containsAny(input, ['迷路', 'lost', '找不到', '困'])) {
          return UrgencyDetectionResult(
            level: UrgencyLevel.urgent,
            confidence: 0.7,
            reason: '迷路求助',
          );
        }
        return null;
      default:
        return null;
    }
  }

  /// 检查是否包含任意关键词
  bool _containsAny(String input, List<String> keywords) {
    for (final keyword in keywords) {
      if (input.contains(keyword.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  /// 是否需要立即触发SOS
  static bool shouldTriggerSOS(UrgencyLevel level) {
    return level == UrgencyLevel.emergency;
  }

  /// 是否需要快速响应（优先处理）
  static bool needsPriorityResponse(UrgencyLevel level) {
    return level == UrgencyLevel.emergency ||
        level == UrgencyLevel.urgent;
  }
}

/// 紧急度检测结果
class UrgencyDetectionResult {
  final UrgencyLevel level;
  final double confidence;
  final String reason;

  const UrgencyDetectionResult({
    required this.level,
    required this.confidence,
    required this.reason,
  });
}
