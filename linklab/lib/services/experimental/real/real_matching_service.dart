import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';
import '../../../models/call_models.dart';
import '../../push_notification_service.dart';

/// 真實匹配服務
/// 調用Supabase Edge Function進行志願者匹配
/// AGENTS.md §4.2：競賽版僅走 Demo 主線，當前文件只保留爲實驗性真實鏈路實現。
class RealMatchingService {
  static final RealMatchingService _instance = RealMatchingService._internal();
  factory RealMatchingService() => _instance;
  RealMatchingService._internal();

  SupabaseClient? _supabaseClient;
  SupabaseClient get _supabase {
    if (!Supabase.instance.isInitialized) {
      throw StateError('Supabase not initialized');
    }
    _supabaseClient ??= Supabase.instance.client;
    return _supabaseClient!;
  }

  // 狀態流控制器
  final _matchingStateController = StreamController<MatchingState>.broadcast();
  final _matchedVolunteerController =
      StreamController<MatchedVolunteer?>.broadcast();
  final _matchProgressController = StreamController<MatchProgress>.broadcast();

  Stream<MatchingState> get matchingStateStream =>
      _matchingStateController.stream;
  Stream<MatchedVolunteer?> get matchedVolunteerStream =>
      _matchedVolunteerController.stream;
  Stream<MatchProgress> get matchProgressStream =>
      _matchProgressController.stream;

  // 當前匹配狀態
  String? _currentHelpRequestId;
  Timer? _timeoutTimer;
  Timer? _expandTimer;
  Timer? _heartbeatTimer;
  RealtimeChannel? _matchChannel;

  /// 開始匹配
  ///
  /// [seekerId] 求助者ID
  /// [urgency] 緊急度: normal, important, urgent, emergency
  /// [location] 位置 {latitude, longitude}
  /// [skills] 需要的技能標籤
  /// [helpType] 求助類型描述
  Future<MatchingResult?> findMatches({
    required String seekerId,
    required UrgencyLevel urgency,
    required Location location,
    required List<String> skills,
    String? helpType,
  }) async {
    try {
      _updateMatchingState(MatchingState.searching);
      _matchProgressController.add(
        MatchProgress(
          stage: MatchStage.searching,
          message: '正在搜索附近志願者...',
          progress: 0.1,
        ),
      );

      final response = await http.post(
        Uri.parse('${AppConstants.supabaseUrl}/functions/v1/matching-engine'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${_supabase.auth.currentSession?.accessToken ?? ''}',
        },
        body: jsonEncode({
          'seekerId': seekerId,
          'urgency': urgency.name,
          'location': {'lat': location.latitude, 'lng': location.longitude},
          'skills': skills,
          'helpType': helpType ?? '一般求助',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('匹配請求失敗: ${response.body}');
      }

      final result = jsonDecode(response.body) as Map<String, dynamic>;

      if (result['success'] == false) {
        if (result['convertedToAsync'] == true) {
          _updateMatchingState(MatchingState.asyncPending);
          _matchProgressController.add(
            MatchProgress(
              stage: MatchStage.asyncPending,
              message: '當前志願者繁忙，已轉爲異步留言',
              progress: 1.0,
            ),
          );
        } else {
          _updateMatchingState(MatchingState.noVolunteers);
        }
        return null;
      }

      _currentHelpRequestId = result['helpRequestId'] as String;

      _matchProgressController.add(
        MatchProgress(
          stage: MatchStage.notifying,
          message: '已找到${(result['volunteers'] as List).length}位志願者，正在發送通知...',
          progress: 0.3,
        ),
      );

      final matchingResult = MatchingResult(
        helpRequestId: result['helpRequestId'] as String,
        volunteers: (result['volunteers'] as List<dynamic>)
            .map((v) => MatchedVolunteer.fromJson(v as Map<String, dynamic>))
            .toList(),
        timeoutAt: DateTime.parse(result['timeoutAt'] as String),
      );

      _updateMatchingState(MatchingState.waitingResponse);
      _matchProgressController.add(
        MatchProgress(
          stage: MatchStage.waiting,
          message: '等待志願者響應...',
          progress: 0.5,
        ),
      );

      // 設置超時定時器
      _setupTimeoutTimers(matchingResult.timeoutAt);

      // 訂閱匹配結果
      _subscribeToMatchResult();

      // 啓動心跳
      _startHeartbeat();

      return matchingResult;
    } catch (error, stackTrace) {
      AppLogger.error('真實匹配請求失敗', error, stackTrace);
      _updateMatchingState(MatchingState.error);
      throw Exception('匹配失敗: $error');
    }
  }

  /// 志願者接受匹配
  Future<bool> acceptMatch(String helpRequestId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await http.post(
        Uri.parse(
          '${AppConstants.supabaseUrl}/functions/v1/matching-engine/accept',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${_supabase.auth.currentSession?.accessToken ?? ''}',
        },
        body: jsonEncode({
          'helpRequestId': helpRequestId,
          'volunteerId': userId,
        }),
      );

      if (response.statusCode != 200) return false;

      final result = jsonDecode(response.body) as Map<String, dynamic>;
      return result['success'] == true;
    } catch (error, stackTrace) {
      AppLogger.error('接受匹配失敗', error, stackTrace);
      return false;
    }
  }

  /// 志願者拒絕匹配
  Future<void> rejectMatch(String helpRequestId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await http.post(
        Uri.parse(
          '${AppConstants.supabaseUrl}/functions/v1/matching-engine/reject',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${_supabase.auth.currentSession?.accessToken ?? ''}',
        },
        body: jsonEncode({
          'helpRequestId': helpRequestId,
          'volunteerId': userId,
        }),
      );
    } catch (error, stackTrace) {
      AppLogger.error('拒絕匹配失敗', error, stackTrace);
    }
  }

