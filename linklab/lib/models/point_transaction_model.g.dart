// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'point_transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PointTransactionModelImpl _$$PointTransactionModelImplFromJson(
  Map<String, dynamic> json,
) => _$PointTransactionModelImpl(
  id: json['id'] as String,
  userId: json['userId'] as String,
  points: (json['points'] as num).toInt(),
  type: $enumDecode(_$PointTransactionTypeEnumMap, json['type']),
  description: json['description'] as String?,
  relatedId: json['relatedId'] as String?,
  isPositive: json['isPositive'] as bool? ?? false,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$$PointTransactionModelImplToJson(
  _$PointTransactionModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'points': instance.points,
  'type': _$PointTransactionTypeEnumMap[instance.type]!,
  'description': instance.description,
  'relatedId': instance.relatedId,
  'isPositive': instance.isPositive,
  'createdAt': instance.createdAt?.toIso8601String(),
};

const _$PointTransactionTypeEnumMap = {
  PointTransactionType.dailyCheckIn: 'dailyCheckIn',
  PointTransactionType.weeklyBonus: 'weeklyBonus',
  PointTransactionType.monthlyBonus: 'monthlyBonus',
  PointTransactionType.realtimeHelp: 'realtimeHelp',
  PointTransactionType.asyncHelp: 'asyncHelp',
  PointTransactionType.fiveStarRating: 'fiveStarRating',
  PointTransactionType.continuousHelpBonus: 'continuousHelpBonus',
  PointTransactionType.dailyTask: 'dailyTask',
  PointTransactionType.penalty: 'penalty',
  PointTransactionType.other: 'other',
};
