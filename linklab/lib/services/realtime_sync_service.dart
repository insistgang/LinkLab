import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/help_request_model.dart';
import '../models/user_model.dart';

/// Realtime状态同步服务
/// 负责志愿者在线状态、求助状态、通话状态的实时同步
class RealtimeSyncService {
  static final RealtimeSyncService _instance = RealtimeSyncService._internal();
  factory RealtimeSyncService() => _instance;
  RealtimeSyncService._internal();

  SupabaseClient? _supabaseClient;
  SupabaseClient get _supabase {
    if (!Supabase.instance.isInitialized) {
      throw StateError('Supabase not initialized');
    }
    _supabaseClient ??= Supabase.instance.client;
    return _supabaseClient!;
  }

  // 频道缓存
  final Map<String, RealtimeChannel> _channels = {};

  // 状态流
  final _volunteerStatusController = StreamController<VolunteerStatus>.broadcast();
  final _helpRequestStatusController = StreamController<HelpRequestStatus>.broadcast();
  final _callStatusController = StreamController<CallStatusEvent>.broadcast();

  Stream<VolunteerStatus> get volunteerStatusStream => _volunteerStatusController.stream;
  Stream<HelpRequestStatus> get helpRequestStatusStream => _helpRequestStatusController.stream;
  Stream<CallStatusEvent> get callStatusStream => _callStatusController.stream;

