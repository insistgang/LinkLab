import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/call_camera_provider.dart';
import '../../providers/demo_call_flow_provider.dart';
import '../../providers/facade_providers.dart';
import '../../services/demo_call_service.dart' show DemoVolunteer;
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_overlays.dart';
import '../../widgets/demo/demo_routes.dart';
import '../../widgets/demo/demo_stage.dart';
import '../../widgets/demo/linkable_icon.dart';
import 'demo_call_rating_screen.dart';
import 'demo_matching_screen.dart';

/// F11 竞赛 Demo 通话页。
///
/// 该页只展示本地可复现的语音协助闭环，不建立真实 WebRTC、不录音、
/// 不请求真实麦克风权限。
class DemoCallScreen extends ConsumerStatefulWidget {
  const DemoCallScreen({
    super.key,
    this.autoStart = true,
    this.autoConnectDelay = const Duration(milliseconds: 650),
    this.trackDuration = true,
  });

  final bool autoStart;
  final Duration autoConnectDelay;
  final bool trackDuration;

  @override
  ConsumerState<DemoCallScreen> createState() => _DemoCallScreenState();
}

class _DemoCallScreenState extends ConsumerState<DemoCallScreen> {
  bool _navigatingToRating = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        // Facade 优先：调用 CallSessionFacade.startCall
        _startCallWithFacade();
        // Fallback：原有 demo flow（始终执行以驱动 UI 状态）
        ref
            .read(demoCallFlowProvider.notifier)
            .start(
              autoConnectDelay: widget.autoConnectDelay,
              trackDuration: widget.trackDuration,
            );
      });
    }
  }

  Future<void> _startCallWithFacade() async {
    try {
      final facade = ref.read(callSessionFacadeProvider);
      await facade.startCall('demo-volunteer-001');
    } catch (_) {
      // Facade 异常，demo flow 已在 fallback 中启动
    }
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(demoCallFlowProvider);
    final cameraState = ref.watch(callCameraProvider);

    return DemoStageScaffold(
      title: '实时语音协助',
      subtitle: 'F11 本地 Demo Call，可开启本机摄像头预览',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingM,
          AppTheme.spacingL,
          AppTheme.spacingM,
          AppTheme.spacingXXL,
        ),
        children: [
          _CallStatusCard(state: callState),
          const SizedBox(height: AppTheme.spacingM),
          _VolunteerCard(volunteer: callState.volunteer),
          const SizedBox(height: AppTheme.spacingM),
          _DemoVoiceCard(state: callState),
          const SizedBox(height: AppTheme.spacingM),
          _CallCameraCard(
            callState: callState,
            cameraState: cameraState,
            onStartPreview: () =>
                ref.read(callCameraProvider.notifier).startPreview(),
            onStopPreview: () =>
                ref.read(callCameraProvider.notifier).stopPreview(),
          ),
          const SizedBox(height: AppTheme.spacingM),
          _DemoNoticeCard(state: callState),
          const SizedBox(height: AppTheme.spacingM),
          _CallControls(
            state: callState,
            onToggleMute: () =>
                ref.read(demoCallFlowProvider.notifier).toggleMute(),
            onToggleSpeaker: () =>
                ref.read(demoCallFlowProvider.notifier).toggleSpeaker(),
            onEndCall: _endCall,
            onSimulateDisconnect: () =>
                ref.read(demoCallFlowProvider.notifier).simulateDisconnect(),
            onRestoreConnection: () =>
                ref.read(demoCallFlowProvider.notifier).restoreConnection(),
            onFailReconnect: () =>
                ref.read(demoCallFlowProvider.notifier).failReconnect(),
            onRetryConnection: () => ref
                .read(demoCallFlowProvider.notifier)
                .retryConnection(trackDuration: widget.trackDuration),
            onReturnToMatching: _returnToMatching,
            onShowSafety: _showSafetyNotice,
          ),
        ],
      ),
    );
  }

  Future<void> _endCall() async {
    if (_navigatingToRating) {
      return;
    }
    _navigatingToRating = true;
    await ref.read(callCameraProvider.notifier).stopPreview();

    // Facade 优先：调用 CallSessionFacade.endCall
    try {
      final facade = ref.read(callSessionFacadeProvider);
      final result = await facade.endCall();
      if (!result.success) {
        // Facade 失败，继续走 fallback
      }
    } catch (_) {
      // Facade 异常，降级到旧流程
    }

    // Fallback：原有 demo flow
    final controller = ref.read(demoCallFlowProvider.notifier);
    await controller.completeCall();
    final completedState = ref.read(demoCallFlowProvider);

    if (!mounted) {
      return;
    }

    await replaceWithDemoStageRoute<void, void>(
      context,
      page: DemoCallRatingScreen(
        volunteer: _toRatingVolunteer(completedState.volunteer),
        duration: completedState.duration,
      ),
    );
  }

  Future<void> _returnToMatching() async {
    await ref.read(callCameraProvider.notifier).stopPreview();
    await ref.read(demoCallFlowProvider.notifier).failReconnect();
    if (!mounted) {
      return;
    }
    await replaceWithDemoStageRoute<void, void>(
      context,
      page: const DemoMatchingScreen(autoRunDemo: false),
    );
  }

  void _showSafetyNotice() {
    showDemoStageSnackBar(
      context,
      icon: Icons.privacy_tip_outlined,
      accentColor: AppTheme.stageWarning,
      message: '竞赛 Demo 不录音、不上传通话内容；如遇不适可结束通话或回到匹配。',
    );
  }

  DemoVolunteer _toRatingVolunteer(DemoCallVolunteerSnapshot snapshot) {
    return DemoVolunteer(
      id: snapshot.id,
      name: snapshot.nickname,
      avatar: snapshot.avatarLabel,
      rating: 4.9,
      helpCount: 128,
      skills: snapshot.skills.isEmpty ? const ['语音协助'] : snapshot.skills,
    );
  }
}

