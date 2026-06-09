import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/logger.dart';
import '../../models/schedule_model.dart';
import 'volunteer_demo_store.dart';

/// 排班服務 (F23)
/// 管理志願者的可用時間和在線狀態
class ScheduleService {
  ScheduleService({
    SupabaseClient? supabase,
    VolunteerDemoStore? demoStore,
  })  : _supabaseClient = supabase,
        _demoStore = demoStore ?? VolunteerDemoStore();

  SupabaseClient? _supabaseClient;
  final VolunteerDemoStore _demoStore;

  bool get _hasSupabase => Supabase.instance.isInitialized;

  SupabaseClient get _supabase {
    if (!_hasSupabase) {
      throw StateError('Supabase not initialized');
    }
    _supabaseClient ??= Supabase.instance.client;
    return _supabaseClient!;
  }

  /// 獲取志願者的排班設置
  Future<ScheduleModel> getSchedule(String volunteerId) async {
    if (!_hasSupabase) {
      try {
        return await _demoStore.getSchedule(volunteerId);
      } catch (e) {
        AppLogger.error('獲取本地排班設置失敗', e);
        return ScheduleModel(
          userId: volunteerId,
          weeklySchedule: ScheduleModel.defaultSchedule,
        );
      }
    }

    try {
      final response = await _supabase
          .from('volunteer_profiles')
          .select('available_schedule, is_online, last_heartbeat_at')
          .eq('user_id', volunteerId)
          .single();

      final responseMap = Map<String, dynamic>.from(response as Map);
      final scheduleData =
          responseMap['available_schedule'] as Map<String, dynamic>?;

      return ScheduleModel(
        userId: volunteerId,
        weeklySchedule: _parseWeeklySchedule(scheduleData),
        isOnline: responseMap['is_online'] as bool? ?? false,
        lastStatusUpdateAt: responseMap['last_heartbeat_at'] != null
            ? DateTime.parse(responseMap['last_heartbeat_at'].toString())
            : null,
      );
    } catch (e) {
      AppLogger.error('獲取排班設置失敗', e);
      return ScheduleModel(
        userId: volunteerId,
        weeklySchedule: ScheduleModel.defaultSchedule,
      );
    }
  }

  /// 解析周排班數據
  Map<String, List<TimeSlot>> _parseWeeklySchedule(Map<String, dynamic>? data) {
    if (data == null) return ScheduleModel.defaultSchedule;

    final result = <String, List<TimeSlot>>{};

    for (final day in ScheduleModel.defaultSchedule.keys) {
      final dayData = data[day] as List?; 
      if (dayData != null) {
        result[day] = dayData
            .map(
              (slot) {
                final slotMap = Map<String, dynamic>.from(slot as Map);
                return TimeSlot(
                  start: slotMap['start'].toString(),
                  end: slotMap['end'].toString(),
                );
              },
            )
            .toList();
      } else {
        result[day] = [];
      }
    }

    return result;
  }

