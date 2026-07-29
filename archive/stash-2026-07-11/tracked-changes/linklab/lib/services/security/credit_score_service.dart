import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';
import '../../models/security/credit_score_model.dart';

/// 信用分服务
class CreditScoreService {
  SupabaseClient? _supabaseClient;
  SupabaseClient get _supabase {
    if (!Supabase.instance.isInitialized) {
      throw StateError('Supabase not initialized');
    }
    _supabaseClient ??= Supabase.instance.client;
    return _supabaseClient!;
  }

  /// 获取用户信用分
  Future<CreditScore?> getCreditScore(String userId) async {
    try {
      final response = await _supabase
          .from('credit_scores')
          .select()
          .eq('user_id', userId)
          .single();

      return CreditScore.fromJson(Map<String, dynamic>.from(response as Map));
    } catch (e) {
      AppLogger.error('获取信用分失败', e);
      return null;
    }
  }

  /// 初始化用户信用分（新用户）
  Future<CreditScore> initializeCreditScore(String userId) async {
    try {
      final creditScore = CreditScore(
        userId: userId,
        score: 5.0,
        totalRatings: 0,
        positiveRatings: 0,
        negativeRatings: 0,
        consecutiveGoodRatings: 0,
        createdAt: DateTime.now(),
      );

      await _supabase.from('credit_scores').insert({
        'user_id': userId,
        'score': creditScore.score,
        'total_ratings': creditScore.totalRatings,
        'positive_ratings': creditScore.positiveRatings,
        'negative_ratings': creditScore.negativeRatings,
        'consecutive_good_ratings': creditScore.consecutiveGoodRatings,
        'created_at': creditScore.createdAt?.toIso8601String(),
      });

      AppLogger.info('初始化信用分成功: $userId');
      return creditScore;
    } catch (e) {
      AppLogger.error('初始化信用分失败', e);
      rethrow;
    }
  }

  /// 计算信用分
  Future<CreditScoreCalculation> calculateScore(String userId) async {
    try {
      // 获取当前信用分
      var creditScore = await getCreditScore(userId);
      if (creditScore == null) {
        creditScore = await initializeCreditScore(userId);
      }

      final changes = <CreditScoreChange>[];
      var newScore = creditScore.score;

      // 获取最近30天的评价记录
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentRatings = await _getRecentRatings(userId, thirtyDaysAgo);

      // 处理每条评价
      for (final rating in recentRatings) {
        if (rating.createdAt?.isBefore(thirtyDaysAgo) ?? true) continue;

        CreditChangeReason reason;
        double change = 0.0;

        switch (rating.rating) {
          case 5:
            reason = CreditChangeReason.rating5Star;
            change = reason.defaultChange;
            break;
          case 4:
            reason = CreditChangeReason.rating4Star;
            change = reason.defaultChange;
            break;
          default:
            reason = CreditChangeReason.rating3StarOrBelow;
            change = reason.defaultChange;
            break;
        }

        newScore += change;
        changes.add(CreditScoreChange(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          change: change,
          scoreBefore: newScore - change,
          scoreAfter: newScore,
          reason: reason,
          relatedId: rating.id,
          description: '${reason.label}: ${rating.rating}星',
        ));
      }

      // 检查连续好评奖励
      if (creditScore.consecutiveGoodRatings >= 10) {
        final bonus = CreditChangeReason.consecutiveGoodBonus;
        newScore += bonus.defaultChange;
        changes.add(CreditScoreChange(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          change: bonus.defaultChange,
          scoreBefore: newScore - bonus.defaultChange,
          scoreAfter: newScore,
          reason: bonus,
          description: '连续10次好评奖励',
        ));
      }

      // 检查30天无违规奖励
      if (creditScore.lastViolationAt == null ||
          creditScore.lastViolationAt!.isBefore(thirtyDaysAgo)) {
        // 检查是否已经有月度奖励
        final hasMonthlyBonus = await _hasMonthlyBonus(userId);
        if (!hasMonthlyBonus) {
          final bonus = CreditChangeReason.monthlyNoViolation;
          newScore += bonus.defaultChange;
          changes.add(CreditScoreChange(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            userId: userId,
            change: bonus.defaultChange,
            scoreBefore: newScore - bonus.defaultChange,
            scoreAfter: newScore,
            reason: bonus,
            description: '30天无违规奖励',
          ));
        }
      }

      // 确保分数在0-5范围内
      newScore = newScore.clamp(0.0, 5.0);

      // 更新信用分
      await _updateCreditScore(userId, newScore, creditScore, changes);

      return CreditScoreCalculation(
        newScore: newScore,
        changes: changes,
        summary: '信用分更新: ${creditScore.score.toStringAsFixed(1)} → ${newScore.toStringAsFixed(1)}',
      );
    } catch (e) {
      AppLogger.error('计算信用分失败', e);
      rethrow;
    }
  }

