import 'ai_service.dart';

/// 緊急度檢測器
/// 負責判斷用戶輸入的緊急程度
class UrgencyDetector {
  /// 危急級別關鍵詞
  static final List<String> _emergencyKeywords = [
    '救命', 'help', 'emergency', '救命啊', '救救我',
    '着火了', 'fire', '火災', '殺人', '搶劫', 'robbery',
    '心臟病', '心梗', '中風', '昏迷', '不省人事',
    '大出血', '大量出血', '嚴重受傷', '骨折',
    '有人打我', '被打了', '襲擊', 'attack',
  ];

  /// 緊急級別關鍵詞
  static final List<String> _urgentKeywords = [
    '快', ' urgent', ' hurry', '趕緊', '馬上',
    '摔倒', '跌倒', 'fell down', '滑倒',
    '出血', '流血', 'bleeding', 'blood',
    '疼', '痛', '好痛', 'pain', 'hurt',
    '頭暈', 'dizzy', 'faint', '暈',
    '呼吸困難', 'breathing', '喘不上氣',
    '過敏', 'allergy', '休克',
    '找不到', '迷路', 'lost', '找不到路',
    '被困', 'trapped', '鎖住了',
  ];

  /// 重要級別關鍵詞
  static final List<String> _importantKeywords = [
    '藥', '喫藥', 'medicine', 'medication',
    '醫院', 'hospital', '醫生', 'doctor',
    '不舒服', '難受', 'not feeling well',
    '擔心', 'worried', 'concerned',
    '重要', 'important', '急事',
    '需要幫忙', 'help needed', 'assistance',
  ];

  /// 情緒緊急詞（表示用戶情緒焦慮/恐慌）
  static final List<String> _emotionalUrgencyKeywords = [
    '害怕', 'scared', 'afraid', 'fear',
    '恐慌', 'panic', 'terrified',
    '焦慮', 'anxious', 'worried sick',
    '絕望', 'hopeless', 'desperate',
    '快瘋了', 'going crazy', 'can\'t take it',
  ];

  /// 檢測緊急度
  UrgencyDetectionResult detect(String input, {IntentType? intent}) {
    final lowerInput = input.toLowerCase();

    // 1. 檢查危急級別
    if (_containsAny(lowerInput, _emergencyKeywords)) {
      return UrgencyDetectionResult(
        level: UrgencyLevel.emergency,
        confidence: 0.95,
        reason: '檢測到危急關鍵詞',
      );
    }

    // 2. 檢查緊急級別
    if (_containsAny(lowerInput, _urgentKeywords)) {
      return UrgencyDetectionResult(
        level: UrgencyLevel.urgent,
        confidence: 0.85,
        reason: '檢測到緊急關鍵詞',
      );
    }

    // 3. 結合意圖判斷
    if (intent != null) {
      final intentBasedUrgency = _detectByIntent(intent, lowerInput);
      if (intentBasedUrgency != null) {
        return intentBasedUrgency;
      }
    }

    // 4. 檢查重要級別
    if (_containsAny(lowerInput, _importantKeywords)) {
      return UrgencyDetectionResult(
        level: UrgencyLevel.important,
        confidence: 0.7,
        reason: '檢測到重要關鍵詞',
      );
    }

    // 5. 檢查情緒緊急度
    if (_containsAny(lowerInput, _emotionalUrgencyKeywords)) {
      return UrgencyDetectionResult(
        level: UrgencyLevel.important,
        confidence: 0.65,
        reason: '檢測到情緒焦慮',
      );
    }

    // 默認普通級別
    return UrgencyDetectionResult(
      level: UrgencyLevel.normal,
      confidence: 0.9,
      reason: '無緊急信號',
    );
  }

  /// 基於意圖檢測緊急度
  UrgencyDetectionResult? _detectByIntent(IntentType intent, String input) {
    switch (intent) {
      case IntentType.emergency:
        return UrgencyDetectionResult(
          level: UrgencyLevel.emergency,
          confidence: 0.95,
          reason: '緊急求助意圖',
        );
      case IntentType.medicalConsultation:
        // 醫療問診根據關鍵詞進一步判斷
        if (_containsAny(input, ['疼', '痛', '出血', '摔', '暈', 'breathing'])) {
          return UrgencyDetectionResult(
            level: UrgencyLevel.urgent,
            confidence: 0.8,
            reason: '醫療症狀緊急',
          );
        }
        return UrgencyDetectionResult(
          level: UrgencyLevel.important,
          confidence: 0.7,
          reason: '醫療諮詢',
        );
      case IntentType.medicineConfirmation:
        return UrgencyDetectionResult(
          level: UrgencyLevel.important,
          confidence: 0.75,
          reason: '藥品確認',
        );
      case IntentType.navigation:
        // 導航場景如果包含"迷路"等詞則提升緊急度
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

  /// 檢查是否包含任意關鍵詞
  bool _containsAny(String input, List<String> keywords) {
    for (final keyword in keywords) {
      if (input.contains(keyword.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  /// 是否需要立即觸發SOS
  static bool shouldTriggerSOS(UrgencyLevel level) {
    return level == UrgencyLevel.emergency;
  }

  /// 是否需要快速響應（優先處理）
  static bool needsPriorityResponse(UrgencyLevel level) {
    return level == UrgencyLevel.emergency ||
        level == UrgencyLevel.urgent;
  }
}

/// 緊急度檢測結果
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
