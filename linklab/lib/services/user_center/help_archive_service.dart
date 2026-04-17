import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import '../../core/utils/logger.dart';
import '../../models/help_request_model.dart';
import '../../models/help_statistics_model.dart';
import '../local_storage.dart' as storage;

/// 帮助档案服务 (F14)
/// 管理求助者的历史帮助记录和统计
class HelpArchiveService {
  HelpArchiveService({SupabaseClient? supabase}) : _supabaseClient = supabase;

  SupabaseClient? _supabaseClient;
  final storage.LocalStorage _localStorage = storage.LocalStorage();

  bool get _hasSupabase {
    try {
      return Supabase.instance.isInitialized;
    } catch (_) {
      return false;
    }
  }

  SupabaseClient get _supabase {
    if (!_hasSupabase) {
      throw StateError('Supabase not initialized');
    }
    _supabaseClient ??= Supabase.instance.client;
    return _supabaseClient!;
  }

  /// 获取帮助历史记录
  Future<List<HelpRequestModel>> getHelpHistory(
    String userId, {
    int limit = 20,
    int offset = 0,
    HelpRecordFilter? filter,
  }) async {
    if (!_hasSupabase) {
      return _getLocalHelpHistory(limit: limit, offset: offset, filter: filter);
    }

    try {
      dynamic query = _supabase.from('help_requests').select();
      query = query.eq('seeker_id', userId);

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

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map(
            (json) => HelpRequestModel.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();
    } catch (e) {
      AppLogger.error('获取帮助历史失败', e);
      return [];
    }
  }

  /// 获取帮助统计数据
  Future<HelpStatistics> getStatistics(String userId) async {
    if (!_hasSupabase) {
      return _buildLocalStatistics();
    }

    try {
      final totalResponse = await _supabase
          .from('help_requests')
          .select()
          .eq('seeker_id', userId);

      final allRequests = (totalResponse as List)
          .map(
            (json) => HelpRequestModel.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();

      return _buildStatisticsFromRequests(allRequests);
    } catch (e) {
      AppLogger.error('获取帮助统计失败', e);
      return const HelpStatistics();
    }
  }

  Future<HelpRequestModel?> getHelpRequestDetail(String requestId) async {
    if (!_hasSupabase) {
      try {
        return _getLocalHelpHistory(
          limit: 100,
          offset: 0,
        ).firstWhere((request) => request.id == requestId);
      } catch (_) {
        return null;
      }
    }

    try {
      final response = await _supabase
          .from('help_requests')
          .select()
          .eq('id', requestId)
          .single();

      return HelpRequestModel.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
    } catch (e) {
      AppLogger.error('获取帮助记录详情失败', e);
      return null;
    }
  }

  Future<List<HelpRequestModel>> searchHelpHistory(
    String userId,
    String keyword,
  ) async {
    if (!_hasSupabase) {
      final normalizedKeyword = keyword.trim();
      return _getLocalHelpHistory(limit: 100, offset: 0).where((request) {
        return (request.intent ?? '').contains(normalizedKeyword);
      }).toList();
    }

    try {
      final response = await _supabase
          .from('help_requests')
          .select()
          .eq('seeker_id', userId)
          .ilike('intent', '%$keyword%')
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (json) => HelpRequestModel.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();
    } catch (e) {
      AppLogger.error('搜索帮助记录失败', e);
      return [];
    }
  }

  List<HelpTypeStat> _calculateTypeStats(List<HelpRequestModel> requests) {
    final typeCount = <String, int>{};

    for (final request in requests) {
      final type = request.type ?? 'unknown';
      typeCount[type] = (typeCount[type] ?? 0) + 1;
    }

    return typeCount.entries
        .map(
          (entry) => HelpTypeStat(
            type: entry.key,
            count: entry.value,
            typeLabel: _getTypeLabel(entry.key),
          ),
        )
        .toList();
  }

  List<MonthlyStat> _calculateMonthlyStats(List<HelpRequestModel> requests) {
    final now = DateTime.now();
    final monthlyData = <String, Map<String, int>>{};

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      monthlyData[key] = {'count': 0, 'ai': 0, 'volunteer': 0};
    }

    for (final request in requests) {
      if (request.createdAt == null) continue;

      final month = request.createdAt!;
      final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      final bucket = monthlyData[key];
      if (bucket == null) continue;

      bucket['count'] = bucket['count']! + 1;
      if (request.status == 'ai_resolved') {
        bucket['ai'] = bucket['ai']! + 1;
      } else if (request.volunteerId != null) {
        bucket['volunteer'] = bucket['volunteer']! + 1;
      }
    }

    return monthlyData.entries
        .map(
          (entry) => MonthlyStat(
            month: entry.key,
            count: entry.value['count']!,
            aiCount: entry.value['ai']!,
            volunteerCount: entry.value['volunteer']!,
          ),
        )
        .toList();
  }

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

  List<HelpRequestModel> _getLocalHelpHistory({
    int limit = 20,
    int offset = 0,
    HelpRecordFilter? filter,
  }) {
    List<HelpRequestModel> items =
        _localStorage
            .getHelpHistory()
            .map(
              (json) =>
                  HelpRequestModel.fromJson(Map<String, dynamic>.from(json)),
            )
            .toList()
          ..sort(
            (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                .compareTo(
                  a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
                ),
          );

    final type = filter?.type;
    final status = filter?.status;
    final startDate = filter?.startDate;
    final endDate = filter?.endDate;

    if (type != null) {
      items = items.where((item) => item.type == type).toList();
    }
    if (status != null) {
      items = items.where((item) => item.status == status).toList();
    }
    if (startDate != null) {
      items = items.where((item) {
        final createdAt = item.createdAt;
        return createdAt != null &&
            (createdAt.isAfter(startDate) ||
                createdAt.isAtSameMomentAs(startDate));
      }).toList();
    }
    if (endDate != null) {
      items = items.where((item) {
        final createdAt = item.createdAt;
        return createdAt != null &&
            (createdAt.isBefore(endDate) ||
                createdAt.isAtSameMomentAs(endDate));
      }).toList();
    }

    if (offset >= items.length) {
      return [];
    }

    final end = (offset + limit).clamp(0, items.length).toInt();
    return items.sublist(offset, end);
  }

  HelpStatistics _buildLocalStatistics() {
    final allRequests = _getLocalHelpHistory(limit: 100, offset: 0);
    return _buildStatisticsFromRequests(allRequests);
  }

  HelpStatistics _buildStatisticsFromRequests(
    List<HelpRequestModel> allRequests,
  ) {
    final totalRequests = allRequests.length;
    final aiResolvedCount = allRequests
        .where((request) => request.status == 'ai_resolved')
        .length;
    final volunteerHelpCount = allRequests
        .where((request) => request.volunteerId != null)
        .length;
    final sosCount = allRequests
        .where((request) => request.type == 'sos')
        .length;
    final aiResolutionRate = totalRequests > 0
        ? aiResolvedCount / totalRequests
        : 0.0;
    final totalDurationMinutes = allRequests
        .where((request) => request.durationSeconds != null)
        .fold<int>(0, (sum, request) => sum + (request.durationSeconds! ~/ 60));
    final ratedRequests = allRequests
        .where((request) => request.seekerRating != null)
        .toList();
    final averageRating = ratedRequests.isNotEmpty
        ? ratedRequests.fold<int>(
                0,
                (sum, request) => sum + request.seekerRating!,
              ) /
              ratedRequests.length
        : 0.0;

    return HelpStatistics(
      totalRequests: totalRequests,
      aiResolvedCount: aiResolvedCount,
      volunteerHelpCount: volunteerHelpCount,
      sosCount: sosCount,
      aiResolutionRate: aiResolutionRate,
      totalDurationMinutes: totalDurationMinutes,
      averageRating: averageRating,
      typeStats: _calculateTypeStats(allRequests),
      monthlyStats: _calculateMonthlyStats(allRequests),
      lastUpdatedAt: DateTime.now(),
    );
  }
}
