import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../demo_data/demo_data_exports.dart';
import '../models/call_models.dart';
import 'real_matching_service.dart';

/// 匹配服务类
/// 负责调用匹配引擎、处理匹配超时和状态管理
class MatchingService {
  static final MatchingService _instance = MatchingService._internal();
  factory MatchingService() => _instance;
  MatchingService._internal();

  SupabaseClient? _supabaseClient;
  SupabaseClient get _supabase {
    if (!Supabase.instance.isInitialized) {
      throw StateError('Supabase not initialized');
    }
    _supabaseClient ??= Supabase.instance.client;
    return _supabaseClient!;
  }

  RealMatchingService? _realMatchingServiceInstance;
  RealMatchingService get _realMatchingService {
    _realMatchingServiceInstance ??= RealMatchingService();
    return _realMatchingServiceInstance!;
  }

  // 状态流
  final _matchingStateController = StreamController<MatchingState>.broadcast();
  final _matchedVolunteerController = StreamController<MatchedVolunteer?>.broadcast();

  Stream<MatchingState> get matchingStateStream => _matchingStateController.stream;
  Stream<MatchedVolunteer?> get matchedVolunteerStream => _matchedVolunteerController.stream;

  // 当前匹配状态
  String? _currentHelpRequestId;
  String? get currentHelpRequestId => _currentHelpRequestId;
  Timer? _timeoutTimer;
  Timer? _expandTimer;
  bool _isRealServiceInitialized = false;

  void _initRealServiceListeners() {
    if (_isRealServiceInitialized || AppConfig.isDemoMode) return;
    _isRealServiceInitialized = true;

    // 监听真实匹配服务的状态变化
    _realMatchingService.matchingStateStream.listen((state) {
      _matchingStateController.add(state);
    });
    _realMatchingService.matchedVolunteerStream.listen((volunteer) {
      _matchedVolunteerController.add(volunteer);
    });
  }

  /// 开始匹配
  ///
  /// [seekerId] 求助者ID
  /// [urgency] 紧急度: normal, important, urgent, emergency
  /// [location] 位置 {lat, lng}
  /// [skills] 需要的技能标签
  /// [helpType] 求助类型描述
  Future<MatchingResult?> startMatching({
    required String seekerId,
    required String urgency,
    required Map<String, double> location,
    List<String>? skills,
    String? helpType,
  }) async {
    // 演示模式
    if (AppConfig.isDemoMode) {
      return await _startDemoMatching();
    }

    // 真实模式 - 使用RealMatchingService
    _initRealServiceListeners();
    return await _realMatchingService.findMatches(
      seekerId: seekerId,
      urgency: _parseUrgency(urgency),
      location: Location(
        latitude: location['lat'] ?? 0,
        longitude: location['lng'] ?? 0,
      ),
      skills: skills ?? [],
      helpType: helpType,
    );
  }

  /// 解析紧急度字符串
  UrgencyLevel _parseUrgency(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'emergency':
        return UrgencyLevel.emergency;
      case 'urgent':
        return UrgencyLevel.urgent;
      case 'important':
        return UrgencyLevel.important;
      default:
        return UrgencyLevel.normal;
    }
  }

  /// 演示模式匹配
  Future<MatchingResult?> _startDemoMatching() async {
    try {
      _updateMatchingState(MatchingState.searching);

      // 模拟延迟3秒
      await Future.delayed(const Duration(seconds: 3));

      // 返回预设志愿者
      final volunteer = demoVolunteers.first;

      _updateMatchingState(MatchingState.matched);

      // 转换为MatchingResult格式
      final matchedVolunteer = MatchedVolunteer(
        id: volunteer.id,
        userId: volunteer.id,
        score: 0.95,
        distance: 1.2,
        skills: volunteer.skills,
      );

      _matchedVolunteerController.add(matchedVolunteer);

      return MatchingResult(
        helpRequestId: 'demo_help_${DateTime.now().millisecondsSinceEpoch}',
        volunteers: [matchedVolunteer],
        timeoutAt: DateTime.now().add(const Duration(seconds: 30)),
      );
    } catch (e) {
      _updateMatchingState(MatchingState.error);
      throw Exception('演示匹配失败: $e');
    }
  }

  /// 接受匹配（志愿者端）
  Future<bool> acceptMatch(String helpRequestId) async {
    if (AppConfig.isDemoMode) {
      // 演示模式直接返回成功
      await Future.delayed(const Duration(seconds: 1));
      return true;
    }
    return await _realMatchingService.acceptMatch(helpRequestId);
  }

  /// 拒绝匹配（志愿者端）
  Future<void> rejectMatch(String helpRequestId) async {
    if (AppConfig.isDemoMode) {
      return;
    }
    await _realMatchingService.rejectMatch(helpRequestId);
  }

  /// 取消匹配
  Future<void> cancelMatching() async {
    _cancelTimers();

    if (AppConfig.isDemoMode) {
      _updateMatchingState(MatchingState.cancelled);
      return;
    }

    await _realMatchingService.cancelMatching();
  }

  /// 取消定时器
  void _cancelTimers() {
    _timeoutTimer?.cancel();
    _expandTimer?.cancel();
    _timeoutTimer = null;
    _expandTimer = null;
  }

  /// 更新匹配状态
  void _updateMatchingState(MatchingState state) {
    _matchingStateController.add(state);
  }

  /// 释放资源
  void dispose() {
    _cancelTimers();
    _matchingStateController.close();
    _matchedVolunteerController.close();
    _realMatchingService.dispose();
  }
}

/// 匹配状态
enum MatchingState {
  idle,               // 空闲
  searching,          // 搜索中
  waitingResponse,    // 等待志愿者响应
  expandingRange,     // 扩大搜索范围
  matched,            // 匹配成功
  noVolunteers,       // 无可用志愿者
  convertingToAsync,  // 转为异步中
  asyncPending,       // 异步等待中
  cancelled,          // 已取消
  error,              // 错误
}
