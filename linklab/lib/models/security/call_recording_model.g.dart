// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_recording_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CallRecordingImpl _$$CallRecordingImplFromJson(Map<String, dynamic> json) =>
    _$CallRecordingImpl(
      id: json['id'] as String,
      callId: json['callId'] as String,
      seekerId: json['seekerId'] as String,
      volunteerId: json['volunteerId'] as String?,
      fileUrl: json['fileUrl'] as String?,
      filePath: json['filePath'] as String?,
      fileSize: (json['fileSize'] as num?)?.toInt(),
      duration: (json['duration'] as num?)?.toInt(),
      isUploaded: json['isUploaded'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      detectionResults:
          (json['detectionResults'] as List<dynamic>?)
              ?.map((e) => DetectionResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
      uploadedAt: json['uploadedAt'] == null
          ? null
          : DateTime.parse(json['uploadedAt'] as String),
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$CallRecordingImplToJson(_$CallRecordingImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'callId': instance.callId,
      'seekerId': instance.seekerId,
      'volunteerId': instance.volunteerId,
      'fileUrl': instance.fileUrl,
      'filePath': instance.filePath,
      'fileSize': instance.fileSize,
      'duration': instance.duration,
      'isUploaded': instance.isUploaded,
      'isDeleted': instance.isDeleted,
      'detectionResults': instance.detectionResults,
      'startedAt': instance.startedAt?.toIso8601String(),
      'endedAt': instance.endedAt?.toIso8601String(),
      'uploadedAt': instance.uploadedAt?.toIso8601String(),
      'deletedAt': instance.deletedAt?.toIso8601String(),
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$DetectionResultImpl _$$DetectionResultImplFromJson(
  Map<String, dynamic> json,
) => _$DetectionResultImpl(
  id: json['id'] as String,
  type: $enumDecode(_$DetectionTypeEnumMap, json['type']),
  confidence: (json['confidence'] as num).toDouble(),
  isViolation: json['isViolation'] as bool? ?? false,
  violationLevel: $enumDecodeNullable(
    _$ViolationLevelEnumMap,
    json['violationLevel'],
  ),
  detectedText: json['detectedText'] as String?,
  matchedKeywords: json['matchedKeywords'] as String?,
  timestamp: (json['timestamp'] as num?)?.toInt(),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$$DetectionResultImplToJson(
  _$DetectionResultImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'type': _$DetectionTypeEnumMap[instance.type]!,
  'confidence': instance.confidence,
  'isViolation': instance.isViolation,
  'violationLevel': _$ViolationLevelEnumMap[instance.violationLevel],
  'detectedText': instance.detectedText,
  'matchedKeywords': instance.matchedKeywords,
  'timestamp': instance.timestamp,
  'createdAt': instance.createdAt?.toIso8601String(),
};

const _$DetectionTypeEnumMap = {
  DetectionType.abuse: 'abuse',
  DetectionType.sensitive: 'sensitive',
  DetectionType.fraud: 'fraud',
  DetectionType.abnormal: 'abnormal',
  DetectionType.spam: 'spam',
};

const _$ViolationLevelEnumMap = {
  ViolationLevel.low: 'low',
  ViolationLevel.medium: 'medium',
  ViolationLevel.high: 'high',
  ViolationLevel.critical: 'critical',
};
