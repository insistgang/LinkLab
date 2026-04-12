// 统一通话服务
// 支持演示模式和真实模式自动切换

import 'dart:async';
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/call_models.dart';
import 'demo_call_service.dart';
import 'real_call_service.dart';
import 'webrtc/webrtc_exports.dart';

/// 通话状态
enum CallStatus {
  idle,
  connecting,
  ringing,
  connected,
  ended,
  failed,
}

/// 统一通话服务
/// 根据 AppConfig.mode 自动切换演示/真实模式
class UnifiedCallService extends ChangeNotifier {
  static final UnifiedCallService _instance = UnifiedCallService._internal();
  factory UnifiedCallService() => _instance;
  UnifiedCallService._internal() {
    _setupRealServiceListeners();
  }

  // ==================== 服务实例 ====================

  /// 演示模式服务
  final DemoCallService _demoService = DemoCallService();

  /// 真实模式服务
  final RealCallService _realService = RealCallService();

  // ==================== 状态 ====================

  CallStatus _status = CallStatus.idle;
  DemoVolunteer? _currentVolunteer;
  VolunteerInfo? _realVolunteer;
  Duration _callDuration = Duration.zero;
  String? _errorMessage;
  NetworkQuality _networkQuality = NetworkQuality.unknown;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isRecording = false;

  // ==================== 计时器 ====================

  Timer? _durationTimer;
  Timer? _autoEndTimer;

  // ==================== Getters ====================

  CallStatus get status => _status;
  DemoVolunteer? get currentVolunteer => _currentVolunteer;
  VolunteerInfo? get realVolunteer => _realVolunteer;
  Duration get callDuration => _callDuration;
  String? get errorMessage => _errorMessage;
  NetworkQuality get networkQuality => _networkQuality;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isRecording => _isRecording;
  bool get isInCall => _status == CallStatus.connected;
  bool get isConnecting => _status == CallStatus.connecting || _status == CallStatus.ringing;

  String get statusText {
    switch (_status) {
      case CallStatus.connecting:
        return '正在连接...';
      case CallStatus.ringing:
        return '等待接听...';
      case CallStatus.connected:
        return '通话中 ${_formatDuration(_callDuration)}';
      case CallStatus.ended:
        return '通话结束';
      case CallStatus.failed:
        return '连接失败: $_errorMessage';
      default:
        return '';
    }
  }

  String get networkQualityText => NetworkQualityEvaluator.getQualityDescription(_networkQuality);

  // ==================== 服务引用 ====================

  /// 获取当前使用的服务
  dynamic get _currentService => AppConfig.isDemoMode ? _demoService : _realService;

  /// 获取真实通话服务（用于高级功能）
  RealCallService get realCallService => _realService;

  // ==================== 监听器设置 ====================

  void _setupRealServiceListeners() {
    // 监听真实服务的通话状态
    _realService.callStateStream.listen((state) {
      if (!AppConfig.isRealMode) return;

      switch (state) {
        case CallState.connecting:
          _status = CallStatus.connecting;
          break;
        case CallState.ringing:
          _status = CallStatus.ringing;
          break;
        case CallState.connected:
          _status = CallStatus.connected;
          _startDurationTimer();
          break;
        case CallState.ended:
          _status = CallStatus.ended;
          _stopDurationTimer();
          break;
        case CallState.failed:
          _status = CallStatus.failed;
          _stopDurationTimer();
          break;
        default:
          break;
      }
      notifyListeners();
    });

    // 监听网络质量
    _realService.networkQualityStream.listen((quality) {
      _networkQuality = quality;
      notifyListeners();
    });

    // 监听通话时长
    _realService.addListener(() {
      if (AppConfig.isRealMode) {
        _callDuration = _realService.callDuration;
        _isMuted = _realService.isMuted;
        _isSpeakerOn = _realService.isSpeakerOn;
        _isRecording = _realService.isRecording;
        notifyListeners();
      }
    });
  }

  // ==================== 初始化 ====================

  /// 初始化服务
  Future<void> initialize() async {
    if (AppConfig.isRealMode) {
      await _realService.initialize();
    }
  }

  // ==================== 通话控制 ====================

  /// 开始通话（演示模式）
  Future<void> startCall(DemoVolunteer volunteer) async {
    _resetState();
    _currentVolunteer = volunteer;
    _status = CallStatus.connecting;
    notifyListeners();

    if (AppConfig.isDemoMode) {
      await _startDemoCall();
    } else {
      await _startRealCall(volunteer);
    }
  }

