import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/community_models.dart';
import '../../services/community/featured_story_service.dart';
import '../../widgets/accessible/index.dart';

/// 故事详情页面
class StoryDetailScreen extends StatefulWidget {
  const StoryDetailScreen({
    super.key,
    required this.story,
  });

  final FeaturedStory story;

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  final _storyService = FeaturedStoryService();
  late FeaturedStory _story;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _story = widget.story;
    _checkLikeStatus();
  }

  Future<void> _checkLikeStatus() async {
    // TODO: 获取当前用户ID
    const userId = 'current_user_id';
    final hasLiked = await _storyService.hasLiked(_story.id, userId);
    setState(() => _isLiked = hasLiked);
  }

  Future<void> _toggleLike() async {
    try {
      // TODO: 获取当前用户ID
      const userId = 'current_user_id';

      if (_isLiked) {
        await _storyService.unlikeStory(_story.id, userId);
        setState(() {
          _isLiked = false;
          _story = _story.copyWith(likeCount: _story.likeCount - 1);
        });
      } else {
        await _storyService.likeStory(_story.id, userId);
        setState(() {
          _isLiked = true;
          _story = _story.copyWith(likeCount: _story.likeCount + 1);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AccessibleScaffold(
      title: '故事详情',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            AccessibleText(
              _story.title,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeXLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            // 作者信息
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: _story.authorAvatar != null
                      ? NetworkImage(_story.authorAvatar!)
                      : null,
                  child: _story.authorAvatar == null
                      ? const Icon(Icons.person)
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
            // 封面图
            if (_story.coverImage != null)
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppTheme.borderRadiusLarge),
                child: Image.network(
                  _story.coverImage!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            if (_story.coverImage != null)
              const SizedBox(height: AppTheme.spacingL),
            // 内容
            AccessibleText(
              _story.content,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeNormal,
                height: 1.8,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXL),
            // 互动栏
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.backgroundGrey,
                borderRadius:
                    BorderRadius.circular(AppTheme.borderRadiusMedium),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ActionButton(
                    icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                    label: '${_story.likeCount}',
                    color: _isLiked ? AppTheme.errorColor : AppTheme.textHint,
                    onTap: _toggleLike,
                  ),
                  _ActionButton(
                    icon: Icons.remove_red_eye,
                    label: '${_story.readCount}',
                    onTap: () {},
                  ),
                  _ActionButton(
                    icon: Icons.share,
                    label: '分享',
                    onTap: () {
                      // TODO: 分享功能
                    },
                  ),
                ],
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

/// 操作按钮
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: color ?? AppTheme.textHint),
            const SizedBox(width: AppTheme.spacingXS),
            AccessibleText(
              label,
              style: TextStyle(
                fontSize: AppTheme.fontSizeNormal,
                color: color ?? AppTheme.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
