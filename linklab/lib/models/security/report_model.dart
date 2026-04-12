import 'package:freezed_annotation/freezed_annotation.dart';

part 'report_model.freezed.dart';
part 'report_model.g.dart';

/// 举报记录模型
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

  /// 是否已处理
  bool get isProcessed => status != ReportStatus.pending;

  /// 是否举报成立
  bool get isValid => decision == ReportDecision.valid;
}

/// 举报状态
enum ReportStatus {
  pending,    // 待处理
  processing, // 处理中
  resolved,   // 已解决
}

/// 举报处理结果
enum ReportDecision {
  valid,      // 举报成立
  invalid,    // 举报不成立
  uncertain,  // 无法确定
}

/// 举报原因类型
enum ReportReason {
  harassment,     // 骚扰
  abuse,          // 辱骂
  fraud,          // 诈骗
  inappropriate,  // 不当内容
  noShow,         // 未履约
  other,          // 其他
}

extension ReportReasonExtension on ReportReason {
  String get label {
    switch (this) {
      case ReportReason.harassment:
        return '骚扰行为';
      case ReportReason.abuse:
        return '辱骂攻击';
      case ReportReason.fraud:
        return '诈骗诱导';
      case ReportReason.inappropriate:
        return '不当内容';
      case ReportReason.noShow:
        return '未履约';
      case ReportReason.other:
        return '其他';
    }
  }

  String get description {
    switch (this) {
      case ReportReason.harassment:
        return '对方有骚扰行为';
      case ReportReason.abuse:
        return '对方使用辱骂或攻击性语言';
      case ReportReason.fraud:
        return '对方有诈骗或诱导行为';
      case ReportReason.inappropriate:
        return '对方发布不当内容';
      case ReportReason.noShow:
        return '对方未按约定提供帮助/求助';
      case ReportReason.other:
        return '其他违规行为';
    }
 }
}

/// 黑名单模型
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

  /// 是否已过期
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// 是否有效
  bool get isActive => !isExpired;
}

/// 黑名单级别
enum BlacklistLevel {
  user,    // 用户级：账号永久封禁
  device,  // 设备级：设备指纹封禁
  ip,      // IP级：IP段限制
}

extension BlacklistLevelExtension on BlacklistLevel {
  String get label {
    switch (this) {
      case BlacklistLevel.user:
        return '账号封禁';
      case BlacklistLevel.device:
        return '设备封禁';
      case BlacklistLevel.ip:
        return 'IP限制';
    }
  }

  String get description {
    switch (this) {
      case BlacklistLevel.user:
        return '该账号已被永久封禁';
      case BlacklistLevel.device:
        return '该设备已被封禁，无法注册新账号';
      case BlacklistLevel.ip:
        return '该IP段已被限制注册';
    }
  }
}

/// 举报统计
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

  /// 被举报成功率
  double get validRate =>
      totalReportsReceived > 0 ? validReports / totalReportsReceived : 0;

  /// 是否高风险用户（被多次有效举报）
  bool get isHighRisk => validReports >= 3;
}
