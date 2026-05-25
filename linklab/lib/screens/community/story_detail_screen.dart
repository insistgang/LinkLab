import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/community_models.dart';
import '../../providers/community_provider.dart';
import '../../services/community/featured_story_service.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_stage.dart';
import '../../widgets/demo/linkable_icon.dart';

/// 故事详情页面 —— 纯静态展示，不开放互动功能（AGENTS.md §4 F24-F27 降级）
class StoryDetailScreen extends ConsumerStatefulWidget {
  const StoryDetailScreen({super.key, required this.story});

  final FeaturedStory story;

  @override
  ConsumerState<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends ConsumerState<StoryDetailScreen> {
  late FeaturedStory _story;

  FeaturedStoryService get _storyService => ref.read(featuredStoryProvider);

  @override
  void initState() {
    super.initState();
    _story = widget.story;
    _loadStory();
  }

  Future<void> _loadStory() async {
    final detail = await _storyService.getStoryDetail(_story.id);
    if (!mounted || detail == null) return;
    setState(() => _story = detail);
  }

  @override
  Widget build(BuildContext context) {
    return DemoStageScaffold(
      title: '故事详情',
      subtitle: '精选故事只做静态展示，不开放互动社区',
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingL,
          AppTheme.spacingL,
          AppTheme.spacingL,
          96,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AccessibleText(
              _story.title,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeXLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: _story.authorAvatar != null
                      ? NetworkImage(_story.authorAvatar!)
                      : null,
                  child: _story.authorAvatar == null
                      ? const LinkableMaterialIcon(
                          icon: Icons.person,
                          semanticLabel: '作者头像',
                        )
                      : null,
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AccessibleText(
                        _story.authorType == 'anonymous'
                            ? '匿名用户'
                            : (_story.authorName ?? '用户'),
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeNormal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      AccessibleText(
                        _formatDate(_story.createdAt),
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: AppTheme.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingL),
            if (_story.coverImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                child: Image.network(
                  _story.coverImage!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            if (_story.coverImage != null)
              const SizedBox(height: AppTheme.spacingL),
            AccessibleText(
              _story.content,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeNormal,
                height: 1.8,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXL),
            // 静态统计栏：仅展示阅读数，不含点赞/分享等互动功能
            Semantics(
              label: '阅读 ${_story.readCount} 次',
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundGrey,
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusMedium,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LinkableMaterialIcon(
                      icon: Icons.remove_red_eye,
                      size: 24,
                      color: AppTheme.textHint,
                      semanticLabel: '阅读次数',
                    ),
                    const SizedBox(width: AppTheme.spacingXS),
                    AccessibleText(
                      '${_story.readCount} 次阅读',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeNormal,
                        color: AppTheme.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
