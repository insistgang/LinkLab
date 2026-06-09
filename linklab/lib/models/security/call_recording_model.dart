import 'package:freezed_annotation/freezed_annotation.dart';

part 'call_recording_model.freezed.dart';
part 'call_recording_model.g.dart';

/// 通話錄音模型
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
    int? duration, // 錄音時長（秒）
    @Default(false) bool isUploaded,
    @Default(false) bool isDeleted,
    @Default([]) List<DetectionResult> detectionResults,
    DateTime? startedAt,
    DateTime? endedAt,
    DateTime? uploadedAt,
    DateTime? deletedAt,
    DateTime? expiresAt, // 7天后自動刪除
    DateTime? createdAt,
  }) = _CallRecording;

  factory CallRecording.fromJson(Map<String, dynamic> json) =>
      _$CallRecordingFromJson(json);

  const CallRecording._();

  /// 是否已過期
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// 是否包含違規內容
  bool get hasViolation =>
      detectionResults.any((r) => r.isViolation);

  /// 違規嚴重程度
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

/// AI檢測結果
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
    int? timestamp, // 在錄音中的時間點（毫秒）
    DateTime? createdAt,
  }) = _DetectionResult;

  factory DetectionResult.fromJson(Map<String, dynamic> json) =>
      _$DetectionResultFromJson(json);
}

/// 檢測類型
enum DetectionType {
  abuse,        // 辱罵/人身攻擊
  sensitive,    // 敏感內容（涉黃/涉暴）
  fraud,        // 詐騙誘導
  abnormal,     // 異常行爲
  spam,         // 垃圾信息
}

extension DetectionTypeExtension on DetectionType {
  String get label {
    switch (this) {
      case DetectionType.abuse:
        return '辱罵攻擊';
      case DetectionType.sensitive:
        return '敏感內容';
      case DetectionType.fraud:
        return '詐騙誘導';
      case DetectionType.abnormal:
        return '異常行爲';
      case DetectionType.spam:
        return '垃圾信息';
    }
  }

  String get description {
    switch (this) {
      case DetectionType.abuse:
        return '檢測到辱罵或人身攻擊內容';
      case DetectionType.sensitive:
        return '檢測到涉黃/涉暴等敏感內容';
      case DetectionType.fraud:
        return '檢測到金錢交易或個人信息索取';
      case DetectionType.abnormal:
        return '檢測到長時間沉默或重複呼叫等異常';
      case DetectionType.spam:
        return '檢測到垃圾信息';
    }
  }
}

/// 違規級別
enum ViolationLevel {
  low,      // 輕微
  medium,   // 中等
  high,     // 嚴重
  critical, // 極嚴重
}

extension ViolationLevelExtension on ViolationLevel {
  String get label {
    switch (this) {
      case ViolationLevel.low:
        return '輕微';
      case ViolationLevel.medium:
        return '中等';
      case ViolationLevel.high:
        return '嚴重';
      case ViolationLevel.critical:
        return '極嚴重';
    }
  }

  String get action {
    switch (this) {
      case ViolationLevel.low:
        return '自動警告';
      case ViolationLevel.medium:
        return '記錄標記';
      case ViolationLevel.high:
        return '中斷通話';
      case ViolationLevel.critical:
        return '立即封號';
    }
  }
}

/// 錄音配置
class RecordingConfig {
  /// 默認錄音存儲天數
  static const int defaultRetentionDays = 7;

  /// 最大錄音文件大小（MB）
  static const int maxFileSizeMB = 100;

  /// 錄音質量
  static const int sampleRate = 16000;
  static const int bitRate = 32000;

  /// 是否默認開啓錄音
  static const bool defaultEnabled = true;

  /// 檢測閾值
  static const double abuseThreshold = 0.7;
  static const double sensitiveThreshold = 0.8;
  static const double fraudThreshold = 0.75;
}
