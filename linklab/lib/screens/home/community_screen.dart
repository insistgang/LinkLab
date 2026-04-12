import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/community_models.dart';
import '../../services/community/featured_story_service.dart';
import '../../widgets/accessible/index.dart';
import '../community/community_screens_exports.dart';

/// 社群页面
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _storyService = FeaturedStoryService();
  List<FeaturedStory> _featuredStories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    setState(() => _isLoading = true);
    final stories = await _storyService.getDailyFeatured(limit: 3);
    setState(() {
      _featuredStories = stories;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AccessibleScaffold(
      title: '社群',
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 功能入口网格
              _buildFeatureGrid(),
              const SizedBox(height: AppTheme.spacingXL),
              // 精选故事
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AccessibleText(
                    '精选故事',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: 查看全部故事
                    },
                    child: const AccessibleText('查看更多'),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              _buildStoriesList(),
              const SizedBox(height: AppTheme.spacingXL),
              // 新手村
              const AccessibleText(
                '新手村',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              AccessibleCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NewbieVillageScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      width: AppTheme.minTouchTarget * 1.2,
                      height: AppTheme.minTouchTarget * 1.2,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                      ),
                      child: const Icon(
                        Icons.school,
                        size: AppTheme.fontSizeXLarge,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingL),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AccessibleText(
                            '新手指南',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeLarge,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: AppTheme.spacingXS),
                          AccessibleText(
                            '完成3个模拟场景，成为正式志愿者',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeNormal,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: AppTheme.textHint,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingXL),
              // 志愿者招募
              Semantics(
                label: '志愿者招募',
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppTheme.secondaryColor,
                        AppTheme.secondaryLight,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AccessibleText(
                        '成为志愿者',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeXLarge,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textOnPrimary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      const AccessibleText(
                        '用您的眼睛，帮助需要的人',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeNormal,
                          color: AppTheme.textOnPrimary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingL),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NewbieVillageScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.textOnPrimary,
                          foregroundColor: AppTheme.secondaryColor,
                          minimumSize: const Size(double.infinity, AppTheme.buttonHeight),
                        ),
                        child: const AccessibleText(
                          '立即申请',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeLarge,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建功能入口网格
  Widget _buildFeatureGrid() {
    final features = [
      {
        'icon': Icons.group,
        'label': '兴趣小组',
        'color': AppTheme.primaryColor,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const InterestGroupsScreen(),
            ),
          );
        },
      },
      {
        'icon': Icons.location_city,
        'label': '地区社群',
        'color': AppTheme.secondaryColor,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RegionalCommunityScreen(),
            ),
          );
        },
      },
      {
        'icon': Icons.auto_stories,
        'label': '精选故事',
        'color': Colors.orange,
        'onTap': () {
          // TODO: 打开故事列表
        },
      },
      {
        'icon': Icons.school,
        'label': '新手村',
        'color': Colors.green,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewbieVillageScreen(),
            ),
          );
        },
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return _FeatureItem(
          icon: feature['icon'] as IconData,
          label: feature['label'] as String,
          color: feature['color'] as Color,
          onTap: feature['onTap'] as VoidCallback,
        );
      },
    );
  }

  /// 构建故事列表
  Widget _buildStoriesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_featuredStories.isEmpty) {
      return const Center(
        child: AccessibleText(
          '暂无精选故事',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return Column(
      children: _featuredStories.map((story) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
          child: _StoryCard(
            title: story.title,
            excerpt: story.summary ?? story.content.substring(0, story.content.length > 50 ? 50 : story.content.length),
            author: story.authorType == 'anonymous'
                ? '匿名用户'
                : (story.authorName ?? '用户'),
            readTime: '${story.readCount}次阅读',
            coverImage: story.coverImage,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StoryDetailScreen(story: story),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }
}

/// 功能入口项
class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            ),
            child: Icon(
              icon,
              size: 28,
              color: color,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          AccessibleText(
            label,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 故事卡片
class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.title,
    required this.excerpt,
    required this.author,
    required this.readTime,
    this.coverImage,
    required this.onTap,
  });

  final String title;
  final String excerpt;
  final String author;
  final String readTime;
  final String? coverImage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AccessibleCard(
      semanticLabel: title,
      hint: excerpt,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccessibleText(
                  title,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spacingS),
                AccessibleText(
                  excerpt,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeNormal,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spacingM),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: AppTheme.fontSizeNormal,
                      color: AppTheme.textHint,
                    ),
                    const SizedBox(width: AppTheme.spacingXS),
                    AccessibleText(
                      author,
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: AppTheme.textHint,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingL),
                    Icon(
                      Icons.remove_red_eye,
                      size: AppTheme.fontSizeNormal,
                      color: AppTheme.textHint,
                    ),
                    const SizedBox(width: AppTheme.spacingXS),
                    AccessibleText(
                      readTime,
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: AppTheme.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (coverImage != null) ...[
            const SizedBox(width: AppTheme.spacingM),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
              child: Image.network(
                coverImage!,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  color: AppTheme.backgroundGrey,
                  child: const Icon(Icons.image, color: AppTheme.textHint),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
