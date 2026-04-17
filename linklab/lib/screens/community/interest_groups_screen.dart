import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/community_models.dart';
import '../../services/app_session_service.dart';
import '../../services/community/interest_group_service.dart';
import '../../widgets/accessible/index.dart';
import 'group_chat_screen.dart';

/// 兴趣小组页面
class InterestGroupsScreen extends ConsumerStatefulWidget {
  const InterestGroupsScreen({super.key});

  @override
  ConsumerState<InterestGroupsScreen> createState() =>
      _InterestGroupsScreenState();
}

class _InterestGroupsScreenState
    extends ConsumerState<InterestGroupsScreen> {
  final _groupService = InterestGroupService();
  List<InterestGroup> _groups = [];
  List<InterestGroup> _myGroups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);

    final groups = await _groupService.getGroups();
    final userId = AppSessionService.instance.currentUser?.id ?? 'demo-user-id';
    final myGroups = await _groupService.getMyGroups(userId);

    setState(() {
      _groups = groups;
      _myGroups = myGroups;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AccessibleScaffold(
      title: '兴趣小组',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: '全部小组'),
                      Tab(text: '我的小组'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildAllGroupsTab(),
                        _buildMyGroupsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAllGroupsTab() {
    if (_groups.isEmpty) {
      return const Center(
        child: AccessibleText(
          '暂无小组',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      itemCount: _groups.length,
      itemBuilder: (context, index) {
        final group = _groups[index];
        return _GroupCard(
          group: group,
          isJoined: _myGroups.any((g) => g.id == group.id),
          onJoin: () => _joinGroup(group),
          onTap: () => _openGroupChat(group),
        );
      },
    );
  }

  Widget _buildMyGroupsTab() {
    if (_myGroups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_outlined,
              size: 64,
              color: AppTheme.textHint,
            ),
            SizedBox(height: AppTheme.spacingM),
            AccessibleText(
              '您还没有加入任何小组',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            SizedBox(height: AppTheme.spacingS),
            AccessibleText(
              '去全部小组看看吧',
              style: TextStyle(
                color: AppTheme.textHint,
                fontSize: AppTheme.fontSizeSmall,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      itemCount: _myGroups.length,
      itemBuilder: (context, index) {
        final group = _myGroups[index];
        return _GroupCard(
          group: group,
          isJoined: true,
          onJoin: null,
          onTap: () => _openGroupChat(group),
        );
      },
    );
  }

  Future<void> _joinGroup(InterestGroup group) async {
    try {
      final userId = AppSessionService.instance.currentUser?.id ?? 'demo-user-id';
      await _groupService.joinGroup(group.id, userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已加入 ${group.name}')),
        );
        _loadGroups();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加入失败: $e')),
        );
      }
    }
  }

  void _openGroupChat(InterestGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupChatScreen(group: group),
      ),
    );
  }
}

/// 小组卡片
class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.group,
    required this.isJoined,
    required this.onJoin,
    required this.onTap,
  });

  final InterestGroup group;
  final bool isJoined;
  final VoidCallback? onJoin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AccessibleCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Row(
        children: [
          // 图标
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            ),
            child: Icon(
              _getCategoryIcon(group.category),
              size: 28,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          // 信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccessibleText(
                  group.name,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                AccessibleText(
                  group.description,
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
                      '${group.memberCount}人',
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: AppTheme.textHint,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Icon(
                      Icons.message,
                      size: 14,
                      color: AppTheme.textHint,
                    ),
                    const SizedBox(width: 4),
                    AccessibleText(
                      '${group.postCount}帖',
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
          if (!isJoined && onJoin != null)
            AccessibleButton(
              onPressed: onJoin!,
              label: '加入',
              
            )
          else if (isJoined)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingS,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppTheme.successLight,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
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
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case GroupCategory.medical:
        return Icons.local_hospital;
      case GroupCategory.translation:
        return Icons.translate;
      case GroupCategory.psychological:
        return Icons.favorite;
      case GroupCategory.technical:
        return Icons.computer;
      default:
        return Icons.group;
    }
  }
}
