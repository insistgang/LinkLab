import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import '../../core/utils/logger.dart';
import '../../models/point_transaction_model.dart';
import '../local_storage.dart' as app_storage;

/// 安心積分服務 (F15)
/// 管理求助者的積分獲取和使用
class PointsService {
  PointsService({
    SupabaseClient? supabase,
    app_storage.LocalStorage? storage,
  })  : _supabaseClient = supabase,
        _storage = storage ?? app_storage.LocalStorage();

  SupabaseClient? _supabaseClient;
  final app_storage.LocalStorage _storage;
  bool _localInitialized = false;

  bool get _hasSupabase => Supabase.instance.isInitialized;

  SupabaseClient get _supabase {
    if (!_hasSupabase) {
      throw StateError('Supabase not initialized');
    }
    _supabaseClient ??= Supabase.instance.client;
    return _supabaseClient!;
  }

  Future<void> _ensureLocalStorage() async {
    if (_localInitialized) return;
    await _storage.initialize();
    _localInitialized = true;
  }

  String _pointsKey(String userId) => 'user_points_$userId';
  String _transactionsKey(String userId) => 'user_point_transactions_$userId';
  String _checkinsKey(String userId) => 'user_checkins_$userId';

  Future<void> _seedLocalState(String userId) async {
    if (_storage.getString(_pointsKey(userId)) != null &&
        _storage.getString(_transactionsKey(userId)) != null &&
        _storage.getString(_checkinsKey(userId)) != null) {
      return;
    }

    final now = DateTime.now();
    final transactions = [
      PointTransactionModel(
        id: 'user_tx_${userId}_1',
        userId: userId,
        points: 1,
        type: PointTransactionType.dailyCheckIn,
        description: '每日簽到',
        isPositive: true,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      PointTransactionModel(
        id: 'user_tx_${userId}_2',
        userId: userId,
        points: 10,
        type: PointTransactionType.weeklyBonus,
        description: '連續7天簽到獎勵',
        isPositive: true,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      PointTransactionModel(
        id: 'user_tx_${userId}_3',
        userId: userId,
        points: 7,
        type: PointTransactionType.other,
        description: '完成新手引導',
        isPositive: true,
        createdAt: now.subtract(const Duration(days: 8)),
      ),
    ];
    final checkins = List.generate(6, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      return {
        'user_id': userId,
        'checkin_date':
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'consecutive_days': index + 1,
        'points_earned': 1,
      };
    });

    await _storage.setInt(_pointsKey(userId), 18);
    await _storage.setString(
      _transactionsKey(userId),
      jsonEncode(transactions.map((item) => item.toJson()).toList()),
    );
    await _storage.setString(_checkinsKey(userId), jsonEncode(checkins));
  }

  Future<List<PointTransactionModel>> _getLocalTransactions(String userId) async {
    await _ensureLocalStorage();
    await _seedLocalState(userId);

    final raw = _storage.getString(_transactionsKey(userId));
    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map(
            (item) => PointTransactionModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList()
        ..sort((a, b) {
          final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });
    } catch (e) {
      AppLogger.error('讀取本地積分流水失敗', e);
      return [];
    }
  }

  Future<void> _saveLocalTransactions(
    String userId,
    List<PointTransactionModel> transactions,
  ) async {
    await _ensureLocalStorage();
    await _storage.setString(
      _transactionsKey(userId),
      jsonEncode(transactions.map((item) => item.toJson()).toList()),
    );
  }

  Future<List<Map<String, dynamic>>> _getLocalCheckins(String userId) async {
    await _ensureLocalStorage();
    await _seedLocalState(userId);

    final raw = _storage.getString(_checkinsKey(userId));
    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList()
        ..sort((a, b) => '${b['checkin_date']}'.compareTo('${a['checkin_date']}'));
    } catch (e) {
      AppLogger.error('讀取本地簽到記錄失敗', e);
      return [];
    }
  }

  Future<void> _saveLocalCheckins(
    String userId,
    List<Map<String, dynamic>> checkins,
  ) async {
    await _ensureLocalStorage();
    await _storage.setString(_checkinsKey(userId), jsonEncode(checkins));
  }

