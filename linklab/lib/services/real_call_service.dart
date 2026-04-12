import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/call_models.dart';
import 'webrtc/webrtc_exports.dart';

/// 真实通话服务
/// 集成WebRTC、信令和录音功能的完整通话服务
class RealCallService extends ChangeNotifier {
  static final RealCallService _instance = RealCallService._internal();
  factory RealCallService() => _instance;
  RealCallService._internal() {
    _setupWebRTCCallbacks();
    _setupSignalingCallbacks();
  }

  // ==================== 核心服务 ====================

  /// WebRTC服务
  final RealWebRTCService _webRTCService = RealWebRTCService();

  /// 信令服务
  final SignalingService _signalingService = SignalingService();

  /// 录音服务
  final CallRecordingService _recordingService = CallRecordingService();

  // ==================== 状态 ====================

  /// 通话状态
  CallState _callState = CallState.idle;

  /// 当前通话信息
  CallInfo? _currentCall;

  /// 当前志愿者信息
  VolunteerInfo? _currentVolunteer;

  /// 通话时长
  Duration _callDuration = Duration.zero;

  /// 网络质量
  NetworkQuality _networkQuality = NetworkQuality.unknown;

  /// 是否正在录音
  bool _isRecording = false;

  /// 错误信息
  String? _errorMessage;

  /// 远程媒体流
  MediaStream? _remoteStream;

  /// 订阅列表
  final List<StreamSubscription> _subscriptions = [];

  // ==================== Getters ====================

  /// 通话状态
  CallState get callState => _callState;

  /// 当前通话信息
  CallInfo? get currentCall => _currentCall;

  /// 当前志愿者信息
  VolunteerInfo? get currentVolunteer => _currentVolunteer;

  /// 通话时长
  Duration get callDuration => _callDuration;