  /// 处理新的评价
  Future<CreditScore> processNewRating(RatingRecord rating) async {
    try {
      var creditScore = await getCreditScore(rating.toUserId);
      if (creditScore == null) {
        creditScore = await initializeCreditScore(rating.toUserId);
      }

      var newScore = creditScore.score;
      var consecutiveGood = creditScore.consecutiveGoodRatings;

      // 根据评分调整分数
      switch (rating.rating) {
        case 5:
          newScore += CreditChangeReason.rating5Star.defaultChange;
          consecutiveGood++;
          break;
        case 4:
          newScore += CreditChangeReason.rating4Star.defaultChange;
          consecutiveGood++;
          break;
        default:
          newScore += CreditChangeReason.rating3StarOrBelow.defaultChange;
          consecutiveGood = 0;
          break;
      }

      // 检查连续好评奖励
      if (consecutiveGood >= 10 && creditScore.consecutiveGoodRatings < 10) {
        newScore += CreditChangeReason.consecutiveGoodBonus.defaultChange;
      }

      // 确保分数在范围内
      newScore = newScore.clamp(0.0, 5.0);

      // 更新数据库
      await _supabase.from('credit_scores').update({
        'score': newScore,
        'total_ratings': creditScore.totalRatings + 1,
        'positive_ratings': rating.isPositive
            ? creditScore.positiveRatings + 1
            : creditScore.positiveRatings,
        'negative_ratings': rating.isNegative
            ? creditScore.negativeRatings + 1
            : creditScore.negativeRatings,
        'consecutive_good_ratings': consecutiveGood,
        'last_rating_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', rating.toUserId);

      // 记录变动
      await _recordCreditChange(rating.toUserId, rating);

      AppLogger.info('处理新评价完成: ${rating.toUserId}, 新分数: $newScore');

      return creditScore.copyWith(
        score: newScore,
        totalRatings: creditScore.totalRatings + 1,
        consecutiveGoodRatings: consecutiveGood,
      );
    } catch (e) {
      AppLogger.error('处理新评价失败', e);
      rethrow;
    }
  }

  /// 处理举报（扣分）
  Future<CreditScore> processValidReport(String userId) async {
    try {
      var creditScore = await getCreditScore(userId);
      if (creditScore == null) {
        creditScore = await initializeCreditScore(userId);
      }

      var newScore = creditScore.score + CreditChangeReason.validReport.defaultChange;
      newScore = newScore.clamp(0.0, 5.0);

      await _supabase.from('credit_scores').update({
        'score': newScore,
        'last_violation_at': DateTime.now().toIso8601String(),
        'consecutive_good_ratings': 0,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);

      // 记录变动
      await _supabase.from('credit_score_changes').insert({
        'user_id': userId,
        'change': CreditChangeReason.validReport.defaultChange,
        'score_before': creditScore.score,
        'score_after': newScore,
        'reason': 'validReport',
        'description': '被有效举报',
        'created_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('处理举报扣分完成: $userId, 新分数: $newScore');

      return creditScore.copyWith(
        score: newScore,
        lastViolationAt: DateTime.now(),
        consecutiveGoodRatings: 0,
      );
    } catch (e) {
      AppLogger.error('处理举报扣分失败', e);
      rethrow;
    }
  }

  /// 获取匹配权重
  Future<double> getMatchingWeight(String userId) async {
    final creditScore = await getCreditScore(userId);
    return creditScore?.matchingWeight ?? 0.0;
  }

  /// 检查是否可以匹配
  Future<bool> canMatch(String userId) async {
    final creditScore = await getCreditScore(userId);
    return creditScore?.canMatch ?? false;
  }

  /// 获取信用分变动历史
  Future<List<CreditScoreChange>> getCreditHistory(String userId, {int limit = 20}) async {
    try {
      final response = await _supabase
          .from('credit_score_changes')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map(
            (json) => CreditScoreChange.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();
    } catch (e) {
      AppLogger.error('获取信用分历史失败', e);
      return [];
    }
  }

  /// 获取最近评价
  Future<List<RatingRecord>> _getRecentRatings(String userId, DateTime since) async {
    try {
      final response = await _supabase
          .from('rating_records')
          .select()
          .eq('to_user_id', userId)
          .gte('created_at', since.toIso8601String())
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (json) =>
                RatingRecord.fromJson(Map<String, dynamic>.from(json as Map)),
          )
          .toList();
    } catch (e) {
      AppLogger.error('获取最近评价失败', e);
      return [];
    }
  }

  /// 检查是否已有月度奖励
  Future<bool> _hasMonthlyBonus(String userId) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final response = await _supabase
          .from('credit_score_changes')
          .select()
          .eq('user_id', userId)
          .eq('reason', 'monthlyNoViolation')
          .gte('created_at', thirtyDaysAgo.toIso8601String())
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// 更新信用分
  Future<void> _updateCreditScore(
    String userId,
    double newScore,
    CreditScore oldScore,
    List<CreditScoreChange> changes,
  ) async {
    await _supabase.from('credit_scores').update({
      'score': newScore,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId);

    // 批量记录变动
    for (final change in changes) {
      await _supabase.from('credit_score_changes').insert({
        'user_id': userId,
        'change': change.change,
        'score_before': change.scoreBefore,
        'score_after': change.scoreAfter,
        'reason': change.reason.name,
        'related_id': change.relatedId,
        'description': change.description,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  /// 记录信用分变动
  Future<void> _recordCreditChange(String userId, RatingRecord rating) async {
    CreditChangeReason reason;
    switch (rating.rating) {
      case 5:
        reason = CreditChangeReason.rating5Star;
        break;
      case 4:
        reason = CreditChangeReason.rating4Star;
        break;
      default:
        reason = CreditChangeReason.rating3StarOrBelow;
        break;
    }

    await _supabase.from('credit_score_changes').insert({
      'user_id': userId,
      'change': reason.defaultChange,
      'reason': reason.name,
      'related_id': rating.id,
      'description': '${reason.label}: ${rating.rating}星',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// 监听信用分变化
  Stream<CreditScore?> watchCreditScore(String userId) {
    return _supabase
        .from('credit_scores')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((rows) {
          if (rows.isEmpty) return null;
          return CreditScore.fromJson(Map<String, dynamic>.from(rows.first));
        });
  }
}
