// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'badge_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BadgeModelImpl _$$BadgeModelImplFromJson(Map<String, dynamic> json) =>
    _$BadgeModelImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: $enumDecode(_$BadgeTypeEnumMap, json['type']),
      name: json['name'] as String,
      iconUrl: json['iconUrl'] as String?,
      description: json['description'] as String?,
      earnedAt: json['earnedAt'] == null
          ? null
          : DateTime.parse(json['earnedAt'] as String),
      isNew: json['isNew'] as bool? ?? false,
    );

Map<String, dynamic> _$$BadgeModelImplToJson(_$BadgeModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'type': _$BadgeTypeEnumMap[instance.type]!,
      'name': instance.name,
      'iconUrl': instance.iconUrl,
      'description': instance.description,
      'earnedAt': instance.earnedAt?.toIso8601String(),
      'isNew': instance.isNew,
    };

const _$BadgeTypeEnumMap = {
  BadgeType.translator: 'translator',
  BadgeType.helper100: 'helper100',
  BadgeType.helper500: 'helper500',
  BadgeType.helper1000: 'helper1000',
  BadgeType.newYear: 'newYear',
  BadgeType.springFestival: 'springFestival',
  BadgeType.lighthouse: 'lighthouse',
  BadgeType.continuous7: 'continuous7',
  BadgeType.continuous30: 'continuous30',
  BadgeType.skillMaster: 'skillMaster',
  BadgeType.risingStar: 'risingStar',
  BadgeType.kindHeart: 'kindHeart',
  BadgeType.other: 'other',
};
