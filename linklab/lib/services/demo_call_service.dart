// 演示版通話服務
// 模擬通話流程，不建立真實WebRTC連接

import 'dart:async';

import 'package:flutter/material.dart';

import '../demo_flow/demo_help_request_tracker.dart';
import '../config/app_config.dart';
import '../models/help_request_status.dart';
// ignore: deprecated_member_use_from_same_package
import 'app_session_service.dart';
import 'local_storage.dart';
import 'user_center/favorite_volunteer_service.dart';

/// 演示通話狀態
enum DemoCallState {
  idle,
  connecting, // 正在連接
  ringing, // 響鈴中
  connected, // 通話中
  ended, // 已結束
}

/// 演示志願者數據
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

/// 預設演示志願者
const List<DemoVolunteer> demoVolunteers = [
  DemoVolunteer(
    id: 'demo_001',
    name: '張小明',
    avatar: '',
    rating: 4.9,
    helpCount: 128,
    skills: ['醫療輔助', '出行導航'],
  ),
  DemoVolunteer(
    id: 'demo_002',
    name: '李阿姨',
    avatar: '',
    rating: 4.8,
    helpCount: 256,
    skills: ['生活常識', '心理支持'],
  ),
  DemoVolunteer(
    id: 'demo_003',
    name: '王醫生',
    avatar: '',
    rating: 5.0,
    helpCount: 89,
    skills: ['醫療輔助', '緊急救助'],
  ),
];

/// 演示版通話服務
class DemoCallService extends ChangeNotifier {
  static final DemoCallService _instance = DemoCallService._internal();
  factory DemoCallService() => _instance;
  DemoCallService._internal();

  final LocalStorage _storage = LocalStorage();
  final FavoriteVolunteerService _favoriteService = FavoriteVolunteerService();

  DemoCallState _state = DemoCallState.idle;
  DemoVolunteer? _currentVolunteer;
  String? _currentHelpRequestId;
  Duration _callDuration = Duration.zero;
  Timer? _durationTimer;
  Timer? _simulationTimer;
  Completer<void>? _simulationDelayCompleter;
  bool _localInitialized = false;
  int _callSequence = 0;
  bool _isMuted = false;
  bool _isSpeakerOn = true;

  // Getters
  DemoCallState get state => _state;
  DemoVolunteer? get currentVolunteer => _currentVolunteer;
  String? get currentHelpRequestId => _currentHelpRequestId;
  Duration get callDuration => _callDuration;
  bool get isInCall => _state == DemoCallState.connected;
  bool get isConnecting =>
      _state == DemoCallState.connecting || _state == DemoCallState.ringing;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;

  Future<void> _ensureLocalStorage() async {
    if (_localInitialized) return;
    await _storage.initialize();
    _localInitialized = true;
  }

  String get _currentSeekerId =>
      AppSessionService.instance.userProfile?.id ?? 'demo-seeker';

  void _ensureDemoFallbackEnabled(String action) {
    if (!AppConfig.shouldUseDemoFallback(feature: action)) {
      throw StateError('$action 僅在 Demo fallback 開啓時可用');
    }
  }

  /// 開始模擬通話
  Future<void> startCall() async {
    _ensureDemoFallbackEnabled('DemoCallService.startCall');
    await _ensureLocalStorage();

    final sequence = ++_callSequence;
    _state = DemoCallState.connecting;
    notifyListeners();

    // 隨機選擇一個志願者
    _currentVolunteer =
        demoVolunteers[DateTime.now().millisecond % demoVolunteers.length];

    // 模擬連接延遲
    if (!await _waitForSimulationDelay(const Duration(seconds: 1), sequence)) {
      return;
    }

    _state = DemoCallState.ringing;
    notifyListeners();

    // 模擬響鈴
    if (!await _waitForSimulationDelay(const Duration(seconds: 2), sequence)) {
      return;
    }

    _state = DemoCallState.connected;
    _startDurationTimer();
    await _createOrUpdateCurrentHelpRecord();
    notifyListeners();
  }

