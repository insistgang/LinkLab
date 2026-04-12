// 演示版通话服务
// 模拟通话流程，不建立真实WebRTC连接

import 'dart:async';
import 'package:flutter/material.dart';

/// 演示通话状态
enum DemoCallState {
  idle,
  connecting,    // 正在连接
  ringing,       // 响铃中
  connected,     // 通话中
  ended,         // 已结束
}

/// 演示志愿者数据
class DemoVolunteer {
  final String id;
  final String name;
  final String avatar;
  final double rating;
  final int helpCount;
  final List<String> skills;

  const DemoVolunteer({
    required this.id,
    required this.name,
    required this.avatar,
    required this.rating,
    required this.helpCount,
    required this.skills,
  });
}

/// 预设演示志愿者
const List<DemoVolunteer> demoVolunteers = [
  DemoVolunteer(
    id: 'demo_001',
    name: '张小明',
    avatar: 'assets/images/volunteer1.png',
    rating: 4.9,
    helpCount: 128,
    skills: ['医疗辅助', '出行导航'],
  ),
  DemoVolunteer(
    id: 'demo_002',
    name: '李阿姨',
    avatar: 'assets/images/volunteer2.png',
    rating: 4.8,
    helpCount: 256,
    skills: ['生活常识', '心理支持'],
  ),
  DemoVolunteer(
    id: 'demo_003',
    name: '王医生',
    avatar: 'assets/images/volunteer3.png',
    rating: 5.0,
    helpCount: 89,
    skills: ['医疗辅助', '紧急救助'],
  ),
];

/// 演示版通话服务
class DemoCallService extends ChangeNotifier {
  static final DemoCallService _instance = DemoCallService._internal();
  factory DemoCallService() => _instance;
  DemoCallService._internal();

  DemoCallState _state = DemoCallState.idle;
  DemoVolunteer? _currentVolunteer;
  Duration _callDuration = Duration.zero;
  Timer? _durationTimer;
  Timer? _simulationTimer;

  // Getters
  DemoCallState get state => _state;
  DemoVolunteer? get currentVolunteer => _currentVolunteer;
  Duration get callDuration => _callDuration;
  bool get isInCall => _state == DemoCallState.connected;
  bool get isConnecting => _state == DemoCallState.connecting || _state == DemoCallState.ringing;

  /// 开始模拟通话
  Future<void> startCall() async {
    _state = DemoCallState.connecting;
    notifyListeners();

    // 随机选择一个志愿者
    _currentVolunteer = demoVolunteers[DateTime.now().millisecond % demoVolunteers.length];

    // 模拟连接延迟
    await Future.delayed(const Duration(seconds: 1));

    _state = DemoCallState.ringing;
    notifyListeners();

    // 模拟响铃
    await Future.delayed(const Duration(seconds: 2));

    _state = DemoCallState.connected;
    _startDurationTimer();
    notifyListeners();
  }

  /// 开始计时
  void _startDurationTimer() {
    _durationTimer?.cancel();
    _callDuration = Duration.zero;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _callDuration += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  /// 挂断电话
  Future<void> hangUp() async {
    _durationTimer?.cancel();
    _state = DemoCallState.ended;
    notifyListeners();
  }

  /// 重置状态
  void reset() {
    _durationTimer?.cancel();
    _state = DemoCallState.idle;
    _currentVolunteer = null;
    _callDuration = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _simulationTimer?.cancel();
    super.dispose();
  }
}

/// 演示版匹配服务
class DemoMatchingService extends ChangeNotifier {
  static final DemoMatchingService _instance = DemoMatchingService._internal();
  factory DemoMatchingService() => _instance;
  DemoMatchingService._internal();

  bool _isSearching = false;
  int _elapsedSeconds = 0;
  int _matchedCount = 0;
  Timer? _timer;

  // Getters
  bool get isSearching => _isSearching;
  int get elapsedSeconds => _elapsedSeconds;
  int get matchedCount => _matchedCount;
  String get statusText {
    if (!_isSearching) return '准备匹配';
    if (_elapsedSeconds < 3) return '正在搜索志愿者...';
    return '已找到 $_matchedCount 位志愿者';
  }

  /// 开始匹配（演示版）
  Future<void> startMatching() async {
    _isSearching = true;
    _elapsedSeconds = 0;
    _matchedCount = 0;
    notifyListeners();

    // 模拟匹配过程
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;

      // 第2秒显示找到志愿者
      if (_elapsedSeconds == 2) {
        _matchedCount = 3;
      }

      // 第4秒匹配成功
      if (_elapsedSeconds >= 4) {
        timer.cancel();
        _isSearching = false;
      }

      notifyListeners();
    });

    // 等待匹配完成
    await Future.delayed(const Duration(seconds: 4));
    return;
  }

  /// 取消匹配
  void cancelMatching() {
    _timer?.cancel();
    _isSearching = false;
    _elapsedSeconds = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// 演示版SOS服务
class DemoSOSService extends ChangeNotifier {
  static final DemoSOSService _instance = DemoSOSService._internal();
  factory DemoSOSService() => _instance;
  DemoSOSService._internal();

  bool _isActive = false;
  int _elapsedSeconds = 0;
  int _responderCount = 0;
  Timer? _timer;

  // Getters
  bool get isActive => _isActive;
  int get elapsedSeconds => _elapsedSeconds;
  int get responderCount => _responderCount;
  String get statusText {
    if (!_isActive) return '长按3秒发送紧急求助';
    if (_elapsedSeconds < 3) return '正在发送SOS信号...';
    return '已有 $_responderCount 位志愿者响应';
  }

  /// 触发SOS（演示版）
  Future<void> triggerSOS() async {
    _isActive = true;
    _elapsedSeconds = 0;
    _responderCount = 0;
    notifyListeners();

    // 模拟SOS过程
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;

      // 第3秒显示响应
      if (_elapsedSeconds == 3) {
        _responderCount = 5;
      }

      // 第5秒匹配成功
      if (_elapsedSeconds >= 5) {
        timer.cancel();
      }

      notifyListeners();
    });

    await Future.delayed(const Duration(seconds: 5));
    return;
  }

  /// 取消SOS
  void cancelSOS() {
    _timer?.cancel();
    _isActive = false;
    _elapsedSeconds = 0;
    _responderCount = 0;
    notifyListeners();
  }

  /// 解决SOS
  void resolveSOS() {
    _timer?.cancel();
    _isActive = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