  /// 开始真实通话（真实模式）
  Future<void> startRealCall({
    required String seekerId,
    required String helpRequestId,
    required VolunteerInfo volunteer,
  }) async {
    _resetState();
    _realVolunteer = volunteer;
    _status = CallStatus.connecting;
    notifyListeners();

    try {
      await _realService.startCallAsSeeker(
        seekerId: seekerId,
        helpRequestId: helpRequestId,
        volunteer: volunteer,
      );
    } catch (e) {
      _status = CallStatus.failed;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 接听通话（志愿者）
  Future<void> answerCallAsVolunteer({
    required String volunteerId,
    required String seekerId,
    required String helpRequestId,
    required String roomId,
    required VolunteerInfo volunteer,
  }) async {
    _resetState();
    _realVolunteer = volunteer;
    _status = CallStatus.connecting;
    notifyListeners();

    try {
      await _realService.answerCallAsVolunteer(
        volunteerId: volunteerId,
        seekerId: seekerId,
        helpRequestId: helpRequestId,
        roomId: roomId,
        volunteer: volunteer,
      );
    } catch (e) {
      _status = CallStatus.failed;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 演示模式通话
  Future<void> _startDemoCall() async {
    _demoService.addListener(_onDemoServiceUpdate);
    await _demoService.startCall();
    _demoService.removeListener(_onDemoServiceUpdate);

    // 演示模式：30秒后自动结束
    if (AppConfig.isDemoMode) {
      _autoEndTimer?.cancel();
      _autoEndTimer = Timer(
        Duration(seconds: DemoConfig.callAutoEndDuration),
        () => endCall(),
      );
    }
  }

  /// 真实模式通话
  Future<void> _startRealCall(DemoVolunteer volunteer) async {
    try {
      // 将DemoVolunteer转换为VolunteerInfo
      final volunteerInfo = VolunteerInfo(
        id: volunteer.id,
        name: volunteer.name,
        avatar: volunteer.avatar,
        rating: volunteer.rating,
        helpCount: volunteer.helpCount,
        skills: volunteer.skills,
      );

      await _realService.startCallAsSeeker(
        seekerId: 'current_user_id', // 应该从认证服务获取
        helpRequestId: 'help_request_${DateTime.now().millisecondsSinceEpoch}',
        volunteer: volunteerInfo,
      );
    } catch (e) {
      _status = CallStatus.failed;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 静音/取消静音
  Future<void> toggleMute() async {
    if (AppConfig.isDemoMode) {
      // 演示模式：仅切换状态
      _isMuted = !_isMuted;
      notifyListeners();
    } else {
      await _realService.toggleMute();
    }
  }

  /// 切换扬声器
  Future<void> toggleSpeaker() async {
    if (AppConfig.isDemoMode) {
      // 演示模式：仅切换状态
      _isSpeakerOn = !_isSpeakerOn;
      notifyListeners();
    } else {
      await _realService.toggleSpeaker();
    }
  }

  /// 开始录音
  Future<void> startRecording() async {
    if (AppConfig.isDemoMode) {
      // 演示模式：模拟录音
      _isRecording = true;
      notifyListeners();
    } else {
      await _realService.startRecording();
    }
  }

  /// 停止录音
  Future<void> stopRecording() async {
    if (AppConfig.isDemoMode) {
      // 演示模式：模拟停止录音
      _isRecording = false;
      notifyListeners();
    } else {
      await _realService.stopRecording();
    }
  }

  /// 结束通话
  Future<void> endCall() async {
    _autoEndTimer?.cancel();
    _stopDurationTimer();

    if (AppConfig.isDemoMode) {
      await _demoService.hangUp();
    } else {
      await _realService.endCall();
    }

    _status = CallStatus.ended;
    notifyListeners();
  }

  // ==================== 计时器 ====================

  /// 开始计时
  void _startDurationTimer() {
    _autoEndTimer?.cancel();
    _callDuration = Duration.zero;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _callDuration += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  /// 停止计时
  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  // ==================== 状态管理 ====================

  /// 重置状态
  void _resetState() {
    _status = CallStatus.idle;
    _callDuration = Duration.zero;
    _errorMessage = null;
    _networkQuality = NetworkQuality.unknown;
    _isMuted = false;
    _isSpeakerOn = true;
    _isRecording = false;
    _autoEndTimer?.cancel();
    _durationTimer?.cancel();
  }

  /// 演示服务状态更新回调
  void _onDemoServiceUpdate() {
    _status = _convertDemoState(_demoService.state);
    _callDuration = _demoService.callDuration;
    notifyListeners();
  }

  /// 转换演示状态为统一状态
  CallStatus _convertDemoState(DemoCallState state) {
    switch (state) {
      case DemoCallState.connecting:
        return CallStatus.connecting;
      case DemoCallState.ringing:
        return CallStatus.ringing;
      case DemoCallState.connected:
        return CallStatus.connected;
      case DemoCallState.ended:
        return CallStatus.ended;
      default:
        return CallStatus.idle;
    }
  }

  /// 格式化时长
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // ==================== 资源释放 ====================

  @override
  void dispose() {
    _autoEndTimer?.cancel();
    _durationTimer?.cancel();
    _demoService.removeListener(_onDemoServiceUpdate);
    _realService.dispose();
    super.dispose();
  }
}