  /// 開始計時
  void _startDurationTimer() {
    _durationTimer?.cancel();
    _callDuration = Duration.zero;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _callDuration += const Duration(seconds: 1);
      notifyListeners();
    });
  }

  /// 掛斷電話
  Future<void> hangUp() async {
    await _ensureLocalStorage();
    _callSequence++;
    _cancelSimulationDelay();
    _durationTimer?.cancel();
    _durationTimer = null;
    _state = DemoCallState.ended;
    _isMuted = false;
    _isSpeakerOn = true;
    await DemoHelpRequestTracker.markCompleted(
      durationSeconds: _callDuration.inSeconds,
    );
    notifyListeners();
  }

  /// 切換靜音狀態
  void toggleMute() {
    if (_state == DemoCallState.connected) {
      _isMuted = !_isMuted;
      notifyListeners();
    }
  }

  /// 切換揚聲器狀態
  void toggleSpeaker() {
    if (_state == DemoCallState.connected) {
      _isSpeakerOn = !_isSpeakerOn;
      notifyListeners();
    }
  }

  /// 保存求助者評價，並同步到幫助檔案和常用志願者
  Future<void> submitSeekerRating({
    required int rating,
    List<String> tags = const [],
    String? feedback,
  }) async {
    await _ensureLocalStorage();

    final volunteer = _currentVolunteer;
    if (_currentHelpRequestId == null || volunteer == null) {
      return;
    }

    final mergedAiResponse = <String, dynamic>{
      'summary': feedback?.trim().isNotEmpty == true
          ? feedback!.trim()
          : '已完成與 ${volunteer.name} 的實時語音協助。',
      'volunteerName': volunteer.name,
      'volunteerSkills': volunteer.skills,
      if (tags.isNotEmpty) 'ratingTags': tags,
      if (feedback?.trim().isNotEmpty == true) 'feedback': feedback!.trim(),
    };

    await DemoHelpRequestTracker.markCompleted(
      durationSeconds: _callDuration.inSeconds,
      seekerRating: rating,
      feedback:
          mergedAiResponse['feedback']?.toString() ??
          mergedAiResponse['summary']?.toString(),
      ratingTags: tags,
    );

    await _upsertCurrentHelpRecord(
      status: HelpRequestStatus.completed.wireName,
      durationSeconds: _callDuration.inSeconds,
      completedAt: DateTime.now(),
      seekerRating: rating,
      aiResponse: mergedAiResponse,
    );

    await _favoriteService.incrementCooperation(
      _currentSeekerId,
      volunteer.id,
      rating: rating,
      volunteerName: volunteer.name,
    );
  }

  /// 重置狀態
  void reset() {
    _callSequence++;
    _cancelSimulationDelay();
    _durationTimer?.cancel();
    _durationTimer = null;
    _state = DemoCallState.idle;
    _currentVolunteer = null;
    _currentHelpRequestId = null;
    _callDuration = Duration.zero;
    _isMuted = false;
    _isSpeakerOn = true;
    DemoHelpRequestTracker.clearCurrentRequest();
    notifyListeners();
  }

  bool _isCurrentStart(int sequence) {
    return sequence == _callSequence && _state != DemoCallState.ended;
  }

  Future<bool> _waitForSimulationDelay(Duration duration, int sequence) async {
    _cancelSimulationDelay();

    final completer = Completer<void>();
    _simulationDelayCompleter = completer;
    _simulationTimer = Timer(duration, () {
      if (!completer.isCompleted) {
        completer.complete();
      }
      if (identical(_simulationDelayCompleter, completer)) {
        _simulationDelayCompleter = null;
        _simulationTimer = null;
      }
    });

    await completer.future;
    return _isCurrentStart(sequence);
  }

  void _cancelSimulationDelay() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    final completer = _simulationDelayCompleter;
    _simulationDelayCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  Future<void> _createOrUpdateCurrentHelpRecord() async {
    final volunteer = _currentVolunteer;
    if (volunteer == null) {
      return;
    }

    _currentHelpRequestId = await DemoHelpRequestTracker.currentRequestId();
    _currentHelpRequestId ??=
        await DemoHelpRequestTracker.ensureMatchingRequest(
          intent: '與 ${volunteer.name} 進行實時語音協助',
          type: 'realtime_voice',
        );

    await DemoHelpRequestTracker.markConnected(
      volunteerId: volunteer.id,
      volunteerName: volunteer.name,
      volunteerSkills: volunteer.skills,
    );

    await _upsertCurrentHelpRecord(
      status: HelpRequestStatus.connected.wireName,
      completedAt: null,
      aiResponse: {
        'summary': '已爲您接通真人志願者，正在進行語音協助。',
        'volunteerName': volunteer.name,
        'volunteerSkills': volunteer.skills,
      },
    );
  }

  Future<void> _upsertCurrentHelpRecord({
    required String status,
    int? durationSeconds,
    int? seekerRating,
    DateTime? completedAt,
    Map<String, dynamic>? aiResponse,
  }) async {
    final volunteer = _currentVolunteer;
    if (_currentHelpRequestId == null || volunteer == null) {
      return;
    }

    final history = _storage.getHelpHistory();
    final existingIndex = history.indexWhere(
      (item) => item['id'] == _currentHelpRequestId,
    );
    final existing = existingIndex >= 0
        ? Map<String, dynamic>.from(history[existingIndex])
        : <String, dynamic>{};
    final existingAiResponse = existing['aiResponse'] is Map
        ? Map<String, dynamic>.from(existing['aiResponse'] as Map)
        : <String, dynamic>{};

    final payload = <String, dynamic>{
      'id': _currentHelpRequestId,
      'seekerId': _currentSeekerId,
      'type': 'realtime_voice',
      'intent': existing['intent'] ?? '與 ${volunteer.name} 進行實時語音協助',
      'urgency': existing['urgency'] ?? 'normal',
      'status': status,
      'volunteerId': volunteer.id,
      'durationSeconds': durationSeconds ?? existing['durationSeconds'],
      'seekerRating': seekerRating ?? existing['seekerRating'],
      'matchedAt': existing['matchedAt'] ?? existing['createdAt'],
      'createdAt': existing['createdAt'] ?? DateTime.now().toIso8601String(),
      'completedAt': completedAt?.toIso8601String() ?? existing['completedAt'],
      'aiResponse': {
        ...existingAiResponse,
        if (aiResponse != null) ...aiResponse,
      },
    };

    await _storage.upsertHelpRecord(payload);
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _cancelSimulationDelay();
    super.dispose();
  }
}

