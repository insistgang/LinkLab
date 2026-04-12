// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'help_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HelpRequestModelImpl _$$HelpRequestModelImplFromJson(
  Map<String, dynamic> json,
) => _$HelpRequestModelImpl(
  id: json['id'] as String,
  seekerId: json['seekerId'] as String,
  type: json['type'] as String?,
  intent: json['intent'] as String?,
  urgency: json['urgency'] as String?,
  status: json['status'] as String?,
  aiResponse: json['aiResponse'] as Map<String, dynamic>?,
  volunteerId: json['volunteerId'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
  seekerRating: (json['seekerRating'] as num?)?.toInt(),
  volunteerRating: (json['volunteerRating'] as num?)?.toInt(),
  cancelReason: json['cancelReason'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  matchedAt: json['matchedAt'] == null
      ? null
      : DateTime.parse(json['matchedAt'] as String),
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
);

Map<String, dynamic> _$$HelpRequestModelImplToJson(
  _$HelpRequestModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'seekerId': instance.seekerId,
  'type': instance.type,
  'intent': instance.intent,
  'urgency': instance.urgency,
  'status': instance.status,
  'aiResponse': instance.aiResponse,
  'volunteerId': instance.volunteerId,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'durationSeconds': instance.durationSeconds,
  'seekerRating': instance.seekerRating,
  'volunteerRating': instance.volunteerRating,
  'cancelReason': instance.cancelReason,
  'createdAt': instance.createdAt?.toIso8601String(),
  'matchedAt': instance.matchedAt?.toIso8601String(),
  'completedAt': instance.completedAt?.toIso8601String(),
};

_$AsyncTaskModelImpl _$$AsyncTaskModelImplFromJson(Map<String, dynamic> json) =>
    _$AsyncTaskModelImpl(
      id: json['id'] as String,
      helpRequestId: json['helpRequestId'] as String,
      seekerId: json['seekerId'] as String,
      volunteerId: json['volunteerId'] as String?,
      taskType: json['taskType'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String?,
      status: json['status'] as String?,
      result: json['result'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      assignedAt: json['assignedAt'] == null
          ? null
          : DateTime.parse(json['assignedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );

Map<String, dynamic> _$$AsyncTaskModelImplToJson(
  _$AsyncTaskModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'helpRequestId': instance.helpRequestId,
  'seekerId': instance.seekerId,
  'volunteerId': instance.volunteerId,
  'taskType': instance.taskType,
  'description': instance.description,
  'imageUrl': instance.imageUrl,
  'status': instance.status,
  'result': instance.result,
  'createdAt': instance.createdAt?.toIso8601String(),
  'assignedAt': instance.assignedAt?.toIso8601String(),
  'completedAt': instance.completedAt?.toIso8601String(),
};
