import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../demo_flow/demo_matching_flow.dart';
import '../../providers/app_session_provider.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_motion.dart';
import '../../widgets/demo/demo_overlays.dart';
import '../../widgets/demo/demo_routes.dart';
import '../../widgets/demo/demo_stage.dart';
import '../../widgets/demo/linkable_icon.dart';
import 'volunteer_growth_screen.dart';

/// 待帮助列表页面（志愿者模式）
/// 显示待处理的求助请求，志愿者可以响应
class PendingHelpScreen extends ConsumerStatefulWidget {
  const PendingHelpScreen({super.key});

  @override
  ConsumerState<PendingHelpScreen> createState() => _PendingHelpScreenState();
}

class _PendingHelpScreenState extends ConsumerState<PendingHelpScreen> {
  // 演示用的待帮助请求列表
  final List<_PendingHelpItem> _pendingItems = const [
    _PendingHelpItem(
      id: 'pending-1',
      title: '需要帮忙读药品说明书',
      description: '刚拿到新药，需要有人帮忙确认用法用量',
      urgency: 'important',
      type: 'ocr',
      timeAgo: '2分钟前',
      seekerName: '用户1234',
    ),
    _PendingHelpItem(
      id: 'pending-2',
      title: '看不清面前的路牌',
      description: '在医院门口，需要帮忙看路牌方向',
      urgency: 'normal',
      type: 'scene',
      timeAgo: '5分钟前',
      seekerName: '用户5678',
    ),
    _PendingHelpItem(
      id: 'pending-3',
      title: '紧急！迷路了',
      description: '天黑了找不到回家的路，需要紧急帮助',
      urgency: 'emergency',
      type: 'sos',
      timeAgo: '刚刚',
      seekerName: '用户9012',
    ),
    _PendingHelpItem(
      id: 'pending-4',
      title: '需要帮忙确认钞票面额',
      description: '买东西时需要确认手里的是多少钱',
      urgency: 'normal',
      type: 'money',
      timeAgo: '8分钟前',
      seekerName: '用户3456',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(appSessionProvider);
    final volunteerName = session.userProfile?.displayName ?? '志愿者';

    return DemoStageLiveBuilder(
      builder: (context) {
        return DemoStageScaffold(
          title: '待帮助列表',
          subtitle: '查看并响应求助请求',
          showBackButton: false,
          body: RefreshIndicator(
            color: AppTheme.stageAccent,
            onRefresh: () async {
              // 演示模式下模拟刷新
              await Future.delayed(const Duration(seconds: 1));
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingL,
                AppTheme.spacingL,
                AppTheme.spacingL,
                112,
              ),
              children: [
                // 欢迎卡片
                DemoReveal(child: _WelcomeCard(volunteerName: volunteerName)),
                const SizedBox(height: AppTheme.spacingL),
                DemoReveal(
                  delay: const Duration(milliseconds: 60),
                  child: _GrowthEntryCard(
                    onTap: () {
                      pushDemoStageRoute(
                        context,
                        page: const VolunteerGrowthScreen(),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),
                // 统计卡片
                DemoReveal(
                  delay: const Duration(milliseconds: 80),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: '待响应',
                          value: '${_pendingItems.length}',
                          color: AppTheme.stageAccent,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: _StatCard(
                          label: '紧急',
                          value:
                              '${_pendingItems.where((i) => i.urgency == 'emergency').length}',
                          color: AppTheme.stageDanger,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: _StatCard(
                          label: '今日已完成',
                          value: '3',
                          color: AppTheme.stageSuccess,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXL),
                // 紧急求助区域
                if (_pendingItems.any((i) => i.urgency == 'emergency')) ...[
                  const DemoSectionTitle(title: '紧急求助', subtitle: '需要立即响应的请求'),
                  const SizedBox(height: AppTheme.spacingM),
                  ..._pendingItems
                      .where((item) => item.urgency == 'emergency')
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.spacingM,
                          ),
                          child: DemoReveal(
                            delay: const Duration(milliseconds: 130),
                            child: _PendingHelpCard(
                              item: item,
                              isEmergency: true,
                              onAccept: () => _onAcceptRequest(item),
                            ),
                          ),
                        ),
                      ),
                  const SizedBox(height: AppTheme.spacingL),
                ],
                // 普通求助区域
                const DemoSectionTitle(
                  title: '普通求助',
                  subtitle: 'AI 无法处理，需要志愿者协助',
                ),
                const SizedBox(height: AppTheme.spacingM),
                ..._pendingItems
                    .where((item) => item.urgency != 'emergency')
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppTheme.spacingM,
                        ),
                        child: DemoReveal(
                          delay: const Duration(milliseconds: 180),
                          child: _PendingHelpCard(
                            item: item,
                            isEmergency: false,
                            onAccept: () => _onAcceptRequest(item),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onAcceptRequest(_PendingHelpItem item) {
    HapticFeedback.mediumImpact();

    if (item.urgency == 'emergency') {
      // 紧急求助直接进入SOS流程
      showDemoStageDialog<void>(
        context,
        barrierDismissible: false,
        builder: (context) => DemoDialog(
          title: '确认响应紧急求助？',
          icon: Icons.emergency_outlined,
          accentColor: AppTheme.stageDanger,
          description: '${item.seekerName} 发送了紧急求助：${item.title}。确认后将立即建立语音连接。',
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '取消',
                style: TextStyle(color: AppTheme.stageTextSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.stageDanger,
                foregroundColor: AppTheme.stageTextPrimary,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                // 进入演示通话流程
                DemoMatchingFlow.startMatching(context);
              },
              child: const Text('确认响应'),
            ),
          ],
        ),
      );
    } else {
      // 普通求助进入匹配流程
      showDemoStageDialog<void>(
        context,
        barrierDismissible: false,
        builder: (context) => DemoDialog(
          title: '确认响应求助？',
          icon: Icons.handshake_outlined,
          accentColor: AppTheme.stageAccent,
          description: '${item.seekerName} 需要帮助：${item.title}。确认后将建立语音连接。',
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '取消',
                style: TextStyle(color: AppTheme.stageTextSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.stageAccent,
                foregroundColor: AppTheme.stageBackground,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                // 进入演示通话流程
                DemoMatchingFlow.startMatching(context);
              },
              child: const Text('确认响应'),
            ),
          ],
        ),
      );
    }
  }
}

class _GrowthEntryCard extends StatelessWidget {
  const _GrowthEntryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DemoSurfaceCard(
      semanticLabel: '志愿者贡献成长入口',
      hint: '双击查看贡献等级说明和最近贡献记录',
      onTap: onTap,
      color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.96),
      child: Row(
        children: [
          Container(
            width: AppTheme.minTouchTarget,
            height: AppTheme.minTouchTarget,
            decoration: BoxDecoration(
              color: AppTheme.stageSuccess.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const LinkableSvgIcon(
              icon: LinkableIconName.points,
              size: 40,
              semanticLabel: '贡献成长',
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccessibleText(
                  '贡献成长',
                  style: TextStyle(
                    color: AppTheme.stageTextPrimary,
                    fontSize: AppTheme.fontSizeNormal,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                AccessibleText(
                  '查看贡献等级说明，最近贡献记录会和贡献值保持一致。',
                  style: TextStyle(
                    color: AppTheme.stageTextSecondary,
                    fontSize: AppTheme.fontSizeSmall,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingS),
          const LinkableSvgIcon(
            icon: LinkableIconName.navigationGuide,
            size: 24,
            semanticLabel: '进入贡献成长',
          ),
        ],
      ),
    );
  }
}

/// 欢迎卡片
class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.volunteerName});

  final String volunteerName;

  @override
  Widget build(BuildContext context) {
    return DemoSurfaceCard(
      color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.96),
      child: Row(
        children: [
          Container(
            width: AppTheme.minTouchTarget,
            height: AppTheme.minTouchTarget,
            decoration: BoxDecoration(
              gradient: AppTheme.stageAccentGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const LinkableSvgIcon(
              icon: LinkableIconName.volunteerRole,
              size: 42,
              semanticLabel: '志愿者',
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccessibleText(
                  '您好，$volunteerName',
                  style: TextStyle(
                    color: AppTheme.stageTextPrimary,
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                AccessibleText(
                  '感谢您愿意帮助他人！以下是当前待响应的求助请求。',
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
    );
  }
}

/// 统计卡片
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DemoSurfaceCard(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        children: [
          AccessibleText(
            value,
            style: TextStyle(
              color: color,
              fontSize: AppTheme.fontSizeXXLarge,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          AccessibleText(
            label,
            style: TextStyle(
              color: AppTheme.stageTextSecondary,
              fontSize: AppTheme.fontSizeSmall,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// 待帮助请求卡片
class _PendingHelpCard extends StatelessWidget {
  const _PendingHelpCard({
    required this.item,
    required this.isEmergency,
    required this.onAccept,
  });

  final _PendingHelpItem item;
  final bool isEmergency;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return DemoSurfaceCard(
      semanticLabel: '${item.title}，${item.seekerName}，${item.timeAgo}',
      hint: '双击响应此求助',
      onTap: onAccept,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 类型图标
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      (isEmergency
                              ? AppTheme.stageDanger
                              : AppTheme.stageAccent)
                          .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: LinkableSvgIcon(
                  icon: _getTypeIcon(item.type),
                  size: 28,
                  semanticLabel: _getTypeLabel(item.type),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AccessibleText(
                            item.title,
                            style: TextStyle(
                              color: AppTheme.stageTextPrimary,
                              fontSize: AppTheme.fontSizeNormal,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isEmergency)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.stageDanger.withValues(
                                alpha: 0.18,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: AccessibleText(
                              '紧急',
                              style: TextStyle(
                                color: AppTheme.stageDanger,
                                fontSize: AppTheme.fontSizeSmall,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    AccessibleText(
                      '${item.seekerName} · ${item.timeAgo}',
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
          AccessibleText(
            item.description,
            style: TextStyle(
              color: AppTheme.stageTextSecondary,
              fontSize: AppTheme.fontSizeSmall,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.phone_in_talk_outlined, size: 18),
                  label: const Text('响应求助'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isEmergency
                        ? AppTheme.stageDanger
                        : AppTheme.stageAccent,
                    side: BorderSide(
                      color: isEmergency
                          ? AppTheme.stageDanger.withValues(alpha: 0.5)
                          : AppTheme.stageAccent.withValues(alpha: 0.5),
                    ),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  LinkableIconName _getTypeIcon(String type) {
    switch (type) {
      case 'ocr':
        return LinkableIconName.ocrText;
      case 'scene':
        return LinkableIconName.sceneDescribe;
      case 'sos':
        return LinkableIconName.emergency;
      case 'money':
        return LinkableIconName.moneyIdentify;
      default:
        return LinkableIconName.needHelp;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'ocr':
        return '文字识别';
      case 'scene':
        return '场景描述';
      case 'sos':
        return '紧急求助';
      case 'money':
        return '钞票识别';
      default:
        return '求助';
    }
  }
}

/// 待帮助请求数据模型
class _PendingHelpItem {
  const _PendingHelpItem({
    required this.id,
    required this.title,
    required this.description,
    required this.urgency,
    required this.type,
    required this.timeAgo,
    required this.seekerName,
  });

  final String id;
  final String title;
  final String description;
  final String urgency;
  final String type;
  final String timeAgo;
  final String seekerName;
}
