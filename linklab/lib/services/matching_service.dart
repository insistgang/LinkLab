// AGENTS.md §4.2：競賽版已凍結 Demo 主線。
// 本 facade 保留爲歷史頁面兼容層，默認只返回 Demo 匹配結果。

import 'dart:async';

import '../demo_data/demo_data_exports.dart';
import '../models/call_models.dart';

/// 匹配服務類
/// 負責提供 Demo 匹配結果，真實匹配已隔離到 services/experimental/real/。
class MatchingService {
  static final MatchingService _instance = MatchingService._internal();
  factory MatchingService() => _instance;
  MatchingService._internal();

  final _matchingStateController = StreamController<MatchingState>.broadcast();
  final _matchedVolunteerController =
      StreamController<MatchedVolunteer?>.broadcast();

  Stream<MatchingState> get matchingStateStream =>
      _matchingStateController.stream;
  Stream<MatchedVolunteer?> get matchedVolunteerStream =>
      _matchedVolunteerController.stream;

  String? _currentHelpRequestId;
  String? get currentHelpRequestId => _currentHelpRequestId;
  Timer? _timeoutTimer;
  Timer? _expandTimer;

  Future<MatchingResult?> startMatching({
    required String seekerId,
    required String urgency,
    required Map<String, double> location,
    List<String>? skills,
    String? helpType,
  }) async {
    // AGENTS.md §4.2：真實匹配已隔離到 services/experimental/real/real_matching_service.dart，
    // 競賽版兼容 facade 不再自動觸發真實匹配。
    return _startDemoMatching();
  }

  Future<MatchingResult?> _startDemoMatching() async {
    try {
      _updateMatchingState(MatchingState.searching);

      await Future.delayed(const Duration(seconds: 3));

      final volunteer = demoVolunteers.first;

      _updateMatchingState(MatchingState.matched);

      final matchedVolunteer = MatchedVolunteer(
        id: volunteer.id,
        userId: volunteer.id,
        score: 0.95,
        distance: 1.2,
        skills: volunteer.skills,
      );

      _matchedVolunteerController.add(matchedVolunteer);
      _currentHelpRequestId = 'demo_help_${DateTime.now().millisecondsSinceEpoch}';

      return MatchingResult(
        helpRequestId: _currentHelpRequestId!,
        volunteers: [matchedVolunteer],
        timeoutAt: DateTime.now().add(const Duration(seconds: 30)),
      );
    } catch (e) {
      _updateMatchingState(MatchingState.error);
      throw Exception('演示匹配失敗: $e');
    }
  }

  Future<bool> acceptMatch(String helpRequestId) async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  Future<void> rejectMatch(String helpRequestId) async {}

  Future<void> cancelMatching() async {
    _cancelTimers();
    _updateMatchingState(MatchingState.cancelled);
  }

  void _cancelTimers() {
    _timeoutTimer?.cancel();
    _expandTimer?.cancel();
    _timeoutTimer = null;
    _expandTimer = null;
  }

  void _updateMatchingState(MatchingState state) {
    _matchingStateController.add(state);
  }

  void dispose() {
    _cancelTimers();
    _matchingStateController.close();
    _matchedVolunteerController.close();
  }
}

/// 匹配狀態
enum MatchingState {
  idle,
  searching,
  waitingResponse,
  expandingRange,
  matched,
  noVolunteers,
  convertingToAsync,
  asyncPending,
  cancelled,
  error,
}
