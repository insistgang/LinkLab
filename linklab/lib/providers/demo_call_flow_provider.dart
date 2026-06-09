import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/help_request_status.dart';
import '../core/utils/logger.dart';
import 'demo_help_request_flow_provider.dart';
import 'demo_matching_flow_provider.dart';

enum DemoCallUiPhase {
  idle,
  connecting,
  connected,
  reconnecting,
  ended,
  failed,
}

@immutable
class DemoCallVolunteerSnapshot {
  const DemoCallVolunteerSnapshot({
    required this.id,
    required this.nickname,
    required this.avatarLabel,
    required this.skills,
    required this.distanceLabel,
    required this.reason,
    required this.helpType,
    this.isFallback = false,
  });

  factory DemoCallVolunteerSnapshot.fallback() {
    return const DemoCallVolunteerSnapshot(
      id: 'demo_call_fallback_volunteer',
      nickname: '林同學',
      avatarLabel: '林',
      skills: ['醫院導診', '視障協助'],
      distanceLabel: '本地 Demo',
      reason: '已接通演示志願者',
      helpType: '醫院導診 / 視障協助',
      isFallback: true,
    );
  }

  final String id;
  final String nickname;
  final String avatarLabel;
  final List<String> skills;
  final String distanceLabel;
  final String reason;
  final String helpType;
  final bool isFallback;
}

@immutable
class DemoCallFlowState {
  const DemoCallFlowState({
    required this.phase,
    required this.statusMessage,
    required this.volunteer,
    this.duration = Duration.zero,
    this.isMuted = false,
    this.isSpeakerOn = true,
    this.errorMessage,
  });

  factory DemoCallFlowState.initial() {
    return DemoCallFlowState(
      phase: DemoCallUiPhase.idle,
      statusMessage: '等待進入 Demo 通話',
      volunteer: DemoCallVolunteerSnapshot.fallback(),
    );
  }

  final DemoCallUiPhase phase;
  final String statusMessage;
  final DemoCallVolunteerSnapshot volunteer;
  final Duration duration;
  final bool isMuted;
  final bool isSpeakerOn;
  final String? errorMessage;

  bool get isTerminal =>
      phase == DemoCallUiPhase.ended || phase == DemoCallUiPhase.failed;

  bool get isActive =>
      phase == DemoCallUiPhase.connecting ||
      phase == DemoCallUiPhase.connected ||
      phase == DemoCallUiPhase.reconnecting;