  /// 獲取用戶當前積分
  Future<int> getCurrentPoints(String userId) async {
    if (!_hasSupabase) {
      await _ensureLocalStorage();
      await _seedLocalState(userId);
      return _storage.getInt(_pointsKey(userId), defaultValue: 0);
    }

    try {
      final response = await _supabase
          .from('users')
          .select('points')
          .eq('id', userId)
          .single();

      final responseMap = Map<String, dynamic>.from(response as Map);
      return (responseMap['points'] as num?)?.toInt() ?? 0;
    } catch (e) {
      AppLogger.error('獲取用戶積分失敗', e);
      return 0;
    }
  }

  /// 獲取積分交易記錄
  Future<List<PointTransactionModel>> getTransactions(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    if (!_hasSupabase) {
      final transactions = await _getLocalTransactions(userId);
      final start = offset.clamp(0, transactions.length);
      final end = (offset + limit).clamp(start, transactions.length);
      return transactions.sublist(start, end);
    }

    try {
      final response = await _supabase
          .from('point_transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map(
            (json) => PointTransactionModel.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();
    } catch (e) {
      AppLogger.error('獲取積分交易記錄失敗', e);
      return [];
    }
  }

  /// 計算每日簽到積分
  /// 連續簽到規則：
  /// - 連續1天: +1
  /// - 連續7天: +10（額外獎勵）
  /// - 連續30天: +50（月度獎勵）
  Future<int> calculateDailyPoints(String userId) async {
    if (!_hasSupabase) {
      final checkins = await _getLocalCheckins(userId);
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      if (checkins.isNotEmpty &&
          Map<String, dynamic>.from(checkins.first)['checkin_date'].toString() ==
              todayStr) {
        return 0;
      }

      final consecutiveDays = await _getConsecutiveDays(userId);
      int points = PointRules.dailyCheckIn;
      final newConsecutiveDays = consecutiveDays + 1;
      if (newConsecutiveDays % 30 == 0) {
        points += PointRules.monthlyBonus;
      } else if (newConsecutiveDays % 7 == 0) {
        points += PointRules.weeklyBonus;
      }
      return points;
    }

    try {
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

      if (checkins.isNotEmpty) {
        final lastCheckin = Map<String, dynamic>.from(checkins.first as Map);
        if (lastCheckin['checkin_date'].toString() == todayStr) {
          return 0;
        }
      }

      final consecutiveDays = await _getConsecutiveDays(userId);
      int points = PointRules.dailyCheckIn;
      final newConsecutiveDays = consecutiveDays + 1;
      if (newConsecutiveDays % 30 == 0) {
        points += PointRules.monthlyBonus;
      } else if (newConsecutiveDays % 7 == 0) {
        points += PointRules.weeklyBonus;
      }

      return points;
    } catch (e) {
      AppLogger.error('計算每日積分失敗', e);
      return PointRules.dailyCheckIn;
    }
  }

  /// 執行每日簽到
  Future<DailyCheckInResult> performDailyCheckIn(String userId) async {
    if (!_hasSupabase) {
      try {
        final points = await calculateDailyPoints(userId);
        if (points == 0) {
          return const DailyCheckInResult(
            success: false,
            message: '今天已經簽到過了',
          );
        }

        final consecutiveDays = await _getConsecutiveDays(userId);
        final newConsecutiveDays = consecutiveDays + 1;
        final today = DateTime.now();
        final todayStr =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

        final checkins = await _getLocalCheckins(userId);
        checkins.insert(
          0,
          {
            'user_id': userId,
            'checkin_date': todayStr,
            'consecutive_days': newConsecutiveDays,
            'points_earned': points,
          },
        );
        await _saveLocalCheckins(userId, checkins);
        await _addPoints(
          userId,
          points,
          PointTransactionType.dailyCheckIn,
          description: '每日簽到',
        );

        String? bonusMessage;
        if (newConsecutiveDays % 30 == 0) {
          bonusMessage = '連續簽到30天，獲得額外獎勵';
        } else if (newConsecutiveDays % 7 == 0) {
          bonusMessage = '連續簽到7天，獲得額外獎勵';
        }

        return DailyCheckInResult(
          success: true,
          points: points,
          consecutiveDays: newConsecutiveDays,
          message: bonusMessage ?? '簽到成功，獲得$points積分',
        );
      } catch (e) {
        AppLogger.error('本地每日簽到失敗', e);
        return DailyCheckInResult(success: false, message: '簽到失敗：$e');
      }
    }

    try {
      final points = await calculateDailyPoints(userId);

      if (points == 0) {
        return const DailyCheckInResult(
          success: false,
          message: '今天已經簽到過了',
        );
      }

      final consecutiveDays = await _getConsecutiveDays(userId);
      final newConsecutiveDays = consecutiveDays + 1;

      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await _supabase.from('user_checkins').insert({
        'user_id': userId,
        'checkin_date': todayStr,
        'consecutive_days': newConsecutiveDays,
        'points_earned': points,
      });

      await _addPoints(
        userId,
        points,
        PointTransactionType.dailyCheckIn,
        description: '每日簽到',
      );

      String? bonusMessage;
      if (newConsecutiveDays % 30 == 0) {
        bonusMessage = '🎉 恭喜！連續簽到30天，獲得額外獎勵！';
      } else if (newConsecutiveDays % 7 == 0) {
        bonusMessage = '🎊 連續簽到7天，獲得額外獎勵！';
      }

      return DailyCheckInResult(
        success: true,
        points: points,
        consecutiveDays: newConsecutiveDays,
        message: bonusMessage ?? '簽到成功，獲得$points積分',
      );
    } catch (e) {
      AppLogger.error('每日簽到失敗', e);
      return DailyCheckInResult(
        success: false,
        message: '簽到失敗：$e',
      );
    }
  }

  /// 領取連續簽到獎勵（手動觸發）
  Future<void> claimContinuousBonus(String userId) async {
    if (!_hasSupabase) {
      return;
    }

    try {
      await _getConsecutiveDays(userId);
      await _supabase
          .from('point_transactions')
          .select()
          .eq('user_id', userId)
          .eq('type', PointTransactionType.weeklyBonus.name)
          .order('created_at', ascending: false)
          .limit(1);
    } catch (e) {
      AppLogger.error('領取連續獎勵失敗', e);
    }
  }

  /// 獲取連續簽到天數
  Future<int> _getConsecutiveDays(String userId) async {
    if (!_hasSupabase) {
      final checkins = await _getLocalCheckins(userId);
      if (checkins.isEmpty) return 0;

      final lastCheckin = Map<String, dynamic>.from(checkins.first);
      final lastDate = DateTime.parse(lastCheckin['checkin_date'].toString());
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      final lastDateStr =
          '${lastDate.year}-${lastDate.month.toString().padLeft(2, '0')}-${lastDate.day.toString().padLeft(2, '0')}';
      final yesterdayStr =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      if (lastDateStr == yesterdayStr || lastDateStr == todayStr) {
        return (lastCheckin['consecutive_days'] as num?)?.toInt() ?? 0;
      }

      return 0;
    }

    try {
      final response = await _supabase
          .from('user_checkins')
          .select()
          .eq('user_id', userId)
          .order('checkin_date', ascending: false)
          .limit(1);

      final checkins = response as List;
      if (checkins.isEmpty) return 0;

      final lastCheckin = Map<String, dynamic>.from(checkins.first as Map);
      final lastDate = DateTime.parse(lastCheckin['checkin_date'].toString());
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      final lastDateStr =
          '${lastDate.year}-${lastDate.month.toString().padLeft(2, '0')}-${lastDate.day.toString().padLeft(2, '0')}';
      final yesterdayStr =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      if (lastDateStr == yesterdayStr || lastDateStr == todayStr) {
        return (lastCheckin['consecutive_days'] as num?)?.toInt() ?? 0;
      }

      return 0;
    } catch (e) {
      AppLogger.error('獲取連續簽到天數失敗', e);
      return 0;
    }
  }

  /// 添加積分
  Future<void> _addPoints(
    String userId,
    int points,
    PointTransactionType type, {
    String? description,
    String? relatedId,
  }) async {
    if (!_hasSupabase) {
      await _ensureLocalStorage();
      await _seedLocalState(userId);

      final currentPoints = _storage.getInt(_pointsKey(userId), defaultValue: 0);
      await _storage.setInt(_pointsKey(userId), currentPoints + points);

      final transactions = await _getLocalTransactions(userId);
      transactions.insert(
        0,
        PointTransactionModel(
          id: 'user_tx_${DateTime.now().microsecondsSinceEpoch}',
          userId: userId,
          points: points,
          type: type,
          description: description,
          relatedId: relatedId,
          isPositive: points >= 0,
          createdAt: DateTime.now(),
        ),
      );
      await _saveLocalTransactions(userId, transactions);
      return;
    }

    try {
      await _supabase.rpc('add_user_points', params: {
        'p_user_id': userId,
        'p_points': points,
        'p_type': type.name,
        'p_description': description,
        'p_related_id': relatedId,
      });
    } catch (e) {
      AppLogger.error('添加積分失敗', e);
      await _supabase.rpc('increment_user_points', params: {
        'user_id': userId,
        'points': points,
      });
    }
  }

  /// 使用積分（兌換）
  Future<bool> usePoints(
    String userId,
    int points, {
    required String description,
    String? relatedId,
  }) async {
    if (!_hasSupabase) {
      final currentPoints = await getCurrentPoints(userId);
      if (currentPoints < points) {
        return false;
      }

      await _ensureLocalStorage();
      await _storage.setInt(_pointsKey(userId), currentPoints - points);

      final transactions = await _getLocalTransactions(userId);
      transactions.insert(
        0,
        PointTransactionModel(
          id: 'user_tx_${DateTime.now().microsecondsSinceEpoch}',
          userId: userId,
          points: -points,
          type: PointTransactionType.other,
          description: description,
          relatedId: relatedId,
          isPositive: false,
          createdAt: DateTime.now(),
        ),
      );
      await _saveLocalTransactions(userId, transactions);
      return true;
    }

    try {
      final currentPoints = await getCurrentPoints(userId);
      if (currentPoints < points) {
        return false;
      }

      await _supabase.rpc('use_user_points', params: {
        'p_user_id': userId,
        'p_points': points,
        'p_description': description,
        'p_related_id': relatedId,
      });

      return true;
    } catch (e) {
      AppLogger.error('使用積分失敗', e);
      return false;
    }
  }

  /// 獲取簽到狀態
  Future<CheckInStatus> getCheckInStatus(String userId) async {
    if (!_hasSupabase) {
      try {
        final consecutiveDays = await _getConsecutiveDays(userId);
        final today = DateTime.now();
        final todayStr =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        final checkins = await _getLocalCheckins(userId);
        final hasCheckedInToday = checkins.any(
          (item) => '${item['checkin_date']}' == todayStr,
        );

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
        AppLogger.error('獲取本地簽到狀態失敗', e);
        return const CheckInStatus();
      }
    }

    try {
      final consecutiveDays = await _getConsecutiveDays(userId);
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final response = await _supabase
          .from('user_checkins')
          .select()
          .eq('user_id', userId)
          .eq('checkin_date', todayStr)
          .maybeSingle();

      final hasCheckedInToday = response != null;
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
      AppLogger.error('獲取簽到狀態失敗', e);
      return const CheckInStatus();
    }
  }

  /// 獲取下一個里程碑
  String _getNextMilestone(int consecutiveDays) {
    if (consecutiveDays < 7) {
      return '連續7天 (+${PointRules.weeklyBonus})';
    } else if (consecutiveDays < 30) {
      return '連續30天 (+${PointRules.monthlyBonus})';
    } else {
      final next30 = ((consecutiveDays ~/ 30) + 1) * 30;
      return '連續$next30天 (+${PointRules.monthlyBonus})';
    }
  }
}

/// 每日簽到結果
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

/// 簽到狀態
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
