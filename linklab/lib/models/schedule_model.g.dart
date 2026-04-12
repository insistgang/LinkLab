// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ScheduleModelImpl _$$ScheduleModelImplFromJson(Map<String, dynamic> json) =>
    _$ScheduleModelImpl(
      userId: json['userId'] as String,
      weeklySchedule:
          (json['weeklySchedule'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              (e as List<dynamic>)
                  .map((e) => TimeSlot.fromJson(e as Map<String, dynamic>))
                  .toList(),
            ),
          ) ??
          const {},
      isOnline: json['isOnline'] as bool? ?? false,
      status:
          $enumDecodeNullable(_$OnlineStatusEnumMap, json['status']) ??
          OnlineStatus.offline,
      lastStatusUpdateAt: json['lastStatusUpdateAt'] == null
          ? null
          : DateTime.parse(json['lastStatusUpdateAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$ScheduleModelImplToJson(_$ScheduleModelImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'weeklySchedule': instance.weeklySchedule,
      'isOnline': instance.isOnline,
      'status': _$OnlineStatusEnumMap[instance.status]!,
      'lastStatusUpdateAt': instance.lastStatusUpdateAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$OnlineStatusEnumMap = {
  OnlineStatus.online: 'online',
  OnlineStatus.offline: 'offline',
  OnlineStatus.busy: 'busy',
};

_$TimeSlotImpl _$$TimeSlotImplFromJson(Map<String, dynamic> json) =>
    _$TimeSlotImpl(start: json['start'] as String, end: json['end'] as String);

Map<String, dynamic> _$$TimeSlotImplToJson(_$TimeSlotImpl instance) =>
    <String, dynamic>{'start': instance.start, 'end': instance.end};
