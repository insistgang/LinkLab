import 'dart:async';
import '../../models/call_models.dart';

/// 演示版WebRTC服务
/// 用于替代真实的WebRTC P2P通话
class DemoWebRTCService {
  static final DemoWebRTCService _instance = DemoWebRTCService._internal();
  factory DemoWebRTCService() => _instance;
  DemoWebRTCService._internal();

  // 状态监听
  final _callStateController = StreamController<CallState>.broadcast();
  Stream<CallState> get callStateStream => _callStateController.stream;

  // 当前通话信息
  CallInfo? _currentCall;
  CallInfo? get currentCall => _currentCall;

  // 计时器
  Timer? _callTimer;
  int _elapsedSeconds = 0;

  /// 初始化通话
  Future<CallInfo> initializeCall({
    required String seekerId,
    required String volunteerId,
    required CallRole myRole,
  }) async {
    // 模拟初始化延迟
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

  /// 开始通话（模拟连接过程）
  Future<void> startCall() async {
    if (_currentCall == null) return;

    // 模拟连接过程
    _callStateController.add(CallState.connecting);
    await Future.delayed(const Duration(seconds: 1));

    _callStateController.add(CallState.ringing);
    await Future.delayed(const Duration(seconds: 1));

    _callStateController.add(CallState.connected);
    _currentCall!.state = CallState.connected;
    _currentCall!.startTime = DateTime.now();

    // 开始计时
    _startTimer();
  }

  /// 模拟自动接听（用于演示）
  Future<void> autoAnswer({int delaySeconds = 3}) async {
    await Future.delayed(Duration(seconds: delaySeconds));
    await startCall();
  }

  /// 挂断通话
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

  /// 切换静音状态
  void toggleMute() {
    if (_currentCall != null) {
      _currentCall!.isMuted = !_currentCall!.isMuted;
    }
  }

  /// 切换扬声器状态
  void toggleSpeaker() {
    if (_currentCall != null) {
      _currentCall!.isSpeakerOn = !_currentCall!.isSpeakerOn;
    }
  }

  /// 获取通话时长
  Duration getCallDuration() {
    if (_currentCall?.startTime == null) {
      return Duration.zero;
    }

    final endTime = _currentCall?.endTime ?? DateTime.now();
    return endTime.difference(_currentCall!.startTime!);
  }

  /// 获取格式化的通话时长
  String getFormattedDuration() {
    final duration = getCallDuration();
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// 开始计时器
  void _startTimer() {
    _elapsedSeconds = 0;
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
    });
  }

  /// 停止计时器
  void _stopTimer() {
    _callTimer?.cancel();
    _callTimer = null;
  }

  /// 模拟通话统计
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

  /// 释放资源
  void dispose() {
    _stopTimer();
    _callStateController.close();
  }
}
