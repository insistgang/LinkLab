import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/logger.dart';
import '../demo_flow/demo_help_request_tracker.dart';
import '../models/help_request_status.dart';

final demoHelpRequestFlowProvider =
    NotifierProvider<DemoHelpRequestFlowController, DemoHelpRequestFlowState>(
      DemoHelpRequestFlowController.new,
    );

@immutable
class DemoHelpRequestFlowState {
  const DemoHelpRequestFlowState({
    required this.status,
    this.requestId,
    this.intent,
    this.urgency = 'normal',
    this.type = 'ai_auto',
    this.message,
    this.summary,
    this.volunteerId,
    this.volunteerName,
  });

  const DemoHelpRequestFlowState.initial()
    : status = HelpRequestStatus.created,
      requestId = null,
      intent = null,
      urgency = 'normal',
      type = 'ai_auto',
      message = null,
      summary = null,
      volunteerId = null,
      volunteerName = null;

  final HelpRequestStatus status;
  final String? requestId;
  final String? intent;
  final String urgency;
  final String type;
  final String? message;
  final String? summary;
  final String? volunteerId;
  final String? volunteerName;

  DemoHelpRequestFlowState copyWith({
    HelpRequestStatus? status,
    String? requestId,
    String? intent,
    String? urgency,
    String? type,
    String? message,
    String? summary,
    String? volunteerId,
    String? volunteerName,
    bool clearVolunteer = false,
  }) {
    return DemoHelpRequestFlowState(
      status: status ?? this.status,
      requestId: requestId ?? this.requestId,
      intent: intent ?? this.intent,
      urgency: urgency ?? this.urgency,
      type: type ?? this.type,
      message: message ?? this.message,
      summary: summary ?? this.summary,
      volunteerId: clearVolunteer ? null : volunteerId ?? this.volunteerId,
      volunteerName: clearVolunteer
          ? null
          : volunteerName ?? this.volunteerName,
    );
  }
}

class DemoHelpRequestFlowController extends Notifier<DemoHelpRequestFlowState> {
  @override
  DemoHelpRequestFlowState build() {
    return const DemoHelpRequestFlowState.initial();
  }

  Future<void> startAiProcessing({
    required String intent,
    String urgency = 'normal',
  }) async {
    final requestId = await DemoHelpRequestTracker.startCreated(
      intent: intent,
      urgency: urgency,
      type: 'ai_auto',
    );
    state = DemoHelpRequestFlowState(
      status: HelpRequestStatus.created,
      requestId: requestId,
      intent: intent,
      urgency: urgency,
      type: 'ai_auto',
      message: '已创建求助请求',
    );

    await DemoHelpRequestTracker.markAIProcessing(
      requestId: requestId,
      intent: intent,
    );
    _transitionTo(HelpRequestStatus.aiProcessing, message: 'AI 正在分析');
  }

  Future<void> resolveByAI({required String summary}) async {
    _ensureCanTransitionTo(HelpRequestStatus.aiResolved);
    await DemoHelpRequestTracker.markAIResolved(summary: summary);
    _transitionTo(
      HelpRequestStatus.aiResolved,
      message: 'AI 已解决',
      summary: summary,
    );
  }

  Future<void> enterMatching({
    required String intent,
    String type = 'realtime_voice',
    String urgency = 'normal',
  }) async {
    if (state.requestId == null) {
      final requestId = await DemoHelpRequestTracker.startCreated(
        intent: intent,
        urgency: urgency,
        type: type,
      );
      state = DemoHelpRequestFlowState(
        status: HelpRequestStatus.created,
        requestId: requestId,
        intent: intent,
        type: type,
        urgency: urgency,
        message: '已创建求助请求',
      );
    } else {
      state = state.copyWith(intent: intent, type: type, urgency: urgency);
    }

    if (state.status == HelpRequestStatus.created) {
      await DemoHelpRequestTracker.markAIProcessing(
        requestId: state.requestId,
        intent: intent,
      );
      _transitionTo(HelpRequestStatus.aiProcessing, message: 'AI 正在分析');
    }

    _ensureCanTransitionTo(HelpRequestStatus.matching);
    final requestId = await DemoHelpRequestTracker.ensureMatchingRequest(
      intent: intent,
      type: type,
      urgency: urgency,
    );
    state = state.copyWith(
      requestId: requestId,
      intent: intent,
      type: type,
      urgency: urgency,
    );
    _transitionTo(
      HelpRequestStatus.matching,
      message: '正在匹配志愿者',
      clearVolunteer: true,
    );
  }

