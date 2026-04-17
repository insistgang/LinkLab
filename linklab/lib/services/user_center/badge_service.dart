import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/logger.dart';
import '../../models/badge_model.dart';
import '../../models/volunteer_level_model.dart';
import 'skill_tag_service.dart';
import 'volunteer_demo_store.dart';

/// 徽章服务 (F21)
/// 管理志愿者的徽章成就系统
class BadgeService {
  BadgeService({
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

  /// 获取我的徽章（别名方法，兼容UI调用）
  Future<List<BadgeModel>> getMyBadges(String volunteerId) async {
    return getBadges(volunteerId);
  }

  /// 获取可获得的徽章列表
  Future<List<BadgeDefinition>> getAvailableBadges(String volunteerId) async {
    final existingBadges = await getBadges(volunteerId);
    final existingTypes = existingBadges.map((b) => b.type).toSet();

    return BadgeDefinitions.all
        .where((def) => !existingTypes.contains(def.type))
        .toList();
  }

  /// 获取志愿者的所有徽章
  Future<List<BadgeModel>> getBadges(String volunteerId) async {
    if (!_hasSupabase) {
      try {
        return await _demoStore.getBadges(volunteerId);
      } catch (e) {
        AppLogger.error('获取本地徽章失败', e);
        return [];
      }
    }

    try {
      final response = await _supabase
          .from('badges')
          .select()
          .eq('user_id', volunteerId)
          .order('earned_at', ascending: false);

      return (response as List)
          .map((json) => BadgeModel.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    } catch (e) {
      AppLogger.error('获取徽章失败', e);
      return [];
    }
  }

  /// 检查并授予徽章
  /// 在相关事件触发后调用（如帮助完成、升级等）
  Future<List<BadgeModel>> checkAndAwardBadges(String volunteerId) async {
    if (!_hasSupabase) {
      try {
        final existingBadges = await _demoStore.getBadges(volunteerId);
        final existingTypes = existingBadges.map((item) => item.type).toSet();
        final activities = await _demoStore.getActivities(volunteerId);
        final profile = await _demoStore.getProfile(volunteerId);
        final verifiedSkills =
            await SkillTagService(demoStore: _demoStore).getVerifiedSkills(volunteerId);

        final newBadges = <BadgeModel>[];

        if (activities.isNotEmpty &&
            !existingTypes.contains(BadgeType.risingStar)) {
          newBadges.add(
            BadgeModel(
              id: 'badge_${volunteerId}_rising_star',
              userId: volunteerId,
              type: BadgeType.risingStar,
              name: '新星志愿者',
              description: '完成首次帮助，开启志愿之旅',
              earnedAt: DateTime.now(),
              isNew: true,
            ),
          );
        }

        final activityDates = activities
            .map((item) {
              final date = item.createdAt;
              return '${date.year}-${date.month}-${date.day}';
            })
            .toSet()
            .toList();
        if (!existingTypes.contains(BadgeType.continuous7) &&
            _hasConsecutiveDays(activityDates, 7)) {
          newBadges.add(
            BadgeModel(
              id: 'badge_${volunteerId}_continuous7',
              userId: volunteerId,
              type: BadgeType.continuous7,
              name: '坚持不懈',
              description: '连续7天提供帮助',
              earnedAt: DateTime.now(),
              isNew: true,
            ),
          );
        }

        if (!existingTypes.contains(BadgeType.skillMaster) &&
            verifiedSkills.length >= 3) {
          newBadges.add(
            BadgeModel(
              id: 'badge_${volunteerId}_skill_master',
              userId: volunteerId,
              type: BadgeType.skillMaster,
              name: '技能大师',
              description: '获得3个认证技能标签',
              earnedAt: DateTime.now(),
              isNew: true,
            ),
          );
        }

        if (!existingTypes.contains(BadgeType.lighthouse) &&
            LevelDefinitions.calculateLevel(profile.points) >= 7) {
          newBadges.add(
            BadgeModel(
              id: 'badge_${volunteerId}_lighthouse',
              userId: volunteerId,
              type: BadgeType.lighthouse,
              name: '灯塔守护者',
              description: '达到最高等级Lv7',
              earnedAt: DateTime.now(),
              isNew: true,
            ),
          );
        }

        if (newBadges.isNotEmpty) {
          await _demoStore.upsertBadges(volunteerId, newBadges);
        }

        return newBadges;
      } catch (e) {
        AppLogger.error('检查本地徽章失败', e);
        return [];
      }
    }

    final newBadges = <BadgeModel>[];

    try {
      // 获取已有徽章
      final existingBadges = await getBadges(volunteerId);
      final existingTypes = existingBadges.map((b) => b.type).toSet();

      // 检查各种徽章条件
      final checks = [
        _checkRisingStar(volunteerId, existingTypes),
        _checkTranslatorBadge(volunteerId, existingTypes),
        _checkHelperBadges(volunteerId, existingTypes),
        _checkContinuousBadges(volunteerId, existingTypes),
        _checkKindHeartBadge(volunteerId, existingTypes),
        _checkSkillMasterBadge(volunteerId, existingTypes),
        _checkLighthouseBadge(volunteerId, existingTypes),
        _checkSpecialEventBadges(volunteerId, existingTypes),
      ];

      final results = await Future.wait(checks);

      for (final badge in results.where((b) => b != null).cast<BadgeModel>()) {
        // 保存徽章
        await _saveBadge(badge);
        newBadges.add(badge);
      }

      if (newBadges.isNotEmpty) {
        AppLogger.info('授予志愿者新徽章: $volunteerId, 数量: ${newBadges.length}');
      }

      return newBadges;
    } catch (e) {
      AppLogger.error('检查徽章失败', e);
      return [];
    }
  }

  /// 检查新星志愿者徽章
  Future<BadgeModel?> _checkRisingStar(
    String volunteerId,
    Set<BadgeType> existingTypes,
  ) async {
    if (existingTypes.contains(BadgeType.risingStar)) return null;

    final response = await _supabase
        .from('help_requests')
        .select()
        .eq('volunteer_id', volunteerId)
        .eq('status', 'completed')
        .limit(1);

    if ((response as List).isNotEmpty) {
      return BadgeModel(
        id: 'badge_${volunteerId}_rising_star',
        userId: volunteerId,
        type: BadgeType.risingStar,
        name: '新星志愿者',
        description: '完成首次帮助，开启志愿之旅',
        earnedAt: DateTime.now(),
        isNew: true,
      );
    }

    return null;
  }

  /// 检查翻译达人徽章
  Future<BadgeModel?> _checkTranslatorBadge(
    String volunteerId,
    Set<BadgeType> existingTypes,
  ) async {
    if (existingTypes.contains(BadgeType.translator)) return null;

    final response = await _supabase
        .from('help_requests')
        .select()
        .eq('volunteer_id', volunteerId)
        .eq('status', 'completed')
        .ilike('intent', '%翻译%')
        .count(CountOption.exact);

    if (response.count >= 50) {
      return BadgeModel(
        id: 'badge_${volunteerId}_translator',
        userId: volunteerId,
        type: BadgeType.translator,
        name: '翻译达人',
        description: '完成50次翻译类求助',
        earnedAt: DateTime.now(),
        isNew: true,
      );
    }

    return null;
  }

  /// 检查帮助次数徽章
  Future<BadgeModel?> _checkHelperBadges(
    String volunteerId,
    Set<BadgeType> existingTypes,
  ) async {
    final response = await _supabase
        .from('help_requests')
        .select()
        .eq('volunteer_id', volunteerId)
        .eq('status', 'completed')
        .count(CountOption.exact);

    final count = response.count;

    // 检查100次
    if (count >= 100 && !existingTypes.contains(BadgeType.helper100)) {
      return BadgeModel(
        id: 'badge_${volunteerId}_helper100',
        userId: volunteerId,
        type: BadgeType.helper100,
        name: '百次帮助',
        description: '累计完成100次帮助',
        earnedAt: DateTime.now(),
        isNew: true,
      );
    }

    // 检查500次
    if (count >= 500 && !existingTypes.contains(BadgeType.helper500)) {
      return BadgeModel(
        id: 'badge_${volunteerId}_helper500',
        userId: volunteerId,
        type: BadgeType.helper500,
        name: '五百次帮助',
        description: '累计完成500次帮助',
        earnedAt: DateTime.now(),
        isNew: true,
      );
    }

    // 检查1000次
    if (count >= 1000 && !existingTypes.contains(BadgeType.helper1000)) {
      return BadgeModel(
        id: 'badge_${volunteerId}_helper1000',
        userId: volunteerId,
        type: BadgeType.helper1000,
        name: '千次帮助',
        description: '累计完成1000次帮助',
        earnedAt: DateTime.now(),
        isNew: true,
      );
    }

    return null;
  }

  /// 检查连续帮助徽章
  Future<BadgeModel?> _checkContinuousBadges(
    String volunteerId,
    Set<BadgeType> existingTypes,
  ) async {
    // 获取最近30天的帮助记录
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    final response = await _supabase
        .from('help_requests')
        .select('created_at')
        .eq('volunteer_id', volunteerId)
        .eq('status', 'completed')
        .gte('created_at', thirtyDaysAgo.toIso8601String());

    final helps = response as List;

    // 提取有帮助的日期
    final helpDates = helps
        .map((h) {
          final help = Map<String, dynamic>.from(h as Map);
          final date = DateTime.parse(help['created_at'].toString());
          return '${date.year}-${date.month}-${date.day}';
        })
        .toSet()
        .toList();

    // 检查连续7天
    if (helpDates.length >= 7 && !existingTypes.contains(BadgeType.continuous7)) {
      // 验证是否真的有连续7天
      if (_hasConsecutiveDays(helpDates, 7)) {
        return BadgeModel(
          id: 'badge_${volunteerId}_continuous7',
          userId: volunteerId,
          type: BadgeType.continuous7,
          name: '坚持不懈',
          description: '连续7天提供帮助',
          earnedAt: DateTime.now(),
          isNew: true,
        );
      }
    }

    // 检查连续30天
    if (helpDates.length >= 30 && !existingTypes.contains(BadgeType.continuous30)) {
      if (_hasConsecutiveDays(helpDates, 30)) {
        return BadgeModel(
          id: 'badge_${volunteerId}_continuous30',
          userId: volunteerId,
          type: BadgeType.continuous30,
          name: '月度之星',
          description: '连续30天提供帮助',
          earnedAt: DateTime.now(),
          isNew: true,
        );
      }
    }

    return null;
  }

  /// 检查是否有连续N天
  bool _hasConsecutiveDays(List<String> dates, int n) {
    if (dates.length < n) return false;

    final sortedDates = dates.map((d) {
      final parts = d.split('-');
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    }).toList()
      ..sort();

    int consecutiveCount = 1;
    for (int i = 1; i < sortedDates.length; i++) {
      final diff = sortedDates[i].difference(sortedDates[i - 1]).inDays;
      if (diff == 1) {
        consecutiveCount++;
        if (consecutiveCount >= n) return true;
      } else if (diff > 1) {
        consecutiveCount = 1;
      }
    }

    return false;
  }

  /// 检查爱心大使徽章
  Future<BadgeModel?> _checkKindHeartBadge(
    String volunteerId,
    Set<BadgeType> existingTypes,
  ) async {
    if (existingTypes.contains(BadgeType.kindHeart)) return null;

    final response = await _supabase
        .from('help_requests')
        .select()
        .eq('volunteer_id', volunteerId)
        .eq('status', 'completed')
        .gte('seeker_rating', 4)
        .count(CountOption.exact);

    if (response.count >= 100) {
      return BadgeModel(
        id: 'badge_${volunteerId}_kind_heart',
        userId: volunteerId,
        type: BadgeType.kindHeart,
        name: '爱心大使',
        description: '获得100个好评',
        earnedAt: DateTime.now(),
        isNew: true,
      );
    }

    return null;
  }

  /// 检查技能大师徽章
  Future<BadgeModel?> _checkSkillMasterBadge(
    String volunteerId,
    Set<BadgeType> existingTypes,
  ) async {
    if (existingTypes.contains(BadgeType.skillMaster)) return null;

    final response = await _supabase
        .from('volunteer_skills')
        .select()
        .eq('volunteer_id', volunteerId)
        .eq('is_verified', true)
        .count(CountOption.exact);

    if (response.count >= 3) {
      return BadgeModel(
        id: 'badge_${volunteerId}_skill_master',
        userId: volunteerId,
        type: BadgeType.skillMaster,
        name: '技能大师',
        description: '获得3个认证技能标签',
        earnedAt: DateTime.now(),
        isNew: true,
      );
    }

    return null;
  }

  /// 检查灯塔守护者徽章
  Future<BadgeModel?> _checkLighthouseBadge(
    String volunteerId,
    Set<BadgeType> existingTypes,
  ) async {
    if (existingTypes.contains(BadgeType.lighthouse)) return null;

    final response = await _supabase
        .from('volunteer_profiles')
        .select('level')
        .eq('user_id', volunteerId)
        .single();

    final profile = Map<String, dynamic>.from(response as Map);
    final level = (profile['level'] as num?)?.toInt() ?? 0;

    if (level >= 7) {
      return BadgeModel(
        id: 'badge_${volunteerId}_lighthouse',
        userId: volunteerId,
        type: BadgeType.lighthouse,
        name: '灯塔守护者',
        description: '达到最高等级Lv7',
        earnedAt: DateTime.now(),
        isNew: true,
      );
    }

    return null;
  }

  /// 检查特殊事件徽章
  Future<BadgeModel?> _checkSpecialEventBadges(
    String volunteerId,
    Set<BadgeType> existingTypes,
  ) async {
    final now = DateTime.now();

    // 除夕守夜人
    if (now.month == 1 && now.day == 21) { // 简化判断，实际需要农历计算
      if (!existingTypes.contains(BadgeType.springFestival)) {
        final hasHelpToday = await _checkHasHelpedToday(volunteerId);
        if (hasHelpToday) {
          return BadgeModel(
            id: 'badge_${volunteerId}_spring_festival',
            userId: volunteerId,
            type: BadgeType.springFestival,
            name: '除夕守夜人',
            description: '除夕当天完成帮助',
            earnedAt: DateTime.now(),
            isNew: true,
          );
        }
      }
    }

    // 跨年守夜人
    if (now.month == 1 && now.day == 1) {
      if (!existingTypes.contains(BadgeType.newYear)) {
        final hasHelpToday = await _checkHasHelpedToday(volunteerId);
        if (hasHelpToday) {
          return BadgeModel(
            id: 'badge_${volunteerId}_new_year',
            userId: volunteerId,
            type: BadgeType.newYear,
            name: '跨年守夜人',
            description: '元旦当天完成帮助',
            earnedAt: DateTime.now(),
            isNew: true,
          );
        }
      }
    }

    return null;
  }

  /// 检查今天是否已完成帮助
  Future<bool> _checkHasHelpedToday(String volunteerId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final response = await _supabase
        .from('help_requests')
        .select()
        .eq('volunteer_id', volunteerId)
        .eq('status', 'completed')
        .gte('created_at', today.toIso8601String())
        .limit(1);

    return (response as List).isNotEmpty;
  }

  /// 保存徽章到数据库
  Future<void> _saveBadge(BadgeModel badge) async {
    if (!_hasSupabase) {
      await _demoStore.upsertBadges(badge.userId, [badge]);
      return;
    }

    try {
      await _supabase.from('badges').insert({
        'id': badge.id,
        'user_id': badge.userId,
        'badge_type': badge.type.name,
        'badge_name': badge.name,
        'description': badge.description,
        'earned_at': badge.earnedAt?.toIso8601String(),
      });
    } catch (e) {
      AppLogger.error('保存徽章失败', e);
    }
  }

  /// 标记徽章为已查看
  Future<void> markBadgeAsSeen(String badgeId) async {
    if (!_hasSupabase) {
      try {
        // 本地模式下通过全量扫描志愿者徽章列表简化处理。
        return;
      } catch (e) {
        AppLogger.error('标记本地徽章已查看失败', e);
        return;
      }
    }

    try {
      await _supabase
          .from('badges')
          .update({'is_new': false})
          .eq('id', badgeId);
    } catch (e) {
      AppLogger.error('标记徽章已查看失败', e);
    }
  }

  /// 获取徽章统计
  Future<BadgeStats> getBadgeStats(String volunteerId) async {
    try {
      final badges = await getBadges(volunteerId);

      // 按类型分组统计
      final typeCount = <BadgeType, int>{};
      for (final badge in badges) {
        typeCount[badge.type] = (typeCount[badge.type] ?? 0) + 1;
      }

      // 新徽章数量
      final newBadges = badges.where((b) => b.isNew).length;

      return BadgeStats(
        totalBadges: badges.length,
        newBadges: newBadges,
        typeDistribution: typeCount,
      );
    } catch (e) {
      AppLogger.error('获取徽章统计失败', e);
      return const BadgeStats();
    }
  }
}

/// 徽章统计
class BadgeStats {
  final int totalBadges;
  final int newBadges;
  final Map<BadgeType, int> typeDistribution;

  const BadgeStats({
    this.totalBadges = 0,
    this.newBadges = 0,
    this.typeDistribution = const {},
  });
}
