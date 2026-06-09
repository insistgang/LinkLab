import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/community_models.dart';
import '../../providers/community_provider.dart';
import '../../services/community/featured_story_service.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_motion.dart';
import '../../widgets/demo/demo_stage.dart';
import '../../widgets/demo/linkable_icon.dart';
import '../community/story_detail_screen.dart';

/// 社羣降級頁：僅展示精選故事和未來藍圖，不開放互動社區入口。
class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  List<FeaturedStory> _featuredStories = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    setState(() => _isLoading = true);
    final storyService = ref.read(featuredStoryProvider);
    final stories = await storyService.getDailyFeatured(limit: 3);
    if (!mounted) return;
    setState(() {
      _featuredStories = stories;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DemoStageScaffold(
      title: '社羣',
      subtitle: '精選故事只做價值展示，互動社羣作爲 V1.0 藍圖',
      showBackButton: false,
      body: RefreshIndicator(
        color: AppTheme.stageAccent,
        onRefresh: _loadStories,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingL,
            AppTheme.spacingL,
            AppTheme.spacingL,
            112,
          ),
          children: [
            const DemoReveal(child: _CommunityHero()),
            const SizedBox(height: AppTheme.spacingL),
            DemoReveal(
              delay: const Duration(milliseconds: 80),
              child: _SectionHeader(
                title: '精選故事',
                subtitle: '3 條真實互助場景，用於競賽展示與價值說明',
                trailing: IconButton(
                  tooltip: '刷新精選故事',
                  onPressed: _loadStories,
                  icon: const LinkableSvgIcon(
                    icon: LinkableIconName.processing,
                    size: 28,
                    semanticLabel: '刷新精選故事',
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            DemoReveal(
              delay: const Duration(milliseconds: 160),
              child: _buildStoriesList(),
            ),
            const SizedBox(height: AppTheme.spacingL),
            const DemoReveal(
              delay: Duration(milliseconds: 200),
              child: _BlueprintPanel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoriesList() {
    if (_isLoading) {
      return Semantics(
        label: '正在加載精選故事',
        liveRegion: true,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: AppTheme.spacingXL),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_featuredStories.isEmpty) {
      return const _EmptyStoriesCard();
    }

    return Column(
      children: [
        for (final story in _featuredStories)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
            child: _StoryCard(
              story: story,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StoryDetailScreen(story: story),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _CommunityHero extends StatelessWidget {
  const _CommunityHero();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '社羣頁，展示精選互助故事和未來藍圖',
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: AppTheme.stageCardDecoration(
          color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + 4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: AppTheme.minTouchTarget,
              height: AppTheme.minTouchTarget,
              decoration: BoxDecoration(
                gradient: AppTheme.stageAccentGradient,
                borderRadius: BorderRadius.circular(
                  AppTheme.borderRadiusMedium,
                ),
              ),
              child: const LinkableSvgIcon(
                icon: LinkableIconName.community,
                size: 44,
                semanticLabel: '社羣',
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              '社羣',
              style: TextStyle(
                color: AppTheme.stageTextPrimary,
                fontSize: AppTheme.fontSizeXLarge,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              '這裏先展示精選互助故事。羣聊、地區社區和積分互動屬於後續版本，不進入當前 3 分鐘 Demo 主線。',
              style: TextStyle(
                color: AppTheme.stageTextSecondary,
                fontSize: AppTheme.fontSizeNormal,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

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
        ?trailing,
      ],
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.story, required this.onTap});

  final FeaturedStory story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final author = story.authorType == 'anonymous'
        ? '匿名用戶'
        : (story.authorName ?? '用戶');
    final excerpt = story.summary ?? _shorten(story.content);

    return AccessibleCard(
      semanticLabel: '精選故事，${story.title}',
      hint: '雙擊查看故事詳情',
      onTap: onTap,
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: AppTheme.minTouchTarget,
              height: AppTheme.minTouchTarget,
              decoration: BoxDecoration(
                color: AppTheme.stageAccent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(
                  AppTheme.borderRadiusMedium,
                ),
                border: Border.all(
                  color: AppTheme.stageAccent.withValues(alpha: 0.32),
                ),
              ),
              child: const LinkableSvgIcon(
                icon: LinkableIconName.dailyStory,
                size: 44,
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.title,
                    style: TextStyle(
                      color: AppTheme.stageTextPrimary,
                      fontSize: AppTheme.fontSizeLarge,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    excerpt,
                    style: TextStyle(
                      color: AppTheme.stageTextSecondary,
                      fontSize: AppTheme.fontSizeNormal,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Wrap(
                    spacing: AppTheme.spacingS,
                    runSpacing: AppTheme.spacingS,
                    children: [
                      _StoryMeta(icon: LinkableIconName.profile, label: author),
                      _StoryMeta(
                        icon: LinkableIconName.sceneDescribe,
                        label: '${story.readCount} 次閱讀',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spacingS),
            const LinkableSvgIcon(
              icon: LinkableIconName.navigationGuide,
              size: 28,
              semanticLabel: '查看詳情',
            ),
          ],
        ),
      ),
    );
  }

  String _shorten(String value) {
    if (value.length <= 54) return value;
    return '${value.substring(0, 54)}...';
  }
}

class _StoryMeta extends StatelessWidget {
  const _StoryMeta({required this.icon, required this.label});

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
          color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppTheme.stageBorder.withValues(alpha: 0.46),
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
                color: AppTheme.stageTextSecondary,
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

class _BlueprintPanel extends StatelessWidget {
  const _BlueprintPanel();

  @override
  Widget build(BuildContext context) {
    final items = const [
      _BlueprintItem(
        icon: LinkableIconName.volunteerMatch,
        title: '地區社羣',
        body: '後續用於同城志願者互助與活動組織。',
      ),
      _BlueprintItem(
        icon: LinkableIconName.completed,
        title: '公益成長',
        body: '後續再評估積分、徽章和志願者成長體系。',
      ),
      _BlueprintItem(
        icon: LinkableIconName.emergencyContact,
        title: '安全治理',
        body: '舉報、黑名單、內容審覈會先服務主求助鏈路。',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: AppTheme.stageCardDecoration(
        color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              '未來藍圖',
              style: TextStyle(
                color: AppTheme.stageTextPrimary,
                fontSize: AppTheme.fontSizeLarge,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            '這些能力僅作爲 V1.0 展示，不會影響當前 AI、匹配、通話和 SOS 演示閉環。',
            style: TextStyle(
              color: AppTheme.stageTextSecondary,
              fontSize: AppTheme.fontSizeNormal,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          for (final item in items) ...[
            item,
            if (item != items.last) const SizedBox(height: AppTheme.spacingS),
          ],
        ],
      ),
    );
  }
}

class _BlueprintItem extends StatelessWidget {
  const _BlueprintItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  final LinkableIconName icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title，$body',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppTheme.minTouchTarget,
            height: AppTheme.minTouchTarget,
            child: LinkableSvgIcon(icon: icon, size: 42, semanticLabel: title),
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.stageTextPrimary,
                    fontSize: AppTheme.fontSizeNormal,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  body,
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
      ),
    );
  }
}

class _EmptyStoriesCard extends StatelessWidget {
  const _EmptyStoriesCard();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '暫無精選故事，可稍後刷新',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: AppTheme.stageCardDecoration(
          color: AppTheme.stageSurface.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        ),
        child: Column(
          children: [
            const LinkableSvgIcon(
              icon: LinkableIconName.processing,
              size: AppTheme.minTouchTarget,
              semanticLabel: '暫無精選故事',
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              '暫無精選故事',
              style: TextStyle(
                color: AppTheme.stageTextPrimary,
                fontSize: AppTheme.fontSizeLarge,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              '可以稍後刷新，或繼續完成 AI 求助主流程演示。',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.stageTextSecondary,
                fontSize: AppTheme.fontSizeNormal,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}