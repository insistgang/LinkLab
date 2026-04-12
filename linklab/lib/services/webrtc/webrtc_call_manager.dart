// WebRTC 通话管理器
// 整合 RealWebRTCService、SignalingService 和 CallRecordingService
// 提供完整的P2P语音通话功能

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../models/call_models.dart';
import 'call_recording_service.dart';
import 'real_webrtc_service.dart';
import 'signaling_service.dart';
import 'webrtc_config.dart';

/// 通话事件类型
enum CallManagerEventType {
  // 通话生命周期
  callInitialized,
  callConnecting,
  callConnected,
  callDisconnected,
  callEnded,
  callFailed,

  // 信令事件
  signalingConnected,
  signalingDisconnected,
  signalingError,

  // 媒体事件
  localStreamReady,
  remoteStreamReady,
  remoteStreamRemoved,

  // 录音事件
  recordingStarted,
  recordingStopped,
  recordingError,

  // 错误事件
  error,
  permissionDenied,
}

/// 通话管理器事件
class CallManagerEvent {
  final CallManagerEventType type;
  final dynamic data;
  final String? error;
  final DateTime timestamp;

  CallManagerEvent({
    required this.type,
    this.data,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// WebRTC 通话管理器
/// 负责协调WebRTC服务、信令服务和录音服务
class WebRTCCallManager {
  static final WebRTCCallManager _instance = WebRTCCallManager._internal();
  factory WebRTCCallManager() => _instance;
  WebRTCCallManager._internal();

  // ==================== 核心服务 ====================

  /// WebRTC服务
  final RealWebRTCService _webrtcService = RealWebRTCService();

  /// 信令服务
  final SignalingService _signalingService = SignalingService();

  /// 录音服务
  final CallRecordingService _recordingService = CallRecordingService();

  // ==================== 状态流控制器 ====================

  /// 通话管理器事件流
  final _eventController = StreamController<CallManagerEvent>.broadcast();

  /// 合并的通话状态流
  final _callStateController = StreamController<CallState>.broadcast();

  // ==================== 订阅管理 ====================

  /// WebRTC事件订阅
  StreamSubscription<WebRTCEvent>? _webrtcEventSubscription;

  /// WebRTC状态订阅
  StreamSubscription<CallState>? _webrtcStateSubscription;

  /// 信令消息订阅
  StreamSubscription<SignalingMessage>? _signalingMessageSubscription;

  /// 信令房间状态订阅
  StreamSubscription<RoomState>? _roomStateSubscription;

  /// 录音状态订阅
  StreamSubscription<RecordingState>? _recordingStateSubscription;

  // ==================== 状态 ====================

  /// 当前通话信息
  CallInfo? _currentCall;

  /// 是否正在通话中
  bool get isInCall => _currentCall != null;

  /// 当前通话信息
  CallInfo? get currentCall => _currentCall;

  /// 是否已连接
  bool get isConnected => _webrtcService.isConnected;

  /// 通话时长
  Duration get callDuration => _webrtcService.callDuration;

  /// 本地媒体流
  MediaStream? get localStream => _webrtcService.localStream;

  /// 远程媒体流
  MediaStream? get remoteStream => _webrtcService.remoteStream;

  /// 是否正在录音
  bool get isRecording => _recordingService.isRecording;

  // ==================== Getters ====================

  /// 通话管理器事件流
  Stream<CallManagerEvent> get eventStream => _eventController.stream;

  /// 通话状态流
  Stream<CallState> get callStateStream => _callStateController.stream;

  /// WebRTC事件流
  Stream<WebRTCEvent> get webrtcEventStream => _webrtcService.eventStream;

  /// 远程媒体流流
  Stream<MediaStream?> get remoteStreamStream => _webrtcService.remoteStreamStream;

  /// 网络质量流
  Stream<NetworkQuality> get networkQualityStream => _webrtcService.networkQualityStream;

  /// 通话统计信息流
  Stream<CallStats> get statsStream => _webrtcService.statsStream;

  /// 录音状态流
  Stream<RecordingState> get recordingStateStream => _recordingService.stateStream;

  /// 录音时长流
  Stream<Duration> get recordingDurationStream => _recordingService.durationStream;

  /// 录音电平流
  Stream<double> get recordingLevelStream => _recordingService.levelStream;

  /// 信令消息流
  Stream<SignalingMessage> get signalingMessageStream => _signalingService.signalingMessageStream;

  /// 房间参与者流
  Stream<List<RoomParticipant>> get participantsStream => _signalingService.participantsStream;

  // ==================== 初始化方法 ====================

  /// 初始化通话管理器
  Future<void> initialize() async {
    // 初始化录音服务
    await _recordingService.initialize();

    // 设置WebRTC回调
    _setupWebRTCCallbacks();

    // 订阅WebRTC事件
    _webrtcEventSubscription = _webrtcService.eventStream.listen(_handleWebRTCEvent);

    // 订阅WebRTC状态
    _webrtcStateSubscription = _webrtcService.callStateStream.listen(_handleCallStateChange);

    // 订阅信令消息
    _signalingMessageSubscription = _signalingService.signalingMessageStream.listen(_handleSignalingMessage);

    // 订阅房间状态
    _roomStateSubscription = _signalingService.roomStateStream.listen(_handleRoomStateChange);

    // 订阅录音状态
    _recordingStateSubscription = _recordingService.stateStream.listen(_handleRecordingStateChange);

    print('[CallManager] 通话管理器已初始化');
  }

  /// 设置WebRTC回调
  void _setupWebRTCCallbacks() {
    // Offer创建回调
    _webrtcService.onOfferCreated = (sdp, type) async {
      if (_currentCall != null) {
        await _signalingService.sendOffer(_currentCall!.roomId, sdp, type);
      }
    };

    // Answer创建回调
    _webrtcService.onAnswerCreated = (sdp, type) async {
      if (_currentCall != null) {
        await _signalingService.sendAnswer(_currentCall!.roomId, sdp, type);
      }
    };

    // ICE候选回调
    _webrtcService.onIceCandidate = (candidate, sdpMid, sdpMLineIndex) async {
      if (_currentCall != null) {
        await _signalingService.sendIceCandidate(
          _currentCall!.roomId,
          candidate,
          sdpMid: sdpMid,
          sdpMLineIndex: sdpMLineIndex,
        );
      }
    };

    // 通话结束回调
    _webrtcService.onCallEnded = (reason) async {
      await _handleCallEnded(reason);
    };
  }

  // ==================== 通话控制方法 ====================

  /// 作为求助者发起通话
  Future<CallInfo> startCallAsSeeker({
    required String seekerId,
    required String helpRequestId,
    String? volunteerId,
    bool enableRecording = false,
  }) async {
    if (_currentCall != null) {
      throw Exception('已有进行中的通话');
    }

    try {
      _emitEvent(CallManagerEventType.callInitialized);

      // 初始化WebRTC通话
      final callInfo = await _webrtcService.initializeCallAsSeeker(
        seekerId: seekerId,
        helpRequestId: helpRequestId,
        volunteerId: volunteerId,
      );

      _currentCall = callInfo;

      // 加入信令房间
      await _signalingService.joinRoom(callInfo.roomId, role: CallRole.seeker);

      // 更新房间状态
      await _signalingService.updateRoomStatus(callInfo.roomId, 'connecting');

      // 创建并发送Offer（作为发起方）
      await _webrtcService.createOffer();

      // 如果启用录音，开始录音
      if (enableRecording) {
        await startRecording();
      }

      _emitEvent(CallManagerEventType.callConnecting, data: callInfo);

      return callInfo;
    } catch (e) {
      _emitEvent(CallManagerEventType.error, error: '发起通话失败: $e');
      await _cleanup();
      rethrow;
    }
  }

  /// 作为志愿者接听通话
  Future<CallInfo> acceptCallAsVolunteer({
    required String volunteerId,
    required String seekerId,
    required String helpRequestId,
    required String roomId,
    bool enableRecording = false,
  }) async {
    if (_currentCall != null) {
      throw Exception('已有进行中的通话');
    }

    try {
      _emitEvent(CallManagerEventType.callInitialized);

      // 初始化WebRTC通话
      final callInfo = await _webrtcService.initializeCallAsVolunteer(
        volunteerId: volunteerId,
        seekerId: seekerId,
        helpRequestId: helpRequestId,
        roomId: roomId,
      );

      _currentCall = callInfo;

      // 加入信令房间
      await _signalingService.joinRoom(roomId, role: CallRole.volunteer);

      // 更新房间状态
      await _signalingService.updateRoomStatus(roomId, 'connected');

      // 如果启用录音，开始录音
      if (enableRecording) {
        await startRecording();
      }

      _emitEvent(CallManagerEventType.callConnecting, data: callInfo);

      return callInfo;
    } catch (e) {
      _emitEvent(CallManagerEventType.error, error: '接听通话失败: $e');
      await _cleanup();
      rethrow;
    }
  }

  /// 结束通话
  Future<void> endCall(CallEndReason reason) async {
    if (_currentCall == null) return;

    try {
      // 发送挂断信令
      await _signalingService.sendBye(_currentCall!.roomId, reason: reason);

      // 停止录音
      if (_recordingService.isRecording) {
        await stopRecording();
      }

      // 结束WebRTC通话
      await _webrtcService.endCall(reason);

      // 离开信令房间
      await _signalingService.leaveRoom();

      // 更新房间状态
      await _signalingService.updateRoomStatus(
        _currentCall!.roomId,
        reason == CallEndReason.userHangup ? 'ended' : 'failed',
      );

      await _cleanup();

      _emitEvent(CallManagerEventType.callEnded, data: reason);
    } catch (e) {
      _emitEvent(CallManagerEventType.error, error: '结束通话失败: $e');
    }
  }

  /// 静音/取消静音
  Future<bool> toggleMute() async {
    return await _webrtcService.toggleMute();
  }

  /// 设置静音状态
  Future<void> setMute(bool muted) async {
    await _webrtcService.setMute(muted);
  }

  /// 切换扬声器
  Future<bool> toggleSpeaker() async {
    return await _webrtcService.toggleSpeaker();
  }

  /// 设置扬声器状态
  Future<void> setSpeaker(bool enabled) async {
    await _webrtcService.setSpeaker(enabled);
  }

  // ==================== 录音控制方法 ====================

  /// 开始录音
  Future<RecordingInfo?> startRecording() async {
    try {
      final info = await _recordingService.startRecording();
      if (info != null) {
        _emitEvent(CallManagerEventType.recordingStarted, data: info);
      }
      return info;
    } catch (e) {
      _emitEvent(CallManagerEventType.recordingError, error: '开始录音失败: $e');
      return null;
    }
  }

  /// 停止录音
  Future<RecordingInfo?> stopRecording() async {
    try {
      final info = await _recordingService.stopRecording();
      if (info != null) {
        _emitEvent(CallManagerEventType.recordingStopped, data: info);
      }
      return info;
    } catch (e) {
      _emitEvent(CallManagerEventType.recordingError, error: '停止录音失败: $e');
      return null;
    }
  }

  /// 暂停录音
  Future<void> pauseRecording() async {
    await _recordingService.pauseRecording();
  }

  /// 恢复录音
  Future<void> resumeRecording() async {
    await _recordingService.resumeRecording();
  }

  // ==================== 事件处理方法 ====================

  /// 处理WebRTC事件
  void _handleWebRTCEvent(WebRTCEvent event) {
    switch (event.type) {
      case WebRTCEventType.connected:
        _emitEvent(CallManagerEventType.callConnected);
        break;
      case WebRTCEventType.disconnected:
        _emitEvent(CallManagerEventType.callDisconnected);
        break;
      case WebRTCEventType.failed:
        _emitEvent(CallManagerEventType.callFailed, error: event.error);
        break;
      case WebRTCEventType.localStreamAdded:
        _emitEvent(CallManagerEventType.localStreamReady, data: event.data);
        break;
      case WebRTCEventType.remoteStreamAdded:
        _emitEvent(CallManagerEventType.remoteStreamReady, data: event.data);
        break;
      case WebRTCEventType.permissionDenied:
        _emitEvent(CallManagerEventType.permissionDenied, error: event.error);
        break;
      case WebRTCEventType.error:
        _emitEvent(CallManagerEventType.error, error: event.error);
        break;
      default:
        break;
    }
  }

  /// 处理通话状态变化
  void _handleCallStateChange(CallState state) {
    _currentCall?.state = state;
    _callStateController.add(state);

    switch (state) {
      case CallState.connected:
        _emitEvent(CallManagerEventType.callConnected);
        break;
      case CallState.reconnecting:
        _emitEvent(CallManagerEventType.callDisconnected);
        break;
      case CallState.failed:
        _emitEvent(CallManagerEventType.callFailed);
        break;
      case CallState.ended:
        _emitEvent(CallManagerEventType.callEnded);
        break;
      default:
        break;
    }
  }

  /// 处理信令消息
  Future<void> _handleSignalingMessage(SignalingMessage message) async {
    switch (message.type) {
      case SignalingType.offer:
        // 收到Offer，处理并创建Answer
        final sdp = message.data['sdp'] as String?;
        final type = message.data['type'] as String?;
        if (sdp != null && type != null) {
          await _webrtcService.handleOffer(sdp, type);
        }
        break;

      case SignalingType.answer:
        // 收到Answer
        final sdp = message.data['sdp'] as String?;
        final type = message.data['type'] as String?;
        if (sdp != null && type != null) {
          await _webrtcService.handleAnswer(sdp, type);
        }
        break;

      case SignalingType.iceCandidate:
        // 收到ICE候选
        final candidate = message.data['candidate'] as String?;
        final sdpMid = message.data['sdp_mid'] as String?;
        final sdpMLineIndex = message.data['sdp_mline_index'] as int?;
        if (candidate != null) {
          await _webrtcService.addIceCandidate(candidate, sdpMid, sdpMLineIndex);
        }
        break;

      case SignalingType.bye:
        // 对方挂断
        final reasonStr = message.data['reason'] as String?;
        final reason = CallEndReason.values.firstWhere(
          (r) => r.name == reasonStr,
          orElse: () => CallEndReason.remoteHangup,
        );
        await _handleRemoteHangup(reason);
        break;

      default:
        break;
    }
  }

  /// 处理房间状态变化
  void _handleRoomStateChange(RoomState state) {
    switch (state) {
      case RoomState.joined:
        _emitEvent(CallManagerEventType.signalingConnected);
        break;
      case RoomState.left:
        _emitEvent(CallManagerEventType.signalingDisconnected);
        break;
      case RoomState.error:
        _emitEvent(CallManagerEventType.signalingError);
        break;
      default:
        break;
    }
  }

  /// 处理录音状态变化
  void _handleRecordingStateChange(RecordingState state) {
    // 可以在这里添加录音状态变化的处理逻辑
    print('[CallManager] 录音状态: $state');
  }

  /// 处理通话结束
  Future<void> _handleCallEnded(CallEndReason reason) async {
    // 停止录音
    if (_recordingService.isRecording) {
      await stopRecording();
    }

    // 离开信令房间
    await _signalingService.leaveRoom();

    await _cleanup();

    _emitEvent(CallManagerEventType.callEnded, data: reason);
  }

  /// 处理对方挂断
  Future<void> _handleRemoteHangup(CallEndReason reason) async {
    // 停止录音
    if (_recordingService.isRecording) {
      await stopRecording();
    }

    // 结束WebRTC通话
    await _webrtcService.endCall(reason);

    // 离开信令房间
    await _signalingService.leaveRoom();

    await _cleanup();

    _emitEvent(CallManagerEventType.callEnded, data: reason);
  }

  // ==================== 辅助方法 ====================

  /// 清理资源
  Future<void> _cleanup() async {
    _currentCall = null;
  }

  /// 发送事件
  void _emitEvent(CallManagerEventType type, {dynamic data, String? error}) {
    if (!_eventController.isClosed) {
      _eventController.add(CallManagerEvent(
        type: type,
        data: data,
        error: error,
      ));
    }
  }

  /// 获取格式化的通话时长
  String getFormattedDuration() {
    return _webrtcService.getFormattedDuration();
  }

  /// 获取当前统计信息
  Future<CallStats?> getCurrentStats() async {
    return await _webrtcService.getCurrentStats();
  }

  /// 释放所有资源
  Future<void> dispose() async {
    // 取消订阅
    await _webrtcEventSubscription?.cancel();
    await _webrtcStateSubscription?.cancel();
    await _signalingMessageSubscription?.cancel();
    await _roomStateSubscription?.cancel();
    await _recordingStateSubscription?.cancel();

    // 结束当前通话
    if (_currentCall != null) {
      await endCall(CallEndReason.userHangup);
    }

    // 释放服务
    _webrtcService.dispose();
    _signalingService.dispose();
    await _recordingService.dispose();

    // 关闭流控制器
    await _eventController.close();
    await _callStateController.close();
  }
}
