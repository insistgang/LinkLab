import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/logger.dart';
import '../models/demo_match_request.dart';
import '../models/demo_match_result.dart';
import '../models/help_request_status.dart';
import 'demo_help_request_flow_provider.dart';
import 'demo_services_provider.dart';

enum DemoMatchingUiPhase {
  idle,
  analyzing,
  loadingCandidates,
  candidatesReady,
  waitingForAccept,
  tryingCandidate,
  candidateRejected,
  candidateTimedOut,
  accepted,
  expired,
  cancelled,
  error,
}

final demoMatchingFlowProvider =
    NotifierProvider<DemoMatchingFlowController, DemoMatchingFlowState>(
      DemoMatchingFlowController.new,
    );

@immutable
class DemoMatchingFlowState {
  const DemoMatchingFlowState({
    required this.phase,
    required this.statusMessage,
    this.request,
    this.candidates = const [],
    this.currentCandidateIndex = 0,
    this.activeVolunteerId,
    this.activeVolunteerName,
    this.errorMessage,
    this.visibleSteps = const [],
  });

  const DemoMatchingFlowState.initial()
    : phase = DemoMatchingUiPhase.idle,
      statusMessage = '准备匹配',
      request = null,
      candidates = const [],
      currentCandidateIndex = 0,
      activeVolunteerId = null,
      activeVolunteerName = null,
      errorMessage = null,
      visibleSteps = const [];

  final DemoMatchingUiPhase phase;
  final String statusMessage;
  final DemoMatchRequest? request;
  final List<DemoMatchResult> candidates;
  final int currentCandidateIndex;
  final String? activeVolunteerId;
  final String? activeVolunteerName;
  final String? errorMessage;
  final List<String> visibleSteps;

  bool get hasCandidates => candidates.isNotEmpty;

  bool get isTerminal =>
      phase == DemoMatchingUiPhase.accepted ||
      phase == DemoMatchingUiPhase.expired ||
      phase == DemoMatchingUiPhase.cancelled ||
      phase == DemoMatchingUiPhase.error;

  DemoMatchResult? get currentCandidate {
    if (candidates.isEmpty) return null;
    if (currentCandidateIndex < 0) return candidates.first;
    if (currentCandidateIndex >= candidates.length) return candidates.last;
    return candidates[currentCandidateIndex];
  }

  int get currentCandidateNumber {
    if (candidates.isEmpty) return 0;
    return currentCandidateIndex.clamp(0, candidates.length - 1) + 1;
  }

  DemoMatchingFlowState copyWith({
    DemoMatchingUiPhase? phase,
    String? statusMessage,
    DemoMatchRequest? request,
    List<DemoMatchResult>? candidates,
    int? currentCandidateIndex,
    String? activeVolunteerId,
    String? activeVolunteerName,
    String? errorMessage,
    List<String>? visibleSteps,
    bool clearActiveVolunteer = false,
    bool clearError = false,
  }) {
    return DemoMatchingFlowState(
      phase: phase ?? this.phase,
      statusMessage: statusMessage ?? this.statusMessage,
      request: request ?? this.request,
      candidates: candidates ?? this.candidates,
      currentCandidateIndex:
          currentCandidateIndex ?? this.currentCandidateIndex,
      activeVolunteerId: clearActiveVolunteer
          ? null
          : activeVolunteerId ?? this.activeVolunteerId,
      activeVolunteerName: clearActiveVolunteer
          ? null
          : activeVolunteerName ?? this.activeVolunteerName,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      visibleSteps: visibleSteps ?? this.visibleSteps,
    );
  }
}

class DemoMatchingFlowController extends Notifier<DemoMatchingFlowState> {
  Timer? _matchExpireTimer;
  static const _matchTimeout = Duration(seconds: 60);

  @override
  DemoMatchingFlowState build() {
    ref.onDispose(_cancelTimers);
    return const DemoMatchingFlowState.initial();
  }

