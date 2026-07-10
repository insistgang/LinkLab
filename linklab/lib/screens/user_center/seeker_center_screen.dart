import 'package:flutter/material.dart';
import '../../demo_data/volunteers.dart';
import '../../models/demo_help_request_model.dart';
import '../../models/help_request_model.dart';
import '../../models/help_statistics_model.dart';
import '../../models/favorite_volunteer_model.dart';
import '../../models/user_model.dart';
import '../../core/theme/app_theme.dart';
// ignore: deprecated_member_use_from_same_package
import '../../services/app_session_service.dart';
import '../../services/user_center/async_task_service.dart';
import '../../services/user_center/demo_help_request_service.dart';
import '../../services/user_center/help_archive_service.dart';
// MVP: points_service 已砍 (F15)
// import '../../services/user_center/points_service.dart';
import '../../services/user_center/favorite_volunteer_service.dart';
import '../../core/utils/extensions.dart';
import '../../widgets/demo/demo_overlays.dart';
import '../call/async_help_request_screen.dart';
import 'volunteer_detail_screen.dart';

// ignore: deprecated_member_use_from_same_package
String _resolveCurrentUserId() =>
    AppSessionService.instance.userProfile?.id ?? 'demo-user-id';

const int _mvpSeekerTabCount = 2;

/// 求助者中心页面
/// 当前默认只暴露 MVP 允许的档案与状态回看两项能力。
class SeekerCenterScreen extends StatefulWidget {
  const SeekerCenterScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<SeekerCenterScreen> createState() => _SeekerCenterScreenState();
}

class _SeekerCenterScreenState extends State<SeekerCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HelpArchiveService _helpArchiveService = HelpArchiveService();
  final DemoHelpRequestService _demoHelpRequestService =
      DemoHelpRequestService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _mvpSeekerTabCount,
      vsync: this,
      initialIndex: widget.initialTabIndex
          .clamp(0, _mvpSeekerTabCount - 1)
          .toInt(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('求助者中心'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.history), text: '帮助档案'),
            Tab(icon: Icon(Icons.assignment_turned_in_outlined), text: '求助状态'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          HelpArchiveTab(service: _helpArchiveService),
          MyHelpRequestsTab(service: _demoHelpRequestService),
        ],
      ),
    );
  }
}

class AsyncRequestsTab extends StatefulWidget {
  const AsyncRequestsTab({super.key, required this.service});

  final AsyncTaskService service;

  @override
  State<AsyncRequestsTab> createState() => _AsyncRequestsTabState();
}

