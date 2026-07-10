import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../demo_data/community_groups.dart';
import '../../models/community_group_model.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_motion.dart';
import '../../widgets/demo/demo_stage.dart';
import '../../widgets/demo/linkable_icon.dart';

/// 小组详情页 - 显示小组信息和讨论列表
class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key, required this.group});

  final CommunityGroup group;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late List<GroupDiscussion> _discussions;

  @override
  void initState() {
    super.initState();
    _discussions = CommunityGroupsData.getDiscussions(widget.group.id);
  }

  @override
  Widget build(BuildContext context) {
    return DemoStageScaffold(
      title: widget.group.name,
      subtitle: widget.group.categoryLabel,
      showBackButton: true,
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.stageAccent,
              onRefresh: () async {
                // 模拟刷新
                await Future.delayed(const Duration(milliseconds: 500));
                setState(() {
                  _discussions = CommunityGroupsData.getDiscussions(
                    widget.group.id,
                  );
                });
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingL,
                  AppTheme.spacingL,
                  AppTheme.spacingL,
                  AppTheme.spacingL,
                ),
                children: [
                  DemoReveal(child: _GroupInfoCard(group: widget.group)),
                  const SizedBox(height: AppTheme.spacingL),
                  DemoReveal(
                    delay: const Duration(milliseconds: 80),
                    child: _SectionHeader(
                      title: '小组讨论',
                      subtitle: '共 ${_discussions.length} 条讨论',
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  ..._discussions.map(
                    (discussion) => Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                      child: DemoReveal(
                        delay: const Duration(milliseconds: 120),
                        child: _DiscussionCard(discussion: discussion),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}

/// 小组信息卡片
class _GroupInfoCard extends StatelessWidget {
  const _GroupInfoCard({required this.group});

  final CommunityGroup group;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '小组信息，${group.name}，${group.description}，${group.formattedMemberCount}人加入',
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: AppTheme.stageCardDecoration(
          color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + 4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppTheme.stageAccentGradient,
                    borderRadius: BorderRadius.circular(
                      AppTheme.borderRadiusMedium,
                    ),
                  ),
                  child: LinkableSvgIcon(
                    icon: group.icon,
                    size: 44,
                    semanticLabel: group.name,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: TextStyle(
                          color: AppTheme.stageTextPrimary,
                          fontSize: AppTheme.fontSizeXLarge,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXS),
                      Row(
                        children: [
                          _MetaTag(
                            icon: LinkableIconName.profile,
                            label: '${group.formattedMemberCount}人',
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                          _MetaTag(
                            icon: LinkableIconName.processing,
                            label: group.lastActiveDescription,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              group.description,
              style: TextStyle(
                color: AppTheme.stageTextSecondary,
                fontSize: AppTheme.fontSizeNormal,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Wrap(
              spacing: AppTheme.spacingS,
              runSpacing: AppTheme.spacingS,
              children: [
                _CategoryChip(category: group.category),
                _ActionButton(
                  icon: LinkableIconName.group,
                  label: '加入小组',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '已申请加入（Demo模式）',
                          style: TextStyle(color: AppTheme.stageTextPrimary),
                        ),
                        backgroundColor: AppTheme.stageAccent,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 分类标签
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '分类：${CommunityGroupCategory.getLabel(category)}',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingXS,
        ),
        decoration: BoxDecoration(
          color: AppTheme.stageAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppTheme.stageAccent.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinkableSvgIcon(
              icon: CommunityGroupCategory.getIcon(category),
              size: 18,
              semanticLabel: CommunityGroupCategory.getLabel(category),
            ),
            const SizedBox(width: AppTheme.spacingXS),
            Text(
              CommunityGroupCategory.getLabel(category),
              style: TextStyle(
                color: AppTheme.stageAccent,
                fontSize: AppTheme.fontSizeSmall,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 操作按钮
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final LinkableIconName icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingXS,
          ),
          decoration: BoxDecoration(
            color: AppTheme.stageSurface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppTheme.stageBorder.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinkableSvgIcon(icon: icon, size: 18, semanticLabel: label),
              const SizedBox(width: AppTheme.spacingXS),
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.stageTextPrimary,
                  fontSize: AppTheme.fontSizeSmall,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 元数据标签
class _MetaTag extends StatelessWidget {
  const _MetaTag({required this.icon, required this.label});

  final LinkableIconName icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingS,
          vertical: AppTheme.spacingXS,
        ),
        decoration: BoxDecoration(
          color: AppTheme.stageSurface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppTheme.stageBorder.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinkableSvgIcon(icon: icon, size: 16, semanticLabel: label),
            const SizedBox(width: AppTheme.spacingXS),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.stageTextSecondary,
                fontSize: AppTheme.fontSizeXSmall,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 区域标题
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.stageTextPrimary,
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingXS),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppTheme.stageTextSecondary,
                  fontSize: AppTheme.fontSizeSmall,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 讨论卡片
class _DiscussionCard extends StatelessWidget {
  const _DiscussionCard({required this.discussion});

  final GroupDiscussion discussion;

  @override
  Widget build(BuildContext context) {
    return AccessibleCard(
      semanticLabel: '${discussion.userName}说：${discussion.content}',
      hint: '双击查看详情',
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '查看讨论详情（Demo模式）',
              style: TextStyle(color: AppTheme.stageTextPrimary),
            ),
            backgroundColor: AppTheme.stageAccent,
          ),
        );
      },
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: AppTheme.stageCardDecoration(
          color: AppTheme.stageSurface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          borderColor: AppTheme.stageBorder.withValues(alpha: 0.58),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: AppTheme.minTouchTarget,
                  height: AppTheme.minTouchTarget,
                  decoration: BoxDecoration(
                    color: AppTheme.stageAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      discussion.userName[0],
                      style: TextStyle(
                        color: AppTheme.stageAccent,
                        fontSize: AppTheme.fontSizeLarge,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        discussion.userName,
                        style: TextStyle(
                          color: AppTheme.stageTextPrimary,
                          fontSize: AppTheme.fontSizeNormal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        discussion.formattedTime,
                        style: TextStyle(
                          color: AppTheme.stageTextSecondary,
                          fontSize: AppTheme.fontSizeXSmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              discussion.content,
              style: TextStyle(
                color: AppTheme.stageTextPrimary,
                fontSize: AppTheme.fontSizeNormal,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Row(
              children: [
                _InteractionButton(
                  icon: LinkableIconName.like,
                  label: '点赞 ${discussion.likeCount}',
                  onTap: () {},
                ),
                const SizedBox(width: AppTheme.spacingL),
                _InteractionButton(
                  icon: LinkableIconName.message,
                  label: '回复 ${discussion.replyCount}',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 交互按钮
class _InteractionButton extends StatelessWidget {
  const _InteractionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final LinkableIconName icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingS,
            vertical: AppTheme.spacingXS,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinkableSvgIcon(
                icon: icon,
                size: 20,
                semanticLabel: label,
              ),
              const SizedBox(width: AppTheme.spacingXS),
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.stageTextSecondary,
                  fontSize: AppTheme.fontSizeXSmall,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}