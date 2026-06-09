import 'dart:async';

import '../../config/app_config.dart';
import '../../models/call_models.dart';

/// 演示版WebRTC服務
/// 用於替代真實的WebRTC P2P通話
class DemoWebRTCService {
  static final DemoWebRTCService _instance = DemoWebRTCService._internal();
  factory DemoWebRTCService() => _instance;
  DemoWebRTCService._internal();

  // 狀態監聽
  final _callStateController = StreamController<CallState>.broadcast();
  Stream<CallState> get callStateStream => _callStateController.stream;

  // 當前通話信息
  CallInfo? _currentCall;
  CallInfo? get currentCall => _currentCall;

  // 計時器
  Timer? _callTimer;
  int _elapsedSeconds = 0;

  void _ensureDemoFallbackEnabled(String action) {
    if (!AppConfig.shouldUseDemoFallback(feature: action)) {
      throw StateError('$action 僅在 Demo fallback 開啓時可用');
    }
  }

  /// 初始化通話
  Future<CallInfo> initializeCall({
    required String seekerId,
    required String volunteerId,
    required CallRole myRole,
  }) async {
    _ensureDemoFallbackEnabled('DemoWebRTCService.initializeCall');

    // 模擬初始化延遲
    await Future.delayed(const Duration(milliseconds: 500));

    _currentCall = CallInfo(
      callId: 'demo_call_${DateTime.now().millisecondsSinceEpoch}',
      roomId: 'demo_room_${seekerId}_$volunteerId',
      seekerId: seekerId,
      volunteerId: volunteerId,
      myRole: myRole,
      state: CallState.connecting,
    );

    _callStateController.add(CallState.connecting);

    return _currentCall!;
  }

  /// 開始通話（模擬連接過程）
  Future<void> startCall() async {
    _ensureDemoFallbackEnabled('DemoWebRTCService.startCall');
    if (_currentCall == null) return;

    // 模擬連接過程
    _callStateController.add(CallState.connecting);
    await Future.delayed(const Duration(seconds: 1));

    _callStateController.add(CallState.ringing);
    await Future.delayed(const Duration(seconds: 1));

    _callStateController.add(CallState.connected);
    _currentCall!.state = CallState.connected;
    _currentCall!.startTime = DateTime.now();

    // 開始計時
    _startTimer();
  }

  /// 模擬自動接聽（用於演示）
  Future<void> autoAnswer({int delaySeconds = 3}) async {
    _ensureDemoFallbackEnabled('DemoWebRTCService.autoAnswer');
    await Future.delayed(Duration(seconds: delaySeconds));
    await startCall();
  }

  /// 掛斷通話
  Future<void> hangUp() async {
    _stopTimer();

    if (_currentCall != null) {
      _currentCall!.state = CallState.ended;
      _currentCall!.endTime = DateTime.now();
      _callStateController.add(CallState.ended);
    }

    // 清理
    _currentCall = null;
  }

  /// 切換靜音狀態
  void toggleMute() {
    if (_currentCall != null) {
      _currentCall!.isMuted = !_currentCall!.isMuted;
    }
  }

  /// 切換揚聲器狀態
  void toggleSpeaker() {
    if (_currentCall != null) {
      _currentCall!.isSpeakerOn = !_currentCall!.isSpeakerOn;
    }
  }

  /// 獲取通話時長
  Duration getCallDuration() {
    if (_currentCall?.startTime == null) {
      return Duration.zero;
    }

    final endTime = _currentCall?.endTime ?? DateTime.now();
    return endTime.difference(_currentCall!.startTime!);
  }

  /// 獲取格式化的通話時長
  String getFormattedDuration() {
    final duration = getCallDuration();
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// 開始計時器
  void _startTimer() {
    _elapsedSeconds = 0;
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
    });
  }

  /// 停止計時器
  void _stopTimer() {
    _callTimer?.cancel();
    _callTimer = null;
  }

  /// 模擬通話統計
  CallStats getCallStats() {
    final duration = getCallDuration();

    return CallStats(
      duration: duration,
      bytesReceived: 1024 * 1024 * (duration.inSeconds ~/ 10),
      bytesSent: 512 * 1024 * (duration.inSeconds ~/ 10),
      averageBitrate: 128.0,
      packetLoss: 0,
    );
  }

  /// 釋放資源
  void dispose() {
    _stopTimer();
    _callStateController.close();
  }
}
