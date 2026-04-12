import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';
import '../../models/point_transaction_model.dart';

/// 安心积分服务 (F15)
/// 管理求助者的积分获取和使用
class PointsService {
  final SupabaseClient _supabase;

  PointsService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// 获取用户当前积分
  Future<int> getCurrentPoints(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('points')
          .eq('id', userId)
          .single();

      return response['points'] ?? 0;
    } catch (e) {
      AppLogger.error('获取用户积分失败', e);
      return 0;
    }
  }

  /// 获取积分交易记录
  Future<List<PointTransactionModel>> getTransactions(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('point_transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => PointTransactionModel.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('获取积分交易记录失败', e);
      return [];
    }
  }

  /// 计算每日签到积分
  /// 连续签到规则：
  /// - 连续1天: +1
  /// - 连续7天: +10（额外奖励）
  /// - 连续30天: +50（月度奖励）
  Future<int> calculateDailyPoints(String userId) async {
    try {
      // 获取用户签到数据
      final response = await _supabase
          .from('user_checkins')
          .select()
          .eq('user_id', userId)
          .order('checkin_date', ascending: false)
          .limit(1);

      final checkins = response as List;
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // 检查今天是否已签到
      if (checkins.isNotEmpty) {
        final lastCheckin = checkins.first;
        if (lastCheckin['checkin_date'] == todayStr) {
          return 0; // 今天已签到
        }
      }

      // 计算连续签到天数
      final consecutiveDays = await _getConsecutiveDays(userId);

      // 计算应得积分
      int points = PointRules.dailyCheckIn; // 基础签到积分

      // 检查是否达到连续奖励条件
      final newConsecutiveDays = consecutiveDays + 1;
      if (newConsecutiveDays % 30 == 0) {
        // 连续30天奖励
        points += PointRules.monthlyBonus;
      } else if (newConsecutiveDays % 7 == 0) {
        // 连续7天奖励
        points += PointRules.weeklyBonus;
      }

      return points;
    } catch (e) {
      AppLogger.error('计算每日积分失败', e);
      return PointRules.dailyCheckIn;
    }
  }

  /// 执行每日签到
  Future<DailyCheckInResult> performDailyCheckIn(String userId) async {
    try {
      // 计算应得积分
      final points = await calculateDailyPoints(userId);

      if (points == 0) {
        return const DailyCheckInResult(
          success: false,
          message: '今天已经签到过了',
        );
      }

      // 获取连续天数
      final consecutiveDays = await _getConsecutiveDays(userId);
      final newConsecutiveDays = consecutiveDays + 1;

      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // 记录签到
      await _supabase.from('user_checkins').insert({
        'user_id': userId,
        'checkin_date': todayStr,
        'consecutive_days': newConsecutiveDays,
        'points_earned': points,
      });

      // 更新用户总积分
      await _addPoints(userId, points, PointTransactionType.dailyCheckIn,
          description: '每日签到');

      // 检查连续奖励
      String? bonusMessage;
      if (newConsecutiveDays % 30 == 0) {
        bonusMessage = '🎉 恭喜！连续签到30天，获得额外奖励！';
      } else if (newConsecutiveDays % 7 == 0) {
        bonusMessage = '🎊 连续签到7天，获得额外奖励！';
      }

      return DailyCheckInResult(
        success: true,
        points: points,
        consecutiveDays: newConsecutiveDays,
        message: bonusMessage ?? '签到成功，获得$points积分',
      );
    } catch (e) {
      AppLogger.error('每日签到失败', e);
      return DailyCheckInResult(
        success: false,
        message: '签到失败：$e',
      );
    }
  }

  /// 领取连续签到奖励（手动触发）
  Future<void> claimContinuousBonus(String userId) async {
    try {
      final consecutiveDays = await _getConsecutiveDays(userId);

      // 检查是否已领取过本周/本月奖励
      final lastBonus = await _supabase
          .from('point_transactions')
          .select()
          .eq('user_id', userId)
          .eq('type', PointTransactionType.weeklyBonus.name)
          .order('created_at', ascending: false)
          .limit(1);

      // 这里可以实现更复杂的奖励领取逻辑
      // 目前奖励是自动发放的
    } catch (e) {
      AppLogger.error('领取连续奖励失败', e);
    }
  }

  /// 获取连续签到天数
  Future<int> _getConsecutiveDays(String userId) async {
    try {
      final response = await _supabase
          .from('user_checkins')
          .select()
          .eq('user_id', userId)
          .order('checkin_date', ascending: false)
          .limit(1);

      final checkins = response as List;
      if (checkins.isEmpty) return 0;

      final lastCheckin = checkins.first;
      final lastDate = DateTime.parse(lastCheckin['checkin_date']);
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      // 检查上次签到是否是昨天或今天
      final lastDateStr =
          '${lastDate.year}-${lastDate.month.toString().padLeft(2, '0')}-${lastDate.day.toString().padLeft(2, '0')}';
      final yesterdayStr =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      if (lastDateStr == yesterdayStr || lastDateStr == todayStr) {
        return lastCheckin['consecutive_days'] ?? 0;
      }

      return 0; // 断签了
    } catch (e) {
      AppLogger.error('获取连续签到天数失败', e);
      return 0;
    }
  }

  /// 添加积分
  Future<void> _addPoints(
    String userId,
    int points,
    PointTransactionType type, {
    String? description,
    String? relatedId,
  }) async {
    try {
      // 使用数据库事务或RPC来确保原子性
      await _supabase.rpc('add_user_points', params: {
        'p_user_id': userId,
        'p_points': points,
        'p_type': type.name,
        'p_description': description,
        'p_related_id': relatedId,
      });
    } catch (e) {
      AppLogger.error('添加积分失败', e);
      // 降级方案：直接更新
      await _supabase.rpc('increment_user_points', params: {
        'user_id': userId,
        'points': points,
      });
    }
  }

  /// 使用积分（兑换）
  Future<bool> usePoints(
    String userId,
    int points, {
    required String description,
    String? relatedId,
  }) async {
    try {
      final currentPoints = await getCurrentPoints(userId);
      if (currentPoints < points) {
        return false; // 积分不足
      }

      await _supabase.rpc('use_user_points', params: {
        'p_user_id': userId,
        'p_points': points,
        'p_description': description,
        'p_related_id': relatedId,
      });

      return true;
    } catch (e) {
      AppLogger.error('使用积分失败', e);
      return false;
    }
  }

  /// 获取签到状态
  Future<CheckInStatus> getCheckInStatus(String userId) async {
    try {
      final consecutiveDays = await _getConsecutiveDays(userId);
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // 检查今天是否已签到
      final response = await _supabase
          .from('user_checkins')
          .select()
          .eq('user_id', userId)
          .eq('checkin_date', todayStr)
          .maybeSingle();

      final hasCheckedInToday = response != null;

      // 计算明日可获积分
      int tomorrowPoints = PointRules.dailyCheckIn;
      final tomorrowConsecutive = consecutiveDays + (hasCheckedInToday ? 1 : 0);
      if ((tomorrowConsecutive + 1) % 30 == 0) {
        tomorrowPoints += PointRules.monthlyBonus;
      } else if ((tomorrowConsecutive + 1) % 7 == 0) {
        tomorrowPoints += PointRules.weeklyBonus;
      }

      return CheckInStatus(
        hasCheckedInToday: hasCheckedInToday,
        consecutiveDays: consecutiveDays,
        tomorrowPoints: tomorrowPoints,
        nextMilestone: _getNextMilestone(tomorrowConsecutive + 1),
      );
    } catch (e) {
      AppLogger.error('获取签到状态失败', e);
      return const CheckInStatus();
    }
  }

  /// 获取下一个里程碑
  String _getNextMilestone(int consecutiveDays) {
    if (consecutiveDays < 7) {
      return '连续7天 (+${PointRules.weeklyBonus})';
    } else if (consecutiveDays < 30) {
      return '连续30天 (+${PointRules.monthlyBonus})';
    } else {
      final next30 = ((consecutiveDays ~/ 30) + 1) * 30;
      return '连续$next30天 (+${PointRules.monthlyBonus})';
    }
  }
}

/// 每日签到结果
class DailyCheckInResult {
  final bool success;
  final int? points;
  final int? consecutiveDays;
  final String message;

  const DailyCheckInResult({
    required this.success,
    this.points,
    this.consecutiveDays,
    required this.message,
  });
}

/// 签到状态
class CheckInStatus {
  final bool hasCheckedInToday;
  final int consecutiveDays;
  final int tomorrowPoints;
  final String nextMilestone;

  const CheckInStatus({
    this.hasCheckedInToday = false,
    this.consecutiveDays = 0,
    this.tomorrowPoints = 1,
    this.nextMilestone = '',
  });
}
