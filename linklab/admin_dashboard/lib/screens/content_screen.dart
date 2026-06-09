import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../bloc/content_bloc.dart';
import '../constants/app_constants.dart';
import '../constants/theme.dart';
import '../models/content_model.dart';

class ContentScreen extends StatelessWidget {
  const ContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ContentBloc()..add(const ContentLoadStoriesRequested()),
      child: const _ContentContent(),
    );
  }
}

class _ContentContent extends StatefulWidget {
  const _ContentContent();

  @override
  State<_ContentContent> createState() => _ContentContentState();
}

class _ContentContentState extends State<_ContentContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      if (_tabController.index == 0) {
        context.read<ContentBloc>().add(const ContentLoadStoriesRequested());
      } else {
        context.read<ContentBloc>().add(const ContentLoadCommunityRequested());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('內容管理'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '精選故事'),
            Tab(text: '社羣內容'),
          ],
        ),
      ),
      body: BlocConsumer<ContentBloc, ContentState>(
        listener: (context, state) {
          if (state is ContentActionSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          } else if (state is ContentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        builder: (context, state) {
          return TabBarView(
            controller: _tabController,
            children: [_buildStoriesTab(state), _buildCommunityTab(state)],
          );
        },
      ),
    );
  }

  Widget _buildStoriesTab(ContentState state) {
    if (state is ContentLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ContentStoriesLoaded) {
      return _StoriesList(
        stories: state.stories,
        hasMore: state.hasMore,
        onLoadMore: () {
          context.read<ContentBloc>().add(
            ContentLoadStoriesRequested(
              page: state.page + 1,
              pageSize: state.pageSize,
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCommunityTab(ContentState state) {
    if (state is ContentLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ContentCommunityLoaded) {
      return _CommunityList(
        contents: state.contents,
        hasMore: state.hasMore,
        onLoadMore: () {
          context.read<ContentBloc>().add(
            ContentLoadCommunityRequested(
              page: state.page + 1,
              pageSize: state.pageSize,
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}

class _StoriesList extends StatelessWidget {
  final List<StoryModel> stories;
  final bool hasMore;
  final VoidCallback onLoadMore;

  const _StoriesList({
    required this.stories,
    required this.hasMore,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    if (isMobile) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: stories.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == stories.length) {
            return Center(
              child: TextButton(
                onPressed: onLoadMore,
                child: const Text('加載更多'),
              ),
            );
          }
          return _StoryCard(
            story: stories[index],
            onPublish: () {
              context.read<ContentBloc>().add(
                ContentUpdateStoryStatus(
                  stories[index].id,
                  ContentStatus.published,
                ),
              );
            },
            onArchive: () {
              context.read<ContentBloc>().add(
                ContentUpdateStoryStatus(
                  stories[index].id,
                  ContentStatus.archived,
                ),
              );
            },
            onSetFeatured: (isFeatured) {
              context.read<ContentBloc>().add(
                ContentSetStoryFeatured(stories[index].id, isFeatured),
              );
            },
          );
        },
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ...stories.map(
            (story) => _StoryCard(
              story: story,
              onPublish: () {
                context.read<ContentBloc>().add(
                  ContentUpdateStoryStatus(story.id, ContentStatus.published),
                );
              },
              onArchive: () {
                context.read<ContentBloc>().add(
                  ContentUpdateStoryStatus(story.id, ContentStatus.archived),
                );
              },
              onSetFeatured: (isFeatured) {
                context.read<ContentBloc>().add(
                  ContentSetStoryFeatured(story.id, isFeatured),
                );
              },
            ),
          ),
          if (hasMore)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: onLoadMore,
                child: const Text('加載更多'),
              ),
            ),
        ],
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  final StoryModel story;
  final VoidCallback onPublish;
  final VoidCallback onArchive;
  final Function(bool) onSetFeatured;

  const _StoryCard({
    required this.story,
    required this.onPublish,
    required this.onArchive,
    required this.onSetFeatured,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image
          if (story.coverImage != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                story.coverImage!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.image)),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        story.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (story.isFeatured)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: AppTheme.warningColor,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '精選',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.warningColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(width: 8),
                    _buildStatusChip(story.status),
                  ],
                ),
                const SizedBox(height: 8),
                // Summary
                Text(
                  story.summary,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Author & Stats
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: story.authorAvatar != null
                          ? NetworkImage(story.authorAvatar!)
                          : null,
                      child: story.authorAvatar == null
                          ? Text(story.authorName.substring(0, 1))
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      story.authorName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.remove_red_eye,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      story.viewCount.toString(),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.favorite, size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      story.likeCount.toString(),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Actions
                Row(
                  children: [
                    if (story.status != ContentStatus.published)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onPublish,
                          icon: const Icon(Icons.publish, size: 18),
                          label: const Text('發佈'),
                        ),
                      )
                    else
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onArchive,
                          icon: const Icon(Icons.archive, size: 18),
                          label: const Text('下架'),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onSetFeatured(!story.isFeatured),
                        icon: Icon(
                          story.isFeatured ? Icons.star_border : Icons.star,
                          size: 18,
                        ),
                        label: Text(story.isFeatured ? '取消精選' : '設爲精選'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ContentStatus status) {
    Color color;
    String text;
    switch (status) {
      case ContentStatus.draft:
        color = Colors.grey;
        text = '草稿';
        break;
      case ContentStatus.published:
        color = AppTheme.successColor;
        text = '已發佈';
        break;
      case ContentStatus.archived:
        color = AppTheme.errorColor;
        text = '已下架';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _CommunityList extends StatelessWidget {
  final List<CommunityContentModel> contents;
  final bool hasMore;
  final VoidCallback onLoadMore;

  const _CommunityList({
    required this.contents,
    required this.hasMore,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: contents.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == contents.length) {
          return Center(
            child: TextButton(onPressed: onLoadMore, child: const Text('加載更多')),
          );
        }

        final content = contents[index];
        return _CommunityCard(
          content: content,
          onArchive: () {
            context.read<ContentBloc>().add(
              ContentUpdateCommunityStatus(content.id, ContentStatus.archived),
            );
          },
        );
      },
    );
  }
}

class _CommunityCard extends StatelessWidget {
  final CommunityContentModel content;
  final VoidCallback onArchive;

  const _CommunityCard({required this.content, required this.onArchive});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: content.authorAvatar != null
                      ? NetworkImage(content.authorAvatar!)
                      : null,
                  child: content.authorAvatar == null
                      ? Text(content.authorName.substring(0, 1))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content.authorName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${content.groupName} · ${content.createdAt.toString().substring(0, 16)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (content.isPinned)
                  const Icon(
                    Icons.push_pin,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Content
            Text(content.content),
            if (content.imageUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  content.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.image)),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Stats & Actions
            Row(
              children: [
                Icon(Icons.favorite, size: 16, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  content.likeCount.toString(),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.comment, size: 16, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  content.commentCount.toString(),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onArchive,
                  icon: const Icon(Icons.archive, size: 18),
                  label: const Text('下架'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