  /// 更新排班設置
  Future<bool> updateSchedule(
    String volunteerId,
    Map<String, List<TimeSlot>> weeklySchedule,
  ) async {
    if (!_hasSupabase) {
      try {
        final current = await _demoStore.getSchedule(volunteerId);
        await _demoStore.saveSchedule(
          current.copyWith(
            weeklySchedule: weeklySchedule,
            updatedAt: DateTime.now(),
          ),
        );
        return true;
      } catch (e) {
        AppLogger.error('更新本地排班設置失敗', e);
        return false;
      }
    }

    try {
      // 轉換爲JSON格式
      final scheduleData = <String, List<Map<String, String>>>{};
      weeklySchedule.forEach((day, slots) {
        scheduleData[day] = slots
            .map((slot) => {'start': slot.start, 'end': slot.end})
            .toList();
      });

      await _supabase
          .from('volunteer_profiles')
          .update({
            'available_schedule': scheduleData,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', volunteerId);

      AppLogger.info('更新排班設置成功: $volunteerId');
      return true;
    } catch (e) {
      AppLogger.error('更新排班設置失敗', e);
      return false;
    }
  }

  /// 更新單日排班
  Future<bool> updateDaySchedule(
    String volunteerId,
    String day,
    List<TimeSlot> slots,
  ) async {
    try {
      // 獲取當前排班
      final currentSchedule = await getSchedule(volunteerId);

      // 更新指定日期
      final updatedSchedule = Map<String, List<TimeSlot>>.from(
        currentSchedule.weeklySchedule,
      );
      updatedSchedule[day] = slots;

      return await updateSchedule(volunteerId, updatedSchedule);
    } catch (e) {
      AppLogger.error('更新單日排班失敗', e);
      return false;
    }
  }

  /// 添加時間段
  Future<bool> addTimeSlot(
    String volunteerId,
    String day,
    TimeSlot newSlot,
  ) async {
    try {
      final currentSchedule = await getSchedule(volunteerId);
      final currentSlots = List<TimeSlot>.from(
        currentSchedule.weeklySchedule[day] ?? [],
      );

      // 檢查時間衝突
      if (_hasTimeConflict(currentSlots, newSlot)) {
        AppLogger.warning('時間段衝突: $day ${newSlot.displayText}');
        return false;
      }

      currentSlots.add(newSlot);
      // 按開始時間排序
      currentSlots.sort((a, b) => a.start.compareTo(b.start));

      return await updateDaySchedule(volunteerId, day, currentSlots);
    } catch (e) {
      AppLogger.error('添加時間段失敗', e);
      return false;
    }
  }

  /// 移除時間段
  Future<bool> removeTimeSlot(
    String volunteerId,
    String day,
    int slotIndex,
  ) async {
    try {
      final currentSchedule = await getSchedule(volunteerId);
      final currentSlots = List<TimeSlot>.from(
        currentSchedule.weeklySchedule[day] ?? [],
      );

      if (slotIndex >= 0 && slotIndex < currentSlots.length) {
        currentSlots.removeAt(slotIndex);
        return await updateDaySchedule(volunteerId, day, currentSlots);
      }

      return false;
    } catch (e) {
      AppLogger.error('移除時間段失敗', e);
      return false;
    }
  }

  /// 檢查時間衝突
  bool _hasTimeConflict(List<TimeSlot> existingSlots, TimeSlot newSlot) {
    final newStart = _timeToMinutes(newSlot.start);
    final newEnd = _timeToMinutes(newSlot.end);

    for (final slot in existingSlots) {
      final start = _timeToMinutes(slot.start);
      final end = _timeToMinutes(slot.end);

      // 檢查是否有重疊
      if ((newStart >= start && newStart < end) ||
          (newEnd > start && newEnd <= end) ||
          (newStart <= start && newEnd >= end)) {
        return true;
      }
    }

    return false;
  }

  /// 時間轉換爲分鐘數
  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  /// 檢查是否在線（兼容UI調用）
  Future<bool> isOnline(String volunteerId) async {
    final schedule = await getSchedule(volunteerId);
    return schedule.isOnline;
  }

  /// 設置在線（兼容UI調用）
  Future<bool> goOnline(String volunteerId) async {
    return setOnlineStatus(volunteerId, true, status: OnlineStatus.online);
  }

  /// 設置離線（兼容UI調用）
  Future<bool> goOffline(String volunteerId) async {
    return setOnlineStatus(volunteerId, false, status: OnlineStatus.offline);
  }

  /// 設置在線狀態
  Future<bool> setOnlineStatus(
    String volunteerId,
    bool isOnline, {
    OnlineStatus status = OnlineStatus.online,
  }) async {
    if (!_hasSupabase) {
      try {
        final schedule = await _demoStore.getSchedule(volunteerId);
        await _demoStore.saveSchedule(
          schedule.copyWith(
            isOnline: isOnline,
            status: status,
            lastStatusUpdateAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        return true;
      } catch (e) {
        AppLogger.error('設置本地在線狀態失敗', e);
        return false;
      }
    }

    try {
      await _supabase
          .from('volunteer_profiles')
          .update({
            'is_online': isOnline,
            'online_status': status.name,
            'last_heartbeat_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', volunteerId);

      AppLogger.info('更新在線狀態: $volunteerId -> $isOnline');
      return true;
    } catch (e) {
      AppLogger.error('設置在線狀態失敗', e);
      return false;
    }
  }

  /// 更新心跳（保持在線狀態）
  Future<void> updateHeartbeat(String volunteerId) async {
    if (!_hasSupabase) {
      try {
        final schedule = await _demoStore.getSchedule(volunteerId);
        await _demoStore.saveSchedule(
          schedule.copyWith(
            lastStatusUpdateAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      } catch (e) {
        AppLogger.error('更新本地心跳失敗', e);
      }
      return;
    }

    try {
      await _supabase
          .from('volunteer_profiles')
          .update({
            'last_heartbeat_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', volunteerId);
    } catch (e) {
      AppLogger.error('更新心跳失敗', e);
    }
  }

  /// 檢查當前是否可用
  Future<bool> isAvailable(String volunteerId) async {
    try {
      final schedule = await getSchedule(volunteerId);

      // 檢查在線狀態
      if (!schedule.isOnline) return false;

      // 檢查當前時間是否在排班內
      final now = DateTime.now();
      final dayName = _getDayName(now.weekday);
      final slots = schedule.weeklySchedule[dayName] ?? [];

      if (slots.isEmpty) return false;

      final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

      for (final slot in slots) {
        if (slot.contains(currentTime)) return true;
      }

      return false;
    } catch (e) {
      AppLogger.error('檢查可用性失敗', e);
      return false;
    }
  }

  /// 獲取下一個可用時段
  Future<TimeSlot?> getNextAvailableSlot(String volunteerId) async {
    try {
      final schedule = await getSchedule(volunteerId);
      final now = DateTime.now();
      final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

      // 從今天開始查找
      for (int i = 0; i < 7; i++) {
        final checkDate = now.add(Duration(days: i));
        final dayName = _getDayName(checkDate.weekday);
        final slots = schedule.weeklySchedule[dayName] ?? [];

        for (final slot in slots) {
          // 如果是今天，檢查時間是否已過
          if (i == 0) {
            final slotStart = slot.startTime;
            if (slotStart.hour < currentTime.hour ||
                (slotStart.hour == currentTime.hour &&
                    slotStart.minute <= currentTime.minute)) {
              continue;
            }
          }
          return slot;
        }
      }

      return null;
    } catch (e) {
      AppLogger.error('獲取下一個可用時段失敗', e);
      return null;
    }
  }

  /// 獲取今日可用時段
  Future<List<TimeSlot>> getTodaySlots(String volunteerId) async {
    try {
      final schedule = await getSchedule(volunteerId);
      final now = DateTime.now();
      final dayName = _getDayName(now.weekday);
      return schedule.weeklySchedule[dayName] ?? [];
    } catch (e) {
      AppLogger.error('獲取今日時段失敗', e);
      return [];
    }
  }

  /// 獲取星期名稱
  String _getDayName(int weekday) {
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    return days[weekday - 1];
  }

  /// 獲取可用性統計
  Future<AvailabilityStats> getAvailabilityStats(String volunteerId) async {
    try {
      final schedule = await getSchedule(volunteerId);

      // 計算每週總小時數
      double totalHoursPerWeek = 0;
      int daysWithSlots = 0;

      schedule.weeklySchedule.forEach((day, slots) {
        if (slots.isNotEmpty) {
          daysWithSlots++;
          for (final slot in slots) {
            final startMinutes = _timeToMinutes(slot.start);
            final endMinutes = _timeToMinutes(slot.end);
            totalHoursPerWeek += (endMinutes - startMinutes) / 60;
          }
        }
      });

      return AvailabilityStats(
        totalHoursPerWeek: totalHoursPerWeek,
        daysWithSlots: daysWithSlots,
        isOnline: schedule.isOnline,
      );
    } catch (e) {
      AppLogger.error('獲取可用性統計失敗', e);
      return const AvailabilityStats();
    }
  }

  /// 智能推薦排班
  List<RecommendedSlot> getRecommendedSlots() {
    return [
      RecommendedSlot(
        day: 'weekday_evening',
        title: '工作日晚間',
        description: '週一至週五 19:00-22:00',
        slots: {
          'monday': [const TimeSlot(start: '19:00', end: '22:00')],
          'tuesday': [const TimeSlot(start: '19:00', end: '22:00')],
          'wednesday': [const TimeSlot(start: '19:00', end: '22:00')],
          'thursday': [const TimeSlot(start: '19:00', end: '22:00')],
          'friday': [const TimeSlot(start: '19:00', end: '22:00')],
          'saturday': [],
          'sunday': [],
        },
      ),
      RecommendedSlot(
        day: 'weekend_day',
        title: '週末白天',
        description: '週六日 09:00-18:00',
        slots: {
          'monday': [],
          'tuesday': [],
          'wednesday': [],
          'thursday': [],
          'friday': [],
          'saturday': [const TimeSlot(start: '09:00', end: '18:00')],
          'sunday': [const TimeSlot(start: '09:00', end: '18:00')],
        },
      ),
      RecommendedSlot(
        day: 'full_week',
        title: '全周服務',
        description: '每天 19:00-22:00',
        slots: {
          'monday': [const TimeSlot(start: '19:00', end: '22:00')],
          'tuesday': [const TimeSlot(start: '19:00', end: '22:00')],
          'wednesday': [const TimeSlot(start: '19:00', end: '22:00')],
          'thursday': [const TimeSlot(start: '19:00', end: '22:00')],
          'friday': [const TimeSlot(start: '19:00', end: '22:00')],
          'saturday': [const TimeSlot(start: '19:00', end: '22:00')],
          'sunday': [const TimeSlot(start: '19:00', end: '22:00')],
        },
      ),
    ];
  }

  /// 應用推薦排班
  Future<bool> applyRecommendedSlot(
    String volunteerId,
    RecommendedSlot recommended,
  ) async {
    return await updateSchedule(volunteerId, recommended.slots);
  }
}

/// 可用性統計
class AvailabilityStats {
  final double totalHoursPerWeek;
  final int daysWithSlots;
  final bool isOnline;

  const AvailabilityStats({
    this.totalHoursPerWeek = 0,
    this.daysWithSlots = 0,
    this.isOnline = false,
  });

  /// 平均每日小時數
  double get averageHoursPerDay {
    if (daysWithSlots == 0) return 0;
    return totalHoursPerWeek / daysWithSlots;
  }
}

/// 推薦時段
class RecommendedSlot {
  final String day;
  final String title;
  final String description;
  final Map<String, List<TimeSlot>> slots;

  RecommendedSlot({
    required this.day,
    required this.title,
    required this.description,
    required this.slots,
  });
}
