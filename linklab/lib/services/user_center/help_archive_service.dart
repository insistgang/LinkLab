import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';
import '../../models/help_request_model.dart';
import '../../models/help_statistics_model.dart';

/// 帮助档案服务 (F14)
/// 管理求助者的历史帮助记录和统计
class HelpArchiveService {
  final SupabaseClient _supabase;

  HelpArchiveService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// 获取帮助历史记录
  /// [userId] 用户ID
  /// [limit] 返回记录数量限制
  /// [offset] 分页偏移量
  Future<List<HelpRequestModel>> getHelpHistory(
    String userId, {
    int limit = 20,
    int offset = 0,
    HelpRecordFilter? filter,
  }) async {
    try {
      var query = _supabase
          .from('help_requests')
          .select()
          .eq('seeker_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      // 应用筛选条件
      if (filter?.type != null) {
        query = query.eq('type', filter!.type!);
      }
      if (filter?.status != null) {
        query = query.eq('status', filter!.status!);
      }
      if (filter?.startDate != null) {
        query = query.gte('created_at', filter!.startDate!.toIso8601String());
      }
      if (filter?.endDate != null) {
        query = query.lte('created_at', filter!.endDate!.toIso8601String());
      }

      final response = await query;

      return (response as List)
          .map((json) => HelpRequestModel.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('获取帮助历史失败', e);
      return [];
    }
  }

  /// 获取帮助统计数据
  Future<HelpStatistics> getStatistics(String userId) async {
    try {
      // 获取总求助次数
      final totalResponse = await _supabase
          .from('help_requests')
          .select()
          .eq('seeker_id', userId);

      final allRequests = (totalResponse as List)
          .map((json) => HelpRequestModel.fromJson(json))
          .toList();

      // 计算各项统计
      final totalRequests = allRequests.length;
      final aiResolvedCount =
          allRequests.where((r) => r.status == 'ai_resolved').length;
      final volunteerHelpCount =
          allRequests.where((r) => r.volunteerId != null).length;
      final sosCount = allRequests.where((r) => r.type == 'sos').length;

      // AI解决率
      final aiResolutionRate = totalRequests > 0
          ? aiResolvedCount / totalRequests
          : 0.0;

      // 总时长（分钟）
      final totalDurationMinutes = allRequests
          .where((r) => r.durationSeconds != null)
          .fold<int>(
              0, (sum, r) => sum + (r.durationSeconds! ~/ 60));

      // 平均评分
      final ratedRequests = allRequests.where((r) => r.seekerRating != null);
      final averageRating = ratedRequests.isNotEmpty
          ? ratedRequests.fold<int>(0, (sum, r) => sum + r.seekerRating!) /
              ratedRequests.length
          : 0.0;

      // 按类型统计
      final typeStats = _calculateTypeStats(allRequests);

      // 按月统计（最近6个月）
      final monthlyStats = _calculateMonthlyStats(allRequests);

      return HelpStatistics(
        totalRequests: totalRequests,
        aiResolvedCount: aiResolvedCount,
        volunteerHelpCount: volunteerHelpCount,
        sosCount: sosCount,
        aiResolutionRate: aiResolutionRate,
        totalDurationMinutes: totalDurationMinutes,
        averageRating: averageRating,
        typeStats: typeStats,
        monthlyStats: monthlyStats,
        lastUpdatedAt: DateTime.now(),
      );
    } catch (e) {
      AppLogger.error('获取帮助统计失败', e);
      return const HelpStatistics();
    }
  }

  /// 计算类型统计
  List<HelpTypeStat> _calculateTypeStats(List<HelpRequestModel> requests) {
    final typeCount = <String, int>{};

    for (final request in requests) {
      final type = request.type ?? 'unknown';
      typeCount[type] = (typeCount[type] ?? 0) + 1;
    }

    return typeCount.entries
        .map((e) => HelpTypeStat(
              type: e.key,
              count: e.value,
              typeLabel: _getTypeLabel(e.key),
            ))
        .toList();
  }

  /// 计算月度统计
  List<MonthlyStat> _calculateMonthlyStats(List<HelpRequestModel> requests) {
    final now = DateTime.now();
    final monthlyData = <String, Map<String, int>>{};

    // 初始化最近6个月
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      monthlyData[key] = {'count': 0, 'ai': 0, 'volunteer': 0};
    }

    // 统计数据
    for (final request in requests) {
      if (request.createdAt == null) continue;

      final month = request.createdAt!;
      final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';

      if (monthlyData.containsKey(key)) {
        monthlyData[key]!['count'] = monthlyData[key]!['count']! + 1;

        if (request.status == 'ai_resolved') {
          monthlyData[key]!['ai'] = monthlyData[key]!['ai']! + 1;
        } else if (request.volunteerId != null) {
          monthlyData[key]!['volunteer'] = monthlyData[key]!['volunteer']! + 1;
        }
      }
    }

    return monthlyData.entries
        .map((e) => MonthlyStat(
              month: e.key,
              count: e.value['count']!,
              aiCount: e.value['ai']!,
              volunteerCount: e.value['volunteer']!,
            ))
        .toList();
  }

  /// 获取类型标签
  String _getTypeLabel(String type) {
    switch (type) {
      case 'ai_auto':
        return 'AI自助';
      case 'realtime_voice':
        return '语音求助';
      case 'realtime_video':
        return '视频求助';
      case 'async':
        return '异步求助';
      case 'sos':
        return '紧急求助';
      default:
        return '其他';
    }
  }

  /// 获取单条帮助记录详情
  Future<HelpRequestModel?> getHelpRequestDetail(String requestId) async {
    try {
      final response = await _supabase
          .from('help_requests')
          .select()
          .eq('id', requestId)
          .single();

      return HelpRequestModel.fromJson(response);
    } catch (e) {
      AppLogger.error('获取帮助记录详情失败', e);
      return null;
    }
  }

  /// 搜索帮助记录
  Future<List<HelpRequestModel>> searchHelpHistory(
    String userId,
    String keyword,
  ) async {
    try {
      // 使用intent字段进行搜索
      final response = await _supabase
          .from('help_requests')
          .select()
          .eq('seeker_id', userId)
          .ilike('intent', '%$keyword%')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => HelpRequestModel.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('搜索帮助记录失败', e);
      return [];
    }
  }
}
