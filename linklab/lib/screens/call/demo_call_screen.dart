import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/app_session_service.dart';
import '../../services/demo_call_service.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_motion.dart';
import '../../widgets/demo/demo_routes.dart';
import '../../widgets/demo/demo_stage.dart';
import 'demo_call_rating_screen.dart';

/// 演示版通话页面
/// 模拟通话界面，不建立真实WebRTC连接
class DemoCallScreen extends StatefulWidget {
  const DemoCallScreen({super.key});

  @override
  State<DemoCallScreen> createState() => _DemoCallScreenState();
}

class _DemoCallScreenState extends State<DemoCallScreen> {
  final DemoCallService _callService = DemoCallService();

  @override
  void initState() {
    super.initState();
    _startCall();
  }

  Future<void> _startCall() async {
    await _callService.startCall();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _hangUp() async {
    await _callService.hangUp();
    if (mounted) {
      replaceWithDemoStageRoute(
        context,
        page: DemoCallRatingScreen(
          volunteer: _callService.currentVolunteer!,
          duration: _callService.callDuration,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_callService, AppSessionService.instance]),
      builder: (context, child) {
        final volunteer = _callService.currentVolunteer;
        final isConnecting = _callService.isConnecting;
        final isConnected = _callService.isInCall;

        return DemoStageScaffold(
          title: '实时语音通话',
          subtitle: 'Demo 模式下完整模拟 F11 状态变化',
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingL,
              AppTheme.spacingXL,
              AppTheme.spacingL,
              AppTheme.spacingL,
            ),
            children: [
              if (volunteer != null) ...[
                Center(
                  child: Wrap(
                    spacing: AppTheme.spacingS,
                    runSpacing: AppTheme.spacingS,
                    alignment: WrapAlignment.center,
                    children: [
                      DemoPill(
                        icon: isConnected
                            ? Icons.network_check_rounded
                            : Icons.sync_outlined,
                        label: isConnected ? '连接稳定' : '正在建链',
                        color: isConnected
                            ? AppTheme.stageSuccess
                            : AppTheme.stageAccent,
                      ),
                      DemoPill(
                        icon: Icons.hearing_outlined,
                        label: '仅语音主线',
                        color: AppTheme.stageInfo,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),
                DemoReveal(
                  child: Center(
                    child: Container(
                      width: 136,
                      height: 136,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isConnected
                            ? LinearGradient(
                                colors: [
                                  AppTheme.stageSuccess,
                                  AppTheme.stageInfo,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : AppTheme.stageAccentGradient,
                        boxShadow: AppTheme.stageShadow,
                      ),
                      child: Center(
                        child: Text(
                          volunteer.name[0],
                          style: TextStyle(
                            color: AppTheme.stageBackground,
                            fontSize: 56,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),
                AccessibleText(
                  volunteer.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.stageTextPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_rounded, color: AppTheme.stageAccent),
                    const SizedBox(width: AppTheme.spacingXS),
                    Text(
                      '${volunteer.rating}',
                      style: TextStyle(
                        color: AppTheme.stageTextPrimary,
                        fontSize: AppTheme.fontSizeNormal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Text(
                      '已帮助 ${volunteer.helpCount} 次',
                      style: TextStyle(
                        color: AppTheme.stageTextSecondary,
                        fontSize: AppTheme.fontSizeSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),
                Wrap(
                  spacing: AppTheme.spacingS,
                  runSpacing: AppTheme.spacingS,
                  alignment: WrapAlignment.center,
                  children: volunteer.skills
                      .map(
                        (skill) =>
                            DemoPill(label: skill, color: AppTheme.stageInfo),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: AppTheme.spacingXL),
              Center(
                child: AccessibleText(
                  isConnecting
                      ? '正在连接...'
                      : isConnected
                      ? '通话中 ${_formatDuration(_callService.callDuration)}'
                      : '准备建立连接',
                  style: TextStyle(
                    color: isConnected
                        ? AppTheme.stageSuccess
                        : AppTheme.stageAccentLight,
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              DemoReveal(
                delay: const Duration(milliseconds: 80),
                child: DemoSurfaceCard(
                  color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.96),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AccessibleText(
                        '语音主线状态',
                        style: TextStyle(
                          color: AppTheme.stageTextPrimary,
                          fontSize: AppTheme.fontSizeNormal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(14, (index) {
                          final active = isConnected
                              ? (index.isEven || index % 3 == 0)
                              : index < 4;
                          final height = isConnected
                              ? 16.0 + ((index % 5) * 9)
                              : 10.0 + ((index % 3) * 5);
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 240),
                                curve: Curves.easeOutCubic,
                                height: height,
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppTheme.stageAccent
                                      : AppTheme.stageBorder.withValues(
                                          alpha: 0.45,
                                        ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      AccessibleText(
                        isConnected
                            ? '当前为稳定通话阶段，结束后会自动进入评价并回写帮助档案。'
                            : '当前展示建链中的可见状态，避免评审看到无反馈等待。',
                        style: TextStyle(
                          color: AppTheme.stageTextSecondary,
                          fontSize: AppTheme.fontSizeSmall,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              DemoReveal(
                delay: const Duration(milliseconds: 120),
                child: DemoSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AccessibleText(
                        '演示说明',
                        style: TextStyle(
                          color: AppTheme.stageTextPrimary,
                          fontSize: AppTheme.fontSizeNormal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      const _CallInfoRow(
                        icon: Icons.sync_alt_rounded,
                        title: '状态完整可见',
                        subtitle: '连接态、已接通和结束评价都在当前链路可回看。',
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      const _CallInfoRow(
                        icon: Icons.hearing_rounded,
                        title: '仅保留语音主线',
                        subtitle: '视频与屏幕共享已从竞赛版主交付中移出。',
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      const _CallInfoRow(
                        icon: Icons.shield_outlined,
                        title: '可回退 Demo',
                        subtitle: '不依赖真实 WebRTC，适合 3 分钟演示闭环。',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomBar: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _CallActionButton(
                  icon: Icons.mic_none_rounded,
                  label: '静音',
                  color: AppTheme.stageSurfaceStrong,
                  iconColor: AppTheme.stageTextPrimary,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _CallActionButton(
                  icon: Icons.call_end,
                  label: '挂断',
                  color: AppTheme.stageDanger,
                  iconColor: AppTheme.stageTextPrimary,
                  isPrimary: true,
                  onTap: _hangUp,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _CallActionButton(
                  icon: Icons.volume_up_outlined,
                  label: '扬声器',
                  color: AppTheme.stageSurfaceStrong,
                  iconColor: AppTheme.stageAccent,
                  onTap: () {},
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CallInfoRow extends StatelessWidget {
  const _CallInfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.stageAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: AppTheme.stageAccent),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AccessibleText(
                title,
                style: TextStyle(
                  color: AppTheme.stageTextPrimary,
                  fontSize: AppTheme.fontSizeSmall,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXS),
              AccessibleText(
                subtitle,
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
    );
  }
}

class _CallActionButton extends StatelessWidget {
  const _CallActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      hint: '双击执行$label',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: isPrimary ? 74 : 68,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
            border: isPrimary
                ? null
                : Border.all(
                    color: AppTheme.stageBorder.withValues(alpha: 0.82),
                  ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: isPrimary ? 30 : 26),
              const SizedBox(height: AppTheme.spacingXS),
              Text(
                label,
                style: TextStyle(
                  color: iconColor,
                  fontSize: AppTheme.fontSizeSmall,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
