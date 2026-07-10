// WebRTC 通话状态管理 Provider
// 使用 Riverpod 管理通话状态

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../models/call_models.dart';
import '../services/webrtc/webrtc_call_manager.dart';
import '../services/webrtc/webrtc_config.dart';

/// 通话状态
class CallStateData {
  final CallInfo? callInfo;
  final CallState state;
  final bool isConnected;
  final Duration duration;
  final MediaStream? localStream;
  final MediaStream? remoteStream;
  final NetworkQuality networkQuality;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isRecording;
  final String? error;

  const CallStateData({
    this.callInfo,
    this.state = CallState.idle,
    this.isConnected = false,
    this.duration = Duration.zero,
    this.localStream,
    this.remoteStream,
    this.networkQuality = NetworkQuality.unknown,
    this.isMuted = false,
    this.isSpeakerOn = true,
    this.isRecording = false,
    this.error,
  });

  CallStateData copyWith({
    CallInfo? callInfo,
    CallState? state,
    bool? isConnected,
    Duration? duration,
    MediaStream? localStream,
    MediaStream? remoteStream,
    NetworkQuality? networkQuality,
    bool? isMuted,
    bool? isSpeakerOn,
    bool? isRecording,
    String? error,
  }) {
    return CallStateData(
      callInfo: callInfo ?? this.callInfo,
      state: state ?? this.state,
      isConnected: isConnected ?? this.isConnected,
      duration: duration ?? this.duration,
      localStream: localStream ?? this.localStream,
      remoteStream: remoteStream ?? this.remoteStream,
      networkQuality: networkQuality ?? this.networkQuality,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isRecording: isRecording ?? this.isRecording,
      error: error ?? this.error,
    );
  }

  /// 是否正在通话中
  bool get isInCall => state != CallState.idle && state != CallState.ended;

  /// 是否正在连接中
  bool get isConnecting =>
      state == CallState.connecting || state == CallState.ringing;

  /// 获取格式化的时长
  String get formattedDuration {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  /// 获取状态描述
  String get stateDescription {
    switch (state) {
      case CallState.idle:
        return '空闲';
      case CallState.matching:
        return '匹配中';
      case CallState.connecting:
        return '连接中';
      case CallState.ringing:
        return '响铃中';
      case CallState.connected:
        return '通话中';
      case CallState.reconnecting:
        return '重连中';
      case CallState.ended:
        return '已结束';
      case CallState.failed:
        return '连接失败';
    }
  }
}

/// 通话状态 Notifier
class WebRTCCallNotifier extends StateNotifier<CallStateData> {
  WebRTCCallNotifier() : super(const CallStateData()) {
    _initialize();
  }

  final WebRTCCallManager _callManager = WebRTCCallManager();

  // 订阅
  StreamSubscription<CallState>? _callStateSubscription;
  StreamSubscription<MediaStream?>? _remoteStreamSubscription;
  StreamSubscription<NetworkQuality>? _networkQualitySubscription;
  StreamSubscription<CallManagerEvent>? _eventSubscription;
  Timer? _durationTimer;

  /// 初始化
  Future<void> _initialize() async {
    await _callManager.initialize();

    // 订阅通话状态
    _callStateSubscription = _callManager.callStateStream.listen((callState) {
      state = state.copyWith(state: callState);

      // 根据状态启动或停止计时器
      if (callState == CallState.connected) {
        _startDurationTimer();
      } else if (callState == CallState.ended ||
          callState == CallState.failed) {
        _stopDurationTimer();
      }
    });

    // 订阅远程媒体流
    _remoteStreamSubscription =
        _callManager.remoteStreamStream.listen((stream) {
      state = state.copyWith(
        remoteStream: stream,
        isConnected: stream != null,
      );
    });

    // 订阅网络质量
    _networkQualitySubscription =
        _callManager.networkQualityStream.listen((quality) {
      state = state.copyWith(networkQuality: quality);
    });

    // 订阅通话管理器事件
    _eventSubscription = _callManager.eventStream.listen((event) {
      _handleEvent(event);
    });
  }

  /// 处理事件
  void _handleEvent(CallManagerEvent event) {
    switch (event.type) {
      case CallManagerEventType.callInitialized:
        state = state.copyWith(
          callInfo: _callManager.currentCall,
          localStream: _callManager.localStream,
        );
        break;

      case CallManagerEventType.callConnected:
        state = state.copyWith(
          isConnected: true,
          error: null,
        );
        break;

      case CallManagerEventType.callDisconnected:
        state = state.copyWith(isConnected: false);
        break;

      case CallManagerEventType.callEnded:
        _resetState();
        break;

      case CallManagerEventType.callFailed:
        state = state.copyWith(error: event.error ?? '通话连接失败');
        break;

      case CallManagerEventType.error:
        state = state.copyWith(error: event.error);
        break;

      case CallManagerEventType.permissionDenied:
        state = state.copyWith(error: '需要麦克风权限才能进行通话');
        break;

      case CallManagerEventType.recordingStarted:
        state = state.copyWith(isRecording: true);
        break;

      case CallManagerEventType.recordingStopped:
        state = state.copyWith(isRecording: false);
        break;

      default:
        break;
    }
  }

