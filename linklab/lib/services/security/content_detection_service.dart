import '../../core/utils/logger.dart';
import '../../models/security/call_recording_model.dart';

/// AI內容檢測服務
/// 用於檢測通話中的違規內容
class ContentDetectionService {
  // 敏感詞庫
  static final List<String> _abuseKeywords = [
    '笨蛋', '傻瓜', '白癡', '廢物', '滾', '去死', '神經病', '垃圾',
    '蠢貨', '混蛋', '不要臉', '無恥', '賤', '操', '他媽', '傻逼',
    '腦殘', '智障', '瞎子', '瘸子', '聾子', '殘廢',
  ];

  static final List<String> _fraudKeywords = [
    '轉賬', '匯款', '銀行卡', '密碼', '驗證碼', '身份證', '打錢',
    '借錢', '投資', '理財', '返利', '中獎', '領獎', '手續費',
    '保證金', '押金', '解凍', '安全賬戶', '警察', '法院', '檢察院',
  ];

  static final List<String> _sensitiveKeywords = [
    '色情', '賭博', '毒品', '槍支', '暴力', '恐怖', '邪教', '反動',
  ];

  /// 檢測文本內容
  Future<DetectionResult> detectSpeech(String text) async {
    try {
      // 並行檢測各種類型
      final results = await Future.wait<DetectionResult>([
        detectAbuse(text),
        detectFraud(text),
        detectSensitive(text),
      ]);

      // 返回置信度最高的違規結果
      DetectionResult? highestResult;
      for (final result in results) {
        if (result.isViolation) {
          if (highestResult == null ||
              result.confidence > highestResult.confidence) {
            highestResult = result;
          }
        }
      }

      return highestResult ?? DetectionResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: DetectionType.abuse,
        confidence: 0.0,
        isViolation: false,
        detectedText: text,
      );
    } catch (e) {
      AppLogger.error('內容檢測失敗', e);
      return DetectionResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: DetectionType.abuse,
        confidence: 0.0,
        isViolation: false,
        detectedText: text,
      );
    }
  }

  /// 檢測辱罵內容
  Future<DetectionResult> detectAbuse(String text) async {
    final detectedKeywords = <String>[];
    double confidence = 0.0;

    for (final keyword in _abuseKeywords) {
      if (text.toLowerCase().contains(keyword)) {
        detectedKeywords.add(keyword);
        confidence += 0.2;
      }
    }

    // 根據關鍵詞數量和嚴重程度調整置信度
    confidence = confidence.clamp(0.0, 1.0);

    // 根據置信度確定違規級別
    ViolationLevel? level;
    if (confidence >= 0.8) {
      level = ViolationLevel.high;
    } else if (confidence >= 0.5) {
      level = ViolationLevel.medium;
    } else if (confidence >= 0.3) {
      level = ViolationLevel.low;
    }

    return DetectionResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: DetectionType.abuse,
      confidence: confidence,
      isViolation: confidence >= RecordingConfig.abuseThreshold,
      violationLevel: level,
      detectedText: text,
      matchedKeywords: detectedKeywords.join(', '),
    );
  }

  /// 檢測詐騙誘導
  Future<DetectionResult> detectFraud(String text) async {
    final detectedKeywords = <String>[];
    double confidence = 0.0;

    for (final keyword in _fraudKeywords) {
      if (text.toLowerCase().contains(keyword)) {
        detectedKeywords.add(keyword);
        confidence += 0.15;
      }
    }

    // 如果同時出現多個關鍵詞，提高置信度
    if (detectedKeywords.length >= 3) {
      confidence += 0.3;
    }

    confidence = confidence.clamp(0.0, 1.0);

    ViolationLevel? level;
    if (confidence >= 0.8) {
      level = ViolationLevel.critical;
    } else if (confidence >= 0.6) {
      level = ViolationLevel.high;
    } else if (confidence >= 0.4) {
      level = ViolationLevel.medium;
    }

    return DetectionResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: DetectionType.fraud,
      confidence: confidence,
      isViolation: confidence >= RecordingConfig.fraudThreshold,
      violationLevel: level,
      detectedText: text,
      matchedKeywords: detectedKeywords.join(', '),
    );
  }

  /// 檢測敏感內容
  Future<DetectionResult> detectSensitive(String text) async {
    final detectedKeywords = <String>[];
    double confidence = 0.0;

    for (final keyword in _sensitiveKeywords) {
      if (text.toLowerCase().contains(keyword)) {
        detectedKeywords.add(keyword);
        confidence += 0.25;
      }
    }

    confidence = confidence.clamp(0.0, 1.0);

    ViolationLevel? level;
    if (confidence >= 0.7) {
      level = ViolationLevel.critical;
    } else if (confidence >= 0.5) {
      level = ViolationLevel.high;
    }

    return DetectionResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: DetectionType.sensitive,
      confidence: confidence,
      isViolation: confidence >= RecordingConfig.sensitiveThreshold,
      violationLevel: level,
      detectedText: text,
      matchedKeywords: detectedKeywords.join(', '),
    );
  }

  /// 檢測異常行爲
  /// 根據通話時長、沉默時間等指標判斷
  Future<DetectionResult> detectAbnormalBehavior({
    required int callDurationSeconds,
    required int silenceDurationSeconds,
    required int repeatCallCount,
  }) async {
    double confidence = 0.0;
    final issues = <String>[];

    // 長時間沉默
    if (silenceDurationSeconds > 60) {
      confidence += 0.3;
      issues.add('長時間沉默');
    }

    // 重複呼叫
    if (repeatCallCount > 3) {
      confidence += 0.4;
      issues.add('頻繁重複呼叫');
    }

    // 極短通話
    if (callDurationSeconds < 10 && callDurationSeconds > 0) {
      confidence += 0.2;
      issues.add('極短通話');
    }

    confidence = confidence.clamp(0.0, 1.0);

    return DetectionResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: DetectionType.abnormal,
      confidence: confidence,
      isViolation: confidence >= 0.5,
      violationLevel: confidence >= 0.5 ? ViolationLevel.low : null,
      detectedText: issues.join(', '),
    );
  }

  /// 批量檢測
  Future<List<DetectionResult>> batchDetect(List<String> texts) async {
    final results = <DetectionResult>[];
    for (final text in texts) {
      results.add(await detectSpeech(text));
    }
    return results;
  }

  /// 獲取檢測建議
  String getDetectionAdvice(DetectionResult result) {
    if (!result.isViolation) {
      return '內容正常';
    }

    switch (result.type) {
      case DetectionType.abuse:
        return '檢測到辱罵內容，請文明交流';
      case DetectionType.fraud:
        return '警告：檢測到可疑的詐騙關鍵詞，請勿透露個人信息或轉賬';
      case DetectionType.sensitive:
        return '檢測到敏感內容，請遵守社區規範';
      case DetectionType.abnormal:
        return '檢測到異常行爲模式';
      case DetectionType.spam:
        return '檢測到垃圾信息';
    }
  }
}
