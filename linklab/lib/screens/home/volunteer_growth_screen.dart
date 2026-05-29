import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/extensions.dart';
import '../../core/utils/logger.dart';
import '../../models/point_transaction_model.dart';
import '../../models/skill_model.dart';
import '../../models/volunteer_level_model.dart';
import '../../providers/app_session_provider.dart';
import '../../services/user_center/volunteer_demo_store.dart';
import '../../services/user_center/volunteer_level_service.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_motion.dart';
import '../../widgets/demo/demo_stage.dart';
import '../../widgets/demo/linkable_icon.dart';

class VolunteerGrowthScreen extends ConsumerStatefulWidget {
  const VolunteerGrowthScreen({super.key});

  @override
  ConsumerState<VolunteerGrowthScreen> createState() =>
      _VolunteerGrowthScreenState();
}

class _VolunteerGrowthScreenState extends ConsumerState<VolunteerGrowthScreen> {
  final VolunteerLevelService _levelService = VolunteerLevelService();
  final VolunteerDemoStore _demoStore = VolunteerDemoStore();

  late Future<_VolunteerGrowthData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_VolunteerGrowthData> _loadData() async {
    try {
      final session = ref.read(appSessionProvider);
      final volunteerId = session.userProfile?.id ?? 'demo-volunteer-id';

      VolunteerLevelInfo level;
      try {
        level = await _levelService.getLevelInfo(volunteerId);
      } catch (_) {
        level = const VolunteerLevelInfo(
          currentLevel: 1,
          currentPoints: 0,
          pointsToNextLevel: 100,
          progressPercent: 0.0,
        );
      }

      List<PointTransactionModel> visibleTransactions;
      int contributionTotal;
      try {
        final transactions = await _demoStore.getTransactions(volunteerId);
        visibleTransactions = transactions.take(6).toList();
        contributionTotal = _sumContribution(visibleTransactions);
      } catch (_) {
        visibleTransactions = [];
        contributionTotal = 0;
      }

      List<SkillModel> skills;
      try {
        skills = await _demoStore.getSkills(volunteerId);
      } catch (_) {
        skills = [];
      }

      int completedCount;
      try {
        final activities = await _demoStore.getActivities(volunteerId);
        completedCount = activities.length;
      } catch (_) {
        completedCount = 0;
      }

      return _VolunteerGrowthData(
        level: _levelFromContributionTotal(contributionTotal, fallback: level),
        transactions: visibleTransactions,
        contributionTotal: contributionTotal,
        skills: skills.take(6).toList(),
        completedCount: completedCount,
      );
    } catch (e, st) {
      AppLogger.error('成长值数据加载失败', e, st);
      return _VolunteerGrowthData.fallback();
    }
  }

  int _sumContribution(List<PointTransactionModel> transactions) {
    return transactions.fold<int>(
      0,
      (sum, item) => sum + (item.isPositive ? item.points : -item.points),
    );
  }

