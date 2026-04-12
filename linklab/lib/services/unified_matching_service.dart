// 统一匹配服务
// 支持演示模式和真实模式自动切换

import 'dart:async';
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import 'demo_call_service.dart';
import 'matching_service.dart' as real;

/// 匹配状态
enum MatchingStatus {
  idle,
  searching,
  found,
  timeout,
  error,
}

/// 统一匹配服务
/// 根据 AppConfig.mode 自动切换演示/真实模式
class UnifiedMatchingService extends ChangeNotifier {
  static final UnifiedMatchingService _instance = UnifiedMatchingService._internal();
  factory UnifiedMatchingService() => _instance;
  UnifiedMatchingService._internal();

  // 状态
  MatchingStatus _status = MatchingStatus.idle;
  int _elapsedSeconds = 0;
  int _matchedCount = 0;
  DemoVolunteer? _matchedVolunteer;
  String? _errorMessage;

  // 内部服务实例
  final DemoMatchingService _demoService = DemoMatchingService();
  Timer? _timer;

  // Getters
  MatchingStatus get status => _status;
  int get elapsedSeconds => _elapsedSeconds;
  int get matchedCount => _matchedCount;
  DemoVolunteer? get matchedVolunteer => _matchedVolunteer;
  String? get errorMessage => _errorMessage;
  bool get isSearching => _status == MatchingStatus.searching;

  String get statusText {
    switch (_status) {
      case MatchingStatus.searching:
        if (_elapsedSeconds < 2) return '正在搜索志愿者...';
        return '已找到 $_matchedCount 位志愿者';
      case MatchingStatus.found:
        return '匹配成功';
      case MatchingStatus.timeout:
        return '匹配超时';
      case MatchingStatus.error:
        return '匹配失败: $_errorMessage';
      default:
        return '准备匹配';
    }
  }

  /// 开始匹配
  Future<DemoVolunteer?> startMatching() async {
    _resetState();
    _status = MatchingStatus.searching;
    notifyListeners();

    if (AppConfig.isDemoMode) {
      return await _startDemoMatching();
    } else {
      return await _startRealMatching();
    }
  }

  /// 演示模式匹配
  Future<DemoVolunteer?> _startDemoMatching() async {
    // 使用演示服务
    await _demoService.startMatching();

    // 监听演示服务状态
    _demoService.addListener(_onDemoServiceUpdate);

    // 等待匹配完成
    while (_demoService.isSearching) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _demoService.removeListener(_onDemoServiceUpdate);

    // 获取匹配结果
    _matchedCount = _demoService.matchedCount;
    _matchedVolunteer = demoVolunteers[DateTime.now().millisecond % demoVolunteers.length];
    _status = MatchingStatus.found;
    notifyListeners();

    return _matchedVolunteer;
  }

  /// 真实模式匹配
  Future<DemoVolunteer?> _startRealMatching() async {
    try {
      // 调用真实匹配服务
      final result = await real.MatchingService().startMatching(
        seekerId: 'current_user_id',
        urgency: 'normal',
        location: {'lat': 39.9042, 'lng': 116.4074},
      );

      if (result != null && result.volunteers.isNotEmpty) {
        _matchedCount = result.volunteers.length;
        // 转换真实志愿者数据为演示格式
        _matchedVolunteer = _convertToDemoVolunteer(result.volunteers.first);
        _status = MatchingStatus.found;
      } else {
        _status = MatchingStatus.timeout;
      }
    } catch (e) {
      _status = MatchingStatus.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
    return _matchedVolunteer;
  }

  /// 取消匹配
  Future<void> cancelMatching() async {
    _timer?.cancel();

    if (AppConfig.isDemoMode) {
      _demoService.cancelMatching();
    }

    _status = MatchingStatus.idle;
    notifyListeners();
  }

  /// 重置状态
  void _resetState() {
    _status = MatchingStatus.idle;
    _elapsedSeconds = 0;
    _matchedCount = 0;
    _matchedVolunteer = null;
    _errorMessage = null;
    _timer?.cancel();
  }

  /// 演示服务状态更新回调
  void _onDemoServiceUpdate() {
    _elapsedSeconds = _demoService.elapsedSeconds;
    _matchedCount = _demoService.matchedCount;
    notifyListeners();
  }

  /// 转换真实志愿者为演示格式
  DemoVolunteer _convertToDemoVolunteer(dynamic volunteer) {
    return DemoVolunteer(
      id: volunteer.id ?? 'unknown',
      name: '志愿者${volunteer.id?.substring(0, 4) ?? ''}',
      avatar: 'assets/images/volunteer_default.png',
      rating: 4.8,
      helpCount: 100,
      skills: volunteer.skills ?? ['一般帮助'],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _demoService.removeListener(_onDemoServiceUpdate);
    super.dispose();
  }
}