  Future<void> start({DemoMatchRequest? request}) async {
    final resolvedRequest = request ?? _requestFromHelpFlow();
    final engine = ref.read(demoMatchingEngineProvider);
    engine.resetCompetition();

    await _ensureHelpRequestIsMatching(resolvedRequest);

    state = DemoMatchingFlowState(
      phase: DemoMatchingUiPhase.analyzing,
      request: resolvedRequest,
      statusMessage: '正在分析需求',
      visibleSteps: const ['正在分析需求'],
    );

    state = state.copyWith(
      phase: DemoMatchingUiPhase.loadingCandidates,
      statusMessage: '正在匹配附近志愿者',
      visibleSteps: _appendStep('正在匹配附近志愿者'),
      clearError: true,
      clearActiveVolunteer: true,
    );

    try {
      final response = await engine.matchTopVolunteers(resolvedRequest);
      if (!response.usesTopFive) {
        state = state.copyWith(
          phase: DemoMatchingUiPhase.error,
          statusMessage: response.message,
          errorMessage: response.message,
          candidates: const [],
          visibleSteps: _appendStep('SOS 已交由 F13 广播流程'),
        );
        return;
      }

      if (response.results.isEmpty) {
        const message = '当前没有可用志愿者，请稍后再试或返回 AI 助手。';
        state = state.copyWith(
          phase: DemoMatchingUiPhase.error,
          statusMessage: message,
          errorMessage: response.message.isEmpty ? message : response.message,
          candidates: const [],
          visibleSteps: _appendStep(message),
        );
        return;
      }

      state = state.copyWith(
        phase: DemoMatchingUiPhase.candidatesReady,
        candidates: response.results,
        currentCandidateIndex: 0,
        statusMessage: '已找到 Top 5 志愿者',
        visibleSteps: _appendStep('已找到 Top 5 志愿者'),
        clearError: true,
        clearActiveVolunteer: true,
      );

      state = state.copyWith(
        phase: DemoMatchingUiPhase.waitingForAccept,
        statusMessage: '等待接单',
        visibleSteps: _appendStep('等待接单'),
      );

      _startMatchExpireTimer();
    } catch (error, stackTrace) {
      AppLogger.error('F9 demo matching flow failed', error, stackTrace);
      state = state.copyWith(
        phase: DemoMatchingUiPhase.error,
        statusMessage: '演示数据暂时不可用，已切换为本地兜底说明。',
        errorMessage: '你可以取消求助，或回到 AI 助手继续描述问题。',
        candidates: const [],
        visibleSteps: _appendStep('匹配服务异常，已显示降级路径'),
      );
    }
  }

  Future<void> tryCurrentCandidate() async {
    final candidate = state.currentCandidate;
    if (candidate == null || state.isTerminal) return;

    state = state.copyWith(
      phase: DemoMatchingUiPhase.tryingCandidate,
      statusMessage:
          '正在尝试联系第 ${state.currentCandidateNumber} 位志愿者：${candidate.volunteer.nickname}',
      visibleSteps: _appendStep('正在尝试联系第 ${state.currentCandidateNumber} 位志愿者'),
    );
  }

  Future<void> rejectOrTimeoutCurrent({bool timedOut = true}) async {
    final candidate = state.currentCandidate;
    if (candidate == null || state.isTerminal) return;

    final action = ref
        .read(demoMatchingEngineProvider)
        .rejectOrTimeout(candidate.volunteer.id);
    if (!action.success) {
      state = state.copyWith(
        phase: DemoMatchingUiPhase.error,
        statusMessage: action.message,
        errorMessage: action.message,
        visibleSteps: _appendStep('候选人状态更新失败'),
      );
      return;
    }

    final nextIndex = state.currentCandidateIndex + 1;
    if (nextIndex >= state.candidates.length) {
      await expire();
      return;
    }

    final skippedNumber = state.currentCandidateNumber;
    final phase = timedOut
        ? DemoMatchingUiPhase.candidateTimedOut
        : DemoMatchingUiPhase.candidateRejected;
    final reasonText = timedOut ? '超时' : '拒接';
    state = state.copyWith(
      phase: phase,
      currentCandidateIndex: nextIndex,
      statusMessage: '第 $skippedNumber 位志愿者$reasonText，正在尝试下一位',
      visibleSteps: _appendStep('上一位暂时无法接听，正在尝试下一位'),
    );
  }

