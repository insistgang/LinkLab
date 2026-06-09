import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/demo_match_request.dart';
import '../../models/demo_match_result.dart';
import '../../models/demo_volunteer.dart';
import '../../providers/demo_matching_flow_provider.dart';
import '../../providers/facade_providers.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_routes.dart';
import '../../widgets/demo/demo_stage.dart';
import '../../widgets/demo/linkable_icon.dart';
import 'demo_call_screen.dart';

/// 演示版匹配等待頁面。
///
/// 頁面內部 phase 只服務 F9 演示 UI，不新增 help_request 主狀態。
class DemoMatchingScreen extends ConsumerStatefulWidget {
  const DemoMatchingScreen({
    super.key,
    this.initialRequest,
    this.autoRunDemo = true,
  });

  final DemoMatchRequest? initialRequest;
  final bool autoRunDemo;

  @override
  ConsumerState<DemoMatchingScreen> createState() => _DemoMatchingScreenState();
}

class _DemoMatchingScreenState extends ConsumerState<DemoMatchingScreen> {
  final List<Timer> _autoTimers = <Timer>[];
  bool _callNavigationStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_startMatching());
    });
  }

  Future<void> _startMatching() async {
    // Facade 優先：調用 VolunteerMatchingFacade.findVolunteers
    try {
      final facade = ref.read(volunteerMatchingFacadeProvider);
      final result = await facade.findVolunteers(
        intent: widget.initialRequest?.requestType ?? 'general',
        urgency: widget.initialRequest?.urgencyLevel ?? 'normal',
        tags: widget.initialRequest?.preferredSkills ?? const [],
      );
      if (result.success) {
        // Facade 成功，繼續走 demo 流程以驅動 UI 狀態
      }
      // Facade 失敗時靜默降級到舊流程
    } catch (_) {
      // Facade 異常，降級到舊流程
    }

    // Fallback：原有 demo flow
    await ref
        .read(demoMatchingFlowProvider.notifier)
        .start(request: widget.initialRequest);
    if (!mounted || !widget.autoRunDemo) return;
    _scheduleAutoDemo();
  }

  void _scheduleAutoDemo() {
    _clearAutoTimers();
    _queueAutoAction(
      const Duration(milliseconds: 520),
      () => ref.read(demoMatchingFlowProvider.notifier).tryCurrentCandidate(),
    );
    _queueAutoAction(
      const Duration(milliseconds: 1320),
      () => ref
          .read(demoMatchingFlowProvider.notifier)
          .rejectOrTimeoutCurrent(timedOut: true),
    );
    _queueAutoAction(
      const Duration(milliseconds: 2040),
      () => ref.read(demoMatchingFlowProvider.notifier).tryCurrentCandidate(),
    );
    _queueAutoAction(const Duration(milliseconds: 2860), () async {
      await ref
          .read(demoMatchingFlowProvider.notifier)
          .acceptCurrentCandidate();
      if (!mounted) return;
      _queueAutoAction(
        const Duration(milliseconds: 420),
        () async => _enterCall(),
      );
    });
  }

  void _queueAutoAction(Duration delay, Future<void> Function() action) {
    _autoTimers.add(
      Timer(delay, () {
        if (!mounted || !widget.autoRunDemo) return;
        unawaited(action());
      }),
    );
  }

  Future<void> _tryCurrentCandidate() async {
    _clearAutoTimers();
    await ref.read(demoMatchingFlowProvider.notifier).tryCurrentCandidate();
  }

  Future<void> _acceptCurrentCandidate() async {
    _clearAutoTimers();
    // Facade 優先：調用 VolunteerMatchingFacade.acceptVolunteer
    try {
      final facade = ref.read(volunteerMatchingFacadeProvider);
      final matchingState = ref.read(demoMatchingFlowProvider);
      if (matchingState.activeVolunteerId != null) {
        await facade.acceptVolunteer(matchingState.activeVolunteerId!);
      }
    } catch (_) {
      // Facade 異常，降級到舊流程
    }

    // Fallback：原有 demo flow
    await ref.read(demoMatchingFlowProvider.notifier).acceptCurrentCandidate();
  }

  Future<void> _rejectOrTimeoutCurrent() async {
    _clearAutoTimers();
    // Facade 優先：調用 VolunteerMatchingFacade.rejectVolunteer
    try {
      final facade = ref.read(volunteerMatchingFacadeProvider);
      final matchingState = ref.read(demoMatchingFlowProvider);
      if (matchingState.activeVolunteerId != null) {
        await facade.rejectVolunteer(matchingState.activeVolunteerId!);
      }
    } catch (_) {
      // Facade 異常，降級到舊流程
    }

    // Fallback：原有 demo flow
    await ref
        .read(demoMatchingFlowProvider.notifier)
        .rejectOrTimeoutCurrent(timedOut: true);
    if (!mounted) return;
    await ref.read(demoMatchingFlowProvider.notifier).tryCurrentCandidate();
  }

  Future<void> _restartMatching() async {
    _clearAutoTimers();
    _callNavigationStarted = false;
    await ref.read(demoMatchingFlowProvider.notifier).restart();
  }

  Future<void> _expireMatching() async {
    _clearAutoTimers();
    await ref.read(demoMatchingFlowProvider.notifier).expire();
  }

  Future<void> _cancelMatching() async {
    _clearAutoTimers();
    // Facade 優先：調用 VolunteerMatchingFacade.cancelMatching
    try {
      final facade = ref.read(volunteerMatchingFacadeProvider);
      await facade.cancelMatching();
    } catch (_) {
      // Facade 異常，降級到舊流程
    }

    // Fallback：原有 demo flow
    await ref.read(demoMatchingFlowProvider.notifier).cancel();
  }

  Future<void> _enterCall() async {
    if (_callNavigationStarted || !mounted) return;
    _callNavigationStarted = true;
    await replaceWithDemoStageRoute<void, void>(
      context,
      page: const DemoCallScreen(),
    );
  }

  void _clearAutoTimers() {
    for (final timer in _autoTimers) {
      timer.cancel();
    }
    _autoTimers.clear();
  }

  @override
  void dispose() {
    _clearAutoTimers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchingState = ref.watch(demoMatchingFlowProvider);

    return DemoStageLiveBuilder(
      builder: (context) {
        return DemoStageScaffold(
          title: '正在爲你尋找合適的志願者',
          subtitle: 'F9 本地 Top 5 匹配，不依賴真實定位、推送或 Supabase',
          onBackPressed: _cancelMatching,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingL,
              AppTheme.spacingL,
              AppTheme.spacingL,
              AppTheme.spacingL,
            ),
            children: [
              _StatusSummaryCard(state: matchingState),
              const SizedBox(height: AppTheme.spacingM),
              _CandidateSection(state: matchingState),
              const SizedBox(height: AppTheme.spacingL),
              _MatchingActions(
                state: matchingState,
                onTryCandidate: _tryCurrentCandidate,
                onAccept: _acceptCurrentCandidate,
                onRejectOrTimeout: _rejectOrTimeoutCurrent,
                onRestart: _restartMatching,
                onExpire: _expireMatching,
                onCancel: _cancelMatching,
                onEnterCall: _enterCall,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusSummaryCard extends StatelessWidget {
  const _StatusSummaryCard({required this.state});

  final DemoMatchingFlowState state;

  @override
  Widget build(BuildContext context) {
    final icon = _phaseIcon(state.phase);
    final color = AppTheme.stageAccent;

    return Semantics(
      liveRegion: true,
      label: '匹配狀態：${state.statusMessage}',
      child: DemoSurfaceCard(
        color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.96),
        borderColor: color.withValues(alpha: 0.42),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppTheme.spacingS,
              runSpacing: AppTheme.spacingS,
              children: [
                DemoPill(
                  icon: Icons.volunteer_activism_outlined,
                  label: '競賽 Demo 匹配',
                  color: AppTheme.stageAccent,
                ),
                DemoPill(
                  icon: Icons.location_off_outlined,
                  label: '本地模擬距離',
                  color: AppTheme.stageAccent,
                ),
                DemoPill(
                  icon: Icons.notifications_off_outlined,
                  label: '無真實推送',
                  color: AppTheme.stageAccent,
                ),
                DemoPill(
                  svgIcon: LinkableIconName.emergencyDetect,
                  label: '緊急識別',
                  color: AppTheme.stageAccent,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusIcon(icon: icon, color: color),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AccessibleText(
                        state.statusMessage,
                        isHeader: true,
                        style: TextStyle(
                          color: AppTheme.stageTextPrimary,
                          fontSize: AppTheme.fontSizeLarge,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      AccessibleText(
                        '演示中已加速，真實場景最多等待 60 秒。候選人來自本地 demo 數據，不依賴真實在線狀態、真實定位或外部服務。',
                        style: TextStyle(
                          color: AppTheme.stageTextSecondary,
                          fontSize: AppTheme.fontSizeSmall,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: AppTheme.spacingM),
              _InlineNotice(
                icon: Icons.error_outline,
                text: state.errorMessage!,
                color: AppTheme.stageAccent,
              ),
            ],
            if (state.visibleSteps.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingM),
              _PhaseTimeline(steps: state.visibleSteps),
            ],
          ],
        ),
      ),
    );
  }

  IconData _phaseIcon(DemoMatchingUiPhase phase) {
    return switch (phase) {
      DemoMatchingUiPhase.idle => Icons.pending_outlined,
      DemoMatchingUiPhase.analyzing => Icons.psychology_alt_outlined,
      DemoMatchingUiPhase.loadingCandidates => Icons.radar_outlined,
      DemoMatchingUiPhase.candidatesReady => Icons.groups_outlined,
      DemoMatchingUiPhase.waitingForAccept => Icons.hourglass_top_outlined,
      DemoMatchingUiPhase.tryingCandidate => Icons.phone_in_talk_outlined,
      DemoMatchingUiPhase.candidateRejected => Icons.phone_disabled_outlined,
      DemoMatchingUiPhase.candidateTimedOut => Icons.timer_off_outlined,
      DemoMatchingUiPhase.accepted => Icons.check_circle_outline,
      DemoMatchingUiPhase.expired => Icons.event_busy_outlined,
      DemoMatchingUiPhase.cancelled => Icons.cancel_outlined,
      DemoMatchingUiPhase.error => Icons.error_outline,
    };
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: LinkableMaterialIcon(
        icon: icon,
        color: color,
        size: 42,
        semanticLabel: '匹配狀態',
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinkableMaterialIcon(
          icon: icon,
          color: color,
          size: 24,
          semanticLabel: text,
        ),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(
          child: AccessibleText(
            text,
            style: TextStyle(
              color: AppTheme.stageTextPrimary,
              fontSize: AppTheme.fontSizeSmall,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _PhaseTimeline extends StatelessWidget {
  const _PhaseTimeline({required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final step in steps)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LinkableSvgIcon(
                  icon: LinkableIconName.completed,
                  size: 20,
                  semanticLabel: '已完成',
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: AccessibleText(
                    step,
                    style: TextStyle(
                      color: AppTheme.stageTextSecondary,
                      fontSize: AppTheme.fontSizeSmall,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CandidateSection extends StatelessWidget {
  const _CandidateSection({required this.state});

  final DemoMatchingFlowState state;

  @override
  Widget build(BuildContext context) {
    if (state.phase == DemoMatchingUiPhase.analyzing ||
        state.phase == DemoMatchingUiPhase.loadingCandidates ||
        state.phase == DemoMatchingUiPhase.idle) {
      return DemoSurfaceCard(
        child: Column(
          children: [
            LinearProgressIndicator(
              color: AppTheme.stageAccent,
              backgroundColor: AppTheme.stageBorder.withValues(alpha: 0.28),
            ),
            const SizedBox(height: AppTheme.spacingM),
            AccessibleText(
              '正在準備候選人列表...',
              style: TextStyle(
                color: AppTheme.stageTextSecondary,
                fontSize: AppTheme.fontSizeNormal,
              ),
            ),
          ],
        ),
      );
    }

    if (state.candidates.isEmpty) {
      return DemoSurfaceCard(
        semanticLabel: '當前沒有可用志願者',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InlineNotice(
              icon: Icons.group_off_outlined,
              text: '當前沒有可用志願者，請稍後再試或返回 AI 助手。',
              color: AppTheme.stageAccent,
            ),
            const SizedBox(height: AppTheme.spacingS),
            AccessibleText(
              '你可以取消求助，或回到 AI 助手繼續描述問題。',
              style: TextStyle(
                color: AppTheme.stageTextSecondary,
                fontSize: AppTheme.fontSizeSmall,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DemoSectionTitle(
          title: 'Top 5 志願者候選',
          subtitle: '離線志願者已被過濾；推薦理由來自本地 F9-A 匹配引擎。',
          trailing: DemoPill(
            icon: Icons.filter_alt_outlined,
            label: '最多 5 位',
            color: AppTheme.stageAccent,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        for (var index = 0; index < state.candidates.length; index++) ...[
          _VolunteerCandidateCard(
            result: state.candidates[index],
            isCurrent: index == state.currentCandidateIndex,
            isAccepted:
                state.activeVolunteerId == state.candidates[index].volunteer.id,
          ),
          const SizedBox(height: AppTheme.spacingM),
        ],
      ],
    );
  }
}

class _VolunteerCandidateCard extends StatelessWidget {
  const _VolunteerCandidateCard({
    required this.result,
    required this.isCurrent,
    required this.isAccepted,
  });

  final DemoMatchResult result;
  final bool isCurrent;
  final bool isAccepted;

  @override
  Widget build(BuildContext context) {
    final volunteer = result.volunteer;
    final borderColor = isAccepted
        ? AppTheme.stageAccent
        : isCurrent
        ? AppTheme.stageAccent
        : AppTheme.stageBorder;

    return Semantics(
      container: true,
      label:
          '候選志願者第 ${result.rank} 名，${volunteer.nickname}，距離 ${_distanceLabel(volunteer.distanceMeters)}，技能 ${volunteer.skills.join('、')}，信譽 ${_reputationLabel(volunteer.reputationScore)}，${result.reason}',
      child: DemoSurfaceCard(
        color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.96),
        borderColor: borderColor.withValues(alpha: isCurrent ? 0.78 : 0.42),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _VolunteerAvatar(volunteer: volunteer),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppTheme.spacingS,
                        runSpacing: AppTheme.spacingS,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          AccessibleText(
                            '${result.rank}. ${volunteer.nickname}',
                            style: TextStyle(
                              color: AppTheme.stageTextPrimary,
                              fontSize: AppTheme.fontSizeLarge,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          if (isAccepted)
                            DemoPill(
                              icon: Icons.check_circle_outline,
                              label: '已接單',
                              color: AppTheme.stageAccent,
                            )
                          else if (isCurrent)
                            DemoPill(
                              icon: Icons.phone_in_talk_outlined,
                              label: '正在嘗試',
                              color: AppTheme.stageAccent,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      Wrap(
                        spacing: AppTheme.spacingS,
                        runSpacing: AppTheme.spacingS,
                        children: [
                          _MetricPill(
                            icon: Icons.near_me_outlined,
                            label: _distanceLabel(volunteer.distanceMeters),
                          ),
                          _MetricPill(
                            icon: Icons.verified_user_outlined,
                            label:
                                '信譽 ${_reputationLabel(volunteer.reputationScore)}',
                          ),
                          _MetricPill(
                            icon: Icons.history_outlined,
                            label: '幫助 ${volunteer.helpCount} 次',
                          ),
                          _MetricPill(
                            icon: Icons.timer_outlined,
                            label: '預計 ${volunteer.estimatedResponseSeconds} 秒',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            Wrap(
              spacing: AppTheme.spacingS,
              runSpacing: AppTheme.spacingS,
              children: volunteer.skills
                  .map(
                    (skill) =>
                        DemoPill(label: skill, color: AppTheme.stageAccent),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: AppTheme.spacingM),
            _InlineNotice(
              icon: Icons.recommend_outlined,
              text: result.reason,
              color: AppTheme.stageAccent,
            ),
          ],
        ),
      ),
    );
  }

  String _distanceLabel(int meters) {
    if (meters < 1000) return '$meters 米';
    return '${(meters / 1000).toStringAsFixed(1)} 公里';
  }

  String _reputationLabel(double score) {
    return '${(score * 100).round()} 分';
  }
}

class _VolunteerAvatar extends StatelessWidget {
  const _VolunteerAvatar({required this.volunteer});

  final DemoVolunteer volunteer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTheme.stageAccentGradient,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.42),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          volunteer.avatarLabel,
          style: TextStyle(
            color: AppTheme.stageBackground,
            fontSize: AppTheme.fontSizeLarge,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DemoPill(icon: icon, label: label, color: AppTheme.stageAccent);
  }
}

class _MatchingActions extends StatelessWidget {
  const _MatchingActions({
    required this.state,
    required this.onTryCandidate,
    required this.onAccept,
    required this.onRejectOrTimeout,
    required this.onRestart,
    required this.onExpire,
    required this.onCancel,
    required this.onEnterCall,
  });

  final DemoMatchingFlowState state;
  final VoidCallback onTryCandidate;
  final VoidCallback onAccept;
  final VoidCallback onRejectOrTimeout;
  final VoidCallback onRestart;
  final VoidCallback onExpire;
  final VoidCallback onCancel;
  final VoidCallback onEnterCall;

  bool get _canOperate {
    return state.hasCandidates &&
        state.phase != DemoMatchingUiPhase.accepted &&
        state.phase != DemoMatchingUiPhase.expired &&
        state.phase != DemoMatchingUiPhase.cancelled &&
        state.phase != DemoMatchingUiPhase.error;
  }

  @override
  Widget build(BuildContext context) {
    final accepted = state.phase == DemoMatchingUiPhase.accepted;
    return DemoSurfaceCard(
      semanticLabel: '匹配演示操作區',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DemoSectionTitle(
            title: 'Demo 操作',
            subtitle: '這些按鈕只在競賽 Demo 中模擬 F9 狀態變化，不接真實外部服務。',
          ),
          const SizedBox(height: AppTheme.spacingM),
          Wrap(
            spacing: AppTheme.spacingS,
            runSpacing: AppTheme.spacingS,
            children: [
              _DemoActionButton(
                icon: Icons.phone_in_talk_outlined,
                label: '嘗試聯繫',
                semanticLabel: '嘗試聯繫當前候選志願者',
                hint: '雙擊顯示正在嘗試聯繫第一個候選人',
                onTap: _canOperate ? onTryCandidate : null,
              ),
              _DemoActionButton(
                icon: Icons.check_circle_outline,
                label: accepted ? '已接單' : '模擬接單',
                semanticLabel: '模擬接單',
                hint: '雙擊模擬當前志願者成功接單，並進入 connected 狀態',
                onTap: _canOperate ? onAccept : null,
                color: AppTheme.stageAccent,
              ),
              _DemoActionButton(
                icon: Icons.timer_off_outlined,
                label: '模擬拒接 / 超時',
                semanticLabel: '模擬拒接或超時',
                hint: '雙擊讓當前候選人拒接或超時，並嘗試下一位',
                onTap: _canOperate ? onRejectOrTimeout : null,
                color: AppTheme.stageAccent,
              ),
              _DemoActionButton(
                icon: Icons.group_off_outlined,
                label: '模擬無人接單',
                semanticLabel: '模擬無人接單',
                hint: '雙擊將本次匹配標記爲無人接單並進入 expired 狀態',
                onTap: accepted ? null : onExpire,
                color: AppTheme.stageAccent,
              ),
              _DemoActionButton(
                icon: Icons.refresh_rounded,
                label: '重新匹配',
                semanticLabel: '重新匹配',
                hint: '雙擊重置本地匹配並重新生成 Top 5',
                onTap: onRestart,
                color: AppTheme.stageAccent,
              ),
              _DemoActionButton(
                icon: Icons.cancel_outlined,
                label: '取消匹配',
                helperLabel: '取消求助',
                semanticLabel: '取消求助',
                hint: '雙擊取消當前求助並進入 cancelled 狀態',
                onTap: accepted ? null : onCancel,
                color: AppTheme.stageAccent,
              ),
            ],
          ),
          if (accepted) ...[
            const SizedBox(height: AppTheme.spacingM),
            _DemoActionButton(
              icon: Icons.call_outlined,
              label: '進入通話',
              semanticLabel: '進入通話',
              hint: '雙擊進入現有 demo 通話頁面，不建立真實 WebRTC',
              onTap: onEnterCall,
              color: AppTheme.stageAccent,
              expand: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _DemoActionButton extends StatelessWidget {
  const _DemoActionButton({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.hint,
    required this.onTap,
    this.helperLabel,
    this.color,
    this.expand = false,
  });

  final IconData icon;
  final String label;
  final String? helperLabel;
  final String semanticLabel;
  final String hint;
  final VoidCallback? onTap;
  final Color? color;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.stageAccent;
    final enabled = onTap != null;
    final button = Semantics(
      button: true,
      label: semanticLabel,
      hint: hint,
      enabled: enabled,
      child: Material(
        color: enabled
            ? effectiveColor.withValues(alpha: 0.16)
            : AppTheme.stageBorder.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: expand ? 0 : 132,
              minHeight: AppTheme.minTouchTarget + 8,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingM,
                vertical: AppTheme.spacingS,
              ),
              child: Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LinkableMaterialIcon(
                    icon: icon,
                    color: enabled
                        ? effectiveColor
                        : AppTheme.stageTextSecondary,
                    size: 22,
                    semanticLabel: label,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          softWrap: true,
                          style: TextStyle(
                            color: enabled
                                ? AppTheme.stageTextPrimary
                                : AppTheme.stageTextSecondary,
                            fontSize: AppTheme.fontSizeSmall,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (helperLabel != null)
                          Text(
                            helperLabel!,
                            softWrap: true,
                            style: TextStyle(
                              color: AppTheme.stageTextSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
