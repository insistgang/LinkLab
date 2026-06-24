import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_session_provider.dart';
import '../../providers/call_camera_provider.dart';
import '../../providers/demo_call_flow_provider.dart';
import '../../providers/demo_help_request_flow_provider.dart';
import '../../providers/facade_providers.dart';
import '../../services/demo_call_service.dart' show DemoVolunteer;
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_overlays.dart';
import '../../widgets/demo/demo_routes.dart';
import '../../widgets/demo/demo_stage.dart';
import '../../widgets/demo/linkable_icon.dart';
import 'demo_call_rating_screen.dart';
import 'demo_matching_screen.dart';

/// F11 競賽 Demo 通話頁。
///
/// 該頁只展示本地可復現的語音協助閉環，不建立真實 WebRTC、不錄音、
/// 不請求真實麥克風權限。
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
        // Facade 優先：調用 CallSessionFacade.startCall
        _startCallWithFacade();
        // Fallback：原有 demo flow（始終執行以驅動 UI 狀態）
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
      // Facade 異常，demo flow 已在 fallback 中啓動
    }
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(demoCallFlowProvider);
    final cameraState = ref.watch(callCameraProvider);
    final sessionState = ref.watch(appSessionProvider);
    final helpState = ref.watch(demoHelpRequestFlowProvider);
    final viewerIsVolunteer = sessionState.userProfile?.isVolunteer == true;

    return DemoStageScaffold(
      title: '實時語音協助',
      subtitle: 'F11 本地 Demo Call，可開啓本機攝像頭預覽',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingM,
          AppTheme.spacingL,
          AppTheme.spacingM,
          AppTheme.spacingXXL,
        ),
        children: [
          _CallStatusCard(
            state: callState,
            viewerIsVolunteer: viewerIsVolunteer,
          ),
          const SizedBox(height: AppTheme.spacingM),
          if (viewerIsVolunteer)
            _SeekerRequestCard(helpState: helpState)
          else
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

    // Facade 優先：調用 CallSessionFacade.endCall
    try {
      final facade = ref.read(callSessionFacadeProvider);
      final result = await facade.endCall();
      if (!result.success) {
        // Facade 失敗，繼續走 fallback
      }
    } catch (_) {
      // Facade 異常，降級到舊流程
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
      accentColor: AppTheme.stageAccent,
      message: '競賽 Demo 不錄音、不上傳通話內容；如遇不適可結束通話或回到匹配。',
    );
  }

  DemoVolunteer _toRatingVolunteer(DemoCallVolunteerSnapshot snapshot) {
    return DemoVolunteer(
      id: snapshot.id,
      name: snapshot.nickname,
      avatar: snapshot.avatarLabel,
      rating: 4.9,
      helpCount: 128,
      skills: snapshot.skills.isEmpty ? const ['語音協助'] : snapshot.skills,
    );
  }
}

class _CallStatusCard extends StatelessWidget {
  const _CallStatusCard({required this.state, required this.viewerIsVolunteer});

  final DemoCallFlowState state;
  final bool viewerIsVolunteer;