/// 演示版匹配服務
class DemoMatchingService extends ChangeNotifier {
  static final DemoMatchingService _instance = DemoMatchingService._internal();
  factory DemoMatchingService() => _instance;
  DemoMatchingService._internal();

  bool _isSearching = false;
  int _elapsedSeconds = 0;
  int _matchedCount = 0;
  Timer? _timer;
  Completer<void>? _matchingCompleter;

  // Getters
  bool get isSearching => _isSearching;
  int get elapsedSeconds => _elapsedSeconds;
  int get matchedCount => _matchedCount;
  String get statusText {
    if (!_isSearching) return '準備匹配';
    if (_elapsedSeconds < 3) return '正在搜索志願者...';
    return '已找到 $_matchedCount 位志願者';
  }

  /// 開始匹配（演示版）
  Future<void> startMatching() async {
    if (!AppConfig.shouldUseDemoFallback(
      feature: 'DemoMatchingService.startMatching',
    )) {
      throw StateError(
        'DemoMatchingService.startMatching 僅在 Demo fallback 開啓時可用',
      );
    }

    _isSearching = true;
    _elapsedSeconds = 0;
    _matchedCount = 0;
    _timer?.cancel();
    _matchingCompleter = Completer<void>();
    notifyListeners();

    // 模擬匹配過程
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;

      // 第2秒顯示找到志願者
      if (_elapsedSeconds == 2) {
        _matchedCount = 3;
      }

      // 第4秒匹配成功
      if (_elapsedSeconds >= 4) {
        timer.cancel();
        _isSearching = false;
        if (!(_matchingCompleter?.isCompleted ?? true)) {
          _matchingCompleter?.complete();
        }
      }

      notifyListeners();
    });

    await _matchingCompleter?.future;
  }

  /// 取消匹配
  void cancelMatching() {
    _timer?.cancel();
    _isSearching = false;
    _elapsedSeconds = 0;
    _matchedCount = 0;
    if (!(_matchingCompleter?.isCompleted ?? true)) {
      _matchingCompleter?.complete();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// 演示版SOS服務
class DemoSOSService extends ChangeNotifier {
  static final DemoSOSService _instance = DemoSOSService._internal();
  factory DemoSOSService() => _instance;
  DemoSOSService._internal();

  bool _isActive = false;
  int _elapsedSeconds = 0;
  int _responderCount = 0;
  Timer? _timer;
  Completer<void>? _sosCompleter;
  int _sosSequence = 0;

  // Getters
  bool get isActive => _isActive;
  int get elapsedSeconds => _elapsedSeconds;
  int get responderCount => _responderCount;
  String get statusText {
    if (!_isActive) return '長按3秒發送緊急求助';
    if (_elapsedSeconds < 3) return '正在發送SOS信號...';
    return '已有 $_responderCount 位志願者響應';
  }

  /// 觸發SOS（演示版）
  Future<void> triggerSOS() async {
    if (!AppConfig.shouldUseDemoFallback(
      feature: 'DemoSOSService.triggerSOS',
    )) {
      throw StateError('DemoSOSService.triggerSOS 僅在 Demo fallback 開啓時可用');
    }

    _timer?.cancel();
    final sequence = ++_sosSequence;
    _sosCompleter = Completer<void>();
    _isActive = true;
    _elapsedSeconds = 0;
    _responderCount = 0;
    notifyListeners();

    // 模擬SOS過程
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (sequence != _sosSequence) {
        timer.cancel();
        return;
      }

      _elapsedSeconds++;

      // 第3秒顯示響應
      if (_elapsedSeconds == 3) {
        _responderCount = 5;
      }

      // 第5秒匹配成功
      if (_elapsedSeconds >= 5) {
        timer.cancel();
        _timer = null;
        _completeSOSFuture();
      }

      notifyListeners();
    });

    await _sosCompleter?.future;
    return;
  }

  /// 取消SOS
  void cancelSOS() {
    _sosSequence++;
    _timer?.cancel();
    _timer = null;
    _completeSOSFuture();
    _isActive = false;
    _elapsedSeconds = 0;
    _responderCount = 0;
    notifyListeners();
  }

  /// 解決SOS
  void resolveSOS() {
    _sosSequence++;
    _timer?.cancel();
    _timer = null;
    _completeSOSFuture();
    _isActive = false;
    notifyListeners();
  }

  void _completeSOSFuture() {
    if (!(_sosCompleter?.isCompleted ?? true)) {
      _sosCompleter?.complete();
    }
  }

  @override
  void dispose() {
    _sosSequence++;
    _timer?.cancel();
    _timer = null;
    _completeSOSFuture();
    super.dispose();
  }
}