  /// 設置超時定時器
  void _setupTimeoutTimers(DateTime timeoutAt) {
    final now = DateTime.now();
    final timeoutDuration = timeoutAt.difference(now);

    // 30秒後擴大搜索範圍
    _expandTimer = Timer(const Duration(seconds: 30), () async {
      await _expandSearchRange();
    });

    // 60秒後轉爲異步
    _timeoutTimer = Timer(timeoutDuration, () async {
      await _convertToAsync();
    });
  }

  /// 擴大搜索範圍
  Future<void> _expandSearchRange() async {
    if (_currentHelpRequestId == null) return;

    try {
      _updateMatchingState(MatchingState.expandingRange);
      _matchProgressController.add(
        MatchProgress(
          stage: MatchStage.expanding,
          message: '擴大搜索範圍...',
          progress: 0.7,
        ),
      );

      final response = await http.post(
        Uri.parse(
          '${AppConstants.supabaseUrl}/functions/v1/matching-engine/timeout',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${_supabase.auth.currentSession?.accessToken ?? ''}',
        },
        body: jsonEncode({
          'helpRequestId': _currentHelpRequestId,
          'expandRange': true,
        }),
      );

      final result = jsonDecode(response.body) as Map<String, dynamic>;

      if (result['success'] == true && result['expanded'] == true) {
        // 更新超時時間
        if (result['timeoutAt'] != null) {
          _timeoutTimer?.cancel();
          _setupTimeoutTimers(DateTime.parse(result['timeoutAt'] as String));
        }

        _matchProgressController.add(
          MatchProgress(
            stage: MatchStage.expanding,
            message: '已擴大搜索範圍，新增${result['newVolunteersCount'] ?? 0}位志願者',
            progress: 0.8,
          ),
        );
      }
    } catch (error, stackTrace) {
      AppLogger.error('擴大搜索範圍失敗', error, stackTrace);
    }
  }

