// WebRTC 通話狀態管理 Provider
// 使用 Riverpod 管理通話狀態

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../models/call_models.dart';
import '../services/webrtc/webrtc_call_manager.dart';
import '../services/webrtc/webrtc_config.dart';

/// 通話狀態
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

  /// 是否正在通話中
  bool get isInCall => state != CallState.idle && state != CallState.ended;

  /// 是否正在連接中
  bool get isConnecting =>
      state == CallState.connecting || state == CallState.ringing;

  /// 獲取格式化的時長
  String get formattedDuration {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  /// 獲取狀態描述
  String get stateDescription {
    switch (state) {
      case CallState.idle:
        return '空閒';
      case CallState.matching:
        return '匹配中';
      case CallState.connecting:
        return '連接中';
      case CallState.ringing:
        return '響鈴中';
      case CallState.connected:
        return '通話中';
      case CallState.reconnecting:
        return '重連中';
      case CallState.ended:
        return '已結束';
      case CallState.failed:
        return '連接失敗';
    }
  }
}

/// 通話狀態 Notifier
class WebRTCCallNotifier extends StateNotifier<CallStateData> {
  WebRTCCallNotifier() : super(const CallStateData()) {
    _initialize();
  }

  final WebRTCCallManager _callManager = WebRTCCallManager();

  // 訂閱
  StreamSubscription<CallState>? _callStateSubscription;
  StreamSubscription<MediaStream?>? _remoteStreamSubscription;
  StreamSubscription<NetworkQuality>? _networkQualitySubscription;
  StreamSubscription<CallManagerEvent>? _eventSubscription;
  Timer? _durationTimer;

  /// 初始化
  Future<void> _initialize() async {
    await _callManager.initialize();

    // 訂閱通話狀態
    _callStateSubscription = _callManager.callStateStream.listen((callState) {
      state = state.copyWith(state: callState);

      // 根據狀態啓動或停止計時器
      if (callState == CallState.connected) {
        _startDurationTimer();
      } else if (callState == CallState.ended ||
          callState == CallState.failed) {
        _stopDurationTimer();
      }
    });

    // 訂閱遠程媒體流
    _remoteStreamSubscription =
        _callManager.remoteStreamStream.listen((stream) {
      state = state.copyWith(
        remoteStream: stream,
        isConnected: stream != null,
      );
    });

    // 訂閱網絡質量
    _networkQualitySubscription =
        _callManager.networkQualityStream.listen((quality) {
      state = state.copyWith(networkQuality: quality);
    });

    // 訂閱通話管理器事件
    _eventSubscription = _callManager.eventStream.listen((event) {
      _handleEvent(event);
    });
  }

  /// 處理事件
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
        state = state.copyWith(error: event.error ?? '通話連接失敗');
        break;

      case CallManagerEventType.error:
        state = state.copyWith(error: event.error);
        break;

      case CallManagerEventType.permissionDenied:
        state = state.copyWith(error: '需要麥克風權限才能進行通話');
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

  /// 啓動時長計時器
  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(duration: _callManager.callDuration);
    });
  }

  /// 停止時長計時器
  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  /// 作爲求助者發起通話
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

  /// 作爲志願者接聽通話
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

  /// 結束通話
  Future<void> endCall(CallEndReason reason) async {
    await _callManager.endCall(reason);
  }

  /// 靜音/取消靜音
  Future<void> toggleMute() async {
    final isMuted = await _callManager.toggleMute();
    state = state.copyWith(isMuted: isMuted);
  }

  /// 設置靜音狀態
  Future<void> setMute(bool muted) async {
    await _callManager.setMute(muted);
    state = state.copyWith(isMuted: muted);
  }

  /// 切換揚聲器
  Future<void> toggleSpeaker() async {
    final isSpeakerOn = await _callManager.toggleSpeaker();
    state = state.copyWith(isSpeakerOn: isSpeakerOn);
  }

  /// 設置揚聲器狀態
  Future<void> setSpeaker(bool enabled) async {
    await _callManager.setSpeaker(enabled);
    state = state.copyWith(isSpeakerOn: enabled);
  }

  /// 開始錄音
  Future<void> startRecording() async {
    await _callManager.startRecording();
  }

  /// 停止錄音
  Future<void> stopRecording() async {
    await _callManager.stopRecording();
  }

  /// 重置狀態
  void _resetState() {
    _stopDurationTimer();
    state = const CallStateData();
  }

  /// 清除錯誤
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

/// 通話狀態 Provider
final webRTCCallProvider =
    StateNotifierProvider<WebRTCCallNotifier, CallStateData>((ref) {
  return WebRTCCallNotifier();
});

/// 是否正在通話中 Provider
final isInCallProvider = Provider<bool>((ref) {
  return ref.watch(webRTCCallProvider).isInCall;
});

/// 通話狀態 Provider
final callStateProvider = Provider<CallState>((ref) {
  return ref.watch(webRTCCallProvider).state;
});

/// 通話時長 Provider
final callDurationProvider = Provider<Duration>((ref) {
  return ref.watch(webRTCCallProvider).duration;
});

/// 格式化的通話時長 Provider
final formattedCallDurationProvider = Provider<String>((ref) {
  return ref.watch(webRTCCallProvider).formattedDuration;
});

/// 網絡質量 Provider
final networkQualityProvider = Provider<NetworkQuality>((ref) {
  return ref.watch(webRTCCallProvider).networkQuality;
});

/// 通話錯誤 Provider
final callErrorProvider = Provider<String?>((ref) {
  return ref.watch(webRTCCallProvider).error;
});

// ==================== 輔助方法 ====================

/// 獲取網絡質量顏色
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

/// 獲取網絡質量圖標
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

/// 獲取網絡質量描述
String getNetworkQualityDescription(NetworkQuality quality) {
  switch (quality) {
    case NetworkQuality.excellent:
      return '網絡優秀';
    case NetworkQuality.good:
      return '網絡良好';
    case NetworkQuality.fair:
      return '網絡一般';
    case NetworkQuality.poor:
      return '網絡較差';
    case NetworkQuality.bad:
      return '網絡很差';
    case NetworkQuality.unknown:
      return '網絡狀態未知';
  }
}
