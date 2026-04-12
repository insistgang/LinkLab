import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';
import '../../models/volunteer_level_model.dart';
import '../../models/point_transaction_model.dart';

/// 志愿者等级服务 (F18)
/// 7级体系：青苗→嫩芽→新叶→绿荫→暖阳→星辰→灯塔
class VolunteerLevelService {
  final SupabaseClient _supabase;

  VolunteerLevelService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// 获取志愿者等级信息
  Future<VolunteerLevelInfo> getLevelInfo(String volunteerId) async {
    try {
      final response = await _supabase
          .from('volunteer_profiles')
          .select('level, points')
          .eq('user_id', volunteerId)
          .single();

      final currentLevel = response['level'] ?? 1;
      final currentPoints = response['points'] ?? 0;

      return _buildLevelInfo(currentLevel, currentPoints);
    } catch (e) {
      AppLogger.error('获取志愿者等级信息失败', e);
      return _buildLevelInfo(1, 0);
    }
  }

  /// 计算等级信息
  VolunteerLevelInfo _buildLevelInfo(int currentLevel, int currentPoints) {
    final currentLevelDef = LevelDefinitions.getByLevel(currentLevel);
    final pointsToNext = LevelDefinitions.getPointsToNextLevel(currentPoints);
    final progressPercent = LevelDefinitions.getProgressPercent(currentPoints);

    LevelDefinition? nextLevel;
    if (currentLevel < 7) {
      nextLevel = LevelDefinitions.getByLevel(currentLevel + 1);
    }

    return VolunteerLevelInfo(
      currentLevel: currentLevel,
      currentPoints: currentPoints,
      pointsToNextLevel: pointsToNext,
      progressPercent: progressPercent,
      nextLevel: nextLevel,
      allLevels: LevelDefinitions.all,
    );
  }

  /// 计算等级（根据积分）
  Future<LevelInfo> calculateLevel(String volunteerId) async {
    try {
      final response = await _supabase
          .from('volunteer_profiles')
          .select('points')
          .eq('user_id', volunteerId)
          .single();

      final points = response['points'] ?? 0;
      final level = LevelDefinitions.calculateLevel(points);
      final levelDef = LevelDefinitions.getByLevel(level);

      return LevelInfo(
        level: level,
        name: levelDef.name,
        emoji: levelDef.emoji,
        points: points,
        minPoints: levelDef.minPoints,
        maxPoints: levelDef.maxPoints,
      );
    } catch (e) {
      AppLogger.error('计算等级失败', e);
      return const LevelInfo(
        level: 1,
        name: '青苗',
        emoji: '🌱',
        points: 0,
        minPoints: 0,
        maxPoints: 99,
      );
    }
  }

  /// 检查并升级等级
  /// 返回升级结果，如果没有升级返回null
  Future<LevelUpResult?> checkAndUpgrade(String volunteerId) async {
    try {
      // 获取当前等级和积分
      final response = await _supabase
          .from('volunteer_profiles')
          .select('level, points')
          .eq('user_id', volunteerId)
          .single();

      final currentLevel = response['level'] ?? 1;
      final currentPoints = response['points'] ?? 0;

      // 计算应达到的等级
      final expectedLevel = LevelDefinitions.calculateLevel(currentPoints);

      // 如果应达等级高于当前等级，执行升级
      if (expectedLevel > currentLevel) {
        // 更新等级
        await _supabase
            .from('volunteer_profiles')
            .update({'level': expectedLevel})
            .eq('user_id', volunteerId);

        // 获取新旧等级定义
        final oldLevelDef = LevelDefinitions.getByLevel(currentLevel);
        final newLevelDef = LevelDefinitions.getByLevel(expectedLevel);

        // 获取新解锁的权益
        final newPrivileges = newLevelDef.privileges
            .where((p) => !oldLevelDef.privileges.contains(p))
            .toList();

        AppLogger.info('志愿者升级: $volunteerId Lv$currentLevel -> Lv$expectedLevel');

        return LevelUpResult(
          oldLevel: currentLevel,
          newLevel: expectedLevel,
          oldLevelName: oldLevelDef.name,
          newLevelName: newLevelDef.name,
          emoji: newLevelDef.emoji,
          newPrivileges: newPrivileges,
        );
      }

      return null; // 没有升级
    } catch (e) {
      AppLogger.error('检查升级失败', e);
      return null;
    }
  }

  /// 添加积分
  /// 在帮助完成后调用
  Future<void> addPoints(
    String volunteerId,
    int points,
    PointTransactionType type, {
    String? description,
    String? relatedId,
  }) async {
    try {
      // 使用RPC添加积分（原子操作）
      await _supabase.rpc('add_volunteer_points', params: {
        'p_volunteer_id': volunteerId,
        'p_points': points,
        'p_type': type.name,
        'p_description': description ?? PointRules.getTypeDescription(type),
        'p_related_id': relatedId,
      });

      // 检查是否需要升级
      await checkAndUpgrade(volunteerId);
    } catch (e) {
      AppLogger.error('添加积分失败', e);
      // 降级方案
      await _supabase.rpc('increment_volunteer_points', params: {
        'volunteer_id': volunteerId,
        'points': points,
      });
    }
  }