  /// 轉爲異步留言
  Future<void> _convertToAsync() async {
    if (_currentHelpRequestId == null) return;

    try {
      _updateMatchingState(MatchingState.convertingToAsync);
      _matchProgressController.add(
        MatchProgress(
          stage: MatchStage.converting,
          message: '轉爲異步留言...',
          progress: 0.9,
        ),
      );

      await http.post(
        Uri.parse(
          '${AppConstants.supabaseUrl}/functions/v1/matching-engine/timeout',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${_supabase.auth.currentSession?.accessToken ?? ''}',
        },
        body: jsonEncode({
          'helpRequestId': _currentHelpRequestId,
          'expandRange': false,
        }),
      );

      _updateMatchingState(MatchingState.asyncPending);
      _matchProgressController.add(
        MatchProgress(
          stage: MatchStage.asyncPending,
          message: '已轉爲異步留言，志願者將在有空時回覆',
          progress: 1.0,
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error('轉異步留言失敗', error, stackTrace);
      _updateMatchingState(MatchingState.error);
    }
  }

  /// 訂閱匹配結果
  void _subscribeToMatchResult() {
    if (_currentHelpRequestId == null) return;

    _matchChannel = _supabase
        .channel('help_request:$_currentHelpRequestId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'help_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: _currentHelpRequestId!,
          ),
          callback: (payload) {
            final newRecord = Map<String, dynamic>.from(payload.newRecord);
            final status = newRecord['status']?.toString();

            if (status == 'connected') {
              // 匹配成功
              _cancelTimers();
              _updateMatchingState(MatchingState.matched);
              _matchProgressController.add(
                MatchProgress(
                  stage: MatchStage.matched,
                  message: '匹配成功！',
                  progress: 1.0,
                ),
              );

              // 獲取志願者信息
              final volunteerId = newRecord['volunteer_id']?.toString();
              if (volunteerId != null) {
                _fetchVolunteerInfo(volunteerId);
              }
            } else if (status == 'cancelled') {
              _cancelTimers();
              _updateMatchingState(MatchingState.cancelled);
            }
          },
        )
        .subscribe();
  }

  /// 獲取志願者信息
  Future<void> _fetchVolunteerInfo(String volunteerId) async {
    try {
      final response = await _supabase
          .from('volunteer_profiles')
          .select('*, users:user_id(name, avatar_url)')
          .eq('user_id', volunteerId)
          .single();
      final profile = Map<String, dynamic>.from(response as Map);
      final rawSkills = profile['skills'];
      final skills = rawSkills is List
          ? rawSkills.map((item) => item.toString()).toList()
          : <String>[];

      final volunteer = MatchedVolunteer(
        id: volunteerId,
        userId: profile['user_id'].toString(),
        score: profile['credit_score'] != null
            ? (profile['credit_score'] as num).toDouble() / 5.0
            : 0.8,
        distance: 0,
        skills: skills,
      );

      _matchedVolunteerController.add(volunteer);
    } catch (error, stackTrace) {
      AppLogger.error('獲取志願者信息失敗', error, stackTrace);
    }
  }

  /// 啓動心跳
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_currentHelpRequestId == null) {
        _heartbeatTimer?.cancel();
        return;
      }

      try {
        await _supabase
            .from('help_requests')
            .update({'updated_at': DateTime.now().toIso8601String()})
            .eq('id', _currentHelpRequestId!);
      } catch (error, stackTrace) {
        AppLogger.error('匹配心跳更新失敗', error, stackTrace);
      }
    });
  }

  /// 取消匹配
  Future<void> cancelMatching() async {
    _cancelTimers();

    final currentHelpRequestId = _currentHelpRequestId;
    if (currentHelpRequestId != null) {
      await _supabase
          .from('help_requests')
          .update({'status': 'cancelled'})
          .eq('id', currentHelpRequestId);
    }

    _updateMatchingState(MatchingState.cancelled);
  }

  /// 取消定時器
  void _cancelTimers() {
    _timeoutTimer?.cancel();
    _expandTimer?.cancel();
    _heartbeatTimer?.cancel();
    _matchChannel?.unsubscribe();

    _timeoutTimer = null;
    _expandTimer = null;
    _heartbeatTimer = null;
    _matchChannel = null;
  }

  /// 更新匹配狀態
  void _updateMatchingState(MatchingState state) {
    _matchingStateController.add(state);
  }

  /// 釋放資源
  void dispose() {
    _cancelTimers();
    _matchingStateController.close();
    _matchedVolunteerController.close();
    _matchProgressController.close();
  }
}

/// 匹配狀態
enum MatchingState {
  searching,
  waitingResponse,
  expandingRange,
  matched,
  noVolunteers,
  convertingToAsync,
  asyncPending,
  cancelled,
  error,
}

/// 匹配階段
enum MatchStage {
  searching,
  notifying,
  waiting,
  expanding,
  converting,
  matched,
  asyncPending,
}

/// 匹配進度
class MatchProgress {
  final MatchStage stage;
  final String message;
  final double progress; // 0.0 - 1.0

  MatchProgress({
    required this.stage,
    required this.message,
    required this.progress,
  });
}

/// 緊急度等級
enum UrgencyLevel {
  normal, // 普通
  important, // 重要
  urgent, // 急迫
  emergency, // 緊急
}