  /// 订阅志愿者在线状态
  ///
  /// [volunteerId] 志愿者ID
  void subscribeVolunteerStatus(String volunteerId) {
    final channelName = 'volunteer_status:$volunteerId';

    if (_channels.containsKey(channelName)) return;

    final channel = _supabase
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'volunteer_profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: volunteerId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            _volunteerStatusController.add(VolunteerStatus(
              volunteerId: volunteerId,
              isOnline: record['is_online'] ?? false,
              isAvailable: record['is_available'] ?? false,
              lastHeartbeatAt: record['last_heartbeat_at'] != null
                  ? DateTime.parse(record['last_heartbeat_at'])
                  : null,
            ));
          },
        )
        .subscribe();

    _channels[channelName] = channel;
  }

  /// 订阅求助状态
  ///
  /// [helpRequestId] 求助记录ID
  void subscribeHelpRequestStatus(String helpRequestId) {
    final channelName = 'help_request:$helpRequestId';

    if (_channels.containsKey(channelName)) return;

    final channel = _supabase
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'help_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: helpRequestId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            _helpRequestStatusController.add(HelpRequestStatus(
              helpRequestId: helpRequestId,
              status: record['status'] ?? 'pending',
              volunteerId: record['volunteer_id'],
              matchedAt: record['matched_at'] != null
                  ? DateTime.parse(record['matched_at'])
                  : null,
              completedAt: record['completed_at'] != null
                  ? DateTime.parse(record['completed_at'])
                  : null,
            ));
          },
        )
        .subscribe();

    _channels[channelName] = channel;
  }

  /// 订阅通话状态
  ///
  /// [roomId] 通话房间ID
  void subscribeCallStatus(String roomId) {
    final channelName = 'call:$roomId';

    if (_channels.containsKey(channelName)) return;

    final channel = _supabase
        .channel(channelName)
        .onBroadcast(
          event: 'signaling',
          callback: (payload) {
            _callStatusController.add(CallStatusEvent(
              roomId: roomId,
              type: payload['type'] as String,
              fromUserId: payload['from_user_id'] as String,
              data: payload['data'],
              timestamp: DateTime.now(),
            ));
          },
        )
        .subscribe();

    _channels[channelName] = channel;
  }

  /// 订阅SOS状态
  ///
  /// [sosId] SOS记录ID
  void subscribeSOSStatus(String sosId) {
    final channelName = 'sos:$sosId';

    if (_channels.containsKey(channelName)) return;

    final channel = _supabase
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'sos_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: sosId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            _helpRequestStatusController.add(HelpRequestStatus(
              helpRequestId: sosId,
              status: record['status'] ?? 'active',
              volunteerId: record['responder_id'],
              matchedAt: record['responded_at'] != null
                  ? DateTime.parse(record['responded_at'])
                  : null,
            ));
          },
        )
        .subscribe();

    _channels[channelName] = channel;
  }

  /// 订阅志愿者匹配请求
  ///
  /// [userId] 用户ID（志愿者）
  void subscribeMatchingRequests(String userId) {
    final channelName = 'volunteer_matches:$userId';

    if (_channels.containsKey(channelName)) return;

    final channel = _supabase
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'help_request_matches',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'volunteer_user_id',
            value: userId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            // 触发匹配请求事件
            _onMatchingRequestReceived(record);
          },
        )
        .subscribe();

    _channels[channelName] = channel;
  }

  /// 取消订阅
  ///
  /// [channelName] 频道名称，如果为null则取消所有订阅
  void unsubscribe([String? channelName]) {
    if (channelName != null) {
      _channels[channelName]?.unsubscribe();
      _channels.remove(channelName);
    } else {
      // 取消所有订阅
      for (final channel in _channels.values) {
        channel.unsubscribe();
      }
      _channels.clear();
    }
  }

  /// 发送通话信令
  ///
  /// [roomId] 房间ID
  /// [type] 信令类型
  /// [data] 信令数据
  Future<void> sendSignalingMessage({
    required String roomId,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    await _supabase.channel('call:$roomId').sendBroadcastMessage(
      'signaling',
      {
        'type': type,
        'from_user_id': _supabase.auth.currentUser?.id,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 处理匹配请求接收
  void _onMatchingRequestReceived(Map<String, dynamic> record) {
    // 这里可以触发本地通知或回调
    // 实际实现中可以通过另一个stream暴露给UI层
  }

  /// 释放资源
  void dispose() {
    unsubscribe();
    _volunteerStatusController.close();
    _helpRequestStatusController.close();
    _callStatusController.close();
  }
}

/// 志愿者状态
class VolunteerStatus {
  final String volunteerId;
  final bool isOnline;
  final bool isAvailable;
  final DateTime? lastHeartbeatAt;

  VolunteerStatus({
    required this.volunteerId,
    required this.isOnline,
    required this.isAvailable,
    this.lastHeartbeatAt,
  });

  /// 是否活跃（5分钟内有心跳）
  bool get isActive {
    if (lastHeartbeatAt == null) return false;
    return DateTime.now().difference(lastHeartbeatAt!).inMinutes < 5;
  }
}

/// 求助状态
class HelpRequestStatus {
  final String helpRequestId;
  final String status;
  final String? volunteerId;
  final DateTime? matchedAt;
  final DateTime? completedAt;

  HelpRequestStatus({
    required this.helpRequestId,
    required this.status,
    this.volunteerId,
    this.matchedAt,
    this.completedAt,
  });

  /// 是否已匹配
  bool get isMatched => status == 'connected';

  /// 是否已完成
  bool get isCompleted => status == 'completed';

  /// 是否已取消
  bool get isCancelled => status == 'cancelled';
}

/// 通话状态事件
class CallStatusEvent {
  final String roomId;
  final String type; // offer, answer, ice-candidate, join, leave
  final String fromUserId;
  final dynamic data;
  final DateTime timestamp;

  CallStatusEvent({
    required this.roomId,
    required this.type,
    required this.fromUserId,
    this.data,
    required this.timestamp,
  });
}

/// 在线状态管理器
class OnlinePresenceManager {
  static final OnlinePresenceManager _instance = OnlinePresenceManager._internal();
  factory OnlinePresenceManager() => _instance;
  OnlinePresenceManager._internal();

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
      await _supabase.from('user_presence').upsert({
        'user_id': userId,
        'is_online': true,
        'last_seen_at': DateTime.now().toIso8601String(),
      });

      _isOnline = true;
      _startHeartbeat();
    } catch (e) {
      print('上线失败: $e');
    }
  }

  /// 下线
  Future<void> goOffline() async {
    _heartbeatTimer?.cancel();

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('user_presence').upsert({
        'user_id': userId,
        'is_online': false,
        'last_seen_at': DateTime.now().toIso8601String(),
      });

      _isOnline = false;
    } catch (e) {
      print('下线失败: $e');
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
        await _supabase.from('user_presence').upsert({
          'user_id': userId,
          'is_online': true,
          'last_seen_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        print('心跳发送失败: $e');
      }
    });
  }

  /// 释放资源
  void dispose() {
    _heartbeatTimer?.cancel();
    goOffline();
  }
}
