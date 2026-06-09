import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/logger.dart';
import '../../models/point_transaction_model.dart';
import '../../models/volunteer_level_model.dart';
import 'volunteer_demo_store.dart';

/// 志願者等級服務 (F18)
/// 7級體系：青苗→嫩芽→新葉→綠蔭→暖陽→星辰→燈塔
class VolunteerLevelService {
  VolunteerLevelService({
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

  /// 獲取志願者等級信息
  Future<VolunteerLevelInfo> getLevelInfo(String volunteerId) async {
    if (!_hasSupabase) {
      try {
        final profile = await _demoStore.getProfile(volunteerId);
        final currentLevel = LevelDefinitions.calculateLevel(profile.points);
        if (currentLevel != profile.level) {
          await _demoStore.saveProfile(profile.copyWith(level: currentLevel));
        }
        return _buildLevelInfo(currentLevel, profile.points);
      } catch (e) {
        AppLogger.error('獲取本地志願者等級信息失敗', e);
        return _buildLevelInfo(1, 0);
      }
    }

    try {
      final response = await _supabase
          .from('volunteer_profiles')
          .select('level, points')
          .eq('user_id', volunteerId)
          .single();

      final currentLevel = (response['level'] as num?)?.toInt() ?? 1;
      final currentPoints = (response['points'] as num?)?.toInt() ?? 0;

      return _buildLevelInfo(currentLevel, currentPoints);
    } catch (e) {
      AppLogger.error('獲取志願者等級信息失敗', e);
      return _buildLevelInfo(1, 0);
    }
  }

  /// 計算等級信息
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

  /// 計算等級（根據積分）
  Future<LevelInfo> calculateLevel(String volunteerId) async {
    if (!_hasSupabase) {
      try {
        final profile = await _demoStore.getProfile(volunteerId);
        final level = LevelDefinitions.calculateLevel(profile.points);
        final levelDef = LevelDefinitions.getByLevel(level);

        return LevelInfo(
          level: level,
          name: levelDef.name,
          emoji: levelDef.emoji,
          points: profile.points,
          minPoints: levelDef.minPoints,
          maxPoints: levelDef.maxPoints,
        );
      } catch (e) {
        AppLogger.error('計算本地等級失敗', e);
      }
    }

    try {
      final response = await _supabase
          .from('volunteer_profiles')
          .select('points')
          .eq('user_id', volunteerId)
          .single();

      final points = (response['points'] as num?)?.toInt() ?? 0;
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
      AppLogger.error('計算等級失敗', e);
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

  /// 檢查並升級等級
  /// 返回升級結果，如果沒有升級返回null
  Future<LevelUpResult?> checkAndUpgrade(String volunteerId) async {
    if (!_hasSupabase) {
      try {
        final profile = await _demoStore.getProfile(volunteerId);
        final expectedLevel = LevelDefinitions.calculateLevel(profile.points);

        if (expectedLevel <= profile.level) {
          return null;
        }

        await _demoStore.saveProfile(profile.copyWith(level: expectedLevel));

        final oldLevelDef = LevelDefinitions.getByLevel(profile.level);
        final newLevelDef = LevelDefinitions.getByLevel(expectedLevel);
        final newPrivileges = newLevelDef.privileges
            .where((item) => !oldLevelDef.privileges.contains(item))
            .toList();

        return LevelUpResult(
          oldLevel: profile.level,
          newLevel: expectedLevel,
          oldLevelName: oldLevelDef.name,
          newLevelName: newLevelDef.name,
          emoji: newLevelDef.emoji,
          newPrivileges: newPrivileges,
        );
      } catch (e) {
        AppLogger.error('檢查本地升級失敗', e);
        return null;
      }
    }

    try {
      // 獲取當前等級和積分
      final response = await _supabase
          .from('volunteer_profiles')
          .select('level, points')
          .eq('user_id', volunteerId)
          .single();

      final currentLevel = (response['level'] as num?)?.toInt() ?? 1;
      final currentPoints = (response['points'] as num?)?.toInt() ?? 0;

      // 計算應達到的等級
      final expectedLevel = LevelDefinitions.calculateLevel(currentPoints);

      // 如果應達等級高於當前等級，執行升級
      if (expectedLevel > currentLevel) {
        // 更新等級
        await _supabase
            .from('volunteer_profiles')
            .update({'level': expectedLevel})
            .eq('user_id', volunteerId);

        // 獲取新舊等級定義
        final oldLevelDef = LevelDefinitions.getByLevel(currentLevel);
        final newLevelDef = LevelDefinitions.getByLevel(expectedLevel);

        // 獲取新解鎖的權益
        final newPrivileges = newLevelDef.privileges
            .where((p) => !oldLevelDef.privileges.contains(p))
            .toList();

        AppLogger.info('志願者升級: $volunteerId Lv$currentLevel -> Lv$expectedLevel');

        return LevelUpResult(
          oldLevel: currentLevel,
          newLevel: expectedLevel,
          oldLevelName: oldLevelDef.name,
          newLevelName: newLevelDef.name,
          emoji: newLevelDef.emoji,
          newPrivileges: newPrivileges,
        );
      }

      return null; // 沒有升級
    } catch (e) {
      AppLogger.error('檢查升級失敗', e);
      return null;
    }
  }

  /// 添加積分
  /// 在幫助完成後調用
  Future<void> addPoints(
    String volunteerId,
    int points,
    PointTransactionType type, {
    String? description,
    String? relatedId,
  }) async {
    if (!_hasSupabase) {
      try {
        final profile = await _demoStore.getProfile(volunteerId);
        final updatedPoints = profile.points + points;
        final nextLevel = LevelDefinitions.calculateLevel(updatedPoints);

        await _demoStore.saveProfile(
          profile.copyWith(
            points: updatedPoints,
            level: nextLevel,
          ),
        );
        await _demoStore.appendTransaction(
          volunteerId,
          PointTransactionModel(
            id: 'vtx_${DateTime.now().microsecondsSinceEpoch}',
            userId: volunteerId,
            points: points,
            type: type,
            description: description ?? PointRules.getTypeDescription(type),
            relatedId: relatedId,
            isPositive: points >= 0,
            createdAt: DateTime.now(),
          ),
        );

        await checkAndUpgrade(volunteerId);
        return;
      } catch (e) {
        AppLogger.error('本地添加積分失敗', e);
        return;
      }
    }

    try {
      // 使用RPC添加積分（原子操作）
      await _supabase.rpc('add_volunteer_points', params: {
        'p_volunteer_id': volunteerId,
        'p_points': points,
        'p_type': type.name,
        'p_description': description ?? PointRules.getTypeDescription(type),
        'p_related_id': relatedId,
      });

      // 檢查是否需要升級
      await checkAndUpgrade(volunteerId);
    } catch (e) {
      AppLogger.error('添加積分失敗', e);
      // 降級方案
      await _supabase.rpc('increment_volunteer_points', params: {
        'volunteer_id': volunteerId,
        'points': points,
      });
    }
  }

  /// 完成實時幫助後添加積分
  Future<void> onRealtimeHelpCompleted(
    String volunteerId,
    String helpRequestId, {
    int? seekerRating,
  }) async {
    if (!_hasSupabase) {
      await _demoStore.addActivity(
        volunteerId,
        VolunteerActivityRecord(
          id: helpRequestId,
          volunteerId: volunteerId,
          seekerId: 'seeker_realtime',
          seekerName: '實時求助者',
          type: 'realtime_voice',
          durationMinutes: 16,
          rating: seekerRating,
          createdAt: DateTime.now(),
        ),
      );
    }

    // 基礎積分
    await addPoints(
      volunteerId,
      PointRules.realtimeHelp,
      PointTransactionType.realtimeHelp,
      description: '完成實時幫助',
      relatedId: helpRequestId,
    );

    // 五星好評額外積分
    if (seekerRating == 5) {
      await addPoints(
        volunteerId,
        PointRules.fiveStarRating,
        PointTransactionType.fiveStarRating,
        description: '獲得五星好評',
        relatedId: helpRequestId,
      );
    }

    // 檢查連續幫助獎勵
    await _checkContinuousHelpBonus(volunteerId);
  }

  /// 完成異步幫助後添加積分
  Future<void> onAsyncHelpCompleted(
    String volunteerId,
    String taskId, {
    int? seekerRating,
  }) async {
    if (!_hasSupabase) {
      await _demoStore.addActivity(
        volunteerId,
        VolunteerActivityRecord(
          id: taskId,
          volunteerId: volunteerId,
          seekerId: 'seeker_async',
          seekerName: '異步求助用戶',
          type: 'async',
          durationMinutes: 12,
          rating: seekerRating,
          createdAt: DateTime.now(),
        ),
      );
    }

    await addPoints(
      volunteerId,
      PointRules.asyncHelp,
      PointTransactionType.asyncHelp,
      description: '完成異步幫助',
      relatedId: taskId,
    );

    if (seekerRating == 5) {
      await addPoints(
        volunteerId,
        PointRules.fiveStarRating,
        PointTransactionType.fiveStarRating,
        description: '獲得五星好評',
        relatedId: taskId,
      );
    }

    await _checkContinuousHelpBonus(volunteerId);
  }

  /// 檢查連續幫助獎勵
  Future<void> _checkContinuousHelpBonus(String volunteerId) async {
    if (!_hasSupabase) {
      try {
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        final activities = await _demoStore.getActivities(volunteerId);
        final transactions = await _demoStore.getTransactions(volunteerId);
        final helpDates = activities
            .where((item) => item.createdAt.isAfter(sevenDaysAgo))
            .map((item) {
              final date = item.createdAt;
              return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            })
            .toSet();

        final hasRecentBonus = transactions.any(
          (item) =>
              item.type == PointTransactionType.continuousHelpBonus &&
              (item.createdAt?.isAfter(sevenDaysAgo) ?? false),
        );

        if (helpDates.length >= 7 && !hasRecentBonus) {
          await addPoints(
            volunteerId,
            PointRules.continuousHelpBonus,
            PointTransactionType.continuousHelpBonus,
            description: '連續7天幫助獎勵',
          );
        }
      } catch (e) {
        AppLogger.error('檢查本地連續幫助獎勵失敗', e);
      }
      return;
    }

    try {
      // 獲取最近7天的幫助記錄
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      final response = await _supabase
          .from('help_requests')
          .select('created_at')
          .eq('volunteer_id', volunteerId)
          .eq('status', 'completed')
          .gte('created_at', sevenDaysAgo.toIso8601String())
          .order('created_at', ascending: false);

      final helps = response as List;

      // 檢查是否有連續7天的幫助
      final helpDates = helps
          .map((h) {
            final item = Map<String, dynamic>.from(h as Map);
            final date = DateTime.parse('${item['created_at']}');
            return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          })
          .toSet()
          .toList();

      // 檢查今天是否有幫助
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      if (helpDates.contains(todayStr) && helpDates.length >= 7) {
        // 檢查是否已領取本週獎勵
        final lastBonus = await _supabase
            .from('point_transactions')
            .select()
            .eq('user_id', volunteerId)
            .eq('type', PointTransactionType.continuousHelpBonus.name)
            .gte('created_at', sevenDaysAgo.toIso8601String())
            .maybeSingle();

        if (lastBonus == null) {
          // 發放連續幫助獎勵
          await addPoints(
            volunteerId,
            PointRules.continuousHelpBonus,
            PointTransactionType.continuousHelpBonus,
            description: '連續7天幫助獎勵',
          );
        }
      }
    } catch (e) {
      AppLogger.error('檢查連續幫助獎勵失敗', e);
    }
  }

  /// 獲取積分流水
  Future<List<PointTransactionModel>> getPointTransactions(
    String volunteerId, {
    int limit = 20,
    int offset = 0,
  }) async {
    if (!_hasSupabase) {
      try {
        final transactions = await _demoStore.getTransactions(volunteerId);
        final start = offset.clamp(0, transactions.length);
        final end = (offset + limit).clamp(start, transactions.length);
        return transactions.sublist(start, end);
      } catch (e) {
        AppLogger.error('獲取本地積分流水失敗', e);
        return [];
      }
    }

    try {
      final response = await _supabase
          .from('point_transactions')
          .select()
          .eq('user_id', volunteerId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => PointTransactionModel.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    } catch (e) {
      AppLogger.error('獲取積分流水失敗', e);
      return [];
    }
  }

  /// 懲罰扣分
  Future<void> applyPenalty(
    String volunteerId,
    String reason, {
    String? relatedId,
  }) async {
    if (!_hasSupabase) {
      await addPoints(
        volunteerId,
        PointRules.penalty,
        PointTransactionType.penalty,
        description: '違規處罰: $reason',
        relatedId: relatedId,
      );
      return;
    }

    try {
      await _supabase.rpc('add_volunteer_points', params: {
        'p_volunteer_id': volunteerId,
        'p_points': PointRules.penalty,
        'p_type': PointTransactionType.penalty.name,
        'p_description': '違規處罰: $reason',
        'p_related_id': relatedId,
      });

      AppLogger.warning('志願者被處罰: $volunteerId, 原因: $reason');
    } catch (e) {
      AppLogger.error('應用懲罰失敗', e);
    }
  }
}

/// 等級信息（簡化版）
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

  /// 進度百分比
  double get progressPercent {
    if (maxPoints <= minPoints) return 1.0;
    return (points - minPoints) / (maxPoints - minPoints);
  }

  /// 到下一級所需積分
  int get pointsToNext => maxPoints - points;
}

/// 升級結果
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

  /// 升級提示消息
  String get message =>
      '🎉 恭喜升級！$oldLevelName → $emoji $newLevelName';

  /// 是否解鎖新權益
  bool get hasNewPrivileges => newPrivileges.isNotEmpty;
}
