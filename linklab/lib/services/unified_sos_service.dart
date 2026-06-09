// AGENTS.md §4.2：競賽版已凍結 Demo 主線，真實路徑僅供實驗，已隔離到 services/experimental/real/。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'demo_call_service.dart';

/// SOS狀態
enum SOSStatus {
  idle,
  triggering,
  broadcasting,
  waiting,
  responded,
  cancelled,
  resolved,
}

/// 統一SOS服務
/// 競賽版默認只調度本地 Demo SOS 流程。
class UnifiedSOSService extends ChangeNotifier {
  static final UnifiedSOSService _instance = UnifiedSOSService._internal();
  factory UnifiedSOSService() => _instance;
  UnifiedSOSService._internal();

  SOSStatus _status = SOSStatus.idle;
  int _elapsedSeconds = 0;
  int _responderCount = 0;
  String? _errorMessage;

  final DemoSOSService _demoService = DemoSOSService();
  Timer? _responseTimer;

  SOSStatus get status => _status;
  int get elapsedSeconds => _elapsedSeconds;
  int get responderCount => _responderCount;
  String? get errorMessage => _errorMessage;
  bool get isActive =>
      _status != SOSStatus.idle &&
      _status != SOSStatus.cancelled &&
      _status != SOSStatus.resolved;

  String get statusText {
    switch (_status) {
      case SOSStatus.triggering:
        return '正在觸發SOS...';
      case SOSStatus.broadcasting:
        return '正在廣播求助信號...';
      case SOSStatus.waiting:
        return '等待志願者響應...';
      case SOSStatus.responded:
        return '已有 $_responderCount 位志願者響應';
      case SOSStatus.cancelled:
        return 'SOS已取消';
      case SOSStatus.resolved:
        return 'SOS已解決';
      default:
        return '長按3秒發送緊急求助';
    }
  }

  Future<void> triggerSOS() async {
    if (_status != SOSStatus.idle) return;

    _resetState();
    _status = SOSStatus.triggering;
    notifyListeners();

    HapticFeedback.heavyImpact();

    // AGENTS.md §4.2：真實 SOS 已隔離到 services/experimental/real/sos_service.dart，
    // 競賽版統一服務不再自動切換到真實路徑。
    await _triggerDemoSOS();
  }

  Future<void> _triggerDemoSOS() async {
    _demoService.addListener(_onDemoServiceUpdate);
    await _demoService.triggerSOS();
    _demoService.removeListener(_onDemoServiceUpdate);

    _status = SOSStatus.responded;
    _responderCount = 5;
    notifyListeners();
  }

  Future<void> cancelSOS() async {
    _responseTimer?.cancel();
    _demoService.cancelSOS();
    _status = SOSStatus.cancelled;
    notifyListeners();
  }

  Future<void> resolveSOS() async {
    _responseTimer?.cancel();
    _demoService.resolveSOS();
    _status = SOSStatus.resolved;
    notifyListeners();
  }

  void _resetState() {
    _status = SOSStatus.idle;
    _elapsedSeconds = 0;
    _responderCount = 0;
    _errorMessage = null;
    _responseTimer?.cancel();
  }

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
