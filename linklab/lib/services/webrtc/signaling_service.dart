import 'dart:async';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/logger.dart';
import '../../models/call_models.dart';
import 'webrtc_config.dart';

/// 信令服務
/// 使用Supabase Realtime進行WebRTC信令交換
class SignalingService {
  static final SignalingService _instance = SignalingService._internal();
  factory SignalingService() => _instance;
  SignalingService._internal();

  // ==================== Supabase客戶端 ====================

  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== 頻道和訂閱 ====================

  /// 當前信令頻道
  RealtimeChannel? _signalingChannel;

  /// 房間Presence頻道
  RealtimeChannel? _presenceChannel;

  /// 廣播訂閱
  StreamSubscription? _broadcastSubscription;

  /// Presence訂閱
  StreamSubscription? _presenceSubscription;

  // ==================== 狀態流控制器 ====================

  /// 信令消息流
  final _signalingMessageController = StreamController<SignalingMessage>.broadcast();

  /// 房間狀態流
  final _roomStateController = StreamController<RoomState>.broadcast();

  /// 參與者變化流
  final _participantsController = StreamController<List<RoomParticipant>>.broadcast();

  /// 連接狀態流
  final _connectionStateController = StreamController<SignalingConnectionState>.broadcast();

  // ==================== 狀態 ====================

  /// 當前房間ID
  String? _currentRoomId;

  /// 當前用戶ID
  String? get _currentUserId => _supabase.auth.currentUser?.id;

  /// 房間參與者列表
  final List<RoomParticipant> _participants = [];

  /// 是否已加入房間
  bool get isInRoom => _currentRoomId != null;

  /// 當前房間ID
  String? get currentRoomId => _currentRoomId;

  // ==================== Getters ====================

  /// 信令消息流
  Stream<SignalingMessage> get signalingMessageStream => _signalingMessageController.stream;

  /// 房間狀態流
  Stream<RoomState> get roomStateStream => _roomStateController.stream;

  /// 參與者變化流
  Stream<List<RoomParticipant>> get participantsStream => _participantsController.stream;

  /// 連接狀態流
  Stream<SignalingConnectionState> get connectionStateStream => _connectionStateController.stream;

  /// 房間參與者列表
  List<RoomParticipant> get participants => List.unmodifiable(_participants);

  // ==================== 房間管理 ====================

