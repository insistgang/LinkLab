// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'volunteer_level_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VolunteerLevelInfoImpl _$$VolunteerLevelInfoImplFromJson(
  Map<String, dynamic> json,
) => _$VolunteerLevelInfoImpl(
  currentLevel: (json['currentLevel'] as num).toInt(),
  currentPoints: (json['currentPoints'] as num).toInt(),
  pointsToNextLevel: (json['pointsToNextLevel'] as num).toInt(),
  progressPercent: (json['progressPercent'] as num).toDouble(),
  nextLevel: json['nextLevel'] == null
      ? null
      : LevelDefinition.fromJson(json['nextLevel'] as Map<String, dynamic>),
  allLevels:
      (json['allLevels'] as List<dynamic>?)
          ?.map((e) => LevelDefinition.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$$VolunteerLevelInfoImplToJson(
  _$VolunteerLevelInfoImpl instance,
) => <String, dynamic>{
  'currentLevel': instance.currentLevel,
  'currentPoints': instance.currentPoints,
  'pointsToNextLevel': instance.pointsToNextLevel,
  'progressPercent': instance.progressPercent,
  'nextLevel': instance.nextLevel,
  'allLevels': instance.allLevels,
};

_$LevelDefinitionImpl _$$LevelDefinitionImplFromJson(
  Map<String, dynamic> json,
) => _$LevelDefinitionImpl(
  level: (json['level'] as num).toInt(),
  name: json['name'] as String,
  emoji: json['emoji'] as String,
  minPoints: (json['minPoints'] as num).toInt(),
  maxPoints: (json['maxPoints'] as num).toInt(),
  privileges:
      (json['privileges'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  description: json['description'] as String?,
);

Map<String, dynamic> _$$LevelDefinitionImplToJson(
  _$LevelDefinitionImpl instance,
) => <String, dynamic>{
  'level': instance.level,
  'name': instance.name,
  'emoji': instance.emoji,
  'minPoints': instance.minPoints,
  'maxPoints': instance.maxPoints,
  'privileges': instance.privileges,
  'description': instance.description,
};
