import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/logger.dart';

/// Realtime狀態同步服務
/// 負責志願者在線狀態、求助狀態、通話狀態的實時同步
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

  // 頻道緩存
  final Map<String, RealtimeChannel> _channels = {};

  // 狀態流
  final _volunteerStatusController = StreamController<VolunteerStatus>.broadcast();
  final _helpRequestStatusController = StreamController<HelpRequestStatus>.broadcast();
  final _callStatusController = StreamController<CallStatusEvent>.broadcast();

  Stream<VolunteerStatus> get volunteerStatusStream => _volunteerStatusController.stream;
  Stream<HelpRequestStatus> get helpRequestStatusStream => _helpRequestStatusController.stream;
  Stream<CallStatusEvent> get callStatusStream => _callStatusController.stream;

  /// 訂閱志願者在線狀態
  ///
  /// [volunteerId] 志願者ID
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
            column: 'user_id',
            value: volunteerId,
          ),
          callback: (payload) {
            final record = Map<String, dynamic>.from(payload.newRecord);
            final lastHeartbeatAt = record['last_heartbeat_at']?.toString();
            _volunteerStatusController.add(VolunteerStatus(
              volunteerId: volunteerId,
              isOnline: record['is_online'] == true,
              isAvailable: record['is_available'] != false,
              lastHeartbeatAt: lastHeartbeatAt != null
                  ? DateTime.parse(lastHeartbeatAt)
                  : null,
            ));
          },
        )
        .subscribe();

    _channels[channelName] = channel;
  }

  /// 訂閱求助狀態
  ///
  /// [helpRequestId] 求助記錄ID
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
            final record = Map<String, dynamic>.from(payload.newRecord);
            final matchedAt = record['matched_at']?.toString();
            final completedAt = record['completed_at']?.toString();
            _helpRequestStatusController.add(HelpRequestStatus(
              helpRequestId: helpRequestId,
              status: record['status']?.toString() ?? 'created',
              volunteerId: record['volunteer_id']?.toString(),
              matchedAt: matchedAt != null
                  ? DateTime.parse(matchedAt)
                  : null,
              completedAt: completedAt != null
                  ? DateTime.parse(completedAt)
                  : null,
            ));
          },
        )
        .subscribe();

    _channels[channelName] = channel;
  }

  /// 訂閱通話狀態
  ///
  /// [roomId] 通話房間ID
  void subscribeCallStatus(String roomId) {
    final channelName = 'call:$roomId';

    if (_channels.containsKey(channelName)) return;

    final channel = _supabase
        .channel(channelName)
        .onBroadcast(
          event: 'signaling',
          callback: (payload) {
            final message = Map<String, dynamic>.from(payload);
            _callStatusController.add(CallStatusEvent(
              roomId: roomId,
              type: message['type']?.toString() ?? 'unknown',
              fromUserId: message['from_user_id']?.toString() ?? '',
              data: message['data'],
              timestamp: DateTime.now(),
            ));
          },
        )
        .subscribe();

    _channels[channelName] = channel;
  }

  /// 訂閱SOS狀態
  ///
  /// [sosId] SOS記錄ID
  void subscribeSOSStatus(String sosId) {
    final channelName = 'sos:$sosId';

    if (_channels.containsKey(channelName)) return;

    final channel = _supabase
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'help_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: sosId,
          ),
          callback: (payload) {
            final record = Map<String, dynamic>.from(payload.newRecord);
            if (record['type']?.toString() != 'sos') {
              return;
            }

            final matchedAt = record['matched_at']?.toString();
            final completedAt = record['completed_at']?.toString();
            _helpRequestStatusController.add(HelpRequestStatus(
              helpRequestId: sosId,
              status: record['status']?.toString() ?? 'matching',
              volunteerId: record['volunteer_id']?.toString(),
              matchedAt: matchedAt != null
                  ? DateTime.parse(matchedAt)
                  : null,
              completedAt: completedAt != null
                  ? DateTime.parse(completedAt)
                  : null,
            ));
          },
        )
        .subscribe();

    _channels[channelName] = channel;
  }

  /// 訂閱志願者匹配請求
  ///
  /// [userId] 用戶ID（志願者）
  void subscribeMatchingRequests(String userId) {
    final channelName = 'volunteer_matches:$userId';

    if (_channels.containsKey(channelName)) return;

    final channel = _supabase
        .channel(channelName)
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
            final requestType = record['type']?.toString();
            if (requestType == 'realtime_voice' ||
                requestType == 'realtime_video' ||
                requestType == 'sos') {
              _onMatchingRequestReceived(record);
            }
          },
        )
        .subscribe();

    _channels[channelName] = channel;
  }

  /// 取消訂閱
  ///
  /// [channelName] 頻道名稱，如果爲null則取消所有訂閱
  void unsubscribe([String? channelName]) {
    if (channelName != null) {
      _channels[channelName]?.unsubscribe();
      _channels.remove(channelName);
    } else {
      // 取消所有訂閱
      for (final channel in _channels.values) {
        channel.unsubscribe();
      }
      _channels.clear();
    }
  }

  /// 發送通話信令
  ///
  /// [roomId] 房間ID
  /// [type] 信令類型
  /// [data] 信令數據
  Future<void> sendSignalingMessage({
    required String roomId,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    await _supabase.channel('call:$roomId').sendBroadcastMessage(
      event: 'signaling',
      payload: {
        'type': type,
        'from_user_id': _supabase.auth.currentUser?.id,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 處理匹配請求接收
  void _onMatchingRequestReceived(Map<String, dynamic> record) {
    // 這裏可以觸發本地通知或回調
    // 實際實現中可以通過另一個stream暴露給UI層
  }

  /// 釋放資源
  void dispose() {
    unsubscribe();
    _volunteerStatusController.close();
    _helpRequestStatusController.close();
    _callStatusController.close();
  }
}

/// 志願者狀態
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

  /// 是否活躍（5分鐘內有心跳）
  bool get isActive {
    if (lastHeartbeatAt == null) return false;
    return DateTime.now().difference(lastHeartbeatAt!).inMinutes < 5;
  }
}

/// 求助狀態
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

/// 通話狀態事件
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

/// 在線狀態管理器
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

  /// 上線
  Future<void> goOnline() async {
    if (_isOnline) return;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase
          .from('volunteer_profiles')
          .update({
            'is_online': true,
            'is_available': true,
            'last_heartbeat_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);

      _isOnline = true;
      _startHeartbeat();
    } catch (e) {
      AppLogger.error('在線狀態上線失敗', e);
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
    } catch (e) {
      AppLogger.error('在線狀態下線失敗', e);
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
      } catch (e) {
        AppLogger.error('在線狀態心跳發送失敗', e);
      }
    });
  }

  /// 釋放資源
  void dispose() {
    _heartbeatTimer?.cancel();
    goOffline();
  }
}
