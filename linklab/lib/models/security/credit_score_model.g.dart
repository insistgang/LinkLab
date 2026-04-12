// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credit_score_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CreditScoreImpl _$$CreditScoreImplFromJson(Map<String, dynamic> json) =>
    _$CreditScoreImpl(
      userId: json['userId'] as String,
      score: (json['score'] as num?)?.toDouble() ?? 5.0,
      totalRatings: (json['totalRatings'] as num?)?.toInt() ?? 0,
      positiveRatings: (json['positiveRatings'] as num?)?.toInt() ?? 0,
      negativeRatings: (json['negativeRatings'] as num?)?.toInt() ?? 0,
      consecutiveGoodRatings:
          (json['consecutiveGoodRatings'] as num?)?.toInt() ?? 0,
      lastRatingAt: json['lastRatingAt'] == null
          ? null
          : DateTime.parse(json['lastRatingAt'] as String),
      lastViolationAt: json['lastViolationAt'] == null
          ? null
          : DateTime.parse(json['lastViolationAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$CreditScoreImplToJson(_$CreditScoreImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'score': instance.score,
      'totalRatings': instance.totalRatings,
      'positiveRatings': instance.positiveRatings,
      'negativeRatings': instance.negativeRatings,
      'consecutiveGoodRatings': instance.consecutiveGoodRatings,
      'lastRatingAt': instance.lastRatingAt?.toIso8601String(),
      'lastViolationAt': instance.lastViolationAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_$RatingRecordImpl _$$RatingRecordImplFromJson(Map<String, dynamic> json) =>
    _$RatingRecordImpl(
      id: json['id'] as String,
      callId: json['callId'] as String,
      helpRequestId: json['helpRequestId'] as String,
      fromUserId: json['fromUserId'] as String,
      toUserId: json['toUserId'] as String,
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      isSeekerToVolunteer: json['isSeekerToVolunteer'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$RatingRecordImplToJson(_$RatingRecordImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'callId': instance.callId,
      'helpRequestId': instance.helpRequestId,
      'fromUserId': instance.fromUserId,
      'toUserId': instance.toUserId,
      'rating': instance.rating,
      'comment': instance.comment,
      'tags': instance.tags,
      'isSeekerToVolunteer': instance.isSeekerToVolunteer,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$CreditScoreChangeImpl _$$CreditScoreChangeImplFromJson(
  Map<String, dynamic> json,
) => _$CreditScoreChangeImpl(
  id: json['id'] as String,
  userId: json['userId'] as String,
  change: (json['change'] as num).toDouble(),
  scoreBefore: (json['scoreBefore'] as num).toDouble(),
  scoreAfter: (json['scoreAfter'] as num).toDouble(),
  reason: $enumDecode(_$CreditChangeReasonEnumMap, json['reason']),
  relatedId: json['relatedId'] as String?,
  description: json['description'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$$CreditScoreChangeImplToJson(
  _$CreditScoreChangeImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'change': instance.change,
  'scoreBefore': instance.scoreBefore,
  'scoreAfter': instance.scoreAfter,
  'reason': _$CreditChangeReasonEnumMap[instance.reason]!,
  'relatedId': instance.relatedId,
  'description': instance.description,
  'createdAt': instance.createdAt?.toIso8601String(),
};

const _$CreditChangeReasonEnumMap = {
  CreditChangeReason.rating5Star: 'rating5Star',
  CreditChangeReason.rating4Star: 'rating4Star',
  CreditChangeReason.rating3StarOrBelow: 'rating3StarOrBelow',
  CreditChangeReason.validReport: 'validReport',
  CreditChangeReason.consecutiveGoodBonus: 'consecutiveGoodBonus',
  CreditChangeReason.monthlyNoViolation: 'monthlyNoViolation',
  CreditChangeReason.manualAdjustment: 'manualAdjustment',
};
