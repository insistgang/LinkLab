import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';
import '../../models/security/credit_score_model.dart';
import 'credit_score_service.dart';

/// 评价服务
class RatingService {
  SupabaseClient? _supabaseClient;
  SupabaseClient get _supabase {
    if (!Supabase.instance.isInitialized) {
      throw StateError('Supabase not initialized');
    }
    _supabaseClient ??= Supabase.instance.client;
    return _supabaseClient!;
  }

  CreditScoreService? _creditScoreServiceInstance;
  CreditScoreService get _creditScoreService {
    _creditScoreServiceInstance ??= CreditScoreService();
    return _creditScoreServiceInstance!;
  }

  /// 提交评价
  Future<RatingRecord?> submitRating({
    required String helpRequestId,
    required String callId,
    required String fromUserId,
    required String toUserId,
    required int rating, // 1-5星
    String? comment,
    List<String>? tags,
    bool isSeekerToVolunteer = true,
  }) async {
    try {
      // 检查是否已经评价过
      final existingRating = await _getExistingRating(callId, fromUserId);
      if (existingRating != null) {
        AppLogger.warning('已经评价过此通话');
        return existingRating;
      }

      final ratingRecord = RatingRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        callId: callId,
        helpRequestId: helpRequestId,
        fromUserId: fromUserId,
        toUserId: toUserId,
        rating: rating.clamp(1, 5),
        comment: comment,
        tags: tags ?? [],
        isSeekerToVolunteer: isSeekerToVolunteer,
        createdAt: DateTime.now(),
      );

      // 保存评价
      await _supabase.from('rating_records').insert({
        'id': ratingRecord.id,
        'call_id': callId,
        'help_request_id': helpRequestId,
        'from_user_id': fromUserId,
        'to_user_id': toUserId,
        'rating': ratingRecord.rating,
        'comment': comment,
        'tags': tags,
        'is_seeker_to_volunteer': isSeekerToVolunteer,
        'created_at': ratingRecord.createdAt?.toIso8601String(),
      });

      // 更新信用分
      await _creditScoreService.processNewRating(ratingRecord);

      AppLogger.info('评价提交成功: ${ratingRecord.id}');
      return ratingRecord;
    } catch (e) {
      AppLogger.error('提交评价失败', e);
      rethrow;
    }
  }

  /// 获取评价详情
  Future<RatingRecord?> getRating(String ratingId) async {
    try {
      final response = await _supabase
          .from('rating_records')
          .select()
          .eq('id', ratingId)
          .single();

      return RatingRecord.fromJson(response);
    } catch (e) {
      AppLogger.error('获取评价失败', e);
      return null;
    }
  }

  /// 获取通话的评价
  Future<List<RatingRecord>> getCallRatings(String callId) async {
    try {
      final response = await _supabase
          .from('rating_records')
          .select()
          .eq('call_id', callId);

      return (response as List)
          .map((json) => RatingRecord.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('获取通话评价失败', e);
      return [];
    }
  }

  /// 获取用户收到的评价
  Future<List<RatingRecord>> getUserRatings(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('rating_records')
          .select()
          .eq('to_user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => RatingRecord.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('获取用户评价失败', e);
      return [];
    }
  }

  /// 获取用户发出的评价
  Future<List<RatingRecord>> getUserGivenRatings(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('rating_records')
          .select()
          .eq('from_user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => RatingRecord.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('获取用户发出的评价失败', e);
      return [];
    }
  }

  /// 获取用户平均评分
  Future<double> getUserAverageRating(String userId) async {
    try {
      final response = await _supabase
          .from('rating_records')
          .select('rating')
          .eq('to_user_id', userId);

      if (response.isEmpty) return 5.0;

      final ratings = (response as List).map((r) => r['rating'] as int).toList();
      final sum = ratings.reduce((a, b) => a + b);
      return sum / ratings.length;
    } catch (e) {
      AppLogger.error('获取用户平均评分失败', e);
      return 5.0;
    }
  }

  /// 获取评价统计
  Future<RatingStatistics> getRatingStatistics(String userId) async {
    try {
      final response = await _supabase
          .from('rating_records')
          .select('rating')
          .eq('to_user_id', userId);

      if (response.isEmpty) {
        return RatingStatistics.empty(userId);
      }

      final ratings = (response as List).map((r) => r['rating'] as int).toList();

      final distribution = <int, int>{};
      for (var i = 1; i <= 5; i++) {
        distribution[i] = ratings.where((r) => r == i).length;
      }

      final sum = ratings.reduce((a, b) => a + b);
      final average = sum / ratings.length;

      return RatingStatistics(
        userId: userId,
        totalRatings: ratings.length,
        averageRating: average,
        fiveStarCount: distribution[5] ?? 0,
        fourStarCount: distribution[4] ?? 0,
        threeStarCount: distribution[3] ?? 0,
        twoStarCount: distribution[2] ?? 0,
        oneStarCount: distribution[1] ?? 0,
      );
    } catch (e) {
      AppLogger.error('获取评价统计失败', e);
      return RatingStatistics.empty(userId);
    }
  }

  /// 检查是否已经评价过
  Future<RatingRecord?> _getExistingRating(String callId, String fromUserId) async {
    try {
      final response = await _supabase
          .from('rating_records')
          .select()
          .eq('call_id', callId)
          .eq('from_user_id', fromUserId)
          .maybeSingle();

      if (response == null) return null;
      return RatingRecord.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// 获取常用标签统计
  Future<Map<String, int>> getCommonTags(String userId) async {
    try {
      final response = await _supabase
          .from('rating_records')
          .select('tags')
          .eq('to_user_id', userId);

      final tagCounts = <String, int>{};
      for (final record in response) {
        final tags = (record['tags'] as List<dynamic>?) ?? [];
        for (final tag in tags) {
          tagCounts[tag as String] = (tagCounts[tag] ?? 0) + 1;
        }
      }

      return tagCounts;
    } catch (e) {
      AppLogger.error('获取常用标签失败', e);
      return {};
    }
  }
}

/// 评价统计
class RatingStatistics {
  final String userId;
  final int totalRatings;
  final double averageRating;
  final int fiveStarCount;
  final int fourStarCount;
  final int threeStarCount;
  final int twoStarCount;
  final int oneStarCount;

  RatingStatistics({
    required this.userId,
    required this.totalRatings,
    required this.averageRating,
    required this.fiveStarCount,
    required this.fourStarCount,
    required this.threeStarCount,
    required this.twoStarCount,
    required this.oneStarCount,
  });

  factory RatingStatistics.empty(String userId) => RatingStatistics(
        userId: userId,
        totalRatings: 0,
        averageRating: 5.0,
        fiveStarCount: 0,
        fourStarCount: 0,
        threeStarCount: 0,
        twoStarCount: 0,
        oneStarCount: 0,
      );

  /// 好评率
  double get positiveRate =>
      totalRatings > 0 ? (fiveStarCount + fourStarCount) / totalRatings : 1.0;

  /// 好评数量
  int get positiveCount => fiveStarCount + fourStarCount;

  /// 差评数量
  int get negativeCount => threeStarCount + twoStarCount + oneStarCount;
}