  /// 启动时长计时器
  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(duration: _callManager.callDuration);
    });
  }

  /// 停止时长计时器
  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  /// 作为求助者发起通话
  Future<void> startCallAsSeeker({
    required String seekerId,
    required String helpRequestId,
    String? volunteerId,
    bool enableRecording = false,
  }) async {
    try {
      state = state.copyWith(error: null);
      await _callManager.startCallAsSeeker(
        seekerId: seekerId,
        helpRequestId: helpRequestId,
        volunteerId: volunteerId,
        enableRecording: enableRecording,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// 作为志愿者接听通话
  Future<void> acceptCallAsVolunteer({
    required String volunteerId,
    required String seekerId,
    required String helpRequestId,
    required String roomId,
    bool enableRecording = false,
  }) async {
    try {
      state = state.copyWith(error: null);
      await _callManager.acceptCallAsVolunteer(
        volunteerId: volunteerId,
        seekerId: seekerId,
        helpRequestId: helpRequestId,
        roomId: roomId,
        enableRecording: enableRecording,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// 结束通话
  Future<void> endCall(CallEndReason reason) async {
    await _callManager.endCall(reason);
  }

  /// 静音/取消静音
  Future<void> toggleMute() async {
    final isMuted = await _callManager.toggleMute();
    state = state.copyWith(isMuted: isMuted);
  }

  /// 设置静音状态
  Future<void> setMute(bool muted) async {
    await _callManager.setMute(muted);
    state = state.copyWith(isMuted: muted);
  }

  /// 切换扬声器
  Future<void> toggleSpeaker() async {
    final isSpeakerOn = await _callManager.toggleSpeaker();
    state = state.copyWith(isSpeakerOn: isSpeakerOn);
  }

  /// 设置扬声器状态
  Future<void> setSpeaker(bool enabled) async {
    await _callManager.setSpeaker(enabled);
    state = state.copyWith(isSpeakerOn: enabled);
  }

  /// 开始录音
  Future<void> startRecording() async {
    await _callManager.startRecording();
  }

  /// 停止录音
  Future<void> stopRecording() async {
    await _callManager.stopRecording();
  }

  /// 重置状态
  void _resetState() {
    _stopDurationTimer();
    state = const CallStateData();
  }

  /// 清除错误
  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _callStateSubscription?.cancel();
    _remoteStreamSubscription?.cancel();
    _networkQualitySubscription?.cancel();
    _eventSubscription?.cancel();
    _callManager.dispose();
    super.dispose();
  }
}

// ==================== Providers ====================

/// 通话状态 Provider
final webRTCCallProvider =
    StateNotifierProvider<WebRTCCallNotifier, CallStateData>((ref) {
  return WebRTCCallNotifier();
});

/// 是否正在通话中 Provider
final isInCallProvider = Provider<bool>((ref) {
  return ref.watch(webRTCCallProvider).isInCall;
});

/// 通话状态 Provider
final callStateProvider = Provider<CallState>((ref) {
  return ref.watch(webRTCCallProvider).state;
});

/// 通话时长 Provider
final callDurationProvider = Provider<Duration>((ref) {
  return ref.watch(webRTCCallProvider).duration;
});

/// 格式化的通话时长 Provider
final formattedCallDurationProvider = Provider<String>((ref) {
  return ref.watch(webRTCCallProvider).formattedDuration;
});

/// 网络质量 Provider
final networkQualityProvider = Provider<NetworkQuality>((ref) {
  return ref.watch(webRTCCallProvider).networkQuality;
});

/// 通话错误 Provider
final callErrorProvider = Provider<String?>((ref) {
  return ref.watch(webRTCCallProvider).error;
});

// ==================== 辅助方法 ====================

/// 获取网络质量颜色
Color getNetworkQualityColor(NetworkQuality quality) {
  switch (quality) {
    case NetworkQuality.excellent:
      return Colors.green;
    case NetworkQuality.good:
      return Colors.lightGreen;
    case NetworkQuality.fair:
      return Colors.yellow;
    case NetworkQuality.poor:
      return Colors.orange;
    case NetworkQuality.bad:
      return Colors.red;
    case NetworkQuality.unknown:
      return Colors.grey;
  }
}

/// 获取网络质量图标
IconData getNetworkQualityIcon(NetworkQuality quality) {
  switch (quality) {
    case NetworkQuality.excellent:
    case NetworkQuality.good:
      return Icons.signal_cellular_alt;
    case NetworkQuality.fair:
      return Icons.signal_cellular_alt_2_bar;
    case NetworkQuality.poor:
    case NetworkQuality.bad:
      return Icons.signal_cellular_alt_1_bar;
    case NetworkQuality.unknown:
      return Icons.signal_cellular_off;
  }
}

/// 获取网络质量描述
String getNetworkQualityDescription(NetworkQuality quality) {
  switch (quality) {
    case NetworkQuality.excellent:
      return '网络优秀';
    case NetworkQuality.good:
      return '网络良好';
    case NetworkQuality.fair:
      return '网络一般';
    case NetworkQuality.poor:
      return '网络较差';
    case NetworkQuality.bad:
      return '网络很差';
    case NetworkQuality.unknown:
      return '网络状态未知';
  }
}
