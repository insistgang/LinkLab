import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/logger.dart';
import '../../models/timeline_model.dart';
import 'skill_tag_service.dart';
import 'volunteer_demo_store.dart';

/// 善意时间线服务 (F20)
/// 管理志愿者的帮助履历可视化
class TimelineService {
  TimelineService({
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

  /// 获取时间线数据
  /// [year] 年份，默认为当前年份
  Future<TimelineModel> getTimeline(String volunteerId, int year) async {
    final targetYear = year;

    if (!_hasSupabase) {
      try {
        final activities = await _demoStore.getActivities(volunteerId);
        final yearActivities = activities
            .where((item) => item.createdAt.year == targetYear)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        final dayMap = <String, TimelineDay>{};
        int totalHelps = 0;
        int totalMinutes = 0;

        for (final activity in yearActivities) {
          final date = activity.createdAt;
          final dateStr =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

          final event = TimelineEvent(
            id: activity.id,
            type: activity.type,
            seekerName: activity.seekerName,
            durationMinutes: activity.durationMinutes,
            rating: activity.rating,
            createdAt: activity.createdAt,
          );

          final currentDay = dayMap[dateStr];
          if (currentDay == null) {
            dayMap[dateStr] = TimelineDay(
              date: dateStr,
              helpCount: 1,
              minutes: activity.durationMinutes,
              events: [event],
            );
          } else {
            dayMap[dateStr] = currentDay.copyWith(
              helpCount: currentDay.helpCount + 1,
              minutes: currentDay.minutes + activity.durationMinutes,
              events: [...currentDay.events, event],
            );
          }

          totalHelps++;
          totalMinutes += activity.durationMinutes;
        }

        final sortedDates = dayMap.keys.toList()..sort();
        final sortedDays = dayMap.values.toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        return TimelineModel(
          volunteerId: volunteerId,
          year: targetYear,
          days: sortedDays,
          totalHelps: totalHelps,
          totalMinutes: totalMinutes,
          streakDays: _calculateStreakDays(sortedDates),
          stats: await _calculateLocalStats(volunteerId, yearActivities),
        );
      } catch (e) {
        AppLogger.error('获取本地时间线数据失败', e);
        return TimelineModel(volunteerId: volunteerId, year: targetYear);
      }
    }

    try {
      // 获取该年度的帮助记录
      final startDate = DateTime(targetYear, 1, 1);
      final endDate = DateTime(targetYear, 12, 31, 23, 59, 59);

      final response = await _supabase
          .from('help_requests')
          .select('''
            id,
            type,
            duration_seconds,
            seeker_rating,
            created_at,
            seeker:seeker_id(name)
          ''')
          .eq('volunteer_id', volunteerId)
          .eq('status', 'completed')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: true);

      final helps = response as List;

      // 按日期分组统计
      final dayMap = <String, TimelineDay>{};
      int totalHelps = 0;
      int totalMinutes = 0;

      for (final help in helps) {
        final helpMap = Map<String, dynamic>.from(help as Map);
        final date = DateTime.parse(helpMap['created_at'].toString());
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        final durationSeconds =
            (helpMap['duration_seconds'] as num?)?.toInt() ?? 0;
        final durationMinutes = durationSeconds ~/ 60;

        if (dayMap.containsKey(dateStr)) {
          final day = dayMap[dateStr]!;
          dayMap[dateStr] = day.copyWith(
            helpCount: day.helpCount + 1,
            minutes: day.minutes + durationMinutes,
            events: [
              ...day.events,
              _createTimelineEvent(helpMap),
            ],
          );
        } else {
          dayMap[dateStr] = TimelineDay(
            date: dateStr,
            helpCount: 1,
            minutes: durationMinutes,
            events: [_createTimelineEvent(helpMap)],
          );
        }

        totalHelps++;
        totalMinutes += durationMinutes;
      }

      // 计算连续帮助天数
      final streakDays = _calculateStreakDays(dayMap.keys.toList()..sort());

      // 获取统计信息
      final stats = await _calculateStats(volunteerId, targetYear);

      return TimelineModel(
        volunteerId: volunteerId,
        year: targetYear,
        days: dayMap.values.toList(),
        totalHelps: totalHelps,
        totalMinutes: totalMinutes,
        streakDays: streakDays,
        stats: stats,
      );
    } catch (e) {
      AppLogger.error('获取时间线数据失败', e);
      return TimelineModel(
        volunteerId: volunteerId,
        year: targetYear,
      );
    }
  }

  /// 创建时间线事件
  TimelineEvent _createTimelineEvent(Map<String, dynamic> help) {
    final seeker = help['seeker'] is Map
        ? Map<String, dynamic>.from(help['seeker'] as Map)
        : null;

    return TimelineEvent(
      id: '${help['id'] ?? ''}',
      type: help['type']?.toString() ?? 'unknown',
      seekerName: seeker?['name']?.toString() ?? '匿名求助者',
      durationMinutes: ((help['duration_seconds'] as num?)?.toInt() ?? 0) ~/ 60,
      rating: (help['seeker_rating'] as num?)?.toInt(),
      createdAt:
          DateTime.tryParse(help['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// 计算连续帮助天数
  int _calculateStreakDays(List<String> sortedDates) {
    if (sortedDates.isEmpty) return 0;

    int maxStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < sortedDates.length; i++) {
      final prevDate = DateTime.parse(sortedDates[i - 1]);
      final currDate = DateTime.parse(sortedDates[i]);

      final diff = currDate.difference(prevDate).inDays;

      if (diff == 1) {
        currentStreak++;
        maxStreak = currentStreak > maxStreak ? currentStreak : maxStreak;
      } else if (diff > 1) {
        currentStreak = 1;
      }
    }

    return maxStreak;
  }

  /// 计算统计数据
  Future<TimelineStats> _calculateStats(String volunteerId, int year) async {
    try {
      final startDate = DateTime(year, 1, 1);
      final endDate = DateTime(year, 12, 31, 23, 59, 59);

      final response = await _supabase
          .from('help_requests')
          .select('type, seeker_rating, seeker_id')
          .eq('volunteer_id', volunteerId)
          .eq('status', 'completed')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      final helps = response as List;

      // 实时/异步帮助统计
      final realtimeCount = helps
          .where((h) {
            final item = Map<String, dynamic>.from(h as Map);
            return item['type'] == 'realtime_voice' ||
                item['type'] == 'realtime_video';
          })
          .length;
      final asyncCount = helps.where((h) {
        final item = Map<String, dynamic>.from(h as Map);
        return item['type'] == 'async';
      }).length;

      // 评分统计
      final ratings = helps
          .map((h) {
            final item = Map<String, dynamic>.from(h as Map);
            return (item['seeker_rating'] as num?)?.toInt();
          })
          .whereType<int>()
          .toList();

      final averageRating = ratings.isNotEmpty
          ? ratings.reduce((a, b) => a + b) / ratings.length
          : 0.0;

      final fiveStarCount = ratings.where((r) => r == 5).length;

      // 找出帮助最多的求助者
      final seekerCount = <String, int>{};
      for (final help in helps) {
        final item = Map<String, dynamic>.from(help as Map);
        final seekerId = item['seeker_id']?.toString();
        if (seekerId != null) {
          seekerCount[seekerId] = (seekerCount[seekerId] ?? 0) + 1;
        }
      }

      String? mostHelpedSeekerId;
      int mostHelpedCount = 0;
      seekerCount.forEach((id, count) {
        if (count > mostHelpedCount) {
          mostHelpedSeekerId = id;
          mostHelpedCount = count;
        }
      });

      // 获取最常帮助者的名字
      String? mostHelpedSeekerName;
      if (mostHelpedSeekerId != null) {
        final seekerResponse = await _supabase
            .from('users')
            .select('name')
            .eq('id', mostHelpedSeekerId!)
            .maybeSingle();

        final seekerResponseMap = seekerResponse == null
            ? null
            : Map<String, dynamic>.from(seekerResponse as Map);
        mostHelpedSeekerName = seekerResponseMap?['name']?.toString();
      }

      return TimelineStats(
        realtimeHelpCount: realtimeCount,
        asyncHelpCount: asyncCount,
        averageRating: averageRating,
        fiveStarCount: fiveStarCount,
        mostHelpedSeekerId: mostHelpedSeekerId,
        mostHelpedSeekerName: mostHelpedSeekerName,
        mostHelpedCount: mostHelpedCount,
      );
    } catch (e) {
      AppLogger.error('计算时间线统计失败', e);
      return const TimelineStats();
    }
  }

  Future<TimelineStats> _calculateLocalStats(
    String volunteerId,
    List<VolunteerActivityRecord> activities,
  ) async {
    try {
      final realtimeCount = activities
          .where((item) => item.type == 'realtime_voice' || item.type == 'realtime_video')
          .length;
      final asyncCount = activities.where((item) => item.type == 'async').length;

      final ratings = activities
          .where((item) => item.rating != null)
          .map((item) => item.rating!)
          .toList();
      final averageRating = ratings.isEmpty
          ? 0.0
          : ratings.reduce((a, b) => a + b) / ratings.length;
      final fiveStarCount = ratings.where((item) => item == 5).length;

      final seekerCount = <String, int>{};
      final seekerNames = <String, String>{};
      for (final activity in activities) {
        seekerCount[activity.seekerId] = (seekerCount[activity.seekerId] ?? 0) + 1;
        seekerNames[activity.seekerId] = activity.seekerName;
      }

      String? mostHelpedSeekerId;
      int mostHelpedCount = 0;
      seekerCount.forEach((id, count) {
        if (count > mostHelpedCount) {
          mostHelpedSeekerId = id;
          mostHelpedCount = count;
        }
      });

      final skills = await SkillTagService(demoStore: _demoStore).getVerifiedSkills(volunteerId);

      return TimelineStats(
        realtimeHelpCount: realtimeCount,
        asyncHelpCount: asyncCount,
        averageRating: averageRating,
        fiveStarCount: fiveStarCount,
        mostHelpedSeekerId: mostHelpedSeekerId,
        mostHelpedSeekerName: mostHelpedSeekerId == null
            ? null
            : seekerNames[mostHelpedSeekerId!],
        mostHelpedCount: mostHelpedCount,
        topSkills: skills.take(3).map((item) => item.name).toList(),
      );
    } catch (e) {
      AppLogger.error('计算本地时间线统计失败', e);
      return const TimelineStats();
    }
  }

  /// 生成年度报告
  Future<AnnualReport> generateAnnualReport(
    String volunteerId, {
    int? year,
  }) async {
    final targetYear = year ?? DateTime.now().year - 1; // 默认生成上一年的报告

    try {
      final timeline = await getTimeline(volunteerId, targetYear);
      return AnnualReportGenerator.generate(volunteerId, targetYear, timeline);
    } catch (e) {
      AppLogger.error('生成年度报告失败', e);
      return AnnualReport(
        volunteerId: volunteerId,
        year: targetYear,
        title: '$targetYear年度善意报告',
        generatedAt: DateTime.now(),
      );
    }
  }

  /// 获取月度总结
  Future<MonthlySummary> getMonthlySummary(
    String volunteerId,
    int year,
    int month,
  ) async {
    if (!_hasSupabase) {
      try {
        final activities = await _demoStore.getActivities(volunteerId);
        final monthActivities = activities.where((item) {
          return item.createdAt.year == year && item.createdAt.month == month;
        }).toList();

        final activeDays = monthActivities
            .map((item) {
              final date = item.createdAt;
              return '${date.year}-${date.month}-${date.day}';
            })
            .toSet()
            .length;

        return MonthlySummary(
          year: year,
          month: month,
          totalHelps: monthActivities.length,
          totalMinutes: monthActivities.fold<int>(
            0,
            (sum, item) => sum + item.durationMinutes,
          ),
          activeDays: activeDays,
          goodRatings: monthActivities.where((item) => (item.rating ?? 0) >= 4).length,
        );
      } catch (e) {
        AppLogger.error('获取本地月度总结失败', e);
        return MonthlySummary(year: year, month: month);
      }
    }

    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

      final response = await _supabase
          .from('help_requests')
          .select()
          .eq('volunteer_id', volunteerId)
          .eq('status', 'completed')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      final helps = response as List;

      final totalHelps = helps.length;
      final totalMinutes = helps.fold<int>(
        0,
        (sum, h) {
          final item = Map<String, dynamic>.from(h as Map);
          return sum + (((item['duration_seconds'] as num?)?.toInt() ?? 0) ~/ 60);
        },
      );

      // 获取好评数
      final goodRatings = helps.where((h) {
        final item = Map<String, dynamic>.from(h as Map);
        return ((item['seeker_rating'] as num?)?.toInt() ?? 0) >= 4;
      }).length;

      // 计算活跃天数
      final activeDays = helps
        .map((h) {
            final item = Map<String, dynamic>.from(h as Map);
            final date =
                DateTime.tryParse(item['created_at']?.toString() ?? '') ?? DateTime.now();
            return '${date.year}-${date.month}-${date.day}';
          })
          .toSet()
          .length;

      return MonthlySummary(
        year: year,
        month: month,
        totalHelps: totalHelps,
        totalMinutes: totalMinutes,
        activeDays: activeDays,
        goodRatings: goodRatings,
      );
    } catch (e) {
      AppLogger.error('获取月度总结失败', e);
      return MonthlySummary(year: year, month: month);
    }
  }

  /// 获取里程碑
  Future<List<TimelineMilestone>> getMilestones(String volunteerId) async {
    if (!_hasSupabase) {
      try {
        final activities = await _demoStore.getActivities(volunteerId);
        if (activities.isEmpty) {
          return [];
        }

        final milestones = <TimelineMilestone>[
          TimelineMilestone(
            type: 'first_help',
            title: '首次帮助',
            description: '开启了志愿之旅',
            date: activities.last.createdAt,
          ),
        ];

        const milestoneCounts = [10, 50, 100, 500, 1000];
        for (final target in milestoneCounts) {
          if (activities.length >= target) {
            milestones.add(
              TimelineMilestone(
                type: 'help_count_$target',
                title: '$target次帮助',
                description: '累计完成$target次帮助',
                date: activities[target - 1].createdAt,
              ),
            );
          }
        }

        milestones.sort((a, b) => a.date.compareTo(b.date));
        return milestones;
      } catch (e) {
        AppLogger.error('获取本地里程碑失败', e);
        return [];
      }
    }

    try {
      final milestones = <TimelineMilestone>[];

      // 首次帮助
      final firstHelp = await _supabase
          .from('help_requests')
          .select('created_at')
          .eq('volunteer_id', volunteerId)
          .eq('status', 'completed')
          .order('created_at', ascending: true)
          .limit(1)
          .maybeSingle();

      if (firstHelp != null) {
        final firstHelpMap = Map<String, dynamic>.from(firstHelp as Map);
        milestones.add(TimelineMilestone(
          type: 'first_help',
          title: '首次帮助',
          description: '开启了志愿之旅',
          date: DateTime.tryParse(firstHelpMap['created_at']?.toString() ?? '') ??
              DateTime.now(),
        ));
      }

      // 累计帮助里程碑
      final totalCountResponse = await _supabase
          .from('help_requests')
          .select('created_at')
          .eq('volunteer_id', volunteerId)
          .eq('status', 'completed')
          .order('created_at', ascending: true);

      final allHelps = totalCountResponse as List;
      final milestonesCounts = [10, 50, 100, 500, 1000];

      for (final target in milestonesCounts) {
        if (allHelps.length >= target) {
          final milestoneHelp =
              Map<String, dynamic>.from(allHelps[target - 1] as Map);
          milestones.add(TimelineMilestone(
            type: 'help_count_$target',
            title: '$target次帮助',
            description: '累计完成$target次帮助',
            date: DateTime.tryParse(
                  milestoneHelp['created_at']?.toString() ?? '',
                ) ??
                DateTime.now(),
          ));
        }
      }

      // 按日期排序
      milestones.sort((a, b) => a.date.compareTo(b.date));

      return milestones;
    } catch (e) {
      AppLogger.error('获取里程碑失败', e);
      return [];
    }
  }
}

/// 月度总结
class MonthlySummary {
  final int year;
  final int month;
  final int totalHelps;
  final int totalMinutes;
  final int activeDays;
  final int goodRatings;

  MonthlySummary({
    required this.year,
    required this.month,
    this.totalHelps = 0,
    this.totalMinutes = 0,
    this.activeDays = 0,
    this.goodRatings = 0,
  });

  /// 月份名称
  String get monthName => '$month月';

  /// 平均每日帮助数
  double get averageHelpsPerDay {
    if (activeDays == 0) return 0;
    return totalHelps / activeDays;
  }
}

/// 时间线里程碑
class TimelineMilestone {
  final String type;
  final String title;
  final String description;
  final DateTime date;

  TimelineMilestone({
    required this.type,
    required this.title,
    required this.description,
    required this.date,
  });
}
