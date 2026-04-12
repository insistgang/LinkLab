// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeline_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TimelineModelImpl _$$TimelineModelImplFromJson(Map<String, dynamic> json) =>
    _$TimelineModelImpl(
      volunteerId: json['volunteerId'] as String,
      year: (json['year'] as num).toInt(),
      days:
          (json['days'] as List<dynamic>?)
              ?.map((e) => TimelineDay.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      totalHelps: (json['totalHelps'] as num?)?.toInt() ?? 0,
      totalMinutes: (json['totalMinutes'] as num?)?.toInt() ?? 0,
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
      stats: json['stats'] == null
          ? null
          : TimelineStats.fromJson(json['stats'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$TimelineModelImplToJson(_$TimelineModelImpl instance) =>
    <String, dynamic>{
      'volunteerId': instance.volunteerId,
      'year': instance.year,
      'days': instance.days,
      'totalHelps': instance.totalHelps,
      'totalMinutes': instance.totalMinutes,
      'streakDays': instance.streakDays,
      'stats': instance.stats,
    };

_$TimelineDayImpl _$$TimelineDayImplFromJson(Map<String, dynamic> json) =>
    _$TimelineDayImpl(
      date: json['date'] as String,
      helpCount: (json['helpCount'] as num?)?.toInt() ?? 0,
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
      events:
          (json['events'] as List<dynamic>?)
              ?.map((e) => TimelineEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$TimelineDayImplToJson(_$TimelineDayImpl instance) =>
    <String, dynamic>{
      'date': instance.date,
      'helpCount': instance.helpCount,
      'minutes': instance.minutes,
      'events': instance.events,
    };

_$TimelineEventImpl _$$TimelineEventImplFromJson(Map<String, dynamic> json) =>
    _$TimelineEventImpl(
      id: json['id'] as String,
      type: json['type'] as String,
      seekerName: json['seekerName'] as String?,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      rating: (json['rating'] as num?)?.toInt(),
      thankYouNote: json['thankYouNote'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$TimelineEventImplToJson(_$TimelineEventImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'seekerName': instance.seekerName,
      'durationMinutes': instance.durationMinutes,
      'rating': instance.rating,
      'thankYouNote': instance.thankYouNote,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

_$TimelineStatsImpl _$$TimelineStatsImplFromJson(Map<String, dynamic> json) =>
    _$TimelineStatsImpl(
      realtimeHelpCount: (json['realtimeHelpCount'] as num?)?.toInt() ?? 0,
      asyncHelpCount: (json['asyncHelpCount'] as num?)?.toInt() ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      fiveStarCount: (json['fiveStarCount'] as num?)?.toInt() ?? 0,
      mostHelpedSeekerId: json['mostHelpedSeekerId'] as String?,
      mostHelpedSeekerName: json['mostHelpedSeekerName'] as String?,
      mostHelpedCount: (json['mostHelpedCount'] as num?)?.toInt() ?? 0,
      topSkills:
          (json['topSkills'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$TimelineStatsImplToJson(_$TimelineStatsImpl instance) =>
    <String, dynamic>{
      'realtimeHelpCount': instance.realtimeHelpCount,
      'asyncHelpCount': instance.asyncHelpCount,
      'averageRating': instance.averageRating,
      'fiveStarCount': instance.fiveStarCount,
      'mostHelpedSeekerId': instance.mostHelpedSeekerId,
      'mostHelpedSeekerName': instance.mostHelpedSeekerName,
      'mostHelpedCount': instance.mostHelpedCount,
      'topSkills': instance.topSkills,
    };

_$AnnualReportImpl _$$AnnualReportImplFromJson(Map<String, dynamic> json) =>
    _$AnnualReportImpl(
      volunteerId: json['volunteerId'] as String,
      year: (json['year'] as num).toInt(),
      title: json['title'] as String,
      sections:
          (json['sections'] as List<dynamic>?)
              ?.map((e) => ReportSection.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      generatedAt: json['generatedAt'] == null
          ? null
          : DateTime.parse(json['generatedAt'] as String),
    );

Map<String, dynamic> _$$AnnualReportImplToJson(_$AnnualReportImpl instance) =>
    <String, dynamic>{
      'volunteerId': instance.volunteerId,
      'year': instance.year,
      'title': instance.title,
      'sections': instance.sections,
      'generatedAt': instance.generatedAt?.toIso8601String(),
    };

_$ReportSectionImpl _$$ReportSectionImplFromJson(Map<String, dynamic> json) =>
    _$ReportSectionImpl(
      type: json['type'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$ReportSectionImplToJson(_$ReportSectionImpl instance) =>
    <String, dynamic>{
      'type': instance.type,
      'title': instance.title,
      'subtitle': instance.subtitle,
      'data': instance.data,
    };