class _AsyncRequestsTabState extends State<AsyncRequestsTab> {
  List<AsyncTaskModel> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final userId = _resolveCurrentUserId();
    final tasks = await widget.service.getSeekerTasks(userId, limit: 50);
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  Future<void> _openComposer() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AsyncHelpRequestScreen()));
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final pendingCount = _tasks
        .where((task) => task.status == 'pending')
        .length;
    final processingCount = _tasks.where((task) => task.isAssigned).length;
    final completedCount = _tasks
        .where((task) => task.status == 'completed')
        .length;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AsyncSummaryCard(
            pendingCount: pendingCount,
            processingCount: processingCount,
            completedCount: completedCount,
            onCreate: () {
              _openComposer();
            },
          ),
          const SizedBox(height: 16),
          if (_tasks.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.markunread_outlined,
                      size: 56,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '还没有异步留言',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '适合非紧急问题，例如读信件、看菜单、辨认照片。',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _openComposer,
                      icon: const Icon(Icons.add),
                      label: const Text('创建第一条留言'),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._tasks.map(_buildTaskCard),
        ],
      ),
    );
  }

  Widget _buildTaskCard(AsyncTaskModel task) {
    final statusColor = switch (task.status) {
      'completed' => Colors.green,
      'assigned' || 'processing' => Colors.orange,
      'pending' => Colors.blue,
      _ => Colors.grey,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withAlpha(26),
          child: Icon(Icons.schedule_send, color: statusColor),
        ),
        title: Text(task.taskType),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.description.split('\n').first,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              '${task.statusLabel} · ${task.createdAt?.formatRelative() ?? ''}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: Chip(
          label: Text(task.statusLabel),
          backgroundColor: statusColor.withAlpha(31),
          labelStyle: TextStyle(color: statusColor),
        ),
        onTap: () => _showTaskDetail(task),
      ),
    );
  }

  void _showTaskDetail(AsyncTaskModel task) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.taskType,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _DetailRow(label: '当前状态', value: task.statusLabel),
            _DetailRow(
              label: '提交时间',
              value: task.createdAt?.formatDateTime() ?? '未知',
            ),
            if (task.assignedAt != null)
              _DetailRow(
                label: '领取时间',
                value: task.assignedAt!.formatDateTime(),
              ),
            if (task.completedAt != null)
              _DetailRow(
                label: '回复时间',
                value: task.completedAt!.formatDateTime(),
              ),
            const SizedBox(height: 8),
            const Text('留言内容', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(task.description),
            if (task.result != null && task.result!.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                '志愿者回复',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(task.result!),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('关闭'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _openComposer();
                    },
                    icon: const Icon(Icons.add_comment_outlined),
                    label: const Text('再提一个'),
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

class MyHelpRequestsTab extends StatefulWidget {
  const MyHelpRequestsTab({super.key, required this.service});

  final DemoHelpRequestService service;

  @override
  State<MyHelpRequestsTab> createState() => _MyHelpRequestsTabState();
}

class _MyHelpRequestsTabState extends State<MyHelpRequestsTab> {
  List<DemoHelpRequestModel> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final seekerId = _resolveCurrentUserId();
    final requests = await widget.service.getSeekerRequests(seekerId);
    if (!mounted) return;
    setState(() {
      _requests = requests;
      _isLoading = false;
    });
  }

  Future<void> _cancelRequest(DemoHelpRequestModel request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('取消求助'),
        content: Text('确定取消“${request.title}”吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('保留'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认取消'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await widget.service.cancelRequest(
      request.id,
      _resolveCurrentUserId(),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(success ? '求助已取消' : '取消失败，请稍后重试')));
    if (success) {
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_requests.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 96),
            Icon(
              Icons.assignment_turned_in_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              '还没有我的求助',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '先去看看志愿者详情，再发起一次本地演示求助。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VolunteerDetailScreen(
                      volunteerId: defaultMatchedVolunteer.id,
                      volunteerName: defaultMatchedVolunteer.name,
                      volunteerAvatar: defaultMatchedVolunteer.avatar,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.person_search_outlined),
              label: const Text('查看演示志愿者'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final request = _requests[index];
          final canCancel = request.canCancel;
          final statusColor = switch (request.status) {
            DemoHelpRequestStatus.pending => Colors.orange,
            DemoHelpRequestStatus.inProgress => Colors.blue,
            DemoHelpRequestStatus.completed => Colors.green,
            DemoHelpRequestStatus.cancelled => Colors.grey,
            _ => Colors.teal,
          };

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          request.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Chip(
                        label: Text(request.statusLabel),
                        backgroundColor: statusColor.withAlpha(26),
                        labelStyle: TextStyle(color: statusColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    request.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: '提交时间',
                    value: request.createdAt.formatDateTime(),
                  ),
                  _DetailRow(
                    label: '对应志愿者',
                    value: request.volunteerName ?? '待平台匹配',
                  ),
                  _DetailRow(label: '时间偏好', value: request.schedulePreference),
                  if (canCancel) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: () => _cancelRequest(request),
                        icon: const Icon(Icons.close),
                        label: const Text('取消求助'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// F14: 帮助档案标签页
class HelpArchiveTab extends StatefulWidget {
  final HelpArchiveService service;

  const HelpArchiveTab({super.key, required this.service});

  @override
  State<HelpArchiveTab> createState() => _HelpArchiveTabState();
}

class _HelpArchiveTabState extends State<HelpArchiveTab> {
  HelpStatistics? _statistics;
  List<HelpRequestModel> _history = [];
  bool _isLoading = true;
  int _currentPage = 0;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final userId = _resolveCurrentUserId();

    final stats = await widget.service.getStatistics(userId);
    final history = await widget.service.getHelpHistory(
      userId,
      limit: _pageSize,
      offset: _currentPage * _pageSize,
    );

    setState(() {
      _statistics = stats;
      _history = history;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          // 统计卡片
          SliverToBoxAdapter(child: _buildStatisticsCards()),

          // 历史记录标题
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '历史记录',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // 历史记录列表
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index >= _history.length) {
                return _buildLoadMoreButton();
              }
              return _buildHistoryItem(_history[index]);
            }, childCount: _history.length + 1),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards() {
    final stats = _statistics;
    if (stats == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 总求助次数和AI解决率
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: '总求助次数',
                  value: stats.totalRequests.toString(),
                  icon: Icons.help_outline,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'AI解决率',
                  value: stats.aiResolutionRateText,
                  icon: Icons.smart_toy,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 志愿者帮助次数和总时长
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: '志愿者帮助',
                  value: stats.volunteerHelpCount.toString(),
                  icon: Icons.volunteer_activism,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: '总时长(分钟)',
                  value: stats.totalDurationMinutes.toString(),
                  icon: Icons.timer,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 平均评分
          _StatCard(
            title: '平均评分',
            value: '${stats.averageRating.toStringAsFixed(1)} ⭐',
            icon: Icons.star,
            color: Colors.amber,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(HelpRequestModel request) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: _getTypeIcon(request.type),
        title: Text(request.intent ?? '未命名求助'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${request.statusLabel} · ${request.createdAt?.formatRelative() ?? ''}',
            ),
            if (request.seekerRating != null)
              Row(
                children: List.generate(
                  request.seekerRating!,
                  (index) =>
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                ),
              ),
          ],
        ),
        trailing: request.volunteerId != null
            ? const Icon(Icons.person_outline)
            : const Icon(Icons.computer),
        onTap: () => _showRequestDetail(request),
      ),
    );
  }

  Widget _getTypeIcon(String? type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'sos':
        icon = Icons.emergency;
        color = Colors.red;
        break;
      case 'realtime_voice':
        icon = Icons.phone;
        color = Colors.blue;
        break;
      case 'realtime_video':
        icon = Icons.videocam;
        color = Colors.green;
        break;
      case 'async':
        icon = Icons.schedule;
        color = Colors.orange;
        break;
      default:
        icon = Icons.help;
        color = Colors.grey;
        break;
    }

    return CircleAvatar(
      backgroundColor: color.withAlpha(26),
      child: Icon(icon, color: color),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () async {
          setState(() => _currentPage++);
          final userId = _resolveCurrentUserId();
          final moreHistory = await widget.service.getHelpHistory(
            userId,
            limit: _pageSize,
            offset: _currentPage * _pageSize,
          );
          setState(() => _history.addAll(moreHistory));
        },
        child: const Text('加载更多'),
      ),
    );
  }

  void _showRequestDetail(HelpRequestModel request) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('求助详情', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            _DetailRow(label: '求助内容', value: request.intent ?? '无'),
            _DetailRow(label: '求助类型', value: request.type ?? '未知'),
            _DetailRow(label: '紧急程度', value: request.urgencyLabel),
            _DetailRow(label: '当前状态', value: request.statusLabel),
            _DetailRow(
              label: '创建时间',
              value: request.createdAt?.formatDateTime() ?? '未知',
            ),
            if (request.completedAt != null)
              _DetailRow(
                label: '完成时间',
                value: request.completedAt!.formatDateTime(),
              ),
            if (request.durationSeconds != null)
              _DetailRow(
                label: '通话时长',
                value:
                    '${request.durationSeconds! ~/ 60}分${request.durationSeconds! % 60}秒',
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// MVP: F15 安心积分标签页已砍
// class PointsTab ... 整个类及相关组件已移除

/// F16: 常用志愿者标签页
class FavoriteVolunteersTab extends StatefulWidget {
  final FavoriteVolunteerService service;

  const FavoriteVolunteersTab({super.key, required this.service});

  @override
  State<FavoriteVolunteersTab> createState() => _FavoriteVolunteersTabState();
}

class _FavoriteVolunteersTabState extends State<FavoriteVolunteersTab> {
  List<FavoriteVolunteerModel> _favorites = [];
  FavoriteVolunteerStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final userId = _resolveCurrentUserId();
    final favorites = await widget.service.getFavoriteVolunteers(userId);
    final stats = await widget.service.getStats(userId);

    setState(() {
      _favorites = favorites;
      _stats = stats;
      _isLoading = false;
    });
  }

  Future<void> _removeFavorite(String volunteerId) async {
    final userId = _resolveCurrentUserId();
    final success = await widget.service.removeFavorite(userId, volunteerId);

    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已移除常用志愿者')));
      _loadData();
    }
  }

  Future<void> _openVolunteerDetail({
    required String volunteerId,
    String? volunteerName,
    String? volunteerAvatar,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VolunteerDetailScreen(
          volunteerId: volunteerId,
          volunteerName: volunteerName,
          volunteerAvatar: volunteerAvatar,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_favorites.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 96),
            Icon(Icons.favorite_border, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              '暂无常用志愿者',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '与志愿者合作后会自动添加到这里，也可以先打开一个演示志愿者开始体验。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _openVolunteerDetail(
                volunteerId: defaultMatchedVolunteer.id,
                volunteerName: defaultMatchedVolunteer.name,
                volunteerAvatar: defaultMatchedVolunteer.avatar,
              ),
              icon: const Icon(Icons.person_search_outlined),
              label: const Text('查看演示志愿者'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favorites.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildStatsCard();
          }
          return _buildVolunteerCard(_favorites[index - 1]);
        },
      ),
    );
  }

  Widget _buildStatsCard() {
    final stats = _stats;
    if (stats == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatColumn(value: stats.totalFavorites.toString(), label: '常用志愿者'),
            _StatColumn(
              value: stats.totalCooperations.toString(),
              label: '总合作次数',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolunteerCard(FavoriteVolunteerModel volunteer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: volunteer.volunteerAvatar != null
              ? NetworkImage(volunteer.volunteerAvatar!)
              : null,
          child: volunteer.volunteerAvatar == null
              ? Text(volunteer.volunteerName?.substring(0, 1) ?? '?')
              : null,
        ),
        title: Text(volunteer.volunteerName ?? '未知志愿者'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(volunteer.cooperationText),
            if (volunteer.averageRating != null)
              Row(
                children: [
                  Icon(Icons.star, size: 14, color: Colors.amber[600]),
                  Text(' ${volunteer.averageRating!.toStringAsFixed(1)}'),
                ],
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'remove') {
              _removeFavorite(volunteer.volunteerId);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('移除', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          _openVolunteerDetail(
            volunteerId: volunteer.volunteerId,
            volunteerName: volunteer.volunteerName,
            volunteerAvatar: volunteer.volunteerAvatar,
          );
        },
      ),
    );
  }
}

/// F17: 无障碍偏好设置标签页
class AccessibilityPreferencesTab extends StatefulWidget {
  const AccessibilityPreferencesTab({super.key});

  @override
  State<AccessibilityPreferencesTab> createState() =>
      _AccessibilityPreferencesTabState();
}

class _AccessibilityPreferencesTabState
    extends State<AccessibilityPreferencesTab> {
  bool _highContrast = false;
  double _fontScale = 1.0;
  double _voiceSpeed = 1.0;
  bool _hapticFeedback = true;
  bool _voiceGuidance = true;
  bool _autoReadResults = true;
  String _voiceGender = 'female';

  @override
  void initState() {
    super.initState();
    final preferences = AppSessionService.instance.preferences;
    _highContrast = preferences.highContrastMode;
    _fontScale = preferences.fontScale;
    _voiceSpeed = preferences.voiceSpeed;
    _hapticFeedback = preferences.hapticFeedback;
    _voiceGuidance = preferences.voiceGuidance;
    _autoReadResults = preferences.autoReadResults;
    _voiceGender = preferences.voiceGender;
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.stageBackground,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingL,
          AppTheme.spacingL,
          AppTheme.spacingL,
          AppTheme.spacingXXL,
        ),
        children: [
          _buildSectionTitle('显示设置'),
          _buildSettingsCard(
            children: [
              _buildSwitchTile(
                title: '高对比度模式',
                subtitle: '增强界面元素对比度',
                value: _highContrast,
                onChanged: (value) => setState(() => _highContrast = value),
              ),
              _buildStageDivider(),
              _buildSliderTile(
                title: '字体大小',
                value: _fontScale,
                min: 0.8,
                max: 2.0,
                divisions: 12,
                onChanged: (value) => setState(() => _fontScale = value),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          _buildSectionTitle('语音设置'),
          _buildSettingsCard(
            children: [
              _buildSwitchTile(
                title: '语音引导',
                subtitle: '自动朗读界面内容',
                value: _voiceGuidance,
                onChanged: (value) => setState(() => _voiceGuidance = value),
              ),
              _buildStageDivider(),
              _buildSwitchTile(
                title: '自动朗读结果',
                subtitle: 'AI 识别后自动朗读',
                value: _autoReadResults,
                onChanged: (value) => setState(() => _autoReadResults = value),
              ),
              _buildStageDivider(),
              _buildSliderTile(
                title: '语音速度',
                value: _voiceSpeed,
                min: 0.5,
                max: 2.0,
                divisions: 15,
                onChanged: (value) => setState(() => _voiceSpeed = value),
              ),
              _buildStageDivider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '语音性别',
                  style: TextStyle(
                    color: AppTheme.stageTextPrimary,
                    fontSize: AppTheme.fontSizeNormal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _voiceGender,
                    dropdownColor: Color.alphaBlend(
                      AppTheme.stageSurfaceStrong,
                      AppTheme.stageBackground,
                    ),
                    style: TextStyle(
                      color: AppTheme.stageTextPrimary,
                      fontSize: AppTheme.fontSizeNormal,
                      fontWeight: FontWeight.w600,
                    ),
                    iconEnabledColor: AppTheme.stageAccent,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _voiceGender = value);
                      }
                    },
                    items: const [
                      DropdownMenuItem(value: 'female', child: Text('女声')),
                      DropdownMenuItem(value: 'male', child: Text('男声')),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          _buildSectionTitle('触觉反馈'),
          _buildSettingsCard(
            children: [
              _buildSwitchTile(
                title: '启用触觉反馈',
                subtitle: '操作时使用振动反馈',
                value: _hapticFeedback,
                onChanged: (value) => setState(() => _hapticFeedback = value),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXL),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _savePreferences,
              icon: const Icon(Icons.save_outlined),
              label: const Text('保存设置'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.stageAccent,
                foregroundColor: AppTheme.stageBackground,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusLarge,
                  ),
                ),
                textStyle: const TextStyle(
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.stageTextPrimary,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Color.alphaBlend(
        AppTheme.stageSurfaceStrong,
        AppTheme.stageBackground,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        side: BorderSide(color: AppTheme.stageAccent.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(
          color: AppTheme.stageTextPrimary,
          fontSize: AppTheme.fontSizeNormal,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppTheme.stageTextSecondary,
          fontSize: AppTheme.fontSizeSmall,
          height: 1.4,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppTheme.stageAccent,
      activeTrackColor: AppTheme.stageAccent.withValues(alpha: 0.38),
      inactiveThumbColor: AppTheme.stageTextHint,
      inactiveTrackColor: AppTheme.stageBorder.withValues(alpha: 0.46),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.stageTextPrimary,
                    fontSize: AppTheme.fontSizeNormal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingS,
                  vertical: AppTheme.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.stageAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${value.toStringAsFixed(1)}x',
                  style: TextStyle(
                    color: AppTheme.stageAccent,
                    fontSize: AppTheme.fontSizeSmall,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: '${value.toStringAsFixed(1)}x',
            activeColor: AppTheme.stageAccent,
            inactiveColor: AppTheme.stageAccent.withValues(alpha: 0.18),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildStageDivider() {
    return Divider(
      height: AppTheme.spacingXL,
      color: AppTheme.stageBorder.withValues(alpha: 0.56),
    );
  }

  Future<void> _savePreferences() async {
    await AppSessionService.instance.updatePreferences(
      AccessibilityPreferences(
        highContrastMode: _highContrast,
        fontScale: _fontScale,
        voiceSpeed: _voiceSpeed,
        hapticFeedback: _hapticFeedback,
        voiceGuidance: _voiceGuidance,
        autoReadResults: _autoReadResults,
        voiceGender: _voiceGender,
        voiceAccent: AppSessionService.instance.preferences.voiceAccent,
      ),
    );
    if (mounted) {
      showDemoStageSnackBar(
        context,
        message: '设置已保存',
        icon: Icons.check_circle_outline,
        accentColor: AppTheme.stageAccent,
      );
    }
  }
}

// ==================== 辅助组件 ====================

class _AsyncSummaryCard extends StatelessWidget {
  const _AsyncSummaryCard({
    required this.pendingCount,
    required this.processingCount,
    required this.completedCount,
    required this.onCreate,
  });

  final int pendingCount;
  final int processingCount;
  final int completedCount;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.teal[400]!, Colors.blue[500]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '异步留言状态',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '适合非紧急需求，留言会进入志愿者异步任务队列。',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatColumn(
                    value: pendingCount.toString(),
                    label: '待领取',
                    valueColor: Colors.white,
                    labelColor: Colors.white70,
                  ),
                ),
                Expanded(
                  child: _StatColumn(
                    value: processingCount.toString(),
                    label: '处理中',
                    valueColor: Colors.white,
                    labelColor: Colors.white70,
                  ),
                ),
                Expanded(
                  child: _StatColumn(
                    value: completedCount.toString(),
                    label: '已回复',
                    valueColor: Colors.white,
                    labelColor: Colors.white70,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('新建异步留言'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool fullWidth;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: color.withAlpha(204)),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// MVP: F15 安心积分相关组件已砍
// class _PointsCard extends StatelessWidget { ... }
// class _RuleItem extends StatelessWidget { ... }

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;
  final Color? labelColor;

  const _StatColumn({
    required this.value,
    required this.label,
    this.valueColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: labelColor ?? Colors.grey[600]),
        ),
      ],
    );
  }
}
