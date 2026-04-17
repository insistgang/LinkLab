// AGENTS.md §4.2：竞赛版已冻结 Demo 主线，真实路径仅供实验，已隔离到 services/experimental/real/。

import 'dart:async';

import 'package:flutter/material.dart';

import '../config/app_config.dart' show DemoConfig;
import '../models/call_models.dart';
import 'demo_call_service.dart';
import 'experimental/real/real_call_service.dart';
import 'webrtc/webrtc_config.dart';

/// 通话状态
enum CallStatus { idle, connecting, ringing, connected, ended, failed }

/// 统一通话服务
/// 默认只驱动 Demo 通话；历史实验页若显式调用 real API，则只走隔离后的 experimental 实现。
class UnifiedCallService extends ChangeNotifier {
  static final UnifiedCallService _instance = UnifiedCallService._internal();
  factory UnifiedCallService() => _instance;
  UnifiedCallService._internal();

  final DemoCallService _demoService = DemoCallService();
  RealCallService? _experimentalRealService;

  CallStatus _status = CallStatus.idle;
  DemoVolunteer? _currentVolunteer;
  VolunteerInfo? _realVolunteer;
  Duration _callDuration = Duration.zero;
  String? _errorMessage;
  NetworkQuality _networkQuality = NetworkQuality.unknown;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isRecording = false;
  bool _experimentalRealSessionActive = false;
  bool _experimentalListenersBound = false;

  Timer? _durationTimer;
  Timer? _autoEndTimer;

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
  bool get isConnecting =>
      _status == CallStatus.connecting || _status == CallStatus.ringing;

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

  String get networkQualityText =>
      NetworkQualityEvaluator.getQualityDescription(_networkQuality);

  RealCallService get realCallService {
    _experimentalRealService ??= RealCallService();
    _bindExperimentalRealService();
    return _experimentalRealService!;
  }

  void _bindExperimentalRealService() {
    if (_experimentalListenersBound) return;
    _experimentalListenersBound = true;

    realCallService.callStateStream.listen((state) {
      if (!_experimentalRealSessionActive) return;

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
          _experimentalRealSessionActive = false;
          _stopDurationTimer();
          break;
        case CallState.failed:
          _status = CallStatus.failed;
          _experimentalRealSessionActive = false;
          _stopDurationTimer();
          break;
        default:
          break;
      }
      notifyListeners();
    });

    realCallService.networkQualityStream.listen((quality) {
      if (!_experimentalRealSessionActive) return;
      _networkQuality = quality;
      notifyListeners();
    });

    realCallService.addListener(() {
      if (!_experimentalRealSessionActive) return;
      _callDuration = realCallService.callDuration;
      _isMuted = realCallService.isMuted;
      _isSpeakerOn = realCallService.isSpeakerOn;
      _isRecording = realCallService.isRecording;
      _errorMessage = realCallService.errorMessage;
      notifyListeners();
    });
  }

  Future<void> initialize() async {
    // AGENTS.md §4.2：竞赛版默认链路不初始化真实通话依赖。
  }

  Future<void> startCall(DemoVolunteer volunteer) async {
    _resetState();
    _experimentalRealSessionActive = false;
    _currentVolunteer = volunteer;
    _status = CallStatus.connecting;
    notifyListeners();

    await _startDemoCall();
  }

  Future<void> startRealCall({
    required String seekerId,
    required String helpRequestId,
    required VolunteerInfo volunteer,
  }) async {
    // AGENTS.md §4.2：该入口只供历史实验页使用，不进入默认导航和演示脚本。
    _resetState();
    _experimentalRealSessionActive = true;
    _realVolunteer = volunteer;
    _status = CallStatus.connecting;
    notifyListeners();

    try {
      await realCallService.startCallAsSeeker(
        seekerId: seekerId,
        helpRequestId: helpRequestId,
        volunteer: volunteer,
      );
    } catch (e) {
      _status = CallStatus.failed;
      _experimentalRealSessionActive = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> answerCallAsVolunteer({
    required String volunteerId,
    required String seekerId,
    required String helpRequestId,
    required String roomId,
    required VolunteerInfo volunteer,
  }) async {
    // AGENTS.md §4.2：该入口只供历史实验页使用，不进入默认导航和演示脚本。
    _resetState();
    _experimentalRealSessionActive = true;
    _realVolunteer = volunteer;
    _status = CallStatus.connecting;
    notifyListeners();

    try {
      await realCallService.answerCallAsVolunteer(
        volunteerId: volunteerId,
        seekerId: seekerId,
        helpRequestId: helpRequestId,
        roomId: roomId,
        volunteer: volunteer,
      );
    } catch (e) {
      _status = CallStatus.failed;
      _experimentalRealSessionActive = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> _startDemoCall() async {
    _demoService.addListener(_onDemoServiceUpdate);
    await _demoService.startCall();
    _demoService.removeListener(_onDemoServiceUpdate);

    _autoEndTimer?.cancel();
    _autoEndTimer = Timer(
      Duration(seconds: DemoConfig.callAutoEndDuration),
      () => endCall(),
    );
  }

  Future<void> toggleMute() async {
    if (_experimentalRealSessionActive) {
      await realCallService.toggleMute();
      return;
    }

    _isMuted = !_isMuted;
    notifyListeners();
  }

  Future<void> toggleSpeaker() async {
    if (_experimentalRealSessionActive) {
      await realCallService.toggleSpeaker();
      return;
    }

    _isSpeakerOn = !_isSpeakerOn;
    notifyListeners();
  }

  Future<void> startRecording() async {
    if (_experimentalRealSessionActive) {
      await realCallService.startRecording();
      return;
    }

    _isRecording = true;
    notifyListeners();
  }

  Future<void> stopRecording() async {
    if (_experimentalRealSessionActive) {
      await realCallService.stopRecording();
      return;
    }

    _isRecording = false;
    notifyListeners();
  }

  Future<void> endCall() async {
    _autoEndTimer?.cancel();
    _stopDurationTimer();

    if (_experimentalRealSessionActive) {
      await realCallService.endCall();
      _experimentalRealSessionActive = false;
    } else {
      await _demoService.hangUp();
    }

    _status = CallStatus.ended;
    notifyListeners();
  }

  void _startDurationTimer() {
    _autoEndTimer?.cancel();
    _callDuration = Duration.zero;
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _callDuration += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  void _resetState() {
    _status = CallStatus.idle;
    _callDuration = Duration.zero;
    _errorMessage = null;
    _networkQuality = NetworkQuality.unknown;
    _isMuted = false;
    _isSpeakerOn = true;
    _isRecording = false;
    _currentVolunteer = null;
    _realVolunteer = null;
    _autoEndTimer?.cancel();
    _durationTimer?.cancel();
  }

  void _onDemoServiceUpdate() {
    _status = _convertDemoState(_demoService.state);
    _callDuration = _demoService.callDuration;
    notifyListeners();
  }

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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _autoEndTimer?.cancel();
    _durationTimer?.cancel();
    _demoService.removeListener(_onDemoServiceUpdate);
    super.dispose();
  }
}