  /// 加入房間
  Future<void> joinRoom(String roomId, {CallRole? role}) async {
    if (_currentUserId == null) {
      throw Exception('用戶未登錄');
    }

    // 如果已經在房間中，先離開
    if (_currentRoomId != null && _currentRoomId != roomId) {
      await leaveRoom();
    }

    _currentRoomId = roomId;
    _participants.clear();

    try {
      _updateConnectionState(SignalingConnectionState.connecting);

      // 創建信令頻道
      _signalingChannel = _supabase.channel(
        'call:$roomId',
        opts: RealtimeChannelConfig(
          ack: true,
        ),
      );

      // 監聽信令廣播
      _signalingChannel!.onBroadcast(
        event: 'signaling',
        callback: (payload) => _handleSignalingMessage(payload),
      );

      // 監聽系統消息（如用戶加入/離開）
      _signalingChannel!.onBroadcast(
        event: 'system',
        callback: (payload) => _handleSystemMessage(payload),
      );

      // 訂閱頻道
      await _signalingChannel!.subscribe((status, error) {
        if (error != null) {
          AppLogger.error('[Signaling] 訂閱錯誤', error);
          _updateConnectionState(SignalingConnectionState.error);
        } else {
          AppLogger.info('[Signaling] 訂閱狀態: $status');
          if (status == 'SUBSCRIBED') {
            _updateConnectionState(SignalingConnectionState.connected);
            _updateRoomState(RoomState.joined);
          }
        }
      });

      // 等待訂閱完成
      await Future.delayed(const Duration(milliseconds: 500));

      // 發送加入消息
      await _sendSystemMessage('user_joined', {
        'user_id': _currentUserId,
        'role': role?.name,
        'joined_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('[Signaling] 已加入房間: $roomId');
    } catch (error, stackTrace) {
      AppLogger.error('[Signaling] 加入房間失敗', error, stackTrace);
      _updateConnectionState(SignalingConnectionState.error);
      throw Exception('加入房間失敗: $error');
    }
  }

  /// 離開房間
  Future<void> leaveRoom() async {
    if (_currentRoomId == null) return;

    try {
      // 發送離開消息
      await _sendSystemMessage('user_left', {
        'user_id': _currentUserId,
        'left_at': DateTime.now().toIso8601String(),
      });

      // 取消訂閱
      await _signalingChannel?.unsubscribe();
      await _presenceChannel?.unsubscribe();

      // 清理資源
      _broadcastSubscription?.cancel();
      _presenceSubscription?.cancel();
      _signalingChannel = null;
      _presenceChannel = null;

      _participants.clear();
      _currentRoomId = null;

      _updateRoomState(RoomState.left);
      _updateConnectionState(SignalingConnectionState.disconnected);

      AppLogger.info('[Signaling] 已離開房間');
    } catch (error, stackTrace) {
      AppLogger.error('[Signaling] 離開房間失敗', error, stackTrace);
    }
  }

  /// 創建房間（在數據庫中記錄）
  Future<String> createRoom({
    required String seekerId,
    String? helpRequestId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final roomId = _generateRoomId();

      await _supabase.from('call_rooms').insert({
        'id': roomId,
        'seeker_id': seekerId,
        'help_request_id': helpRequestId,
        'status': 'waiting',
        'metadata': metadata,
        'created_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('[Signaling] 房間已創建: $roomId');
      return roomId;
    } catch (error, stackTrace) {
      AppLogger.error('[Signaling] 創建房間失敗', error, stackTrace);
      throw Exception('創建房間失敗: $error');
    }
  }

  /// 更新房間狀態
  Future<void> updateRoomStatus(String roomId, String status) async {
    try {
      await _supabase.from('call_rooms').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', roomId);
    } catch (error, stackTrace) {
      AppLogger.error('[Signaling] 更新房間狀態失敗', error, stackTrace);
    }
  }

  // ==================== 信令發送方法 ====================

  /// 發送Offer
  Future<void> sendOffer(String roomId, String sdp, String type) async {
    await _sendSignalingMessage(
      SignalingType.offer,
      {
        'sdp': sdp,
        'type': type,
      },
      roomId: roomId,
    );
  }

  /// 發送Answer
  Future<void> sendAnswer(String roomId, String sdp, String type) async {
    await _sendSignalingMessage(
      SignalingType.answer,
      {
        'sdp': sdp,
        'type': type,
      },
      roomId: roomId,
    );
  }

  /// 發送ICE候選
  Future<void> sendIceCandidate(
    String roomId,
    String candidate, {
    String? sdpMid,
    int? sdpMLineIndex,
  }) async {
    await _sendSignalingMessage(
      SignalingType.iceCandidate,
      {
        'candidate': candidate,
        'sdp_mid': sdpMid,
        'sdp_mline_index': sdpMLineIndex,
      },
      roomId: roomId,
    );
  }

  /// 發送ICE候選（使用Map格式）
  Future<void> sendIceCandidateFromMap(String roomId, Map<String, dynamic> candidateData) async {
    await _sendSignalingMessage(
      SignalingType.iceCandidate,
      candidateData,
      roomId: roomId,
    );
  }

  /// 發送就緒信號
  Future<void> sendReady(String roomId) async {
    await _sendSignalingMessage(
      SignalingType.ready,
      {},
      roomId: roomId,
    );
  }

  /// 發送掛斷信號
  Future<void> sendBye(String roomId, {CallEndReason? reason}) async {
    await _sendSignalingMessage(
      SignalingType.bye,
      {
        'reason': reason?.name ?? 'user_hangup',
      },
      roomId: roomId,
    );
  }

  /// 發送自定義消息
  Future<void> sendCustomMessage(String roomId, String type, Map<String, dynamic> data) async {
    await _sendSignalingMessage(
      SignalingType.values.firstWhere(
        (t) => t.name == type,
        orElse: () => SignalingType.bye,
      ),
      data,
      roomId: roomId,
    );
  }

  // ==================== 內部信令方法 ====================

  /// 發送信令消息
  Future<void> _sendSignalingMessage(
    SignalingType type,
    Map<String, dynamic> data, {
    String? roomId,
  }) async {
    final targetRoomId = roomId ?? _currentRoomId;
    if (targetRoomId == null) return;
    if (_signalingChannel == null) return;
    if (_currentUserId == null) return;

    final message = SignalingMessage(
      type: type,
      roomId: targetRoomId,
      fromUserId: _currentUserId!,
      data: data,
    );

    try {
      await _signalingChannel!.sendBroadcastMessage(
        event: 'signaling',
        payload: message.toJson(),
      );
      AppLogger.verbose('[Signaling] 發送消息: ${type.name}');
    } catch (error, stackTrace) {
      AppLogger.error('[Signaling] 發送消息失敗', error, stackTrace);
    }
  }

  /// 發送系統消息
  Future<void> _sendSystemMessage(String event, Map<String, dynamic> payload) async {
    if (_signalingChannel == null) return;

    try {
      await _signalingChannel!.sendBroadcastMessage(
        event: 'system',
        payload: {
          'event': event,
          'data': payload,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (error, stackTrace) {
      AppLogger.error('[Signaling] 發送系統消息失敗', error, stackTrace);
    }
  }

  // ==================== 消息處理方法 ====================

  /// 處理信令消息
  void _handleSignalingMessage(Map<String, dynamic> payload) {
    try {
      final message = SignalingMessage.fromJson(payload);

      // 忽略自己的消息
      if (message.fromUserId == _currentUserId) return;

      AppLogger.verbose(
        '[Signaling] 收到消息: ${message.type.name} from ${message.fromUserId}',
      );

      // 轉發給監聽者
      _signalingMessageController.add(message);

      // 根據消息類型處理
      switch (message.type) {
        case SignalingType.join:
          _handleUserJoin(message);
          break;
        case SignalingType.leave:
          _handleUserLeave(message);
          break;
        case SignalingType.bye:
          _handleBye(message);
          break;
        default:
          break;
      }
    } catch (error, stackTrace) {
      AppLogger.error('[Signaling] 處理消息失敗', error, stackTrace);
    }
  }

  /// 處理系統消息
  void _handleSystemMessage(Map<String, dynamic> payload) {
    final event = payload['event'] as String?;
    final data = payload['data'] as Map<String, dynamic>?;

    if (event == null || data == null) return;

    switch (event) {
      case 'user_joined':
        _handleParticipantJoined(data);
        break;
      case 'user_left':
        _handleParticipantLeft(data);
        break;
    }
  }

  /// 處理用戶加入
  void _handleUserJoin(SignalingMessage message) {
    _updateRoomState(RoomState.peerJoined);
  }

  /// 處理用戶離開
  void _handleUserLeave(SignalingMessage message) {
    _updateRoomState(RoomState.peerLeft);
  }

  /// 處理掛斷
  void _handleBye(SignalingMessage message) {
    final reason = message.data['reason'] as String?;
    AppLogger.info('[Signaling] 對方掛斷: $reason');
    _updateRoomState(RoomState.callEnded);
  }

  /// 處理參與者加入
  void _handleParticipantJoined(Map<String, dynamic> data) {
    final userId = data['user_id'] as String?;
    if (userId == null || userId == _currentUserId) return;

    final joinedAtValue = data['joined_at'];
    final participant = RoomParticipant(
      userId: userId,
      role: data['role'] as String?,
      joinedAt: DateTime.tryParse(
            joinedAtValue is String ? joinedAtValue : joinedAtValue?.toString() ?? '',
          ) ??
          DateTime.now(),
    );

    _participants.add(participant);
    _participantsController.add(List.unmodifiable(_participants));
    _updateRoomState(RoomState.peerJoined);

    AppLogger.info('[Signaling] 參與者加入: $userId');
  }

  /// 處理參與者離開
  void _handleParticipantLeft(Map<String, dynamic> data) {
    final userId = data['user_id'] as String?;
    if (userId == null) return;

    _participants.removeWhere((p) => p.userId == userId);
    _participantsController.add(List.unmodifiable(_participants));
    _updateRoomState(RoomState.peerLeft);

    AppLogger.info('[Signaling] 參與者離開: $userId');
  }

  // ==================== 狀態更新方法 ====================

  /// 更新房間狀態
  void _updateRoomState(RoomState state) {
    _roomStateController.add(state);
  }

  /// 更新連接狀態
  void _updateConnectionState(SignalingConnectionState state) {
    _connectionStateController.add(state);
  }

  // ==================== 輔助方法 ====================

  /// 生成房間ID
  String _generateRoomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    return 'room_${timestamp}_${_currentUserId?.substring(0, 8)}';
  }

  /// 釋放資源
  void dispose() {
    leaveRoom();
    _signalingMessageController.close();
    _roomStateController.close();
    _participantsController.close();
    _connectionStateController.close();
  }
}

/// 房間狀態
enum RoomState {
  idle,         // 空閒
  joining,      // 加入中
  joined,       // 已加入
  peerJoined,   // 對方已加入
  peerLeft,     // 對方已離開
  callEnded,    // 通話結束
  left,         // 已離開
  error,        // 錯誤
}

/// 信令連接狀態
enum SignalingConnectionState {
  disconnected, // 未連接
  connecting,   // 連接中
  connected,    // 已連接
  error,        // 錯誤
}

/// 房間參與者
class RoomParticipant {
  final String userId;
  final String? role;
  final DateTime joinedAt;

  RoomParticipant({
    required this.userId,
    this.role,
    required this.joinedAt,
  });
}
