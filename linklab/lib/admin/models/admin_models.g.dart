// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AdminUserImpl _$$AdminUserImplFromJson(Map<String, dynamic> json) =>
    _$AdminUserImpl(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      isActive: json['isActive'] as bool? ?? true,
      lastLoginAt: json['lastLoginAt'] == null
          ? null
          : DateTime.parse(json['lastLoginAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      permissions: (json['permissions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$AdminUserImplToJson(_$AdminUserImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'email': instance.email,
      'role': instance.role,
      'isActive': instance.isActive,
      'lastLoginAt': instance.lastLoginAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'permissions': instance.permissions,
    };

_$UserListItemImpl _$$UserListItemImplFromJson(Map<String, dynamic> json) =>
    _$UserListItemImpl(
      id: json['id'] as String,
      phone: json['phone'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      roles: (json['roles'] as List<dynamic>).map((e) => e as String).toList(),
      disabilityTypes: (json['disabilityTypes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      status: json['status'] as String? ?? 'active',
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] == null
          ? null
          : DateTime.parse(json['lastLoginAt'] as String),
      helpRequestCount: (json['helpRequestCount'] as num?)?.toInt() ?? 0,
      volunteerCount: (json['volunteerCount'] as num?)?.toInt() ?? 0,
      isDisabilityVerified: json['isDisabilityVerified'] as bool?,
      isVolunteerVerified: json['isVolunteerVerified'] as bool?,
    );

Map<String, dynamic> _$$UserListItemImplToJson(_$UserListItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'phone': instance.phone,
      'name': instance.name,
      'avatarUrl': instance.avatarUrl,
      'roles': instance.roles,
      'disabilityTypes': instance.disabilityTypes,
      'status': instance.status,
      'createdAt': instance.createdAt?.toIso8601String(),
      'lastLoginAt': instance.lastLoginAt?.toIso8601String(),
      'helpRequestCount': instance.helpRequestCount,
      'volunteerCount': instance.volunteerCount,
      'isDisabilityVerified': instance.isDisabilityVerified,
      'isVolunteerVerified': instance.isVolunteerVerified,
    };

_$VerificationRequestImpl _$$VerificationRequestImplFromJson(
  Map<String, dynamic> json,
) => _$VerificationRequestImpl(
  id: json['id'] as String,
  userId: json['userId'] as String,
  userName: json['userName'] as String,
  type: json['type'] as String,
  status: json['status'] as String,
  documentUrl: json['documentUrl'] as String?,
  documentType: json['documentType'] as String?,
  rejectionReason: json['rejectionReason'] as String?,
  submittedAt: json['submittedAt'] == null
      ? null
      : DateTime.parse(json['submittedAt'] as String),
  reviewedAt: json['reviewedAt'] == null
      ? null
      : DateTime.parse(json['reviewedAt'] as String),
  reviewedBy: json['reviewedBy'] as String?,
);

Map<String, dynamic> _$$VerificationRequestImplToJson(
  _$VerificationRequestImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'userName': instance.userName,
  'type': instance.type,
  'status': instance.status,
  'documentUrl': instance.documentUrl,
  'documentType': instance.documentType,
  'rejectionReason': instance.rejectionReason,
  'submittedAt': instance.submittedAt?.toIso8601String(),
  'reviewedAt': instance.reviewedAt?.toIso8601String(),
  'reviewedBy': instance.reviewedBy,
};

_$ReportRecordImpl _$$ReportRecordImplFromJson(Map<String, dynamic> json) =>
    _$ReportRecordImpl(
      id: json['id'] as String,
      reporterId: json['reporterId'] as String,
      reporterName: json['reporterName'] as String,
      targetId: json['targetId'] as String,
      targetType: json['targetType'] as String,
      targetName: json['targetName'] as String,
      reason: json['reason'] as String,
      description: json['description'] as String?,
      evidenceUrls: json['evidenceUrls'] as String?,
      status: json['status'] as String,
      resolution: json['resolution'] as String?,
      action: json['action'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      resolvedAt: json['resolvedAt'] == null
          ? null
          : DateTime.parse(json['resolvedAt'] as String),
      resolvedBy: json['resolvedBy'] as String?,
    );

Map<String, dynamic> _$$ReportRecordImplToJson(_$ReportRecordImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reporterId': instance.reporterId,
      'reporterName': instance.reporterName,
      'targetId': instance.targetId,
      'targetType': instance.targetType,
      'targetName': instance.targetName,
      'reason': instance.reason,
      'description': instance.description,
      'evidenceUrls': instance.evidenceUrls,
      'status': instance.status,
      'resolution': instance.resolution,
      'action': instance.action,
      'createdAt': instance.createdAt?.toIso8601String(),
      'resolvedAt': instance.resolvedAt?.toIso8601String(),
      'resolvedBy': instance.resolvedBy,
    };

_$ContentItemImpl _$$ContentItemImplFromJson(Map<String, dynamic> json) =>
    _$ContentItemImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      type: json['type'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      coverImageUrl: json['coverImageUrl'] as String?,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'draft',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      publishedAt: json['publishedAt'] == null
          ? null
          : DateTime.parse(json['publishedAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$ContentItemImplToJson(_$ContentItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'type': instance.type,
      'authorId': instance.authorId,
      'authorName': instance.authorName,
      'coverImageUrl': instance.coverImageUrl,
      'viewCount': instance.viewCount,
      'likeCount': instance.likeCount,
      'status': instance.status,
      'tags': instance.tags,
      'createdAt': instance.createdAt?.toIso8601String(),
      'publishedAt': instance.publishedAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$DashboardStatsImpl _$$DashboardStatsImplFromJson(Map<String, dynamic> json) =>
    _$DashboardStatsImpl(
      totalUsers: (json['totalUsers'] as num).toInt(),
      newUsersToday: (json['newUsersToday'] as num).toInt(),
      dau: (json['dau'] as num).toInt(),
      mau: (json['mau'] as num).toInt(),
      dauGrowthRate: (json['dauGrowthRate'] as num?)?.toDouble() ?? 0.0,
      mauGrowthRate: (json['mauGrowthRate'] as num?)?.toDouble() ?? 0.0,
      totalHelpRequests: (json['totalHelpRequests'] as num).toInt(),
      helpRequestsToday: (json['helpRequestsToday'] as num).toInt(),
      responseRate: (json['responseRate'] as num?)?.toDouble() ?? 0.0,
      aiResolutionRate: (json['aiResolutionRate'] as num?)?.toDouble() ?? 0.0,
      avgCallDuration: (json['avgCallDuration'] as num?)?.toDouble() ?? 0.0,
      satisfactionRate: (json['satisfactionRate'] as num?)?.toDouble() ?? 0.0,
      volunteerRetentionRate:
          (json['volunteerRetentionRate'] as num?)?.toDouble() ?? 0.0,
      pendingReports: (json['pendingReports'] as num).toInt(),
      pendingVerifications: (json['pendingVerifications'] as num).toInt(),
    );

Map<String, dynamic> _$$DashboardStatsImplToJson(
  _$DashboardStatsImpl instance,
) => <String, dynamic>{
  'totalUsers': instance.totalUsers,
  'newUsersToday': instance.newUsersToday,
  'dau': instance.dau,
  'mau': instance.mau,
  'dauGrowthRate': instance.dauGrowthRate,
  'mauGrowthRate': instance.mauGrowthRate,
  'totalHelpRequests': instance.totalHelpRequests,
  'helpRequestsToday': instance.helpRequestsToday,
  'responseRate': instance.responseRate,
  'aiResolutionRate': instance.aiResolutionRate,
  'avgCallDuration': instance.avgCallDuration,
  'satisfactionRate': instance.satisfactionRate,
  'volunteerRetentionRate': instance.volunteerRetentionRate,
  'pendingReports': instance.pendingReports,
  'pendingVerifications': instance.pendingVerifications,
};

_$TrendDataPointImpl _$$TrendDataPointImplFromJson(Map<String, dynamic> json) =>
    _$TrendDataPointImpl(
      date: DateTime.parse(json['date'] as String),
      value: (json['value'] as num).toInt(),
      secondaryValue: (json['secondaryValue'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$TrendDataPointImplToJson(
  _$TrendDataPointImpl instance,
) => <String, dynamic>{
  'date': instance.date.toIso8601String(),
  'value': instance.value,
  'secondaryValue': instance.secondaryValue,
};

_$DistributionItemImpl _$$DistributionItemImplFromJson(
  Map<String, dynamic> json,
) => _$DistributionItemImpl(
  label: json['label'] as String,
  value: (json['value'] as num).toInt(),
  colorValue: (json['colorValue'] as num).toInt(),
);

Map<String, dynamic> _$$DistributionItemImplToJson(
  _$DistributionItemImpl instance,
) => <String, dynamic>{
  'label': instance.label,
  'value': instance.value,
  'colorValue': instance.colorValue,
};

_$StatisticsReportImpl _$$StatisticsReportImplFromJson(
  Map<String, dynamic> json,
) => _$StatisticsReportImpl(
  id: json['id'] as String,
  name: json['name'] as String,
  type: json['type'] as String,
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
  data: json['data'] as Map<String, dynamic>,
  generatedAt: json['generatedAt'] == null
      ? null
      : DateTime.parse(json['generatedAt'] as String),
  generatedBy: json['generatedBy'] as String?,
);

Map<String, dynamic> _$$StatisticsReportImplToJson(
  _$StatisticsReportImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': instance.type,
  'startDate': instance.startDate.toIso8601String(),
  'endDate': instance.endDate.toIso8601String(),
  'data': instance.data,
  'generatedAt': instance.generatedAt?.toIso8601String(),
  'generatedBy': instance.generatedBy,
};

_$OperationLogImpl _$$OperationLogImplFromJson(Map<String, dynamic> json) =>
    _$OperationLogImpl(
      id: json['id'] as String,
      adminId: json['adminId'] as String,
      adminName: json['adminName'] as String,
      operation: json['operation'] as String,
      targetType: json['targetType'] as String,
      targetId: json['targetId'] as String,
      details: json['details'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$OperationLogImplToJson(_$OperationLogImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'adminId': instance.adminId,
      'adminName': instance.adminName,
      'operation': instance.operation,
      'targetType': instance.targetType,
      'targetId': instance.targetId,
      'details': instance.details,
      'createdAt': instance.createdAt.toIso8601String(),
    };
