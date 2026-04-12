// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReportImpl _$$ReportImplFromJson(Map<String, dynamic> json) => _$ReportImpl(
  id: json['id'] as String,
  reporterId: json['reporterId'] as String,
  reportedId: json['reportedId'] as String,
  reason: json['reason'] as String,
  description: json['description'] as String?,
  evidenceUrls:
      (json['evidenceUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  callId: json['callId'] as String?,
  helpRequestId: json['helpRequestId'] as String?,
  status:
      $enumDecodeNullable(_$ReportStatusEnumMap, json['status']) ??
      ReportStatus.pending,
  decision: $enumDecodeNullable(_$ReportDecisionEnumMap, json['decision']),
  reviewerId: json['reviewerId'] as String?,
  reviewNote: json['reviewNote'] as String?,
  submittedAt: json['submittedAt'] == null
      ? null
      : DateTime.parse(json['submittedAt'] as String),
  reviewedAt: json['reviewedAt'] == null
      ? null
      : DateTime.parse(json['reviewedAt'] as String),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$$ReportImplToJson(_$ReportImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reporterId': instance.reporterId,
      'reportedId': instance.reportedId,
      'reason': instance.reason,
      'description': instance.description,
      'evidenceUrls': instance.evidenceUrls,
      'callId': instance.callId,
      'helpRequestId': instance.helpRequestId,
      'status': _$ReportStatusEnumMap[instance.status]!,
      'decision': _$ReportDecisionEnumMap[instance.decision],
      'reviewerId': instance.reviewerId,
      'reviewNote': instance.reviewNote,
      'submittedAt': instance.submittedAt?.toIso8601String(),
      'reviewedAt': instance.reviewedAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
    };

const _$ReportStatusEnumMap = {
  ReportStatus.pending: 'pending',
  ReportStatus.processing: 'processing',
  ReportStatus.resolved: 'resolved',
};

const _$ReportDecisionEnumMap = {
  ReportDecision.valid: 'valid',
  ReportDecision.invalid: 'invalid',
  ReportDecision.uncertain: 'uncertain',
};

_$BlacklistEntryImpl _$$BlacklistEntryImplFromJson(Map<String, dynamic> json) =>
    _$BlacklistEntryImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      level: $enumDecode(_$BlacklistLevelEnumMap, json['level']),
      reason: json['reason'] as String,
      evidence: json['evidence'] as String?,
      deviceFingerprint: json['deviceFingerprint'] as String?,
      ipAddress: json['ipAddress'] as String?,
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$BlacklistEntryImplToJson(
  _$BlacklistEntryImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'level': _$BlacklistLevelEnumMap[instance.level]!,
  'reason': instance.reason,
  'evidence': instance.evidence,
  'deviceFingerprint': instance.deviceFingerprint,
  'ipAddress': instance.ipAddress,
  'expiresAt': instance.expiresAt?.toIso8601String(),
  'createdAt': instance.createdAt?.toIso8601String(),
};

const _$BlacklistLevelEnumMap = {
  BlacklistLevel.user: 'user',
  BlacklistLevel.device: 'device',
  BlacklistLevel.ip: 'ip',
};

_$ReportStatisticsImpl _$$ReportStatisticsImplFromJson(
  Map<String, dynamic> json,
) => _$ReportStatisticsImpl(
  userId: json['userId'] as String,
  totalReportsReceived: (json['totalReportsReceived'] as num?)?.toInt() ?? 0,
  validReports: (json['validReports'] as num?)?.toInt() ?? 0,
  invalidReports: (json['invalidReports'] as num?)?.toInt() ?? 0,
  pendingReports: (json['pendingReports'] as num?)?.toInt() ?? 0,
  lastReportAt: json['lastReportAt'] == null
      ? null
      : DateTime.parse(json['lastReportAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$ReportStatisticsImplToJson(
  _$ReportStatisticsImpl instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'totalReportsReceived': instance.totalReportsReceived,
  'validReports': instance.validReports,
  'invalidReports': instance.invalidReports,
  'pendingReports': instance.pendingReports,
  'lastReportAt': instance.lastReportAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};
