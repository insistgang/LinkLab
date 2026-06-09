// AGENTS.md §4.2：競賽版已凍結 Demo 主線，真實路徑僅供實驗，已隔離到 services/experimental/real/。

import 'dart:async';

import 'package:flutter/material.dart';

import 'demo_call_service.dart';

/// 匹配狀態
enum MatchingStatus { idle, searching, found, timeout, error }

/// 統一匹配服務
/// 競賽版默認只調度本地 Demo 匹配，不再自動切到真實鏈路。
class UnifiedMatchingService extends ChangeNotifier {
  static final UnifiedMatchingService _instance =
      UnifiedMatchingService._internal();
  factory UnifiedMatchingService() => _instance;
  UnifiedMatchingService._internal();

  MatchingStatus _status = MatchingStatus.idle;
  int _elapsedSeconds = 0;
  int _matchedCount = 0;
  DemoVolunteer? _matchedVolunteer;
  String? _errorMessage;

  final DemoMatchingService _demoService = DemoMatchingService();
  Timer? _timer;

  MatchingStatus get status => _status;
  int get elapsedSeconds => _elapsedSeconds;
  int get matchedCount => _matchedCount;
  DemoVolunteer? get matchedVolunteer => _matchedVolunteer;
  String? get errorMessage => _errorMessage;
  bool get isSearching => _status == MatchingStatus.searching;

  String get statusText {
    switch (_status) {
      case MatchingStatus.searching:
        if (_elapsedSeconds < 2) return '正在搜索志願者...';
        return '已找到 $_matchedCount 位志願者';
      case MatchingStatus.found:
        return '匹配成功';
      case MatchingStatus.timeout:
        return '匹配超時';
      case MatchingStatus.error:
        return '匹配失敗: $_errorMessage';
      default:
        return '準備匹配';
    }
  }

  Future<DemoVolunteer?> startMatching() async {
    _resetState();
    _status = MatchingStatus.searching;
    notifyListeners();

    // AGENTS.md §4.2：真實匹配已隔離到 services/experimental/real/real_matching_service.dart，
    // 競賽版統一服務不再自動切換到真實路徑。
    return _startDemoMatching();
  }

  Future<DemoVolunteer?> _startDemoMatching() async {
    await _demoService.startMatching();
    _demoService.addListener(_onDemoServiceUpdate);

    while (_demoService.isSearching) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _demoService.removeListener(_onDemoServiceUpdate);

    _matchedCount = _demoService.matchedCount;
    _matchedVolunteer =
        demoVolunteers[DateTime.now().millisecond % demoVolunteers.length];
    _status = MatchingStatus.found;
    notifyListeners();

    return _matchedVolunteer;
  }

  Future<void> cancelMatching() async {
    _timer?.cancel();
    _demoService.cancelMatching();
    _status = MatchingStatus.idle;
    notifyListeners();
  }

  void _resetState() {
    _status = MatchingStatus.idle;
    _elapsedSeconds = 0;
    _matchedCount = 0;
    _matchedVolunteer = null;
    _errorMessage = null;
    _timer?.cancel();
  }

  void _onDemoServiceUpdate() {
    _elapsedSeconds = _demoService.elapsedSeconds;
    _matchedCount = _demoService.matchedCount;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _demoService.removeListener(_onDemoServiceUpdate);
    super.dispose();
  }
}