  /// 完成实时帮助后添加积分
  Future<void> onRealtimeHelpCompleted(
    String volunteerId,
    String helpRequestId, {
    int? seekerRating,
  }) async {
    // 基础积分
    await addPoints(
      volunteerId,
      PointRules.realtimeHelp,
      PointTransactionType.realtimeHelp,
      description: '完成实时帮助',
      relatedId: helpRequestId,
    );

    // 五星好评额外积分
    if (seekerRating == 5) {
      await addPoints(
        volunteerId,
        PointRules.fiveStarRating,
        PointTransactionType.fiveStarRating,
        description: '获得五星好评',
        relatedId: helpRequestId,
      );
    }

    // 检查连续帮助奖励
    await _checkContinuousHelpBonus(volunteerId);
  }

  /// 完成异步帮助后添加积分
  Future<void> onAsyncHelpCompleted(
    String volunteerId,
    String taskId, {
    int? seekerRating,
  }) async {
    await addPoints(
      volunteerId,
      PointRules.asyncHelp,
      PointTransactionType.asyncHelp,
      description: '完成异步帮助',
      relatedId: taskId,
    );

    if (seekerRating == 5) {
      await addPoints(
        volunteerId,
        PointRules.fiveStarRating,
        PointTransactionType.fiveStarRating,
        description: '获得五星好评',
        relatedId: taskId,
      );
    }

    await _checkContinuousHelpBonus(volunteerId);
  }

  /// 检查连续帮助奖励
  Future<void> _checkContinuousHelpBonus(String volunteerId) async {
    try {
      // 获取最近7天的帮助记录
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      final response = await _supabase
          .from('help_requests')
          .select('created_at')
          .eq('volunteer_id', volunteerId)
          .eq('status', 'completed')
          .gte('created_at', sevenDaysAgo.toIso8601String())
          .order('created_at', ascending: false);

      final helps = response as List;

      // 检查是否有连续7天的帮助
      final helpDates = helps
          .map((h) {
            final date = DateTime.parse(h['created_at']);
            return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          })
          .toSet()
          .toList();

      // 检查今天是否有帮助
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      if (helpDates.contains(todayStr) && helpDates.length >= 7) {
        // 检查是否已领取本周奖励
        final lastBonus = await _supabase
            .from('point_transactions')
            .select()
            .eq('user_id', volunteerId)
            .eq('type', PointTransactionType.continuousHelpBonus.name)
            .gte('created_at', sevenDaysAgo.toIso8601String())
            .maybeSingle();

        if (lastBonus == null) {
          // 发放连续帮助奖励
          await addPoints(
            volunteerId,
            PointRules.continuousHelpBonus,
            PointTransactionType.continuousHelpBonus,
            description: '连续7天帮助奖励',
          );
        }
      }
    } catch (e) {
      AppLogger.error('检查连续帮助奖励失败', e);
    }
  }

  /// 获取积分流水
  Future<List<PointTransactionModel>> getPointTransactions(
    String volunteerId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('point_transactions')
          .select()
          .eq('user_id', volunteerId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => PointTransactionModel.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('获取积分流水失败', e);
      return [];
    }
  }

  /// 惩罚扣分
  Future<void> applyPenalty(
    String volunteerId,
    String reason, {
    String? relatedId,
  }) async {
    try {
      await _supabase.rpc('add_volunteer_points', params: {
        'p_volunteer_id': volunteerId,
        'p_points': PointRules.penalty,
        'p_type': PointTransactionType.penalty.name,
        'p_description': '违规处罚: $reason',
        'p_related_id': relatedId,
      });

      AppLogger.warning('志愿者被处罚: $volunteerId, 原因: $reason');
    } catch (e) {
      AppLogger.error('应用惩罚失败', e);
    }
  }
}

/// 等级信息（简化版）
class LevelInfo {
  final int level;
  final String name;
  final String emoji;
  final int points;
  final int minPoints;
  final int maxPoints;

  const LevelInfo({
    required this.level,
    required this.name,
    required this.emoji,
    required this.points,
    required this.minPoints,
    required this.maxPoints,
  });

  /// 进度百分比
  double get progressPercent {
    if (maxPoints <= minPoints) return 1.0;
    return (points - minPoints) / (maxPoints - minPoints);
  }

  /// 到下一级所需积分
  int get pointsToNext => maxPoints - points;
}

/// 升级结果
class LevelUpResult {
  final int oldLevel;
  final int newLevel;
  final String oldLevelName;
  final String newLevelName;
  final String emoji;
  final List<String> newPrivileges;

  const LevelUpResult({
    required this.oldLevel,
    required this.newLevel,
    required this.oldLevelName,
    required this.newLevelName,
    required this.emoji,
    required this.newPrivileges,
  });

  /// 升级提示消息
  String get message =>
      '🎉 恭喜升级！$oldLevelName → $emoji $newLevelName';

  /// 是否解锁新权益
  bool get hasNewPrivileges => newPrivileges.isNotEmpty;
}
