/// 运营后台管理数据模型
library admin_models;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_models.freezed.dart';
part 'admin_models.g.dart';

/// 管理员用户模型
@freezed
class AdminUser with _$AdminUser {
  const factory AdminUser({
    required String id,
    required String username,
    required String email,
    required String role, // 'super_admin', 'admin', 'operator', 'viewer'
    @Default(true) bool isActive,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    List<String>? permissions,
  }) = _AdminUser;

  factory AdminUser.fromJson(Map<String, dynamic> json) =>
      _$AdminUserFromJson(json);
}

/// 用户列表项模型（简化版）
@freezed
class UserListItem with _$UserListItem {
  const factory UserListItem({
    required String id,
    required String phone,
    String? name,
    String? avatarUrl,
    required List<String> roles,
    required List<String> disabilityTypes,
    @Default('active') String status, // 'active', 'banned', 'pending_verification'
    DateTime? createdAt,
    DateTime? lastLoginAt,
    @Default(0) int helpRequestCount,
    @Default(0) int volunteerCount,
    bool? isDisabilityVerified,
    bool? isVolunteerVerified,
  }) = _UserListItem;

  factory UserListItem.fromJson(Map<String, dynamic> json) =>
      _$UserListItemFromJson(json);
}

/// 认证审核项
@freezed
class VerificationRequest with _$VerificationRequest {
  const factory VerificationRequest({
    required String id,
    required String userId,
    required String userName,
    required String type, // 'disability', 'volunteer_skill'
    required String status, // 'pending', 'approved', 'rejected'
    String? documentUrl,
    String? documentType,
    String? rejectionReason,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
  }) = _VerificationRequest;

  factory VerificationRequest.fromJson(Map<String, dynamic> json) =>
      _$VerificationRequestFromJson(json);
}

/// 举报记录
@freezed
class ReportRecord with _$ReportRecord {
  const factory ReportRecord({
    required String id,
    required String reporterId,
    required String reporterName,
    required String targetId,
    required String targetType, // 'user', 'content', 'call'
    required String targetName,
    required String reason,
    String? description,
    String? evidenceUrls,
    required String status, // 'pending', 'processing', 'resolved', 'dismissed'
    String? resolution,
    String? action, // 'warning', 'ban', 'dismiss'
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? resolvedBy,
  }) = _ReportRecord;

  factory ReportRecord.fromJson(Map<String, dynamic> json) =>
      _$ReportRecordFromJson(json);
}

/// 内容管理项
@freezed
class ContentItem with _$ContentItem {
  const factory ContentItem({
    required String id,
    required String title,
    required String content,
    required String type, // 'story', 'announcement', 'guide'
    required String authorId,
    required String authorName,
    String? coverImageUrl,
    @Default(0) int viewCount,
    @Default(0) int likeCount,
    @Default('draft') String status, // 'draft', 'pending', 'published', 'rejected', 'archived'
    List<String>? tags,
    DateTime? createdAt,
    DateTime? publishedAt,
    DateTime? updatedAt,
  }) = _ContentItem;

  factory ContentItem.fromJson(Map<String, dynamic> json) =>
      _$ContentItemFromJson(json);
}

/// 仪表盘统计数据
@freezed
class DashboardStats with _$DashboardStats {
  const factory DashboardStats({
    required int totalUsers,
    required int newUsersToday,
    required int dau,
    required int mau,
    @Default(0.0) double dauGrowthRate,
    @Default(0.0) double mauGrowthRate,
    required int totalHelpRequests,
    required int helpRequestsToday,
    @Default(0.0) double responseRate,
    @Default(0.0) double aiResolutionRate,
    @Default(0.0) double avgCallDuration,
    @Default(0.0) double satisfactionRate,
    @Default(0.0) double volunteerRetentionRate,
    required int pendingReports,
    required int pendingVerifications,
  }) = _DashboardStats;

  factory DashboardStats.fromJson(Map<String, dynamic> json) =>
      _$DashboardStatsFromJson(json);
}

/// 趋势数据点
@freezed
class TrendDataPoint with _$TrendDataPoint {
  const factory TrendDataPoint({
    required DateTime date,
    required int value,
    int? secondaryValue,
  }) = _TrendDataPoint;

  factory TrendDataPoint.fromJson(Map<String, dynamic> json) =>
      _$TrendDataPointFromJson(json);
}

/// 分布数据项
@freezed
class DistributionItem with _$DistributionItem {
  const factory DistributionItem({
    required String label,
    required int value,
    required int colorValue,
  }) = _DistributionItem;

  factory DistributionItem.fromJson(Map<String, dynamic> json) =>
      _$DistributionItemFromJson(json);
}

/// 统计报表
@freezed
class StatisticsReport with _$StatisticsReport {
  const factory StatisticsReport({
    required String id,
    required String name,
    required String type, // 'daily', 'weekly', 'monthly'
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, dynamic> data,
    DateTime? generatedAt,
    String? generatedBy,
  }) = _StatisticsReport;

  factory StatisticsReport.fromJson(Map<String, dynamic> json) =>
      _$StatisticsReportFromJson(json);
}

/// 用户筛选条件
class UserFilter {
  String? searchQuery;
  List<String>? roles;
  List<String>? disabilityTypes;
  String? status;
  DateTime? createdAfter;
  DateTime? createdBefore;
  bool? isVerified;

  UserFilter({
    this.searchQuery,
    this.roles,
    this.disabilityTypes,
    this.status,
    this.createdAfter,
    this.createdBefore,
    this.isVerified,
  });

  Map<String, dynamic> toJson() {
    return {
      if (searchQuery != null) 'search': searchQuery,
      if (roles != null) 'roles': roles,
      if (disabilityTypes != null) 'disability_types': disabilityTypes,
      if (status != null) 'status': status,
      if (createdAfter != null) 'created_after': createdAfter!.toIso8601String(),
      if (createdBefore != null) 'created_before': createdBefore!.toIso8601String(),
      if (isVerified != null) 'is_verified': isVerified,
    };
  }
}

/// 分页结果
class PaginatedResult<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  const PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });
}

/// 操作日志
@freezed
class OperationLog with _$OperationLog {
  const factory OperationLog({
    required String id,
    required String adminId,
    required String adminName,
    required String operation,
    required String targetType,
    required String targetId,
    String? details,
    required DateTime createdAt,
  }) = _OperationLog;

  factory OperationLog.fromJson(Map<String, dynamic> json) =>
      _$OperationLogFromJson(json);
}
