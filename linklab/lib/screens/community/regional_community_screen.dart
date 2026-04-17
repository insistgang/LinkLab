import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/community_models.dart';
import '../../services/app_session_service.dart';
import '../../services/community/regional_community_service.dart';
import '../../widgets/accessible/index.dart';

/// 地区社群页面
class RegionalCommunityScreen extends StatefulWidget {
  const RegionalCommunityScreen({super.key});

  @override
  State<RegionalCommunityScreen> createState() =>
      _RegionalCommunityScreenState();
}

class _RegionalCommunityScreenState extends State<RegionalCommunityScreen> {
  final _communityService = RegionalCommunityService();
  List<RegionalCommunity> _communities = [];
  List<RegionalCommunity> _myCommunities = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCommunities();
  }

  Future<void> _loadCommunities() async {
    setState(() => _isLoading = true);

    final communities = await _communityService.getPopularCommunities();
    final userId = AppSessionService.instance.currentUser?.id ?? 'demo-user-id';
    final myCommunities = await _communityService.getMyCommunities(userId);

    setState(() {
      _communities = communities;
      _myCommunities = myCommunities;
      _isLoading = false;
    });
  }

  Future<void> _searchCommunities(String query) async {
    if (query.isEmpty) {
      _loadCommunities();
      return;
    }

    setState(() => _isLoading = true);

    final communities = await _communityService.getCommunitiesByCity(query);

    setState(() {
      _communities = communities;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AccessibleScaffold(
      title: '地区社群',
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: AccessibleInput(
              hint: '搜索城市...',
              prefixIcon: const Icon(Icons.search),
              onChanged: (value) {
                _searchQuery = value;
              },
              onSubmitted: _searchCommunities,
            ),
          ),
          // 我的社群
          if (_myCommunities.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AccessibleText(
                  '我的社群',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(AppTheme.spacingM),
                itemCount: _myCommunities.length,
                itemBuilder: (context, index) {
                  final community = _myCommunities[index];
                  return _MyCommunityCard(community: community);
                },
              ),
            ),
          ],
          // 推荐社群
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AccessibleText(
                '推荐社群',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // 社群列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _communities.isEmpty
                    ? const Center(
                        child: AccessibleText(
                          '暂无社群',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadCommunities,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppTheme.spacingM),
                          itemCount: _communities.length,
                          itemBuilder: (context, index) {
                            final community = _communities[index];
                            return _CommunityCard(
                              community: community,
                              isJoined: _myCommunities
                                  .any((c) => c.id == community.id),
                              onJoin: () => _joinCommunity(community),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinCommunity(RegionalCommunity community) async {
    try {
      final userId = AppSessionService.instance.currentUser?.id ?? 'demo-user-id';
      await _communityService.joinCommunity(community.id, userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已加入 ${community.city} 社群')),
        );
        _loadCommunities();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加入失败: $e')),
        );
      }
    }
  }
}

/// 我的社群卡片
class _MyCommunityCard extends StatelessWidget {
  const _MyCommunityCard({required this.community});

  final RegionalCommunity community;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: AppTheme.spacingM),
      child: AccessibleCard(
        onTap: () {
          // TODO: 打开社群详情
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_city,
              size: 40,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: AppTheme.spacingS),
            AccessibleText(
              community.city,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeNormal,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            AccessibleText(
              '${community.memberCount}人',
              style: const TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: AppTheme.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 社群卡片
class _CommunityCard extends StatelessWidget {
  const _CommunityCard({
    required this.community,
    required this.isJoined,
    required this.onJoin,
  });

  final RegionalCommunity community;
  final bool isJoined;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return AccessibleCard(
      onTap: () {
        // TODO: 打开社群详情
      },
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Row(
        children: [
          // 封面
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            ),
            child: const Icon(
              Icons.location_city,
              size: 40,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          // 信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AccessibleText(
                        community.city,
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeLarge,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isJoined)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingS,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successLight,
                          borderRadius:
                              BorderRadius.circular(AppTheme.borderRadiusSmall),
                        ),
                        child: const AccessibleText(
                          '已加入',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeSmall,
                            color: AppTheme.successColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXS),
                AccessibleText(
                  community.description ?? '暂无描述',
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 14,
                      color: AppTheme.textHint,
                    ),
                    const SizedBox(width: 4),
                    AccessibleText(
                      '${community.memberCount}人',
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: AppTheme.textHint,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Icon(
                      Icons.event,
                      size: 14,
                      color: AppTheme.textHint,
                    ),
                    const SizedBox(width: 4),
                    AccessibleText(
                      '${community.eventCount}个活动',
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
          // 加入按钮
          if (!isJoined)
            IconButton(
              onPressed: onJoin,
              icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
            ),
        ],
      ),
    );
  }
}
