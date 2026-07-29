import '../../core/utils/logger.dart';
import '../../models/security/call_recording_model.dart';

/// AI内容检测服务
/// 用于检测通话中的违规内容
class ContentDetectionService {
  // 敏感词库
  static final List<String> _abuseKeywords = [
    '笨蛋', '傻瓜', '白痴', '废物', '滚', '去死', '神经病', '垃圾',
    '蠢货', '混蛋', '不要脸', '无耻', '贱', '操', '他妈', '傻逼',
    '脑残', '智障', '瞎子', '瘸子', '聋子', '残废',
  ];

  static final List<String> _fraudKeywords = [
    '转账', '汇款', '银行卡', '密码', '验证码', '身份证', '打钱',
    '借钱', '投资', '理财', '返利', '中奖', '领奖', '手续费',
    '保证金', '押金', '解冻', '安全账户', '警察', '法院', '检察院',
  ];

  static final List<String> _sensitiveKeywords = [
    '色情', '赌博', '毒品', '枪支', '暴力', '恐怖', '邪教', '反动',
  ];

  /// 检测文本内容
  Future<DetectionResult> detectSpeech(String text) async {
    try {
      // 并行检测各种类型
      final results = await Future.wait<DetectionResult>([
        detectAbuse(text),
        detectFraud(text),
        detectSensitive(text),
      ]);

      // 返回置信度最高的违规结果
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
      AppLogger.error('内容检测失败', e);
      return DetectionResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: DetectionType.abuse,
        confidence: 0.0,
        isViolation: false,
        detectedText: text,
      );
    }
  }

  /// 检测辱骂内容
  Future<DetectionResult> detectAbuse(String text) async {
    final detectedKeywords = <String>[];
    double confidence = 0.0;

    for (final keyword in _abuseKeywords) {
      if (text.toLowerCase().contains(keyword)) {
        detectedKeywords.add(keyword);
        confidence += 0.2;
      }
    }

    // 根据关键词数量和严重程度调整置信度
    confidence = confidence.clamp(0.0, 1.0);

    // 根据置信度确定违规级别
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

  /// 检测诈骗诱导
  Future<DetectionResult> detectFraud(String text) async {
    final detectedKeywords = <String>[];
    double confidence = 0.0;

    for (final keyword in _fraudKeywords) {
      if (text.toLowerCase().contains(keyword)) {
        detectedKeywords.add(keyword);
        confidence += 0.15;
      }
    }

    // 如果同时出现多个关键词，提高置信度
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

  /// 检测敏感内容
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

  /// 检测异常行为
  /// 根据通话时长、沉默时间等指标判断
  Future<DetectionResult> detectAbnormalBehavior({
    required int callDurationSeconds,
    required int silenceDurationSeconds,
    required int repeatCallCount,
  }) async {
    double confidence = 0.0;
    final issues = <String>[];

    // 长时间沉默
    if (silenceDurationSeconds > 60) {
      confidence += 0.3;
      issues.add('长时间沉默');
    }

    // 重复呼叫
    if (repeatCallCount > 3) {
      confidence += 0.4;
      issues.add('频繁重复呼叫');
    }

    // 极短通话
    if (callDurationSeconds < 10 && callDurationSeconds > 0) {
      confidence += 0.2;
      issues.add('极短通话');
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

  /// 批量检测
  Future<List<DetectionResult>> batchDetect(List<String> texts) async {
    final results = <DetectionResult>[];
    for (final text in texts) {
      results.add(await detectSpeech(text));
    }
    return results;
  }

  /// 获取检测建议
  String getDetectionAdvice(DetectionResult result) {
    if (!result.isViolation) {
      return '内容正常';
    }

    switch (result.type) {
      case DetectionType.abuse:
        return '检测到辱骂内容，请文明交流';
      case DetectionType.fraud:
        return '警告：检测到可疑的诈骗关键词，请勿透露个人信息或转账';
      case DetectionType.sensitive:
        return '检测到敏感内容，请遵守社区规范';
      case DetectionType.abnormal:
        return '检测到异常行为模式';
      case DetectionType.spam:
        return '检测到垃圾信息';
    }
  }
}