  DemoCallFlowState copyWith({
    DemoCallUiPhase? phase,
    String? statusMessage,
    DemoCallVolunteerSnapshot? volunteer,
    Duration? duration,
    bool? isMuted,
    bool? isSpeakerOn,
    Object? errorMessage = _sentinel,
  }) {
    return DemoCallFlowState(
      phase: phase ?? this.phase,
      statusMessage: statusMessage ?? this.statusMessage,
      volunteer: volunteer ?? this.volunteer,
      duration: duration ?? this.duration,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  static const Object _sentinel = Object();
}

final demoCallFlowProvider =
    NotifierProvider<DemoCallFlowController, DemoCallFlowState>(
      DemoCallFlowController.new,
    );

class DemoCallFlowController extends Notifier<DemoCallFlowState> {
  Timer? _connectTimer;
  Timer? _durationTimer;
  Timer? _reconnectFailureTimer;
  bool _trackDuration = true;

  @override
  DemoCallFlowState build() {
    ref.onDispose(_cancelTimers);
    return DemoCallFlowState.initial();
  }

  Future<void> start({
    Duration autoConnectDelay = const Duration(milliseconds: 650),
    bool autoConnect = true,
    bool trackDuration = true,
  }) async {
    _cancelTimers();
    _trackDuration = trackDuration;
    final volunteer = _resolveVolunteer();

    state = DemoCallFlowState(
      phase: DemoCallUiPhase.connecting,
      statusMessage: '正在建立安全語音連接',
      volunteer: volunteer,
      isSpeakerOn: true,
    );

    try {
      await _ensureHelpRequestConnected(volunteer);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Demo Call failed to sync help_request connected state.',
        error,
        stackTrace,
      );
      state = state.copyWith(
        phase: DemoCallUiPhase.failed,
        statusMessage: '演示通話連接異常',
        errorMessage: '演示通話連接異常，你可以返回匹配重新分配志願者。',
      );
      return;
    }

    AppLogger.info('Demo Call started with local volunteer ${volunteer.id}.');

    if (autoConnect) {
      _connectTimer = Timer(autoConnectDelay, connectNow);
    }
  }

  void connectNow() {
    if (state.phase == DemoCallUiPhase.ended ||
        state.phase == DemoCallUiPhase.failed) {
      return;
    }

    _connectTimer?.cancel();
    _connectTimer = null;
    state = state.copyWith(
      phase: DemoCallUiPhase.connected,
      statusMessage: '通話中',
      errorMessage: null,
    );
    if (_trackDuration) {
      _startDurationTimer();
    }
  }

  void toggleMute() {
    if (!state.isActive) {
      return;
    }
    state = state.copyWith(isMuted: !state.isMuted);
  }

  void toggleSpeaker() {
    if (!state.isActive) {
      return;
    }
    state = state.copyWith(isSpeakerOn: !state.isSpeakerOn);
  }

  void simulateDisconnect({Duration? autoFailDelay}) {
    if (state.phase != DemoCallUiPhase.connected) {
      return;
    }

    _durationTimer?.cancel();
    _durationTimer = null;
    _reconnectFailureTimer?.cancel();
    state = state.copyWith(
      phase: DemoCallUiPhase.reconnecting,
      statusMessage: '正在嘗試恢復連接',
      errorMessage: null,
    );

    AppLogger.warning('Demo Call entered reconnecting phase; '
        'will auto-fail after ${autoFailDelay?.inSeconds ?? 10}s if not restored.');

    final delay = autoFailDelay ?? const Duration(seconds: 10);
    _reconnectFailureTimer = Timer(delay, () {
      unawaited(failReconnect());
    });
  }

  void restoreConnection() {
    if (state.phase != DemoCallUiPhase.reconnecting) {
      return;
    }

    _reconnectFailureTimer?.cancel();
    _reconnectFailureTimer = null;
    state = state.copyWith(
      phase: DemoCallUiPhase.connected,
      statusMessage: '通話中',
      errorMessage: null,
    );
    if (_trackDuration) {
      _startDurationTimer();
    }
  }

  Future<void> failReconnect() async {
    if (state.phase == DemoCallUiPhase.ended ||
        state.phase == DemoCallUiPhase.failed) {
      return;
    }

    _cancelTimers();
    try {
      final helpState = ref.read(demoHelpRequestFlowProvider);
      if (helpState.status == HelpRequestStatus.connected) {
        await ref
            .read(demoHelpRequestFlowProvider.notifier)
            .returnToMatchingAfterDisconnect();
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'Demo Call failed to return help_request to matching.',
        error,
        stackTrace,
      );
    }

    state = state.copyWith(
      phase: DemoCallUiPhase.failed,
      statusMessage: '連接失敗，正在回到匹配',
      errorMessage: '掉線 10 秒未恢復會重新匹配；演示中已加速。',
    );
  }

  Future<void> retryConnection({
    Duration autoConnectDelay = const Duration(milliseconds: 500),
    bool trackDuration = true,
  }) async {
    if (state.phase != DemoCallUiPhase.failed) {
      return;
    }
    await start(
      autoConnectDelay: autoConnectDelay,
      trackDuration: trackDuration,
    );
  }

  Future<void> completeCall() async {
    if (state.phase == DemoCallUiPhase.ended) {
      return;
    }

    _cancelTimers();
    final completedDuration = state.duration;

    try {
      final helpState = ref.read(demoHelpRequestFlowProvider);
      if (helpState.status == HelpRequestStatus.connected) {
        await ref
            .read(demoHelpRequestFlowProvider.notifier)
            .markCompleted(durationSeconds: completedDuration.inSeconds);
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'Demo Call failed to mark help_request completed.',
        error,
        stackTrace,
      );
    }

    state = state.copyWith(
      phase: DemoCallUiPhase.ended,
      statusMessage: '通話已結束',
      duration: completedDuration,
      errorMessage: null,
    );
  }

  DemoCallVolunteerSnapshot _resolveVolunteer() {
    final matchingState = ref.read(demoMatchingFlowProvider);
    final activeVolunteerId = matchingState.activeVolunteerId;
    if (activeVolunteerId != null) {
      for (final result in matchingState.candidates) {
        if (result.volunteer.id == activeVolunteerId) {
          final volunteer = result.volunteer;
          final helpType = result.matchedSkills.isNotEmpty
              ? result.matchedSkills.take(2).join(' / ')
              : volunteer.skills.take(2).join(' / ');
          return DemoCallVolunteerSnapshot(
            id: volunteer.id,
            nickname: volunteer.nickname,
            avatarLabel: volunteer.avatarLabel,
            skills: volunteer.skills,
            distanceLabel: _formatDistance(volunteer.distanceMeters),
            reason: result.reason,
            helpType: helpType.isEmpty ? '語音協助' : helpType,
          );
        }
      }
    }

    final matchingVolunteerName = matchingState.activeVolunteerName;
    if (matchingVolunteerName != null && matchingVolunteerName.isNotEmpty) {
      return DemoCallVolunteerSnapshot(
        id: activeVolunteerId ?? 'demo_matching_active_volunteer',
        nickname: matchingVolunteerName,
        avatarLabel: _firstLabel(matchingVolunteerName),
        skills: const ['醫院導診', '視障協助'],
        distanceLabel: '本地 Demo',
        reason: '已接通演示志願者',
        helpType: '醫院導診 / 視障協助',
      );
    }

    final helpState = ref.read(demoHelpRequestFlowProvider);
    if (helpState.volunteerName != null &&
        helpState.volunteerName!.isNotEmpty) {
      final volunteerName = helpState.volunteerName!;
      return DemoCallVolunteerSnapshot(
        id: helpState.volunteerId ?? 'demo_help_flow_volunteer',
        nickname: volunteerName,
        avatarLabel: _firstLabel(volunteerName),
        skills: const ['醫院導診', '視障協助'],
        distanceLabel: '本地 Demo',
        reason: '已接通演示志願者',
        helpType: '醫院導診 / 視障協助',
      );
    }

    return DemoCallVolunteerSnapshot.fallback();
  }

  Future<void> _ensureHelpRequestConnected(
    DemoCallVolunteerSnapshot volunteer,
  ) async {
    final helpController = ref.read(demoHelpRequestFlowProvider.notifier);
    final helpState = ref.read(demoHelpRequestFlowProvider);

    if (helpState.status == HelpRequestStatus.connected) {
      return;
    }

    if (helpState.status == HelpRequestStatus.matching) {
      await helpController.markConnected(
        volunteerId: volunteer.id,
        volunteerName: volunteer.nickname,
        volunteerSkills: volunteer.skills,
      );
      return;
    }

    if (helpState.status == HelpRequestStatus.created ||
        helpState.status == HelpRequestStatus.aiProcessing) {
      await helpController.enterMatching(
        intent: '進入 F11 Demo Call 前自動補齊匹配態',
        type: 'demo_call',
        urgency: 'normal',
      );
      await helpController.markConnected(
        volunteerId: volunteer.id,
        volunteerName: volunteer.nickname,
        volunteerSkills: volunteer.skills,
      );
      return;
    }

    AppLogger.warning(
      'Demo Call opened while help_request is ${helpState.status.wireName}; '
      'continuing with local fallback UI.',
    );
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.phase != DemoCallUiPhase.connected) {
        return;
      }
      state = state.copyWith(
        duration: state.duration + const Duration(seconds: 1),
      );
    });
  }

  void _cancelTimers() {
    _connectTimer?.cancel();
    _durationTimer?.cancel();
    _reconnectFailureTimer?.cancel();
    _connectTimer = null;
    _durationTimer = null;
    _reconnectFailureTimer = null;
  }

  static String _formatDistance(int meters) {
    if (meters < 1000) {
      return '$meters 米';
    }
    return '${(meters / 1000).toStringAsFixed(1)} 公里';
  }

  static String _firstLabel(String value) {
    if (value.isEmpty) {
      return '?';
    }
    return value.substring(0, 1);
  }
}