/// 位置信息
class Location {
  final double latitude;
  final double longitude;

  Location({required this.latitude, required this.longitude});

  /// 使用Haversine公式計算到另一個位置的距離（公里）
  double distanceTo(Location other) {
    const earthRadius = 6371; // 地球半徑（公里）

    final dLat = _toRadians(other.latitude - latitude);
    final dLng = _toRadians(other.longitude - longitude);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(latitude)) *
            cos(_toRadians(other.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  static double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }
}

/// 志願者在線狀態服務
class VolunteerPresenceService {
  static final VolunteerPresenceService _instance =
      VolunteerPresenceService._internal();
  factory VolunteerPresenceService() => _instance;
  VolunteerPresenceService._internal();

  SupabaseClient? _supabaseClient;
  SupabaseClient get _supabase {
    if (!Supabase.instance.isInitialized) {
      throw StateError('Supabase not initialized');
    }
    _supabaseClient ??= Supabase.instance.client;
    return _supabaseClient!;
  }

  Timer? _heartbeatTimer;
  bool _isOnline = false;

  /// 上線
  Future<void> goOnline() async {
    if (_isOnline) return;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // 更新志願者狀態
      await _supabase
          .from('volunteer_profiles')
          .update({
            'is_online': true,
            'is_available': true,
            'last_heartbeat_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);

      _isOnline = true;

      // 啓動心跳
      _startHeartbeat();

      // 訂閱匹配請求
      _subscribeToMatchingRequests();
    } catch (error, stackTrace) {
      AppLogger.error('志願者上線失敗', error, stackTrace);
    }
  }

  /// 下線
  Future<void> goOffline() async {
    _heartbeatTimer?.cancel();

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase
          .from('volunteer_profiles')
          .update({'is_online': false, 'is_available': false})
          .eq('user_id', userId);

      _isOnline = false;
    } catch (error, stackTrace) {
      AppLogger.error('志願者下線失敗', error, stackTrace);
    }
  }

  /// 設置忙碌狀態
  Future<void> setBusy(bool busy) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase
          .from('volunteer_profiles')
          .update({'is_available': !busy})
          .eq('user_id', userId);
    } catch (error, stackTrace) {
      AppLogger.error('設置志願者忙碌狀態失敗', error, stackTrace);
    }
  }

  /// 更新位置
  Future<void> updateLocation(double latitude, double longitude) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase
          .from('volunteer_profiles')
          .update({
            'latitude': latitude,
            'longitude': longitude,
            'last_heartbeat_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
    } catch (error, stackTrace) {
      AppLogger.error('更新志願者位置失敗', error, stackTrace);
    }
  }

  /// 啓動心跳
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _heartbeatTimer?.cancel();
        return;
      }

      try {
        await _supabase
            .from('volunteer_profiles')
            .update({'last_heartbeat_at': DateTime.now().toIso8601String()})
            .eq('user_id', userId);
      } catch (error, stackTrace) {
        AppLogger.error('志願者心跳發送失敗', error, stackTrace);
      }
    });
  }

  /// 訂閱匹配請求
  void _subscribeToMatchingRequests() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _supabase
        .channel('volunteer_matches:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'help_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'status',
            value: 'matching',
          ),
          callback: (payload) {
            final record = Map<String, dynamic>.from(payload.newRecord);
            final type = record['type']?.toString();
            if (type == 'realtime_voice' ||
                type == 'realtime_video' ||
                type == 'sos') {
              _showMatchingNotification(record);
            }
          },
        )
        .subscribe();
  }

  /// 顯示匹配通知
  void _showMatchingNotification(Map<String, dynamic> record) {
    final pushService = PushNotificationService();
    pushService.showLocalNotification(
      title: '有新的求助需要您的幫助',
      body: '點擊查看詳情',
      data: {
        'helpRequestId': record['id'],
        'type': 'matching_request',
      },
    );
  }

  /// 釋放資源
  void dispose() {
    _heartbeatTimer?.cancel();
    goOffline();
  }
}

/// 擴展推送通知服務
extension PushNotificationServiceExtension on PushNotificationService {
  /// 顯示本地通知
  Future<void> showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    // 這裏使用flutter_local_notifications顯示本地通知
    // 實際實現需要在PushNotificationService中添加相應方法
  }
}
