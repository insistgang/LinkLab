import 'package:freezed_annotation/freezed_annotation.dart';

part 'schedule_model.freezed.dart';
part 'schedule_model.g.dart';

/// 排班设置模型
@freezed
class ScheduleModel with _$ScheduleModel {
  const factory ScheduleModel({
    required String userId,
    @Default({}) Map<String, List<TimeSlot>> weeklySchedule,
    @Default(false) bool isOnline,
    @Default(OnlineStatus.offline) OnlineStatus status,
    DateTime? lastStatusUpdateAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ScheduleModel;

  factory ScheduleModel.fromJson(Map<String, dynamic> json) =>
      _$ScheduleModelFromJson(json);

  const ScheduleModel._();

  /// 默认排班（空）
  static Map<String, List<TimeSlot>> get defaultSchedule => {
    'monday': [],
    'tuesday': [],
    'wednesday': [],
    'thursday': [],
    'friday': [],
    'saturday': [],
    'sunday': [],
  };

  /// 检查当前是否可用
  bool isAvailableNow() {
    if (!isOnline || status == OnlineStatus.busy) return false;

    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);
    final slots = weeklySchedule[dayName] ?? [];

    if (slots.isEmpty) return false;

    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

    for (final slot in slots) {
      if (slot.contains(currentTime)) return true;
    }

    return false;
  }

  /// 获取今日可用时段
  List<TimeSlot> getTodaySlots() {
    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);
    return weeklySchedule[dayName] ?? [];
  }

  /// 获取星期名称
  String _getDayName(int weekday) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[weekday - 1];
  }
}

/// 时间段
@freezed
class TimeSlot with _$TimeSlot {
  const factory TimeSlot({
    required String start,
    required String end,
  }) = _TimeSlot;

  factory TimeSlot.fromJson(Map<String, dynamic> json) =>
      _$TimeSlotFromJson(json);

  const TimeSlot._();

  /// 解析时间字符串 "HH:mm"
  TimeOfDay get startTime => TimeOfDay.fromString(start);
  TimeOfDay get endTime => TimeOfDay.fromString(end);

  /// 检查时间是否在时段内
  bool contains(TimeOfDay time) {
    final start = startTime;
    final end = endTime;

    final timeMinutes = time.hour * 60 + time.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    return timeMinutes >= startMinutes && timeMinutes <= endMinutes;
  }

  /// 格式化显示
  String get displayText => '$start - $end';
}

/// 在线状态
enum OnlineStatus {
  /// 在线
  online,
  /// 离线
  offline,
  /// 忙碌中
  busy,
}

/// 时间辅助类
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  factory TimeOfDay.fromString(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  @override
  String toString() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// 星期几枚举
enum WeekDay {
  monday('周一', 'monday'),
  tuesday('周二', 'tuesday'),
  wednesday('周三', 'wednesday'),
  thursday('周四', 'thursday'),
  friday('周五', 'friday'),
  saturday('周六', 'saturday'),
  sunday('周日', 'sunday');

  final String displayName;
  final String key;

  const WeekDay(this.displayName, this.key);
}