  Future<void> startSOSUndoWindow({String intent = 'SOS紧急求助'}) async {
    final requestId = await DemoHelpRequestTracker.startSOSUndoWindow(
      intent: intent,
    );
    state = DemoHelpRequestFlowState(
      status: HelpRequestStatus.created,
      requestId: requestId,
      intent: intent,
      urgency: 'emergency',
      type: 'sos',
      message: '已进入 SOS 误触撤销窗口',
    );
  }

  Future<void> markConnected({
    required String volunteerId,
    required String volunteerName,
    List<String> volunteerSkills = const [],
  }) async {
    _ensureCanTransitionTo(HelpRequestStatus.connected);
    await DemoHelpRequestTracker.markConnected(
      volunteerId: volunteerId,
      volunteerName: volunteerName,
      volunteerSkills: volunteerSkills,
    );
    _transitionTo(
      HelpRequestStatus.connected,
      message: '志愿者已接通',
      volunteerId: volunteerId,
      volunteerName: volunteerName,
    );
  }

  Future<void> markExpired() async {
    _ensureCanTransitionTo(HelpRequestStatus.expired);
    await DemoHelpRequestTracker.markExpired();
    _transitionTo(HelpRequestStatus.expired, message: '无人接单，可重新发起');
  }

  Future<void> markCancelled({String? reason}) async {
    _ensureCanTransitionTo(HelpRequestStatus.cancelled);
    await DemoHelpRequestTracker.markCancelled(reason: reason);
    _transitionTo(HelpRequestStatus.cancelled, message: reason ?? '取消成功');
  }

  Future<void> markCompleted({
    int? durationSeconds,
    int? seekerRating,
    String? feedback,
    List<String> ratingTags = const [],
  }) async {
    _ensureCanTransitionTo(HelpRequestStatus.completed);
    await DemoHelpRequestTracker.markCompleted(
      durationSeconds: durationSeconds,
      seekerRating: seekerRating,
      feedback: feedback,
      ratingTags: ratingTags,
    );
    _transitionTo(HelpRequestStatus.completed, message: '帮助已完成');
  }

  Future<void> returnToMatchingAfterDisconnect() async {
    _ensureCanTransitionTo(HelpRequestStatus.matching);
    await DemoHelpRequestTracker.ensureMatchingRequest(
      intent: state.intent ?? '通话掉线后重新匹配',
      type: state.type,
      urgency: state.urgency,
    );
    _transitionTo(
      HelpRequestStatus.matching,
      message: '通话掉线，已重新进入匹配',
      clearVolunteer: true,
    );
  }

  void reset() {
    state = const DemoHelpRequestFlowState.initial();
  }

  void _transitionTo(
    HelpRequestStatus next, {
    String? message,
    String? summary,
    String? volunteerId,
    String? volunteerName,
    bool clearVolunteer = false,
  }) {
    AppLogger.info(
      'Demo help_request controller ${state.status.wireName} -> ${next.wireName}',
    );
    state = state.copyWith(
      status: next,
      message: message,
      summary: summary,
      volunteerId: volunteerId,
      volunteerName: volunteerName,
      clearVolunteer: clearVolunteer,
    );
  }

  void _ensureCanTransitionTo(HelpRequestStatus next) {
    if (state.status.canTransitionTo(next)) {
      return;
    }
    final message =
        '非法 help_request 状态转移：${state.status.wireName} -> ${next.wireName}';
    AppLogger.warning(message);
    throw StateError(message);
  }
}
