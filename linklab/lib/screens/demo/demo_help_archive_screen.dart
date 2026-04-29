import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/extensions.dart';
import '../../models/help_request_model.dart';
import '../../services/app_session_service.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_stage.dart';

/// 竞赛 Demo 默认档案页。
///
/// 只读取本地 demo session 的帮助历史，避免从默认首页/我的页进入
/// SeekerCenterScreen 中仍保留的积分、异步任务、收藏志愿者等非 MVP 代码。
class DemoHelpArchiveScreen extends StatelessWidget {
  const DemoHelpArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AppSessionService.instance;

    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final history = session.getRecentHelpHistory(limit: 20);
        final completedCount = history
            .where((request) => request.status == 'completed')
            .length;
        final aiResolvedCount = history
            .where((request) => request.status == 'ai_resolved')
            .length;
        final sosCount = history
            .where((request) => request.type == 'sos')
            .length;

        return DemoStageScaffold(
          title: '帮助档案',
          subtitle: '仅展示 MVP 主线结果回看，不进入积分、社群或异步任务',
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingL,
              AppTheme.spacingL,
              AppTheme.spacingL,
              96,
            ),
            children: [
              const DemoSectionTitle(
                title: '求助状态',
                subtitle: 'AI 处理、真人通话和 SOS 的终态会沉淀在这里。',
              ),
              const SizedBox(height: AppTheme.spacingM),
              Row(
                children: [
                  Expanded(
                    child: _ArchiveMetricCard(
                      label: 'AI 已解决',
                      value: '$aiResolvedCount',
                      icon: Icons.smart_toy_outlined,
                      color: AppTheme.stageInfo,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: _ArchiveMetricCard(
                      label: '真人完成',
                      value: '$completedCount',
                      icon: Icons.phone_in_talk_outlined,
                      color: AppTheme.stageSuccess,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: _ArchiveMetricCard(
                      label: 'SOS',
                      value: '$sosCount',
                      icon: Icons.emergency_outlined,
                      color: AppTheme.stageDanger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingXL),
              const DemoSectionTitle(
                title: '帮助档案',
                subtitle: '只保留主链路回看，不展示安心积分、徽章或排班。',
              ),
              const SizedBox(height: AppTheme.spacingM),
              if (history.isEmpty)
                const _EmptyArchiveCard()
              else
                ...history.map(
                  (request) => Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                    child: _ArchiveRequestCard(request: request),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ArchiveMetricCard extends StatelessWidget {
  const _ArchiveMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DemoSurfaceCard(
      semanticLabel: '$label $value',
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppTheme.spacingS),
          AccessibleText(
            value,
            style: TextStyle(
              color: AppTheme.stageTextPrimary,
              fontSize: AppTheme.fontSizeXLarge,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          AccessibleText(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.stageTextSecondary,
              fontSize: AppTheme.fontSizeSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchiveRequestCard extends StatelessWidget {
  const _ArchiveRequestCard({required this.request});

  final HelpRequestModel request;

  @override
  Widget build(BuildContext context) {
    return DemoSurfaceCard(
      semanticLabel: '帮助档案 ${request.intent ?? '未命名求助'}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(_icon, color: _color),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccessibleText(
                  _title,
                  style: TextStyle(
                    color: AppTheme.stageTextPrimary,
                    fontSize: AppTheme.fontSizeNormal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                AccessibleText(
                  request.intent ?? '已完成一次主线求助',
                  style: TextStyle(
                    color: AppTheme.stageTextSecondary,
                    fontSize: AppTheme.fontSizeSmall,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                AccessibleText(
                  '${request.statusLabel} · ${request.createdAt?.formatRelative() ?? '刚刚'}',
                  style: TextStyle(
                    color: AppTheme.stageTextHint,
                    fontSize: AppTheme.fontSizeSmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _title {
    switch (request.type) {
      case 'ai_auto':
        return 'AI 自助';
      case 'realtime_voice':
        return '真人语音';
      case 'sos':
        return 'SOS 求助';
      default:
        return '帮助记录';
    }
  }

  IconData get _icon {
    switch (request.type) {
      case 'ai_auto':
        return Icons.smart_toy_outlined;
      case 'realtime_voice':
        return Icons.phone_in_talk_outlined;
      case 'sos':
        return Icons.emergency_outlined;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color get _color {
    switch (request.type) {
      case 'ai_auto':
        return AppTheme.stageInfo;
      case 'sos':
        return AppTheme.stageDanger;
      default:
        return AppTheme.stageAccent;
    }
  }
}

class _EmptyArchiveCard extends StatelessWidget {
  const _EmptyArchiveCard();

  @override
  Widget build(BuildContext context) {
    return DemoSurfaceCard(
      child: Column(
        children: [
          Icon(
            Icons.history_toggle_off,
            color: AppTheme.stageTextHint,
            size: 44,
          ),
          const SizedBox(height: AppTheme.spacingM),
          AccessibleText(
            '还没有帮助记录',
            style: TextStyle(
              color: AppTheme.stageTextPrimary,
              fontSize: AppTheme.fontSizeNormal,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          AccessibleText(
            '完成 AI、真人通话或 SOS 演示后，这里会显示主线回看。',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.stageTextSecondary,
              fontSize: AppTheme.fontSizeSmall,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
