import 'dart:async';
import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/call_models.dart';
import 'webrtc_config.dart';

/// 信令服务
/// 使用Supabase Realtime进行WebRTC信令交换
class SignalingService {
  static final SignalingService _instance = SignalingService._internal();
  factory SignalingService() => _instance;
  SignalingService._internal();

  // ==================== Supabase客户端 ====================

  final SupabaseClient _supabase = Supabase.instance.client;

  // ==================== 频道和订阅 ====================

  /// 当前信令频道
  RealtimeChannel? _signalingChannel;

  /// 房间Presence频道
  RealtimeChannel? _presenceChannel;

  /// 广播订阅
  StreamSubscription? _broadcastSubscription;

  /// Presence订阅
  StreamSubscription? _presenceSubscription;

  // ==================== 状态流控制器 ====================

  /// 信令消息流
  final _signalingMessageController = StreamController<SignalingMessage>.broadcast();

  /// 房间状态流
  final _roomStateController = StreamController<RoomState>.broadcast();

  /// 参与者变化流
  final _participantsController = StreamController<List<RoomParticipant>>.broadcast();

  /// 连接状态流
  final _connectionStateController = StreamController<SignalingConnectionState>.broadcast();

  // ==================== 状态 ====================

  /// 当前房间ID
  String? _currentRoomId;

  /// 当前用户ID
  String? get _currentUserId => _supabase.auth.currentUser?.id;

  /// 房间参与者列表
  final List<RoomParticipant> _participants = [];

  /// 是否已加入房间
  bool get isInRoom => _currentRoomId != null;

  /// 当前房间ID
  String? get currentRoomId => _currentRoomId;

  // ==================== Getters ====================

  /// 信令消息流
  Stream<SignalingMessage> get signalingMessageStream => _signalingMessageController.stream;

  /// 房间状态流
  Stream<RoomState> get roomStateStream => _roomStateController.stream;

  /// 参与者变化流
  Stream<List<RoomParticipant>> get participantsStream => _participantsController.stream;

  /// 连接状态流
  Stream<SignalingConnectionState> get connectionStateStream => _connectionStateController.stream;

  /// 房间参与者列表
  List<RoomParticipant> get participants => List.unmodifiable(_participants);

  // ==================== 房间管理 ====================

  /// 加入房间
  Future<void> joinRoom(String roomId, {CallRole? role}) async {
    if (_currentUserId == null) {
      throw Exception('用户未登录');
    }

    // 如果已经在房间中，先离开
    if (_currentRoomId != null && _currentRoomId != roomId) {
      await leaveRoom();
    }

    _currentRoomId = roomId;
    _participants.clear();

    try {
      _updateConnectionState(SignalingConnectionState.connecting);

      // 创建信令频道
      _signalingChannel = _supabase.channel(
        'call:$roomId',
        opts: RealtimeChannelConfig(
          ack: true,
        ),
      );

      // 监听信令广播
      _signalingChannel!.onBroadcast(
        event: 'signaling',
        callback: (payload) => _handleSignalingMessage(payload),
      );

      // 监听系统消息（如用户加入/离开）
      _signalingChannel!.onBroadcast(
        event: 'system',
        callback: (payload) => _handleSystemMessage(payload),
      );

      // 订阅频道
      await _signalingChannel!.subscribe((status, error) {
        if (error != null) {
          print('[Signaling] 订阅错误: $error');
          _updateConnectionState(SignalingConnectionState.error);
        } else {
          print('[Signaling] 订阅状态: $status');
          if (status == 'SUBSCRIBED') {
            _updateConnectionState(SignalingConnectionState.connected);
            _updateRoomState(RoomState.joined);
          }
        }
      });

      // 等待订阅完成
      await Future.delayed(const Duration(milliseconds: 500));

      // 发送加入消息
      await _sendSystemMessage('user_joined', {
        'user_id': _currentUserId,
        'role': role?.name,
        'joined_at': DateTime.now().toIso8601String(),
      });

      print('[Signaling] 已加入房间: $roomId');
    } catch (e) {
      _updateConnectionState(SignalingConnectionState.error);
      throw Exception('加入房间失败: $e');
    }
  }

  /// 离开房间
  Future<void> leaveRoom() async {
    if (_currentRoomId == null) return;

    try {
      // 发送离开消息
      await _sendSystemMessage('user_left', {
        'user_id': _currentUserId,
        'left_at': DateTime.now().toIso8601String(),
      });

      // 取消订阅
      await _signalingChannel?.unsubscribe();
      await _presenceChannel?.unsubscribe();

      // 清理资源
      _broadcastSubscription?.cancel();
      _presenceSubscription?.cancel();
      _signalingChannel = null;
      _presenceChannel = null;

      _participants.clear();
      _currentRoomId = null;

      _updateRoomState(RoomState.left);
      _updateConnectionState(SignalingConnectionState.disconnected);

      print('[Signaling] 已离开房间');
    } catch (e) {
      print('[Signaling] 离开房间错误: $e');
    }
  }

