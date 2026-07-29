import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/logger.dart';
import '../../../models/call_models.dart';

/// WebRTC 服务类
/// 负责管理PeerConnection、媒体流和信令交换
class WebRTCService {
  static final WebRTCService _instance = WebRTCService._internal();
  factory WebRTCService() => _instance;
  WebRTCService._internal();

  // PeerConnection
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  // 信令
  RealtimeChannel? _signalingChannel;

  SupabaseClient? _supabaseClient;
  SupabaseClient get _supabase {
    if (!Supabase.instance.isInitialized) {
      throw StateError('Supabase not initialized');
    }
    _supabaseClient ??= Supabase.instance.client;
    return _supabaseClient!;
  }

  // 状态
  CallInfo? _currentCall;
  final _callStateController = StreamController<CallState>.broadcast();
  final _remoteStreamController = StreamController<MediaStream?>.broadcast();

  // 获取器
  Stream<CallState> get callStateStream => _callStateController.stream;
  Stream<MediaStream?> get remoteStreamStream => _remoteStreamController.stream;
  CallInfo? get currentCall => _currentCall;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  bool get isInCall => _currentCall != null && _currentCall!.state == CallState.connected;

  // ICE 服务器配置
  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ],
  };

  // 约束
  final Map<String, dynamic> _constraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': false,
    },
    'optional': [],
  };

  /// 初始化通话（作为求助者）
  Future<CallInfo> initializeCallAsSeeker({
    required String seekerId,
    required String helpRequestId,
  }) async {
    final roomId = _generateRoomId();
    _currentCall = CallInfo(
      callId: helpRequestId,
      roomId: roomId,
      seekerId: seekerId,
      myRole: CallRole.seeker,
      state: CallState.connecting,
    );

    await _initializeMedia();
    await _createPeerConnection();
    await _joinSignalingRoom(roomId);

    return _currentCall!;
  }

  /// 初始化通话（作为志愿者）
  Future<CallInfo> initializeCallAsVolunteer({
    required String volunteerId,
    required String seekerId,
    required String helpRequestId,
    required String roomId,
  }) async {
    _currentCall = CallInfo(
      callId: helpRequestId,
      roomId: roomId,
      seekerId: seekerId,
      volunteerId: volunteerId,
      myRole: CallRole.volunteer,
      state: CallState.connecting,
    );

    await _initializeMedia();
    await _createPeerConnection();
    await _joinSignalingRoom(roomId);

    return _currentCall!;
  }

  /// 初始化本地媒体流
  Future<void> _initializeMedia() async {
    try {
      final Map<String, dynamic> mediaConstraints = {
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false, // 仅语音通话
      };

      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    } catch (error, stackTrace) {
      AppLogger.error('历史 WebRTC 服务获取麦克风失败', error, stackTrace);
      throw Exception('无法获取麦克风权限: $error');
    }
  }

  /// 创建PeerConnection
  Future<void> _createPeerConnection() async {
    _peerConnection = await createPeerConnection(_iceServers, _constraints);

    // 添加本地流
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }
    }

    // 监听远程流
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        _remoteStreamController.add(_remoteStream);
      }
    };

    // 监听连接状态
    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _updateCallState(CallState.connected);
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          _updateCallState(CallState.reconnecting);
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          _updateCallState(CallState.failed);
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
          _updateCallState(CallState.ended);
          break;
        default:
          break;
      }
    };

    // 监听ICE候选
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      _sendSignalingMessage(SignalingType.iceCandidate, {
        'candidate': candidate.toMap(),
      });
    };
  }

  /// 加入信令房间
  Future<void> _joinSignalingRoom(String roomId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('用户未登录');

    _signalingChannel = _supabase.channel('call:$roomId');

    _signalingChannel!
        .onBroadcast(
          event: 'signaling',
          callback: (payload) => _handleSignalingMessage(SignalingMessage.fromJson(payload)),
        )
        .subscribe();

    // 发送加入消息
    await Future.delayed(const Duration(milliseconds: 500));
    await _sendSignalingMessage(SignalingType.join, {});
  }

  /// 处理信令消息
  Future<void> _handleSignalingMessage(SignalingMessage message) async {
    // 忽略自己的消息
    if (message.fromUserId == _supabase.auth.currentUser?.id) return;

    switch (message.type) {
      case SignalingType.join:
        // 对方加入，发送offer（如果是求助者）
        if (_currentCall?.myRole == CallRole.seeker) {
          await _createAndSendOffer();
        }
        break;

      case SignalingType.offer:
        await _handleOffer(message.data);
        break;

      case SignalingType.answer:
        await _handleAnswer(message.data);
        break;

      case SignalingType.iceCandidate:
        await _handleIceCandidate(message.data);
        break;

      case SignalingType.bye:
        await endCall(CallEndReason.remoteHangup);
        break;

      default:
        break;
    }
  }

  /// 创建并发送Offer
  Future<void> _createAndSendOffer() async {
    if (_peerConnection == null) return;

    final offer = await _peerConnection!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': false,
    });

    await _peerConnection!.setLocalDescription(offer);

    await _sendSignalingMessage(SignalingType.offer, {
      'sdp': offer.sdp,
      'type': offer.type,
    });

    _updateCallState(CallState.ringing);
  }

  /// 处理Offer
  Future<void> _handleOffer(dynamic data) async {
    if (_peerConnection == null) return;

    final sdp = data['sdp']?.toString();
    final type = data['type']?.toString();
    if (sdp == null || type == null) return;

    final offer = RTCSessionDescription(sdp, type);
    await _peerConnection!.setRemoteDescription(offer);

    // 创建answer
    final answer = await _peerConnection!.createAnswer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': false,
    });

    await _peerConnection!.setLocalDescription(answer);

    await _sendSignalingMessage(SignalingType.answer, {
      'sdp': answer.sdp,
      'type': answer.type,
    });

    _updateCallState(CallState.ringing);
  }

  /// 处理Answer
  Future<void> _handleAnswer(dynamic data) async {
    if (_peerConnection == null) return;

    final sdp = data['sdp']?.toString();
    final type = data['type']?.toString();
    if (sdp == null || type == null) return;

    final answer = RTCSessionDescription(sdp, type);
    await _peerConnection!.setRemoteDescription(answer);
  }

  /// 处理ICE候选
  Future<void> _handleIceCandidate(dynamic data) async {
    if (_peerConnection == null) return;

    final candidateData = data['candidate'];
    if (candidateData is! Map) return;

    final candidateMap = candidateData.cast<String, dynamic>();
    final candidateValue = candidateMap['candidate']?.toString();
    if (candidateValue == null) return;

    final candidate = RTCIceCandidate(
      candidateValue,
      candidateMap['sdpMid']?.toString(),
      _asNullableInt(candidateMap['sdpMLineIndex']),
    );

    await _peerConnection!.addCandidate(candidate);
  }

  /// 发送信令消息
  Future<void> _sendSignalingMessage(SignalingType type, dynamic data) async {
    if (_signalingChannel == null || _currentCall == null) return;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final message = SignalingMessage(
      type: type,
      roomId: _currentCall!.roomId,
      fromUserId: userId,
      data: data,
    );

    await _signalingChannel!.sendBroadcastMessage(
      event: 'signaling',
      payload: message.toJson(),
    );
  }

  /// 静音/取消静音
  Future<void> toggleMute() async {
    if (_localStream == null) return;

    final audioTrack = _localStream!.getAudioTracks().firstOrNull;
    if (audioTrack != null) {
      audioTrack.enabled = !audioTrack.enabled;
      _currentCall?.isMuted = !audioTrack.enabled;
    }
  }

  /// 切换扬声器
  Future<void> toggleSpeaker() async {
    _currentCall?.isSpeakerOn = !(_currentCall?.isSpeakerOn ?? true);
    // 实际切换扬声器需要平台特定实现
  }

  /// 结束通话
  Future<void> endCall(CallEndReason reason) async {
    // 发送bye消息
    await _sendSignalingMessage(SignalingType.bye, {
      'reason': reason.name,
    });

    await _cleanup();
    _updateCallState(CallState.ended);
  }

  /// 清理资源
  Future<void> _cleanup() async {
    // 停止本地流
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _localStream = null;

    // 关闭PeerConnection
    await _peerConnection?.close();
    _peerConnection = null;

    // 取消订阅信令频道
    await _signalingChannel?.unsubscribe();
    _signalingChannel = null;

    _remoteStream = null;
    _remoteStreamController.add(null);
  }

  /// 更新通话状态
  void _updateCallState(CallState state) {
    _currentCall?.state = state;
    _callStateController.add(state);
  }

  /// 生成房间ID
  String _generateRoomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(12, (_) => chars[random.nextInt(chars.length)]).join();
  }

  int? _asNullableInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  /// 释放资源
  void dispose() {
    _cleanup();
    _callStateController.close();
    _remoteStreamController.close();
  }
}