  /// 格式化的通话时长
  String get formattedDuration {
    final minutes = _callDuration.inMinutes.toString().padLeft(2, '0');
    final seconds = (_callDuration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// 网络质量
  NetworkQuality get networkQuality => _networkQuality;

  /// 网络质量描述
  String get networkQualityText => NetworkQualityEvaluator.getQualityDescription(_networkQuality);

  /// 是否正在通话中
  bool get isInCall => _callState == CallState.connected;

  /// 是否正在连接中
  bool get isConnecting =>
      _callState == CallState.connecting || _callState == CallState.ringing;

  /// 是否正在录音
  bool get isRecording => _isRecording;

  /// 是否静音
  bool get isMuted => _currentCall?.isMuted ?? false;

  /// 是否使用扬声器
  bool get isSpeakerOn => _currentCall?.isSpeakerOn ?? true;

  /// 错误信息
  String? get errorMessage => _errorMessage;

  /// 远程媒体流
  MediaStream? get remoteStream => _remoteStream;

  /// 通话状态流
  Stream<CallState> get callStateStream => _webRTCService.callStateStream;

  /// 通话统计信息流
  Stream<CallStats> get statsStream => _webRTCService.statsStream;

  /// 网络质量流
  Stream<NetworkQuality> get networkQualityStream => _webRTCService.networkQualityStream;

  // ==================== 回调设置 ====================

  /// 设置WebRTC回调
  void _setupWebRTCCallbacks() {
    _webRTCService.onOfferCreated = (sdp, type) {
      if (_currentCall != null) {
        _signalingService.sendOffer(_currentCall!.roomId, sdp, type);
      }
    };

    _webRTCService.onAnswerCreated = (sdp, type) {
      if (_currentCall != null) {
        _signalingService.sendAnswer(_currentCall!.roomId, sdp, type);
      }
    };

    _webRTCService.onIceCandidate = (candidate, sdpMid, sdpMLineIndex) {
      if (_currentCall != null) {
        _signalingService.sendIceCandidate(
          _currentCall!.roomId,
          candidate,
          sdpMid: sdpMid,
          sdpMLineIndex: sdpMLineIndex,
        );
      }
    };

    _webRTCService.onCallEnded = (reason) {
      _handleCallEnded(reason);
    };
  }

  /// 设置信令回调
  void _setupSignalingCallbacks() {
    // 监听信令消息
    _subscriptions.add(
      _signalingService.signalingMessageStream.listen(_handleSignalingMessage),
    );

    // 监听房间状态
    _subscriptions.add(
      _signalingService.roomStateStream.listen(_handleRoomStateChange),
    );

    // 监听WebRTC状态
    _subscriptions.add(
      _webRTCService.callStateStream.listen(_handleCallStateChange),
    );

    // 监听远程流
    _subscriptions.add(
      _webRTCService.remoteStreamStream.listen((stream) {
        _remoteStream = stream;
        notifyListeners();
      }),
    );

    // 监听网络质量
    _subscriptions.add(
      _webRTCService.networkQualityStream.listen((quality) {
        _networkQuality = quality;
        notifyListeners();
      }),
    );

    // 监听通话时长
    _subscriptions.add(
      Stream.periodic(const Duration(seconds: 1)).listen((_) {
        if (_callState == CallState.connected) {
          _callDuration = _webRTCService.callDuration;
          notifyListeners();
        }
      }),
    );
  }

  // ==================== 通话控制方法 ====================

  /// 初始化服务
  Future<void> initialize() async {
    await _recordingService.initialize();
  }

  /// 作为求助者发起通话
  Future<void> startCallAsSeeker({
    required String seekerId,
    required String helpRequestId,
    required VolunteerInfo volunteer,
  }) async {
    try {
      _resetState();
      _currentVolunteer = volunteer;
      _callState = CallState.connecting;
      notifyListeners();

      // 初始化WebRTC
      _currentCall = await _webRTCService.initializeCallAsSeeker(
        seekerId: seekerId,
        helpRequestId: helpRequestId,
        volunteerId: volunteer.id,
      );

      // 加入信令房间
      await _signalingService.joinRoom(
        _currentCall!.roomId,
        role: CallRole.seeker,
      );

      // 等待对方加入后创建Offer
      // 实际在收到对方join消息后创建Offer
    } catch (e) {
      _errorMessage = '发起通话失败: $e';
      _callState = CallState.failed;
      notifyListeners();
    }
  }

  /// 作为志愿者接听通话
  Future<void> answerCallAsVolunteer({
    required String volunteerId,
    required String seekerId,
    required String helpRequestId,
    required String roomId,
    required VolunteerInfo volunteer,
  }) async {
    try {
      _resetState();
      _currentVolunteer = volunteer;
      _callState = CallState.connecting;
      notifyListeners();

      // 初始化WebRTC
      _currentCall = await _webRTCService.initializeCallAsVolunteer(
        volunteerId: volunteerId,
        seekerId: seekerId,
        helpRequestId: helpRequestId,
        roomId: roomId,
      );

      // 加入信令房间
      await _signalingService.joinRoom(
        roomId,
        role: CallRole.volunteer,
      );

      // 志愿者加入后，等待求助者的Offer
    } catch (e) {
      _errorMessage = '接听通话失败: $e';
      _callState = CallState.failed;
      notifyListeners();
    }
  }

  /// 静音/取消静音
  Future<void> toggleMute() async {
    final isMuted = await _webRTCService.toggleMute();
    notifyListeners();
  }

  /// 切换扬声器
  Future<void> toggleSpeaker() async {
    final isSpeakerOn = await _webRTCService.toggleSpeaker();
    notifyListeners();
  }

  /// 开始录音
  Future<void> startRecording() async {
    if (_isRecording) return;

    try {
      final info = await _recordingService.startRecording();
      if (info != null) {
        _isRecording = true;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = '开始录音失败: $e';
      notifyListeners();
    }
  }

  /// 停止录音
  Future<RecordingInfo?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      final info = await _recordingService.stopRecording();
      _isRecording = false;
      notifyListeners();
      return info;
    } catch (e) {
      _errorMessage = '停止录音失败: $e';
      notifyListeners();
      return null;
    }
  }

  /// 结束通话
  Future<void> endCall() async {
    if (_currentCall == null) return;

    // 停止录音
    if (_isRecording) {
      await stopRecording();
    }

    // 发送挂断信号
    await _signalingService.sendBye(
      _currentCall!.roomId,
      reason: CallEndReason.userHangup,
    );

    // 结束WebRTC通话
    await _webRTCService.endCall(CallEndReason.userHangup);

    // 离开信令房间
    await _signalingService.leaveRoom();

    _callState = CallState.ended;
    notifyListeners();
  }

  // ==================== 事件处理方法 ====================

  /// 处理信令消息
  void _handleSignalingMessage(SignalingMessage message) {
    switch (message.type) {
      case SignalingType.offer:
        // 收到Offer，创建Answer
        final sdp = message.data['sdp'] as String?;
        final type = message.data['type'] as String?;
        if (sdp != null && type != null) {
          _webRTCService.handleOffer(sdp, type);
        }
        break;

      case SignalingType.answer:
        // 收到Answer
        final sdp = message.data['sdp'] as String?;
        final type = message.data['type'] as String?;
        if (sdp != null && type != null) {
          _webRTCService.handleAnswer(sdp, type);
        }
        break;

      case SignalingType.iceCandidate:
        // 收到ICE候选
        final candidate = message.data['candidate'] as String?;
        final sdpMid = message.data['sdp_mid'] as String?;
        final sdpMLineIndex = message.data['sdp_mline_index'] as int?;
        if (candidate != null) {
          _webRTCService.addIceCandidate(candidate, sdpMid, sdpMLineIndex);
        }
        break;

      case SignalingType.join:
        // 对方加入，如果是求助者则创建Offer
        if (_currentCall?.myRole == CallRole.seeker) {
          _webRTCService.createOffer();
        }
        break;

      case SignalingType.bye:
        // 对方挂断
        final reasonStr = message.data['reason'] as String?;
        final reason = CallEndReason.values.firstWhere(
          (r) => r.name == reasonStr,
          orElse: () => CallEndReason.remoteHangup,
        );
        _handleCallEnded(reason);
        break;

      default:
        break;
    }
  }

  /// 处理房间状态变化
  void _handleRoomStateChange(RoomState state) {
    switch (state) {
      case RoomState.peerJoined:
        // 对方已加入
        break;
      case RoomState.peerLeft:
        // 对方已离开
        if (_callState == CallState.connected) {
          _handleCallEnded(CallEndReason.remoteHangup);
        }
        break;
      case RoomState.callEnded:
        // 通话结束
        _handleCallEnded(CallEndReason.remoteHangup);
        break;
      default:
        break;
    }
  }

  /// 处理通话状态变化
  void _handleCallStateChange(CallState state) {
    _callState = state;
    notifyListeners();

    if (state == CallState.connected) {
      // 通话连接成功，可以开始录音（如果需要）
    } else if (state == CallState.ended || state == CallState.failed) {
      // 通话结束
      _handleCallEnded(state == CallState.failed
          ? CallEndReason.networkError
          : CallEndReason.userHangup);
    }
  }

  /// 处理通话结束
  void _handleCallEnded(CallEndReason reason) {
    // 停止录音
    if (_isRecording) {
      stopRecording();
    }

    // 离开信令房间
    _signalingService.leaveRoom();

    _callState = CallState.ended;
    notifyListeners();
  }

  /// 重置状态
  void _resetState() {
    _callState = CallState.idle;
    _currentCall = null;
    _callDuration = Duration.zero;
    _networkQuality = NetworkQuality.unknown;
    _isRecording = false;
    _errorMessage = null;
    _remoteStream = null;
  }

  // ==================== 资源释放 ====================

  @override
  void dispose() {
    // 取消订阅
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // 释放服务
    _webRTCService.dispose();
    _signalingService.dispose();
    _recordingService.dispose();

    super.dispose();
  }
}

/// 志愿者信息
class VolunteerInfo {
  final String id;
  final String name;
  final String? avatar;
  final double rating;
  final int helpCount;
  final List<String> skills;

  VolunteerInfo({
    required this.id,
    required this.name,
    this.avatar,
    required this.rating,
    required this.helpCount,
    required this.skills,
  });
}
