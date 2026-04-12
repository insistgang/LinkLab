// 统一SOS服务
// 支持演示模式和真实模式自动切换

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_config.dart';
import 'demo_call_service.dart';
import 'sos_service.dart' as real;

/// SOS状态
enum SOSStatus {
  idle,
  triggering,
  broadcasting,
  waiting,
  responded,
  cancelled,
  resolved,
}

/// 统一SOS服务
/// 根据 AppConfig.mode 自动切换演示/真实模式
class UnifiedSOSService extends ChangeNotifier {
  static final UnifiedSOSService _instance = UnifiedSOSService._internal();
  factory UnifiedSOSService() => _instance;
  UnifiedSOSService._internal();

  // 状态
  SOSStatus _status = SOSStatus.idle;
  int _elapsedSeconds = 0;
  int _responderCount = 0;
  String? _errorMessage;

  // 内部服务实例
  final DemoSOSService _demoService = DemoSOSService();
  Timer? _responseTimer;

  // Getters
  SOSStatus get status => _status;
  int get elapsedSeconds => _elapsedSeconds;
  int get responderCount => _responderCount;
  String? get errorMessage => _errorMessage;
  bool get isActive => _status != SOSStatus.idle && _status != SOSStatus.cancelled && _status != SOSStatus.resolved;

  String get statusText {
    switch (_status) {
      case SOSStatus.triggering:
        return '正在触发SOS...';
      case SOSStatus.broadcasting:
        return '正在广播求助信号...';
      case SOSStatus.waiting:
        return '等待志愿者响应...';
      case SOSStatus.responded:
        return '已有 $_responderCount 位志愿者响应';
      case SOSStatus.cancelled:
        return 'SOS已取消';
      case SOSStatus.resolved:
        return 'SOS已解决';
      default:
        return '长按3秒发送紧急求助';
    }
  }

  /// 触发SOS
  Future<void> triggerSOS() async {
    if (_status != SOSStatus.idle) return;

    _resetState();
    _status = SOSStatus.triggering;
    notifyListeners();

    // 震动反馈
    HapticFeedback.heavyImpact();

    if (AppConfig.isDemoMode) {
      await _triggerDemoSOS();
    } else {
      await _triggerRealSOS();
    }
  }

  /// 演示模式SOS
  Future<void> _triggerDemoSOS() async {
    _demoService.addListener(_onDemoServiceUpdate);
    await _demoService.triggerSOS();
    _demoService.removeListener(_onDemoServiceUpdate);

    // 5秒后自动响应
    _status = SOSStatus.responded;
    _responderCount = 5;
    notifyListeners();
  }

  /// 真实模式SOS
  Future<void> _triggerRealSOS() async {
    try {
      await real.SOSService().triggerSOS(real.SOSTriggerMethod.manual);

      // 监听真实SOS状态
      real.SOSService().sosStateStream.listen((state) {
        switch (state) {
          case real.SOSState.broadcasting:
            _status = SOSStatus.broadcasting;
            break;
          case real.SOSState.waitingResponse:
            _status = SOSStatus.waiting;
            break;
          case real.SOSState.responded:
            _status = SOSStatus.responded;
            _responderCount = 1;
            break;
          case real.SOSState.cancelled:
            _status = SOSStatus.cancelled;
            break;
          case real.SOSState.resolved:
            _status = SOSStatus.resolved;
            break;
          default:
            break;
        }
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// 取消SOS
  Future<void> cancelSOS() async {
    _responseTimer?.cancel();

    if (AppConfig.isDemoMode) {
      _demoService.cancelSOS();
    } else {
      await real.SOSService().cancelSOS();
    }

    _status = SOSStatus.cancelled;
    notifyListeners();
  }

  /// 解决SOS
  Future<void> resolveSOS() async {
    _responseTimer?.cancel();

    if (AppConfig.isDemoMode) {
      _demoService.resolveSOS();
    } else {
      await real.SOSService().resolveSOS();
    }

    _status = SOSStatus.resolved;
    notifyListeners();
  }

  /// 重置状态
  void _resetState() {
    _status = SOSStatus.idle;
    _elapsedSeconds = 0;
    _responderCount = 0;
    _errorMessage = null;
    _responseTimer?.cancel();
  }

  /// 演示服务状态更新回调
  void _onDemoServiceUpdate() {
    _elapsedSeconds = _demoService.elapsedSeconds;
    _responderCount = _demoService.responderCount;

    if (_demoService.isActive) {
      if (_elapsedSeconds < 2) {
        _status = SOSStatus.broadcasting;
      } else {
        _status = SOSStatus.waiting;
      }
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _responseTimer?.cancel();
    _demoService.removeListener(_onDemoServiceUpdate);
    super.dispose();
  }
}