  VolunteerLevelInfo _levelFromContributionTotal(
    int contributionTotal, {
    required VolunteerLevelInfo fallback,
  }) {
    if (contributionTotal <= 0) {
      return fallback.copyWith(
        currentLevel: 1,
        currentPoints: 0,
        pointsToNextLevel: LevelDefinitions.getPointsToNextLevel(0),
        progressPercent: LevelDefinitions.getProgressPercent(0),
        nextLevel: LevelDefinitions.getByLevel(2),
      );
    }

    final currentLevel = LevelDefinitions.calculateLevel(contributionTotal);
    final nextLevel = currentLevel >= 7
        ? null
        : LevelDefinitions.getByLevel(currentLevel + 1);

    return VolunteerLevelInfo(
      currentLevel: currentLevel,
      currentPoints: contributionTotal,
      pointsToNextLevel: LevelDefinitions.getPointsToNextLevel(
        contributionTotal,
      ),
      progressPercent: LevelDefinitions.getProgressPercent(contributionTotal),
      nextLevel: nextLevel,
      allLevels: LevelDefinitions.all,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadData();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(appSessionProvider);
    final name = session.userProfile?.displayName ?? '志愿者';

    return DemoStageScaffold(
      title: '成长值',
      subtitle: '志愿者服务记录、演示贡献值和技能覆盖',
      showBackButton: true,
      body: FutureBuilder<_VolunteerGrowthData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppTheme.stageDanger),
                  const SizedBox(height: AppTheme.spacingM),
                  AccessibleText(
                    '加载失败，请稍后重试',
                    style: TextStyle(color: AppTheme.stageTextPrimary),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  AccessibleIconButton(
                    icon: Icons.refresh,
                    semanticLabel: '重试',
                    onPressed: _refresh,
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return Semantics(
              label: '正在加载志愿者成长值',
              liveRegion: true,
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          final data = snapshot.data!;
          return RefreshIndicator(
            color: AppTheme.stageAccent,
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingL,
                AppTheme.spacingL,
                AppTheme.spacingL,
                112,
              ),
              children: [
                DemoReveal(
                  child: _GrowthHero(name: name, level: data.level),
                ),
                const SizedBox(height: AppTheme.spacingL),
                DemoReveal(
                  delay: const Duration(milliseconds: 60),
                  child: _ContributionLevelCard(
                    level: data.level,
                    contributionTotal: data.contributionTotal,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),
                DemoReveal(
                  delay: const Duration(milliseconds: 80),
                  child: Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          label: '已完成',
                          value: '${data.completedCount}',
                          icon: LinkableIconName.completed,
                          color: AppTheme.stageSuccess,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: _MetricCard(
                          label: '好评率',
                          value: '98%',
                          icon: LinkableIconName.like,
                          color: AppTheme.stageAccent,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: _MetricCard(
                          label: '响应',
                          value: '42秒',
                          icon: LinkableIconName.answer,
                          color: AppTheme.stageInfo,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXL),
                const DemoReveal(
                  delay: Duration(milliseconds: 120),
                  child: DemoSectionTitle(
                    title: '服务技能',
                    subtitle: '用于匹配用户问题，不开放复杂认证流程',
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                DemoReveal(
                  delay: const Duration(milliseconds: 150),
                  child: _SkillPanel(skills: data.skills),
                ),
                const SizedBox(height: AppTheme.spacingXL),
                const DemoReveal(
                  delay: Duration(milliseconds: 180),
                  child: DemoSectionTitle(
                    title: '最近贡献记录',
                    subtitle: '下方记录合计等于当前贡献值，不接积分商城',
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                DemoReveal(
                  delay: const Duration(milliseconds: 210),
                  child: _ContributionList(
                    items: data.transactions,
                    total: data.contributionTotal,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXL),
                const DemoReveal(
                  delay: Duration(milliseconds: 240),
                  child: _VolunteerRulesCard(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GrowthHero extends StatelessWidget {
  const _GrowthHero({required this.name, required this.level});

  final String name;
  final VolunteerLevelInfo level;

  @override
  Widget build(BuildContext context) {
    final current = level.currentLevelDef;
    final next = level.nextLevel;

    return DemoSurfaceCard(
      semanticLabel:
          '$name 的志愿者成长值，当前 ${level.currentPoints} 点，等级 ${current.name}',
      color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: AppTheme.stageAccentGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const LinkableSvgIcon(
                  icon: LinkableIconName.points,
                  size: 46,
                  semanticLabel: '成长值',
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AccessibleText(
                      name,
                      style: TextStyle(
                        color: AppTheme.stageTextPrimary,
                        fontSize: AppTheme.fontSizeLarge,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    AccessibleText(
                      'Lv${level.currentLevel} ${current.name} · ${current.description ?? '志愿服务中'}',
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
          const SizedBox(height: AppTheme.spacingL),
          AccessibleText(
            '${level.currentPoints}',
            style: TextStyle(
              color: AppTheme.stageAccent,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          AccessibleText(
            '演示贡献值',
            style: TextStyle(
              color: AppTheme.stageTextSecondary,
              fontSize: AppTheme.fontSizeSmall,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: level.progressPercent.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: AppTheme.stageSurface,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.stageAccent),
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          AccessibleText(
            next == null
                ? '已达到当前演示最高等级'
                : '距离 ${next.name} 还需 ${level.pointsToNextLevel} 点',
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

class _ContributionLevelCard extends StatelessWidget {
  const _ContributionLevelCard({
    required this.level,
    required this.contributionTotal,
  });

  final VolunteerLevelInfo level;
  final int contributionTotal;

  @override
  Widget build(BuildContext context) {
    final current = level.currentLevelDef;

    return DemoSurfaceCard(
      semanticLabel:
          '贡献等级说明，当前贡献等级 Lv${level.currentLevel} ${current.name}，最近贡献记录合计 $contributionTotal 点',
      color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: AppTheme.minTouchTarget,
                height: AppTheme.minTouchTarget,
                decoration: BoxDecoration(
                  color: AppTheme.stageAccent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusMedium,
                  ),
                ),
                child: Icon(
                  Icons.diversity_3_outlined,
                  color: AppTheme.stageAccent,
                  size: 30,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AccessibleText(
                      '贡献等级说明',
                      style: TextStyle(
                        color: AppTheme.stageTextPrimary,
                        fontSize: AppTheme.fontSizeLarge,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    AccessibleText(
                      '当前 Lv${level.currentLevel} ${current.name}，由最近贡献记录合计 $contributionTotal 点计算。',
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
          const _RuleLine(
            icon: Icons.manage_search_outlined,
            text: '贡献等级会展示在匹配和志愿者信息中，帮助求助者理解你的服务经验。',
          ),
          const SizedBox(height: AppTheme.spacingS),
          const _RuleLine(
            icon: Icons.verified_user_outlined,
            text: '等级只作为信任提示和匹配参考，不代表平台认证、排行或兑换权益。',
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final LinkableIconName icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DemoSurfaceCard(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        children: [
          LinkableSvgIcon(icon: icon, size: 30, semanticLabel: label),
          const SizedBox(height: AppTheme.spacingS),
          AccessibleText(
            value,
            style: TextStyle(
              color: color,
              fontSize: AppTheme.fontSizeLarge,
              fontWeight: FontWeight.w900,
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

class _SkillPanel extends StatelessWidget {
  const _SkillPanel({required this.skills});

  final List<SkillModel> skills;

  @override
  Widget build(BuildContext context) {
    return DemoSurfaceCard(
      child: Wrap(
        spacing: AppTheme.spacingS,
        runSpacing: AppTheme.spacingS,
        children: [
          if (skills.isEmpty)
            DemoPill(
              label: '实时语音协助',
              icon: Icons.record_voice_over_outlined,
              color: AppTheme.stageAccentLight,
            )
          else
            for (final skill in skills)
              DemoPill(
                label: skill.name,
                icon: skill.isVerified
                    ? Icons.verified_outlined
                    : Icons.label_outline,
                color: AppTheme.stageAccentLight,
              ),
        ],
      ),
    );
  }
}

class _ContributionList extends StatelessWidget {
  const _ContributionList({required this.items, required this.total});

  final List<PointTransactionModel> items;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const DemoSurfaceCard(
        child: AccessibleText('暂无贡献记录，完成一次用户问题后会显示在这里。'),
      );
    }

    return Column(
      children: [
        DemoSurfaceCard(
          semanticLabel: '最近贡献记录合计 $total 点，与顶部贡献值一致',
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Row(
            children: [
              Icon(
                Icons.equalizer_outlined,
                color: AppTheme.stageAccent,
                size: 28,
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: AccessibleText(
                  '最近记录合计',
                  style: TextStyle(
                    color: AppTheme.stageTextPrimary,
                    fontSize: AppTheme.fontSizeNormal,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              AccessibleText(
                '$total',
                style: TextStyle(
                  color: AppTheme.stageAccent,
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
            child: _ContributionRow(item: item),
          ),
      ],
    );
  }
}

class _ContributionRow extends StatelessWidget {
  const _ContributionRow({required this.item});

  final PointTransactionModel item;

  @override
  Widget build(BuildContext context) {
    final positive = item.isPositive;
    final color = positive ? AppTheme.stageSuccess : AppTheme.stageDanger;
    final sign = positive ? '+' : '';

    return DemoSurfaceCard(
      semanticLabel:
          '${item.description}，贡献值 $sign${item.points}，${item.createdAt?.formatRelative() ?? '刚刚'}',
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              positive ? Icons.add_task_outlined : Icons.remove_circle_outline,
              color: color,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccessibleText(
                  item.description ?? '完成一次志愿服务',
                  style: TextStyle(
                    color: AppTheme.stageTextPrimary,
                    fontSize: AppTheme.fontSizeNormal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                AccessibleText(
                  item.createdAt?.formatRelative() ?? '刚刚',
                  style: TextStyle(
                    color: AppTheme.stageTextSecondary,
                    fontSize: AppTheme.fontSizeSmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingS),
          AccessibleText(
            '$sign${item.points}',
            style: TextStyle(
              color: color,
              fontSize: AppTheme.fontSizeLarge,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _VolunteerRulesCard extends StatelessWidget {
  const _VolunteerRulesCard();

  @override
  Widget build(BuildContext context) {
    return DemoSurfaceCard(
      color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AccessibleText(
            '志愿者侧规则',
            style: TextStyle(
              color: AppTheme.stageTextPrimary,
              fontSize: AppTheme.fontSizeLarge,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          const _RuleLine(
            icon: Icons.health_and_safety_outlined,
            text: '紧急问题优先响应，普通问题按技能匹配。',
          ),
          const SizedBox(height: AppTheme.spacingS),
          const _RuleLine(
            icon: Icons.privacy_tip_outlined,
            text: '不展示求助者真实姓名和精确地址。',
          ),
          const SizedBox(height: AppTheme.spacingS),
          const _RuleLine(
            icon: Icons.card_giftcard_outlined,
            text: '当前贡献值仅用于 Demo 反馈，不代表真实积分兑换。',
          ),
        ],
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.stageAccent, size: 22),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(
          child: AccessibleText(
            text,
            style: TextStyle(
              color: AppTheme.stageTextSecondary,
              fontSize: AppTheme.fontSizeSmall,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _VolunteerGrowthData {
  const _VolunteerGrowthData({
    required this.level,
    required this.contributionTotal,
    required this.transactions,
    required this.skills,
    required this.completedCount,
  });

  factory _VolunteerGrowthData.fallback() {
    return _VolunteerGrowthData(
      level: const VolunteerLevelInfo(
        currentLevel: 1,
        currentPoints: 0,
        pointsToNextLevel: 100,
        progressPercent: 0.0,
      ),
      contributionTotal: 0,
      transactions: [],
      skills: [],
      completedCount: 0,
    );
  }

  final VolunteerLevelInfo level;
  final int contributionTotal;
  final List<PointTransactionModel> transactions;
  final List<SkillModel> skills;
  final int completedCount;
}