  /// 创建房间（在数据库中记录）
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

      print('[Signaling] 房间已创建: $roomId');
      return roomId;
    } catch (e) {
      throw Exception('创建房间失败: $e');
    }
  }

  /// 更新房间状态
  Future<void> updateRoomStatus(String roomId, String status) async {
    try {
      await _supabase.from('call_rooms').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', roomId);
    } catch (e) {
      print('[Signaling] 更新房间状态失败: $e');
    }
  }

  // ==================== 信令发送方法 ====================

  /// 发送Offer
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

  /// 发送Answer
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

  /// 发送ICE候选
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

  /// 发送ICE候选（使用Map格式）
  Future<void> sendIceCandidateFromMap(String roomId, Map<String, dynamic> candidateData) async {
    await _sendSignalingMessage(
      SignalingType.iceCandidate,
      candidateData,
      roomId: roomId,
    );
  }

  /// 发送就绪信号
  Future<void> sendReady(String roomId) async {
    await _sendSignalingMessage(
      SignalingType.ready,
      {},
      roomId: roomId,
    );
  }

  /// 发送挂断信号
  Future<void> sendBye(String roomId, {CallEndReason? reason}) async {
    await _sendSignalingMessage(
      SignalingType.bye,
      {
        'reason': reason?.name ?? 'user_hangup',
      },
      roomId: roomId,
    );
  }

  /// 发送自定义消息
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

  // ==================== 内部信令方法 ====================

  /// 发送信令消息
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
      print('[Signaling] 发送消息: ${type.name}');
    } catch (e) {
      print('[Signaling] 发送消息失败: $e');
    }
  }

  /// 发送系统消息
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
    } catch (e) {
      print('[Signaling] 发送系统消息失败: $e');
    }
  }

  // ==================== 消息处理方法 ====================

  /// 处理信令消息
  void _handleSignalingMessage(Map<String, dynamic> payload) {
    try {
      final message = SignalingMessage.fromJson(payload);

      // 忽略自己的消息
      if (message.fromUserId == _currentUserId) return;

      print('[Signaling] 收到消息: ${message.type.name} from ${message.fromUserId}');

      // 转发给监听者
      _signalingMessageController.add(message);

      // 根据消息类型处理
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
    } catch (e) {
      print('[Signaling] 处理消息错误: $e');
    }
  }

  /// 处理系统消息
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

  /// 处理用户加入
  void _handleUserJoin(SignalingMessage message) {
    _updateRoomState(RoomState.peerJoined);
  }

  /// 处理用户离开
  void _handleUserLeave(SignalingMessage message) {
    _updateRoomState(RoomState.peerLeft);
  }

  /// 处理挂断
  void _handleBye(SignalingMessage message) {
    final reason = message.data['reason'] as String?;
    print('[Signaling] 对方挂断: $reason');
    _updateRoomState(RoomState.callEnded);
  }

  /// 处理参与者加入
  void _handleParticipantJoined(Map<String, dynamic> data) {
    final userId = data['user_id'] as String?;
    if (userId == null || userId == _currentUserId) return;

    final participant = RoomParticipant(
      userId: userId,
      role: data['role'] as String?,
      joinedAt: DateTime.tryParse(data['joined_at'] ?? '') ?? DateTime.now(),
    );

    _participants.add(participant);
    _participantsController.add(List.unmodifiable(_participants));
    _updateRoomState(RoomState.peerJoined);

    print('[Signaling] 参与者加入: $userId');
  }

  /// 处理参与者离开
  void _handleParticipantLeft(Map<String, dynamic> data) {
    final userId = data['user_id'] as String?;
    if (userId == null) return;

    _participants.removeWhere((p) => p.userId == userId);
    _participantsController.add(List.unmodifiable(_participants));
    _updateRoomState(RoomState.peerLeft);

    print('[Signaling] 参与者离开: $userId');
  }

  // ==================== 状态更新方法 ====================

  /// 更新房间状态
  void _updateRoomState(RoomState state) {
    _roomStateController.add(state);
  }

  /// 更新连接状态
  void _updateConnectionState(SignalingConnectionState state) {
    _connectionStateController.add(state);
  }

  // ==================== 辅助方法 ====================

  /// 生成房间ID
  String _generateRoomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    return 'room_${timestamp}_${_currentUserId?.substring(0, 8)}';
  }

  /// 释放资源
  void dispose() {
    leaveRoom();
    _signalingMessageController.close();
    _roomStateController.close();
    _participantsController.close();
    _connectionStateController.close();
  }
}

/// 房间状态
enum RoomState {
  idle,         // 空闲
  joining,      // 加入中
  joined,       // 已加入
  peerJoined,   // 对方已加入
  peerLeft,     // 对方已离开
  callEnded,    // 通话结束
  left,         // 已离开
  error,        // 错误
}

/// 信令连接状态
enum SignalingConnectionState {
  disconnected, // 未连接
  connecting,   // 连接中
  connected,    // 已连接
  error,        // 错误
}

/// 房间参与者
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