class _CallStatusCard extends StatelessWidget {
  const _CallStatusCard({required this.state});

  final DemoCallFlowState state;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(state.phase);
    final icon = _statusIcon(state.phase);

    return DemoSurfaceCard(
      semanticLabel: '实时语音协助状态，${state.statusMessage}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DemoGlassIconBadge(
                icon: icon,
                size: 56,
                iconColor: statusColor,
                semanticLabel: '连接状态图标',
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AccessibleText(
                      state.statusMessage,
                      style: TextStyle(
                        color: AppTheme.stageTextPrimary,
                        fontSize: AppTheme.fontSizeLarge,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    AccessibleText(
                      _statusDescription(state),
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
          const SizedBox(height: AppTheme.spacingM),
          Wrap(
            spacing: AppTheme.spacingS,
            runSpacing: AppTheme.spacingS,
            children: [
              DemoPill(
                label: '本地 Demo Call',
                icon: Icons.bolt_outlined,
                color: AppTheme.stageAccent,
              ),
              DemoPill(
                label: '志愿者已接单',
                icon: Icons.verified_user_outlined,
                color: AppTheme.stageSuccess,
              ),
              DemoPill(
                label: '无真实 WebRTC',
                icon: Icons.cloud_off_outlined,
                color: AppTheme.stageInfo,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _statusColor(DemoCallUiPhase phase) {
    return switch (phase) {
      DemoCallUiPhase.connected => AppTheme.stageSuccess,
      DemoCallUiPhase.reconnecting => AppTheme.stageWarning,
      DemoCallUiPhase.failed => AppTheme.stageDanger,
      DemoCallUiPhase.ended => AppTheme.stageInfo,
      _ => AppTheme.stageAccent,
    };
  }

  static IconData _statusIcon(DemoCallUiPhase phase) {
    return switch (phase) {
      DemoCallUiPhase.connecting => Icons.sync_outlined,
      DemoCallUiPhase.connected => Icons.call_outlined,
      DemoCallUiPhase.reconnecting => Icons.wifi_off_outlined,
      DemoCallUiPhase.ended => Icons.check_circle_outline,
      DemoCallUiPhase.failed => Icons.error_outline,
      DemoCallUiPhase.idle => Icons.hourglass_empty_outlined,
    };
  }

  static String _statusDescription(DemoCallFlowState state) {
    return switch (state.phase) {
      DemoCallUiPhase.idle => '等待从匹配页进入通话流程。',
      DemoCallUiPhase.connecting => '正在建立安全语音连接，演示中不会访问真实麦克风。',
      DemoCallUiPhase.connected =>
        '已接通，通话时长 ${_formatDuration(state.duration)}。',
      DemoCallUiPhase.reconnecting => '模拟掉线中；真实规则是 10 秒未恢复会重新匹配。',
      DemoCallUiPhase.ended => '帮助已完成，可以进入感谢与评分页。',
      DemoCallUiPhase.failed => state.errorMessage ?? '连接失败，你可以重新连接或回到匹配页。',
    };
  }
}

class _VolunteerCard extends StatelessWidget {
  const _VolunteerCard({required this.volunteer});

  final DemoCallVolunteerSnapshot volunteer;

  @override
  Widget build(BuildContext context) {
    return DemoSurfaceCard(
      semanticLabel:
          '已接单志愿者，${volunteer.nickname}，技能 ${volunteer.skills.join('，')}，${volunteer.distanceLabel}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DemoSectionTitle(
            title: '已接单志愿者',
            subtitle: '优先读取 F9 Top 5 已接单结果，缺失时使用本地稳定兜底。',
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.stageAccent.withValues(alpha: 0.22),
                child: AccessibleText(
                  volunteer.avatarLabel,
                  style: TextStyle(
                    color: AppTheme.stageAccentLight,
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AccessibleText(
                      volunteer.nickname,
                      style: TextStyle(
                        color: AppTheme.stageTextPrimary,
                        fontSize: AppTheme.fontSizeLarge,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    AccessibleText(
                      '${volunteer.helpType} · ${volunteer.distanceLabel}',
                      style: TextStyle(
                        color: AppTheme.stageTextSecondary,
                        fontSize: AppTheme.fontSizeSmall,
                      ),
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
            children: [
              for (final skill in volunteer.skills.take(4))
                DemoPill(
                  label: skill,
                  icon: Icons.label_important_outline,
                  color: AppTheme.stageInfo,
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          _InfoLine(icon: Icons.recommend_outlined, text: volunteer.reason),
          if (volunteer.isFallback) ...[
            const SizedBox(height: AppTheme.spacingS),
            const _InfoLine(icon: Icons.info_outline, text: '当前使用演示志愿者继续通话流程。'),
          ],
        ],
      ),
    );
  }
}

class _DemoVoiceCard extends StatelessWidget {
  const _DemoVoiceCard({required this.state});

  final DemoCallFlowState state;

  @override
  Widget build(BuildContext context) {
    final active = state.phase == DemoCallUiPhase.connected;

    return DemoSurfaceCard(
      semanticLabel: '通话波形与时长，当前${state.statusMessage}',
      color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.92),
      child: Column(
        children: [
          AccessibleText(
            _formatDuration(state.duration),
            style: TextStyle(
              color: AppTheme.stageTextPrimary,
              fontSize: AppTheme.fontSizeXLarge,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          AccessibleText(
            active ? '语音协助进行中' : state.statusMessage,
            style: TextStyle(
              color: active
                  ? AppTheme.stageSuccess
                  : AppTheme.stageTextSecondary,
              fontSize: AppTheme.fontSizeNormal,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(9, (index) {
              final height = active ? (18 + (index % 4) * 12).toDouble() : 14.0;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: height,
                decoration: BoxDecoration(
                  color: active
                      ? AppTheme.stageAccent
                      : AppTheme.stageBorder.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _CallCameraCard extends StatelessWidget {
  const _CallCameraCard({
    required this.callState,
    required this.cameraState,
    required this.onStartPreview,
    required this.onStopPreview,
  });

  final DemoCallFlowState callState;
  final CallCameraState cameraState;
  final VoidCallback onStartPreview;
  final VoidCallback onStopPreview;

  @override
  Widget build(BuildContext context) {
    final canUseCamera =
        callState.phase == DemoCallUiPhase.connected ||
        callState.phase == DemoCallUiPhase.connecting ||
        callState.phase == DemoCallUiPhase.reconnecting;
    final controller = cameraState.session?.controller;

    return DemoSurfaceCard(
      semanticLabel: '通话摄像头，本机预览，${cameraState.message}',
      color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DemoSectionTitle(
            title: '摄像头协助',
            subtitle: '需要看清物品或环境时，可开启真实本机摄像头预览。',
          ),
          const SizedBox(height: AppTheme.spacingM),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.stageBackground.withValues(alpha: 0.86),
                  border: Border.all(
                    color: AppTheme.stageBorder.withValues(alpha: 0.62),
                  ),
                ),
                child: cameraState.hasRealPreview && controller != null
                    ? CameraPreview(controller)
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spacingM),
                          child: AccessibleText(
                            cameraState.message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.stageTextSecondary,
                              fontSize: AppTheme.fontSizeSmall,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          AccessibleText(
            cameraState.isLive
                ? '摄像头只在本机显示，不上传画面，也不建立真实视频通话。'
                : '点击后会请求系统摄像头权限，用于现场演示时看清物品/环境。',
            style: TextStyle(
              color: AppTheme.stageTextSecondary,
              fontSize: AppTheme.fontSizeSmall,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          ElevatedButton.icon(
            onPressed: !canUseCamera || cameraState.isStarting
                ? null
                : cameraState.isLive
                ? onStopPreview
                : onStartPreview,
            icon: Icon(
              cameraState.isLive
                  ? Icons.videocam_off_outlined
                  : Icons.videocam_outlined,
            ),
            label: Text(
              cameraState.isStarting
                  ? '正在开启'
                  : cameraState.isLive
                  ? '关闭摄像头'
                  : '开启摄像头',
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(48, 52),
              backgroundColor: cameraState.isLive
                  ? AppTheme.stageDanger
                  : AppTheme.stageAccent,
              foregroundColor: Colors.black,
              disabledBackgroundColor: AppTheme.stageBorder,
              disabledForegroundColor: AppTheme.stageTextHint,
              textStyle: const TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                fontWeight: FontWeight.w800,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppTheme.borderRadiusMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoNoticeCard extends StatelessWidget {
  const _DemoNoticeCard({required this.state});

  final DemoCallFlowState state;

  @override
  Widget build(BuildContext context) {
    return DemoSurfaceCard(
      semanticLabel: 'F11 Demo Call 安全说明',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DemoSectionTitle(
            title: '竞赛 Demo 说明',
            subtitle: '只演示可见状态变化，不接入真实外部服务。',
          ),
          const SizedBox(height: AppTheme.spacingM),
          const _InfoLine(
            icon: Icons.mic_off_outlined,
            text: '不请求真实麦克风权限，不录音，不真实共享位置。',
          ),
          const SizedBox(height: AppTheme.spacingS),
          const _InfoLine(
            icon: Icons.cloud_off_outlined,
            text: '不建立真实 WebRTC，不依赖真实 Supabase、信令或推送。',
          ),
          const SizedBox(height: AppTheme.spacingS),
          _InfoLine(
            icon: Icons.restart_alt_outlined,
            text: state.phase == DemoCallUiPhase.failed
                ? '连接失败后可以返回匹配，help_request 已回到 matching。'
                : '掉线 10 秒未恢复会回到 matching，演示中用按钮加速。',
          ),
          if (FeatureFlags.enableWebRTC) ...[
            const SizedBox(height: AppTheme.spacingS),
            const _InfoLine(
              icon: Icons.warning_amber_outlined,
              text: '当前检测到 WebRTC 开关开启，请确认竞赛版配置。',
            ),
          ],
        ],
      ),
    );
  }
}

class _CallControls extends StatelessWidget {
  const _CallControls({
    required this.state,
    required this.onToggleMute,
    required this.onToggleSpeaker,
    required this.onEndCall,
    required this.onSimulateDisconnect,
    required this.onRestoreConnection,
    required this.onFailReconnect,
    required this.onRetryConnection,
    required this.onReturnToMatching,
    required this.onShowSafety,
  });

  final DemoCallFlowState state;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onEndCall;
  final VoidCallback onSimulateDisconnect;
  final VoidCallback onRestoreConnection;
  final VoidCallback onFailReconnect;
  final VoidCallback onRetryConnection;
  final VoidCallback onReturnToMatching;
  final VoidCallback onShowSafety;

  @override
  Widget build(BuildContext context) {
    final canControl =
        state.phase == DemoCallUiPhase.connected ||
        state.phase == DemoCallUiPhase.reconnecting ||
        state.phase == DemoCallUiPhase.connecting;

    return DemoSurfaceCard(
      semanticLabel: 'Demo 通话操作区',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DemoSectionTitle(
            title: '通话操作',
            subtitle: '所有按钮只驱动本地 Demo 状态，不接入真实通话能力。',
          ),
          const SizedBox(height: AppTheme.spacingM),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 420;
              final buttons = [
                _ActionButton(
                  label: state.isMuted ? '取消静音' : '静音',
                  icon: state.isMuted
                      ? Icons.mic_outlined
                      : Icons.mic_off_outlined,
                  semanticLabel: state.isMuted ? '取消静音按钮' : '静音按钮',
                  semanticHint: '切换本地 Demo 静音状态，不请求真实麦克风权限。',
                  onPressed: canControl ? onToggleMute : null,
                ),
                _ActionButton(
                  label: state.isSpeakerOn ? '关闭免提' : '免提',
                  icon: state.isSpeakerOn
                      ? Icons.volume_up_outlined
                      : Icons.volume_off_outlined,
                  semanticLabel: state.isSpeakerOn ? '关闭免提按钮' : '免提按钮',
                  semanticHint: '切换本地 Demo 免提状态。',
                  onPressed: canControl ? onToggleSpeaker : null,
                ),
                _ActionButton(
                  label: '结束通话',
                  icon: Icons.call_end,
                  semanticLabel: '结束通话按钮',
                  semanticHint: '结束本地 Demo 通话并进入帮助完成评分页。',
                  accentColor: AppTheme.stageDanger,
                  onPressed: canControl ? onEndCall : null,
                ),
              ];

              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final button in buttons) ...[
                      button,
                      const SizedBox(height: AppTheme.spacingS),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  for (final button in buttons) ...[
                    Expanded(child: button),
                    if (button != buttons.last)
                      const SizedBox(width: AppTheme.spacingS),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: AppTheme.spacingM),
          Wrap(
            spacing: AppTheme.spacingS,
            runSpacing: AppTheme.spacingS,
            children: [
              _SecondaryActionButton(
                label: '模拟掉线',
                icon: Icons.wifi_off_outlined,
                semanticLabel: '模拟掉线按钮',
                semanticHint: '让 Demo 通话进入正在重连状态。',
                onPressed: state.phase == DemoCallUiPhase.connected
                    ? onSimulateDisconnect
                    : null,
              ),
              _SecondaryActionButton(
                label: '模拟恢复',
                icon: Icons.wifi_tethering_outlined,
                semanticLabel: '模拟恢复按钮',
                semanticHint: '让 Demo 通话从重连回到已接通。',
                onPressed: state.phase == DemoCallUiPhase.reconnecting
                    ? onRestoreConnection
                    : null,
              ),
              _SecondaryActionButton(
                label: '模拟重连失败',
                icon: Icons.error_outline,
                semanticLabel: '模拟重连失败按钮',
                semanticHint: '让 help_request 回到 matching，演示重新匹配规则。',
                onPressed: state.phase == DemoCallUiPhase.reconnecting
                    ? onFailReconnect
                    : null,
              ),
              _SecondaryActionButton(
                label: '重新连接',
                icon: Icons.refresh_outlined,
                semanticLabel: '重新连接按钮',
                semanticHint: '重新进入本地 Demo 通话连接流程。',
                onPressed: state.phase == DemoCallUiPhase.failed
                    ? onRetryConnection
                    : null,
              ),
              _SecondaryActionButton(
                label: '返回匹配',
                icon: Icons.people_alt_outlined,
                semanticLabel: '返回匹配按钮',
                semanticHint: '回到匹配页重新分配志愿者。',
                onPressed:
                    state.phase == DemoCallUiPhase.failed ||
                        state.phase == DemoCallUiPhase.reconnecting
                    ? onReturnToMatching
                    : null,
              ),
              _SecondaryActionButton(
                label: '举报 / 安全提示',
                icon: Icons.privacy_tip_outlined,
                semanticLabel: '举报和安全提示按钮',
                semanticHint: '查看本地 Demo 的通话安全说明。',
                onPressed: onShowSafety,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.semanticLabel,
    required this.semanticHint,
    required this.onPressed,
    this.accentColor,
  });

  final String label;
  final IconData icon;
  final String semanticLabel;
  final String semanticHint;
  final VoidCallback? onPressed;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = accentColor ?? AppTheme.stageAccent;
    return Semantics(
      button: true,
      label: semanticLabel,
      hint: semanticHint,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: LinkableMaterialIcon(
          icon: icon,
          size: 24,
          color: Colors.black,
          semanticLabel: label,
        ),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 56),
          backgroundColor: effectiveColor,
          foregroundColor: Colors.black,
          disabledBackgroundColor: AppTheme.stageBorder,
          disabledForegroundColor: AppTheme.stageTextHint,
          textStyle: const TextStyle(
            fontSize: AppTheme.fontSizeSmall,
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          ),
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.label,
    required this.icon,
    required this.semanticLabel,
    required this.semanticHint,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final String semanticLabel;
  final String semanticHint;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      hint: semanticHint,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: LinkableMaterialIcon(
          icon: icon,
          size: 20,
          color: AppTheme.stageTextPrimary,
          semanticLabel: label,
        ),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: AppTheme.stageTextPrimary,
          disabledForegroundColor: AppTheme.stageTextHint,
          side: BorderSide(color: AppTheme.stageBorder),
          textStyle: const TextStyle(
            fontSize: AppTheme.fontSizeSmall,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinkableMaterialIcon(
          icon: icon,
          color: AppTheme.stageAccent,
          size: 22,
          semanticLabel: text,
        ),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(
          child: AccessibleText(
            text,
            style: TextStyle(
              color: AppTheme.stageTextSecondary,
              fontSize: AppTheme.fontSizeSmall,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