  @override
  Widget build(BuildContext context) {
    final statusColor = AppTheme.stageAccent;
    final icon = _statusIcon(state.phase);

    return DemoSurfaceCard(
      semanticLabel: '實時語音協助狀態，${state.statusMessage}',
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
                semanticLabel: '連接狀態圖標',
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
                label: viewerIsVolunteer ? '已接入求助用戶' : '志願者已接單',
                icon: Icons.verified_user_outlined,
                color: AppTheme.stageAccent,
              ),
              DemoPill(
                label: '無真實 WebRTC',
                icon: Icons.cloud_off_outlined,
                color: AppTheme.stageAccent,
              ),
            ],
          ),
        ],
      ),
    );
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
      DemoCallUiPhase.idle => '等待從匹配頁進入通話流程。',
      DemoCallUiPhase.connecting => '正在建立安全語音連接，演示中不會訪問真實麥克風。',
      DemoCallUiPhase.connected =>
        '已接通，通話時長 ${_formatDuration(state.duration)}。',
      DemoCallUiPhase.reconnecting => '模擬掉線中；真實規則是 10 秒未恢復會重新匹配。',
      DemoCallUiPhase.ended => '幫助已完成，可以進入感謝與評分頁。',
      DemoCallUiPhase.failed => state.errorMessage ?? '連接失敗，你可以重新連接或回到匹配頁。',
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
          '已接單志願者，${volunteer.nickname}，技能 ${volunteer.skills.join('，')}，${volunteer.distanceLabel}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DemoSectionTitle(
            title: '已接單志願者',
            subtitle: '優先讀取 F9 Top 5 已接單結果，缺失時使用本地穩定兜底。',
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
                  color: AppTheme.stageAccent,
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          _InfoLine(icon: Icons.recommend_outlined, text: volunteer.reason),
          if (volunteer.isFallback) ...[
            const SizedBox(height: AppTheme.spacingS),
            const _InfoLine(icon: Icons.info_outline, text: '當前使用演示志願者繼續通話流程。'),
          ],
        ],
      ),
    );
  }
}

class _SeekerRequestCard extends StatelessWidget {
  const _SeekerRequestCard({required this.helpState});

  final DemoHelpRequestFlowState helpState;

