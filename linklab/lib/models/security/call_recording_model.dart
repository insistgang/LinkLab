import 'package:freezed_annotation/freezed_annotation.dart';

part 'call_recording_model.freezed.dart';
part 'call_recording_model.g.dart';

/// 通话录音模型
@freezed
class CallRecording with _$CallRecording {
  const factory CallRecording({
    required String id,
    required String callId,
    required String seekerId,
    String? volunteerId,
    String? fileUrl,
    String? filePath,
    int? fileSize,
    int? duration, // 录音时长（秒）
    @Default(false) bool isUploaded,
    @Default(false) bool isDeleted,
    @Default([]) List<DetectionResult> detectionResults,
    DateTime? startedAt,
    DateTime? endedAt,
    DateTime? uploadedAt,
    DateTime? deletedAt,
    DateTime? expiresAt, // 7天后自动删除
    DateTime? createdAt,
  }) = _CallRecording;

  factory CallRecording.fromJson(Map<String, dynamic> json) =>
      _$CallRecordingFromJson(json);

  const CallRecording._();

  /// 是否已过期
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// 是否包含违规内容
  bool get hasViolation =>
      detectionResults.any((r) => r.isViolation);

  /// 违规严重程度
  ViolationLevel? get highestViolationLevel {
    if (detectionResults.isEmpty) return null;
    final violations = detectionResults.where((r) => r.isViolation).toList();
    if (violations.isEmpty) return null;

    ViolationLevel highest = ViolationLevel.low;
    for (final v in violations) {
      final level = v.violationLevel;
      if (level != null && level.index > highest.index) {
        highest = level;
      }
    }
    return highest;
  }
}

/// AI检测结果
@freezed
class DetectionResult with _$DetectionResult {
  const factory DetectionResult({
    required String id,
    required DetectionType type,
    required double confidence, // 0.0 - 1.0
    @Default(false) bool isViolation,
    ViolationLevel? violationLevel,
    String? detectedText,
    String? matchedKeywords,
    int? timestamp, // 在录音中的时间点（毫秒）
    DateTime? createdAt,
  }) = _DetectionResult;

  factory DetectionResult.fromJson(Map<String, dynamic> json) =>
      _$DetectionResultFromJson(json);
}

/// 检测类型
enum DetectionType {
  abuse,        // 辱骂/人身攻击
  sensitive,    // 敏感内容（涉黄/涉暴）
  fraud,        // 诈骗诱导
  abnormal,     // 异常行为
  spam,         // 垃圾信息
}

extension DetectionTypeExtension on DetectionType {
  String get label {
    switch (this) {
      case DetectionType.abuse:
        return '辱骂攻击';
      case DetectionType.sensitive:
        return '敏感内容';
      case DetectionType.fraud:
        return '诈骗诱导';
      case DetectionType.abnormal:
        return '异常行为';
      case DetectionType.spam:
        return '垃圾信息';
    }
  }

  String get description {
    switch (this) {
      case DetectionType.abuse:
        return '检测到辱骂或人身攻击内容';
      case DetectionType.sensitive:
        return '检测到涉黄/涉暴等敏感内容';
      case DetectionType.fraud:
        return '检测到金钱交易或个人信息索取';
      case DetectionType.abnormal:
        return '检测到长时间沉默或重复呼叫等异常';
      case DetectionType.spam:
        return '检测到垃圾信息';
    }
  }
}

/// 违规级别
enum ViolationLevel {
  low,      // 轻微
  medium,   // 中等
  high,     // 严重
  critical, // 极严重
}

extension ViolationLevelExtension on ViolationLevel {
  String get label {
    switch (this) {
      case ViolationLevel.low:
        return '轻微';
      case ViolationLevel.medium:
        return '中等';
      case ViolationLevel.high:
        return '严重';
      case ViolationLevel.critical:
        return '极严重';
    }
  }

  String get action {
    switch (this) {
      case ViolationLevel.low:
        return '自动警告';
      case ViolationLevel.medium:
        return '记录标记';
      case ViolationLevel.high:
        return '中断通话';
      case ViolationLevel.critical:
        return '立即封号';
    }
  }
}

/// 录音配置
class RecordingConfig {
  /// 默认录音存储天数
  static const int defaultRetentionDays = 7;

  /// 最大录音文件大小（MB）
  static const int maxFileSizeMB = 100;

  /// 录音质量
  static const int sampleRate = 16000;
  static const int bitRate = 32000;

  /// 是否默认开启录音
  static const bool defaultEnabled = true;

  /// 检测阈值
  static const double abuseThreshold = 0.7;
  static const double sensitiveThreshold = 0.8;
  static const double fraudThreshold = 0.75;
}
