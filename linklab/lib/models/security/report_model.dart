import 'package:freezed_annotation/freezed_annotation.dart';

part 'report_model.freezed.dart';
part 'report_model.g.dart';

/// 舉報記錄模型
@freezed
class Report with _$Report {
  const factory Report({
    required String id,
    required String reporterId,
    required String reportedId,
    required String reason,
    String? description,
    @Default([]) List<String> evidenceUrls,
    String? callId,
    String? helpRequestId,
    @Default(ReportStatus.pending) ReportStatus status,
    ReportDecision? decision,
    String? reviewerId,
    String? reviewNote,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    DateTime? createdAt,
  }) = _Report;

  factory Report.fromJson(Map<String, dynamic> json) =>
      _$ReportFromJson(json);

  const Report._();

  /// 是否已處理
  bool get isProcessed => status != ReportStatus.pending;

  /// 是否舉報成立
  bool get isValid => decision == ReportDecision.valid;
}

/// 舉報狀態
enum ReportStatus {
  pending,    // 待處理
  processing, // 處理中
  resolved,   // 已解決
}

/// 舉報處理結果
enum ReportDecision {
  valid,      // 舉報成立
  invalid,    // 舉報不成立
  uncertain,  // 無法確定
}

/// 舉報原因類型
enum ReportReason {
  harassment,     // 騷擾
  abuse,          // 辱罵
  fraud,          // 詐騙
  inappropriate,  // 不當內容
  noShow,         // 未履約
  other,          // 其他
}

extension ReportReasonExtension on ReportReason {
  String get label {
    switch (this) {
      case ReportReason.harassment:
        return '騷擾行爲';
      case ReportReason.abuse:
        return '辱罵攻擊';
      case ReportReason.fraud:
        return '詐騙誘導';
      case ReportReason.inappropriate:
        return '不當內容';
      case ReportReason.noShow:
        return '未履約';
      case ReportReason.other:
        return '其他';
    }
  }

  String get description {
    switch (this) {
      case ReportReason.harassment:
        return '對方有騷擾行爲';
      case ReportReason.abuse:
        return '對方使用辱罵或攻擊性語言';
      case ReportReason.fraud:
        return '對方有詐騙或誘導行爲';
      case ReportReason.inappropriate:
        return '對方發佈不當內容';
      case ReportReason.noShow:
        return '對方未按約定提供幫助/求助';
      case ReportReason.other:
        return '其他違規行爲';
    }
 }
}

/// 黑名單模型
@freezed
class BlacklistEntry with _$BlacklistEntry {
  const factory BlacklistEntry({
    required String id,
    required String userId,
    required BlacklistLevel level,
    required String reason,
    String? evidence,
    String? deviceFingerprint,
    String? ipAddress,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) = _BlacklistEntry;

  factory BlacklistEntry.fromJson(Map<String, dynamic> json) =>
      _$BlacklistEntryFromJson(json);

  const BlacklistEntry._();

  /// 是否永久封禁
  bool get isPermanent => expiresAt == null;

  /// 是否已過期
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// 是否有效
  bool get isActive => !isExpired;
}

/// 黑名單級別
enum BlacklistLevel {
  user,    // 用戶級：賬號永久封禁
  device,  // 設備級：設備指紋封禁
  ip,      // IP級：IP段限制
}

extension BlacklistLevelExtension on BlacklistLevel {
  String get label {
    switch (this) {
      case BlacklistLevel.user:
        return '賬號封禁';
      case BlacklistLevel.device:
        return '設備封禁';
      case BlacklistLevel.ip:
        return 'IP限制';
    }
  }

  String get description {
    switch (this) {
      case BlacklistLevel.user:
        return '該賬號已被永久封禁';
      case BlacklistLevel.device:
        return '該設備已被封禁，無法註冊新賬號';
      case BlacklistLevel.ip:
        return '該IP段已被限制註冊';
    }
  }
}

/// 舉報統計
@freezed
class ReportStatistics with _$ReportStatistics {
  const factory ReportStatistics({
    required String userId,
    @Default(0) int totalReportsReceived,
    @Default(0) int validReports,
    @Default(0) int invalidReports,
    @Default(0) int pendingReports,
    DateTime? lastReportAt,
    DateTime? updatedAt,
  }) = _ReportStatistics;

  factory ReportStatistics.fromJson(Map<String, dynamic> json) =>
      _$ReportStatisticsFromJson(json);

  const ReportStatistics._();

  /// 被舉報成功率
  double get validRate =>
      totalReportsReceived > 0 ? validReports / totalReportsReceived : 0;

  /// 是否高風險用戶（被多次有效舉報）
  bool get isHighRisk => validReports >= 3;
}