  @override
  Widget build(BuildContext context) {
    final snapshot = _SeekerRequestSnapshot.fromHelpState(helpState);
    final isEmergency = helpState.urgency == 'emergency';
    final accentColor = isEmergency
        ? AppTheme.stageDanger
        : AppTheme.stageAccent;

    return DemoSurfaceCard(
      semanticLabel:
          '已連接求助用戶，${snapshot.seekerName}，${snapshot.title}，${snapshot.description}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DemoSectionTitle(
            title: '已連接求助用戶',
            subtitle: isEmergency ? '志願者端正在響應緊急求助。' : '志願者端正在協助這位用戶。',
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: accentColor.withValues(alpha: 0.18),
                child: AccessibleText(
                  snapshot.avatarLabel,
                  style: TextStyle(
                    color: accentColor,
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
                      snapshot.seekerName,
                      style: TextStyle(
                        color: AppTheme.stageTextPrimary,
                        fontSize: AppTheme.fontSizeLarge,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    AccessibleText(
                      snapshot.title,
                      style: TextStyle(
                        color: AppTheme.stageTextSecondary,
                        fontSize: AppTheme.fontSizeSmall,
                        height: 1.45,
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
                label: isEmergency ? '緊急求助' : '普通求助',
                icon: isEmergency
                    ? Icons.emergency_outlined
                    : Icons.handshake_outlined,
                color: accentColor,
              ),
              DemoPill(
                label: snapshot.typeLabel,
                icon: Icons.assignment_outlined,
                color: AppTheme.stageAccent,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          _InfoLine(
            icon: Icons.record_voice_over_outlined,
            text: snapshot.description,
          ),
          const SizedBox(height: AppTheme.spacingS),
          const _InfoLine(
            icon: Icons.privacy_tip_outlined,
            text: '演示版只顯示匿名用戶，不展示真實電話或精確位置。',
          ),
        ],
      ),
    );
  }
}

class _SeekerRequestSnapshot {
  const _SeekerRequestSnapshot({
    required this.seekerName,
    required this.avatarLabel,
    required this.title,
    required this.description,
    required this.typeLabel,
  });

  factory _SeekerRequestSnapshot.fromHelpState(DemoHelpRequestFlowState state) {
    final parsed = _parseIntent(state.intent);
    final seekerName = parsed.$1;
    final title = parsed.$2;
    final description = parsed.$3;

    return _SeekerRequestSnapshot(
      seekerName: seekerName,
      avatarLabel: _avatarLabel(seekerName),
      title: title,
      description: description,
      typeLabel: _typeLabel(state.type),
    );
  }

  final String seekerName;
  final String avatarLabel;
  final String title;
  final String description;
  final String typeLabel;

  static (String, String, String) _parseIntent(String? intent) {
    final value = intent?.trim();
    if (value == null || value.isEmpty) {
      return ('求助用戶', '語音協助請求', '正在與求助用戶進行語音協助。');
    }

    final nameSplit = value.split('：');
    final hasName = nameSplit.length > 1 && nameSplit.first.trim().isNotEmpty;
    final seekerName = hasName ? nameSplit.first.trim() : '求助用戶';
    final body = hasName ? nameSplit.sublist(1).join('：').trim() : value;
    final sentenceSplit = body.split('。');
    final title = sentenceSplit.first.trim().isEmpty
        ? '語音協助請求'
        : sentenceSplit.first.trim();
    final description = sentenceSplit.length > 1
        ? sentenceSplit.sublist(1).join('。').trim()
        : body;

    return (seekerName, title, description.isEmpty ? title : description);
  }

  static String _avatarLabel(String value) {
    final digits = RegExp(r'\d+').firstMatch(value)?.group(0);
    if (digits != null && digits.isNotEmpty) {
      return digits.substring(digits.length - 1);
    }
    return value.isEmpty ? '?' : value.characters.first;
  }

  static String _typeLabel(String type) {
    return switch (type) {
      'medicine_ocr' => '藥品說明協助',
      'scene_navigation' => '路牌 / 場景協助',
      'sos' => 'SOS 協助',
      'money_identify' => '鈔票面額協助',
      'hospital_navigation' => '醫院導診',
      _ => '語音協助',
    };
  }
}

class _DemoVoiceCard extends StatelessWidget {
  const _DemoVoiceCard({required this.state});

  final DemoCallFlowState state;

  @override
  Widget build(BuildContext context) {
    final active = state.phase == DemoCallUiPhase.connected;

    return DemoSurfaceCard(
      semanticLabel: '通話波形與時長，當前${state.statusMessage}',
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
            active ? '語音協助進行中' : state.statusMessage,
            style: TextStyle(
              color: active
                  ? AppTheme.stageAccent
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
      semanticLabel: '通話攝像頭，本機預覽，${cameraState.message}',
      color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DemoSectionTitle(
            title: '攝像頭協助',
            subtitle: '需要看清物品或環境時，可開啓真實本機攝像頭預覽。',
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
                ? '攝像頭只在本機顯示，不上傳畫面，也不建立真實視頻通話。'
                : '點擊後會請求系統攝像頭權限，用於現場演示時看清物品/環境。',
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
                  ? '正在開啓'
                  : cameraState.isLive
                  ? '關閉攝像頭'
                  : '開啓攝像頭',
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(48, 52),
              backgroundColor: AppTheme.stageAccent,
              foregroundColor: AppTheme.stageBackground,
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
      semanticLabel: 'F11 Demo Call 安全說明',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DemoSectionTitle(
            title: '競賽 Demo 說明',
            subtitle: '只演示可見狀態變化，不接入真實外部服務。',
          ),
          const SizedBox(height: AppTheme.spacingM),
          const _InfoLine(
            icon: Icons.mic_off_outlined,
            text: '不請求真實麥克風權限，不錄音，不真實共享位置。',
          ),
          const SizedBox(height: AppTheme.spacingS),
          const _InfoLine(
            icon: Icons.cloud_off_outlined,
            text: '不建立真實 WebRTC，不依賴真實 Supabase、信令或推送。',
          ),
          const SizedBox(height: AppTheme.spacingS),
          _InfoLine(
            icon: Icons.restart_alt_outlined,
            text: state.phase == DemoCallUiPhase.failed
                ? '連接失敗後可以返回匹配，help_request 已回到 matching。'
                : '掉線 10 秒未恢復會回到 matching，演示中用按鈕加速。',
          ),
          if (FeatureFlags.enableWebRTC) ...[
            const SizedBox(height: AppTheme.spacingS),
            const _InfoLine(
              icon: Icons.warning_amber_outlined,
              text: '當前檢測到 WebRTC 開關開啓，請確認競賽版配置。',
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
      semanticLabel: 'Demo 通話操作區',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DemoSectionTitle(
            title: '通話操作',
            subtitle: '所有按鈕只驅動本地 Demo 狀態，不接入真實通話能力。',
          ),
          const SizedBox(height: AppTheme.spacingM),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 520;
              final buttons = [
                _ActionButton(
                  label: state.isMuted ? '取消靜音' : '靜音',
                  icon: state.isMuted
                      ? Icons.mic_outlined
                      : Icons.mic_off_outlined,
                  semanticLabel: state.isMuted ? '取消靜音按鈕' : '靜音按鈕',
                  semanticHint: '切換本地 Demo 靜音狀態，不請求真實麥克風權限。',
                  onPressed: canControl ? onToggleMute : null,
                ),
                _ActionButton(
                  label: state.isSpeakerOn ? '關閉免提' : '免提',
                  icon: state.isSpeakerOn
                      ? Icons.volume_up_outlined
                      : Icons.volume_off_outlined,
                  semanticLabel: state.isSpeakerOn ? '關閉免提按鈕' : '免提按鈕',
                  semanticHint: '切換本地 Demo 免提狀態。',
                  onPressed: canControl ? onToggleSpeaker : null,
                ),
                _ActionButton(
                  label: '結束通話',
                  icon: Icons.call_end,
                  semanticLabel: '結束通話按鈕',
                  semanticHint: '結束本地 Demo 通話並進入幫助完成評分頁。',
                  accentColor: AppTheme.stageAccent,
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
                label: '模擬掉線',
                icon: Icons.wifi_off_outlined,
                semanticLabel: '模擬掉線按鈕',
                semanticHint: '讓 Demo 通話進入正在重連狀態。',
                onPressed: state.phase == DemoCallUiPhase.connected
                    ? onSimulateDisconnect
                    : null,
              ),
              _SecondaryActionButton(
                label: '模擬恢復',
                icon: Icons.wifi_tethering_outlined,
                semanticLabel: '模擬恢復按鈕',
                semanticHint: '讓 Demo 通話從重連回到已接通。',
                onPressed: state.phase == DemoCallUiPhase.reconnecting
                    ? onRestoreConnection
                    : null,
              ),
              _SecondaryActionButton(
                label: '模擬重連失敗',
                icon: Icons.error_outline,
                semanticLabel: '模擬重連失敗按鈕',
                semanticHint: '讓 help_request 回到 matching，演示重新匹配規則。',
                onPressed: state.phase == DemoCallUiPhase.reconnecting
                    ? onFailReconnect
                    : null,
              ),
              _SecondaryActionButton(
                label: '重新連接',
                icon: Icons.refresh_outlined,
                semanticLabel: '重新連接按鈕',
                semanticHint: '重新進入本地 Demo 通話連接流程。',
                onPressed: state.phase == DemoCallUiPhase.failed
                    ? onRetryConnection
                    : null,
              ),
              _SecondaryActionButton(
                label: '返回匹配',
                icon: Icons.people_alt_outlined,
                semanticLabel: '返回匹配按鈕',
                semanticHint: '回到匹配頁重新分配志願者。',
                onPressed:
                    state.phase == DemoCallUiPhase.failed ||
                        state.phase == DemoCallUiPhase.reconnecting
                    ? onReturnToMatching
                    : null,
              ),
              _SecondaryActionButton(
                label: '舉報 / 安全提示',
                icon: Icons.privacy_tip_outlined,
                semanticLabel: '舉報和安全提示按鈕',
                semanticHint: '查看本地 Demo 的通話安全說明。',
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
          color: AppTheme.stageBackground,
          semanticLabel: label,
        ),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 56),
          backgroundColor: effectiveColor,
          foregroundColor: AppTheme.stageBackground,
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
