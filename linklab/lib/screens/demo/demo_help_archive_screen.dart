import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/extensions.dart';
import '../../models/help_request_model.dart';
import '../../providers/app_session_provider.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_stage.dart';
import '../../widgets/demo/linkable_icon.dart';

/// 競賽 Demo 默認檔案頁。
///
/// 只讀取本地 demo session 的幫助歷史，避免從默認首頁/我的頁進入
/// SeekerCenterScreen 中仍保留的積分、異步任務、收藏志願者等非 MVP 代碼。
class DemoHelpArchiveScreen extends ConsumerWidget {
  const DemoHelpArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(appSessionProvider);
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
      title: '幫助檔案',
      subtitle: '僅展示 MVP 主線結果回看，不進入積分、社羣或異步任務',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingL,
          AppTheme.spacingL,
          AppTheme.spacingL,
          96,
        ),
        children: [
          const DemoSectionTitle(
            title: '求助狀態',
            subtitle: 'AI 處理、真人通話和 SOS 的終態會沉澱在這裏。',
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: _ArchiveMetricCard(
                  label: 'AI 已解決',
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
            title: '幫助檔案',
            subtitle: '只保留主鏈路回看，不展示安心積分、徽章或排班。',
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
          LinkableMaterialIcon(
            icon: icon,
            color: color,
            size: 28,
            semanticLabel: label,
          ),
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
      semanticLabel: '幫助檔案 ${request.intent ?? '未命名求助'}',
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
            child: LinkableMaterialIcon(
              icon: _icon,
              color: _color,
              semanticLabel: _title,
            ),
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
                  request.intent ?? '已完成一次主線求助',
                  style: TextStyle(
                    color: AppTheme.stageTextSecondary,
                    fontSize: AppTheme.fontSizeSmall,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                AccessibleText(
                  '${request.statusLabel} · ${request.createdAt?.formatRelative() ?? '剛剛'}',
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
        return '真人語音';
      case 'sos':
        return 'SOS 求助';
      default:
        return '幫助記錄';
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
          LinkableMaterialIcon(
            icon: Icons.history_toggle_off,
            color: AppTheme.stageTextHint,
            size: 44,
            semanticLabel: '還沒有幫助記錄',
          ),
          const SizedBox(height: AppTheme.spacingM),
          AccessibleText(
            '還沒有幫助記錄',
            style: TextStyle(
              color: AppTheme.stageTextPrimary,
              fontSize: AppTheme.fontSizeNormal,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          AccessibleText(
            '完成 AI、真人通話或 SOS 演示後，這裏會顯示主線回看。',
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
