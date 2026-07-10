import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';
import '../../../models/call_models.dart';
import '../../push_notification_service.dart';

/// 真实匹配服务
/// 调用Supabase Edge Function进行志愿者匹配
/// AGENTS.md §4.2：竞赛版仅走 Demo 主线，当前文件只保留为实验性真实链路实现。
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

  // 状态流控制器
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

  // 当前匹配状态
  String? _currentHelpRequestId;
  Timer? _timeoutTimer;
  Timer? _expandTimer;
  Timer? _heartbeatTimer;
  RealtimeChannel? _matchChannel;

  /// 开始匹配
  ///
  /// [seekerId] 求助者ID
  /// [urgency] 紧急度: normal, important, urgent, emergency
  /// [location] 位置 {latitude, longitude}
  /// [skills] 需要的技能标签
  /// [helpType] 求助类型描述
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
          message: '正在搜索附近志愿者...',
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
        throw Exception('匹配请求失败: ${response.body}');
      }

      final result = jsonDecode(response.body) as Map<String, dynamic>;

      if (result['success'] == false) {
        if (result['convertedToAsync'] == true) {
          _updateMatchingState(MatchingState.asyncPending);
          _matchProgressController.add(
            MatchProgress(
              stage: MatchStage.asyncPending,
              message: '当前志愿者繁忙，已转为异步留言',
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
          message: '已找到${(result['volunteers'] as List).length}位志愿者，正在发送通知...',
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
          message: '等待志愿者响应...',
          progress: 0.5,
        ),
      );

      // 设置超时定时器
      _setupTimeoutTimers(matchingResult.timeoutAt);

      // 订阅匹配结果
      _subscribeToMatchResult();

      // 启动心跳
      _startHeartbeat();

      return matchingResult;
    } catch (error, stackTrace) {
      AppLogger.error('真实匹配请求失败', error, stackTrace);
      _updateMatchingState(MatchingState.error);
      throw Exception('匹配失败: $error');
    }
  }

  /// 志愿者接受匹配
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
      AppLogger.error('接受匹配失败', error, stackTrace);
      return false;
    }
  }

  /// 志愿者拒绝匹配
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
      AppLogger.error('拒绝匹配失败', error, stackTrace);
    }
  }

  /// 设置超时定时器
  void _setupTimeoutTimers(DateTime timeoutAt) {
    final now = DateTime.now();
    final timeoutDuration = timeoutAt.difference(now);

    // 30秒后扩大搜索范围
    _expandTimer = Timer(const Duration(seconds: 30), () async {
      await _expandSearchRange();
    });

    // 60秒后转为异步
    _timeoutTimer = Timer(timeoutDuration, () async {
      await _convertToAsync();
    });
  }

  /// 扩大搜索范围
  Future<void> _expandSearchRange() async {
    if (_currentHelpRequestId == null) return;

    try {
      _updateMatchingState(MatchingState.expandingRange);
      _matchProgressController.add(
        MatchProgress(
          stage: MatchStage.expanding,
          message: '扩大搜索范围...',
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
        // 更新超时时间
        if (result['timeoutAt'] != null) {
          _timeoutTimer?.cancel();
          _setupTimeoutTimers(DateTime.parse(result['timeoutAt'] as String));
        }

        _matchProgressController.add(
          MatchProgress(
            stage: MatchStage.expanding,
            message: '已扩大搜索范围，新增${result['newVolunteersCount'] ?? 0}位志愿者',
            progress: 0.8,
          ),
        );
      }
    } catch (error, stackTrace) {
      AppLogger.error('扩大搜索范围失败', error, stackTrace);
    }
  }

  /// 转为异步留言
  Future<void> _convertToAsync() async {
    if (_currentHelpRequestId == null) return;

    try {
      _updateMatchingState(MatchingState.convertingToAsync);
      _matchProgressController.add(
        MatchProgress(
          stage: MatchStage.converting,
          message: '转为异步留言...',
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
          message: '已转为异步留言，志愿者将在有空时回复',
          progress: 1.0,
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error('转异步留言失败', error, stackTrace);
      _updateMatchingState(MatchingState.error);
    }
  }

  /// 订阅匹配结果
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

              // 获取志愿者信息
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

  /// 获取志愿者信息
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
      AppLogger.error('获取志愿者信息失败', error, stackTrace);
    }
  }

  /// 启动心跳
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
        AppLogger.error('匹配心跳更新失败', error, stackTrace);
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

  /// 取消定时器
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

  /// 更新匹配状态
  void _updateMatchingState(MatchingState state) {
    _matchingStateController.add(state);
  }

  /// 释放资源
  void dispose() {
    _cancelTimers();
    _matchingStateController.close();
    _matchedVolunteerController.close();
    _matchProgressController.close();
  }
}

/// 匹配状态
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

/// 匹配阶段
enum MatchStage {
  searching,
  notifying,
  waiting,
  expanding,
  converting,
  matched,
  asyncPending,
}

/// 匹配进度
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

/// 紧急度等级
enum UrgencyLevel {
  normal, // 普通
  important, // 重要
  urgent, // 急迫
  emergency, // 紧急
}

/// 位置信息
class Location {
  final double latitude;
  final double longitude;

  Location({required this.latitude, required this.longitude});

  /// 使用Haversine公式计算到另一个位置的距离（公里）
  double distanceTo(Location other) {
    const earthRadius = 6371; // 地球半径（公里）

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

/// 志愿者在线状态服务
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

  /// 上线
  Future<void> goOnline() async {
    if (_isOnline) return;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // 更新志愿者状态
      await _supabase
          .from('volunteer_profiles')
          .update({
            'is_online': true,
            'is_available': true,
            'last_heartbeat_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);

      _isOnline = true;

      // 启动心跳
      _startHeartbeat();

      // 订阅匹配请求
      _subscribeToMatchingRequests();
    } catch (error, stackTrace) {
      AppLogger.error('志愿者上线失败', error, stackTrace);
    }
  }

  /// 下线
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
      AppLogger.error('志愿者下线失败', error, stackTrace);
    }
  }

  /// 设置忙碌状态
  Future<void> setBusy(bool busy) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase
          .from('volunteer_profiles')
          .update({'is_available': !busy})
          .eq('user_id', userId);
    } catch (error, stackTrace) {
      AppLogger.error('设置志愿者忙碌状态失败', error, stackTrace);
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
      AppLogger.error('更新志愿者位置失败', error, stackTrace);
    }
  }

  /// 启动心跳
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
        AppLogger.error('志愿者心跳发送失败', error, stackTrace);
      }
    });
  }

  /// 订阅匹配请求
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

  /// 显示匹配通知
  void _showMatchingNotification(Map<String, dynamic> record) {
    final pushService = PushNotificationService();
    pushService.showLocalNotification(
      title: '有新的求助需要您的帮助',
      body: '点击查看详情',
      data: {
        'helpRequestId': record['id'],
        'type': 'matching_request',
      },
    );
  }

  /// 释放资源
  void dispose() {
    _heartbeatTimer?.cancel();
    goOffline();
  }
}

/// 扩展推送通知服务
extension PushNotificationServiceExtension on PushNotificationService {
  /// 显示本地通知
  Future<void> showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    // 这里使用flutter_local_notifications显示本地通知
    // 实际实现需要在PushNotificationService中添加相应方法
  }
}
