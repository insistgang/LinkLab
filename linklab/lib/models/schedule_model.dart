import 'package:freezed_annotation/freezed_annotation.dart';

part 'schedule_model.freezed.dart';
part 'schedule_model.g.dart';

/// 排班設置模型
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

  /// 默認排班（空）
  static Map<String, List<TimeSlot>> get defaultSchedule => {
    'monday': [],
    'tuesday': [],
    'wednesday': [],
    'thursday': [],
    'friday': [],
    'saturday': [],
    'sunday': [],
  };

  /// 檢查當前是否可用
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

  /// 獲取今日可用時段
  List<TimeSlot> getTodaySlots() {
    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);
    return weeklySchedule[dayName] ?? [];
  }

  /// 獲取星期名稱
  String _getDayName(int weekday) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[weekday - 1];
  }
}

/// 時間段
@freezed
class TimeSlot with _$TimeSlot {
  const factory TimeSlot({
    required String start,
    required String end,
  }) = _TimeSlot;

  factory TimeSlot.fromJson(Map<String, dynamic> json) =>
      _$TimeSlotFromJson(json);

  const TimeSlot._();

  /// 解析時間字符串 "HH:mm"
  TimeOfDay get startTime => TimeOfDay.fromString(start);
  TimeOfDay get endTime => TimeOfDay.fromString(end);

  /// 檢查時間是否在時段內
  bool contains(TimeOfDay time) {
    final start = startTime;
    final end = endTime;

    final timeMinutes = time.hour * 60 + time.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    return timeMinutes >= startMinutes && timeMinutes <= endMinutes;
  }

  /// 格式化顯示
  String get displayText => '$start - $end';
}

/// 在線狀態
enum OnlineStatus {
  /// 在線
  online,
  /// 離線
  offline,
  /// 忙碌中
  busy,
}

/// 時間輔助類
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

/// 星期幾枚舉
enum WeekDay {
  monday('週一', 'monday'),
  tuesday('週二', 'tuesday'),
  wednesday('週三', 'wednesday'),
  thursday('週四', 'thursday'),
  friday('週五', 'friday'),
  saturday('週六', 'saturday'),
  sunday('週日', 'sunday');

  final String displayName;
  final String key;

  const WeekDay(this.displayName, this.key);
}