  Future<void> acceptCurrentCandidate() async {
    if (state.activeVolunteerId != null ||
        state.phase == DemoMatchingUiPhase.accepted) {
      return;
    }

    final candidate = state.currentCandidate;
    if (candidate == null) return;

    _cancelTimers();

    final action = ref
        .read(demoMatchingEngineProvider)
        .tryAccept(candidate.volunteer.id);
    if (!action.success) {
      state = state.copyWith(
        phase: DemoMatchingUiPhase.error,
        statusMessage: action.message,
        errorMessage: action.message,
        visibleSteps: _appendStep('接单竞争失败'),
      );
      return;
    }

    await ref
        .read(demoHelpRequestFlowProvider.notifier)
        .markConnected(
          volunteerId: candidate.volunteer.id,
          volunteerName: candidate.volunteer.nickname,
          volunteerSkills: candidate.volunteer.skills,
        );

    state = state.copyWith(
      phase: DemoMatchingUiPhase.accepted,
      activeVolunteerId: candidate.volunteer.id,
      activeVolunteerName: candidate.volunteer.nickname,
      statusMessage: '志愿者已接单',
      visibleSteps: _appendStep('志愿者已接单'),
    );
  }

  Future<void> cancel() async {
    _cancelTimers();
    ref.read(demoMatchingEngineProvider).cancel();
    await ref
        .read(demoHelpRequestFlowProvider.notifier)
        .markCancelled(reason: '用户已取消求助');
    state = state.copyWith(
      phase: DemoMatchingUiPhase.cancelled,
      statusMessage: '用户已取消',
      visibleSteps: _appendStep('用户已取消'),
      clearActiveVolunteer: true,
    );
  }

  Future<void> expire() async {
    _cancelTimers();
    ref.read(demoMatchingEngineProvider).expire();
    await ref.read(demoHelpRequestFlowProvider.notifier).markExpired();
    state = state.copyWith(
      phase: DemoMatchingUiPhase.expired,
      statusMessage: '无人接单，稍后再试',
      visibleSteps: _appendStep('无人接单，稍后再试'),
      clearActiveVolunteer: true,
    );
  }

  Future<void> restart() async {
    final request = state.request;
    ref.read(demoMatchingEngineProvider).resetCompetition();

    final helpFlow = ref.read(demoHelpRequestFlowProvider);
    if (helpFlow.status.isTerminal) {
      ref.read(demoHelpRequestFlowProvider.notifier).reset();
    }

    await start(request: request);
  }

  DemoMatchRequest _requestFromHelpFlow() {
    final flow = ref.read(demoHelpRequestFlowProvider);
    final queryText = _cleanIntent(flow.intent);
    final hasCompleteRequest = flow.requestId != null && queryText.isNotEmpty;

    return DemoMatchRequest(
      requestId: flow.requestId ?? 'demo_match_request',
      queryText: hasCompleteRequest ? queryText : '我在医院找不到科室，需要真人帮忙',
      requestType: hasCompleteRequest ? flow.type : 'hospital_navigation',
      urgencyLevel: hasCompleteRequest ? flow.urgency : '0.6',
      isSos: false,
    );
  }

  Future<void> _ensureHelpRequestIsMatching(DemoMatchRequest request) async {
    final helpFlow = ref.read(demoHelpRequestFlowProvider);
    if (helpFlow.status == HelpRequestStatus.matching) {
      return;
    }

    if (helpFlow.status.isTerminal ||
        helpFlow.status == HelpRequestStatus.connected) {
      ref.read(demoHelpRequestFlowProvider.notifier).reset();
    }

    await ref
        .read(demoHelpRequestFlowProvider.notifier)
        .enterMatching(
          intent: request.queryText,
          type: request.requestType,
          urgency: request.urgencyLevel,
        );
  }

  String _cleanIntent(String? intent) {
    final text = intent?.trim() ?? '';
    if (text.isEmpty) return '';
    return text.replaceFirst(RegExp('^连接真人志愿者[:：]\\s*'), '').trim();
  }

  List<String> _appendStep(String step) {
    final steps = <String>[...state.visibleSteps];
    if (!steps.contains(step)) {
      steps.add(step);
    }
    return List<String>.unmodifiable(steps);
  }

  void _startMatchExpireTimer() {
    _cancelTimers();
    _matchExpireTimer = Timer(_matchTimeout, () {
      if (state.phase == DemoMatchingUiPhase.waitingForAccept ||
          state.phase == DemoMatchingUiPhase.tryingCandidate ||
          state.phase == DemoMatchingUiPhase.candidateRejected ||
          state.phase == DemoMatchingUiPhase.candidateTimedOut) {
        AppLogger.warning('F9 demo matching auto-expired after 60 seconds');
        unawaited(expire());
      }
    });
  }

  void _cancelTimers() {
    _matchExpireTimer?.cancel();
    _matchExpireTimer = null;
  }
}
