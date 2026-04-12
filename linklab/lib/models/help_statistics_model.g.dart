// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'help_statistics_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HelpStatisticsImpl _$$HelpStatisticsImplFromJson(Map<String, dynamic> json) =>
    _$HelpStatisticsImpl(
      totalRequests: (json['totalRequests'] as num?)?.toInt() ?? 0,
      aiResolvedCount: (json['aiResolvedCount'] as num?)?.toInt() ?? 0,
      volunteerHelpCount: (json['volunteerHelpCount'] as num?)?.toInt() ?? 0,
      sosCount: (json['sosCount'] as num?)?.toInt() ?? 0,
      aiResolutionRate: (json['aiResolutionRate'] as num?)?.toDouble() ?? 0.0,
      totalDurationMinutes:
          (json['totalDurationMinutes'] as num?)?.toInt() ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      typeStats:
          (json['typeStats'] as List<dynamic>?)
              ?.map((e) => HelpTypeStat.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      monthlyStats:
          (json['monthlyStats'] as List<dynamic>?)
              ?.map((e) => MonthlyStat.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      lastUpdatedAt: json['lastUpdatedAt'] == null
          ? null
          : DateTime.parse(json['lastUpdatedAt'] as String),
    );

Map<String, dynamic> _$$HelpStatisticsImplToJson(
  _$HelpStatisticsImpl instance,
) => <String, dynamic>{
  'totalRequests': instance.totalRequests,
  'aiResolvedCount': instance.aiResolvedCount,
  'volunteerHelpCount': instance.volunteerHelpCount,
  'sosCount': instance.sosCount,
  'aiResolutionRate': instance.aiResolutionRate,
  'totalDurationMinutes': instance.totalDurationMinutes,
  'averageRating': instance.averageRating,
  'typeStats': instance.typeStats,
  'monthlyStats': instance.monthlyStats,
  'lastUpdatedAt': instance.lastUpdatedAt?.toIso8601String(),
};

_$HelpTypeStatImpl _$$HelpTypeStatImplFromJson(Map<String, dynamic> json) =>
    _$HelpTypeStatImpl(
      type: json['type'] as String,
      count: (json['count'] as num).toInt(),
      typeLabel: json['typeLabel'] as String?,
    );

Map<String, dynamic> _$$HelpTypeStatImplToJson(_$HelpTypeStatImpl instance) =>
    <String, dynamic>{
      'type': instance.type,
      'count': instance.count,
      'typeLabel': instance.typeLabel,
    };

_$MonthlyStatImpl _$$MonthlyStatImplFromJson(Map<String, dynamic> json) =>
    _$MonthlyStatImpl(
      month: json['month'] as String,
      count: (json['count'] as num).toInt(),
      aiCount: (json['aiCount'] as num?)?.toInt() ?? 0,
      volunteerCount: (json['volunteerCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$MonthlyStatImplToJson(_$MonthlyStatImpl instance) =>
    <String, dynamic>{
      'month': instance.month,
      'count': instance.count,
      'aiCount': instance.aiCount,
      'volunteerCount': instance.volunteerCount,
    };
