// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserModelImpl _$$UserModelImplFromJson(Map<String, dynamic> json) =>
    _$UserModelImpl(
      id: json['id'] as String,
      phone: json['phone'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      role:
          (json['role'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const ['seeker'],
      disabilityType:
          (json['disabilityType'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      preferences: json['preferences'] == null
          ? null
          : AccessibilityPreferences.fromJson(
              json['preferences'] as Map<String, dynamic>,
            ),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] == null
          ? null
          : DateTime.parse(json['lastLoginAt'] as String),
    );

Map<String, dynamic> _$$UserModelImplToJson(_$UserModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'phone': instance.phone,
      'name': instance.name,
      'avatarUrl': instance.avatarUrl,
      'role': instance.role,
      'disabilityType': instance.disabilityType,
      'preferences': instance.preferences,
      'createdAt': instance.createdAt?.toIso8601String(),
      'lastLoginAt': instance.lastLoginAt?.toIso8601String(),
    };

_$AccessibilityPreferencesImpl _$$AccessibilityPreferencesImplFromJson(
  Map<String, dynamic> json,
) => _$AccessibilityPreferencesImpl(
  highContrastMode: json['highContrastMode'] as bool? ?? false,
  fontScale: (json['fontScale'] as num?)?.toDouble() ?? 1.0,
  voiceSpeed: (json['voiceSpeed'] as num?)?.toDouble() ?? 1.0,
  hapticFeedback: json['hapticFeedback'] as bool? ?? true,
  voiceGuidance: json['voiceGuidance'] as bool? ?? true,
  autoReadResults: json['autoReadResults'] as bool? ?? true,
  voiceGender: json['voiceGender'] as String? ?? 'female',
  voiceAccent: json['voiceAccent'] as String? ?? 'standard',
);

Map<String, dynamic> _$$AccessibilityPreferencesImplToJson(
  _$AccessibilityPreferencesImpl instance,
) => <String, dynamic>{
  'highContrastMode': instance.highContrastMode,
  'fontScale': instance.fontScale,
  'voiceSpeed': instance.voiceSpeed,
  'hapticFeedback': instance.hapticFeedback,
  'voiceGuidance': instance.voiceGuidance,
  'autoReadResults': instance.autoReadResults,
  'voiceGender': instance.voiceGender,
  'voiceAccent': instance.voiceAccent,
};

_$VolunteerProfileImpl _$$VolunteerProfileImplFromJson(
  Map<String, dynamic> json,
) => _$VolunteerProfileImpl(
  userId: json['userId'] as String,
  skills:
      (json['skills'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  level: (json['level'] as num?)?.toInt() ?? 1,
  points: (json['points'] as num?)?.toInt() ?? 0,
  creditScore: (json['creditScore'] as num?)?.toDouble() ?? 5.0,
  isVerified: json['isVerified'] as bool? ?? false,
  isOnline: json['isOnline'] as bool? ?? false,
  lastHeartbeatAt: json['lastHeartbeatAt'] == null
      ? null
      : DateTime.parse(json['lastHeartbeatAt'] as String),
  totalHelpCount: (json['totalHelpCount'] as num?)?.toInt(),
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
);

Map<String, dynamic> _$$VolunteerProfileImplToJson(
  _$VolunteerProfileImpl instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'skills': instance.skills,
  'level': instance.level,
  'points': instance.points,
  'creditScore': instance.creditScore,
  'isVerified': instance.isVerified,
  'isOnline': instance.isOnline,
  'lastHeartbeatAt': instance.lastHeartbeatAt?.toIso8601String(),
  'totalHelpCount': instance.totalHelpCount,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
};
