import 'package:flutter/material.dart';
import '../../demo_data/volunteers.dart';
import '../../models/demo_help_request_model.dart';
import '../../models/help_request_model.dart';
import '../../models/help_statistics_model.dart';
import '../../models/favorite_volunteer_model.dart';
import '../../models/user_model.dart';
import '../../services/app_session_service.dart';
import '../../services/user_center/async_task_service.dart';
import '../../services/user_center/demo_help_request_service.dart';
import '../../services/user_center/help_archive_service.dart';
import '../../services/user_center/points_service.dart';
import '../../services/user_center/favorite_volunteer_service.dart';
import '../../core/utils/extensions.dart';
import '../call/async_help_request_screen.dart';
import 'volunteer_detail_screen.dart';

String _resolveCurrentUserId() =>
    AppSessionService.instance.userProfile?.id ?? 'demo-user-id';

/// 求助者中心页面 (F14-F17)
/// 整合帮助档案、安心积分、常用志愿者、无障碍偏好
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
  final AsyncTaskService _asyncTaskService = AsyncTaskService();
  final DemoHelpRequestService _demoHelpRequestService =
      DemoHelpRequestService();
  final PointsService _pointsService = PointsService();
  final FavoriteVolunteerService _favoriteService = FavoriteVolunteerService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 6,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 5).toInt(),
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
            Tab(icon: Icon(Icons.markunread_outlined), text: '异步留言'),
            Tab(icon: Icon(Icons.assignment_turned_in_outlined), text: '我的求助'),
            Tab(icon: Icon(Icons.stars), text: '安心积分'),
            Tab(icon: Icon(Icons.favorite), text: '常用志愿者'),
            Tab(icon: Icon(Icons.settings_accessibility), text: '偏好设置'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          HelpArchiveTab(service: _helpArchiveService),
          AsyncRequestsTab(service: _asyncTaskService),
          MyHelpRequestsTab(service: _demoHelpRequestService),
          PointsTab(service: _pointsService),
          FavoriteVolunteersTab(service: _favoriteService),
          const AccessibilityPreferencesTab(),
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

/// F15: 安心积分标签页
class PointsTab extends StatefulWidget {
  final PointsService service;

  const PointsTab({super.key, required this.service});

  @override
  State<PointsTab> createState() => _PointsTabState();
}

class _PointsTabState extends State<PointsTab> {
  int _currentPoints = 0;
  CheckInStatus? _checkInStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final userId = _resolveCurrentUserId();
    final points = await widget.service.getCurrentPoints(userId);
    final status = await widget.service.getCheckInStatus(userId);

    setState(() {
      _currentPoints = points;
      _checkInStatus = status;
      _isLoading = false;
    });
  }

  Future<void> _performCheckIn() async {
    final userId = _resolveCurrentUserId();
    final result = await widget.service.performDailyCheckIn(userId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );

      if (result.success) {
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final status = _checkInStatus;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 积分卡片
          _PointsCard(
            points: _currentPoints,
            onCheckIn: status?.hasCheckedInToday == false
                ? _performCheckIn
                : null,
          ),

          const SizedBox(height: 24),

          // 签到状态
          if (status != null) _buildCheckInStatus(status),

          const SizedBox(height: 24),

          // 积分规则说明
          _buildPointsRules(),
        ],
      ),
    );
  }

  Widget _buildCheckInStatus(CheckInStatus status) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('签到状态', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  status.hasCheckedInToday
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: status.hasCheckedInToday ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  status.hasCheckedInToday ? '今日已签到' : '今日未签到',
                  style: TextStyle(
                    color: status.hasCheckedInToday
                        ? Colors.green
                        : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('连续签到: ${status.consecutiveDays} 天'),
            Text('明日可获: ${status.tomorrowPoints} 积分'),
            Text('下个里程碑: ${status.nextMilestone}'),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsRules() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('积分规则', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            const _RuleItem(icon: Icons.calendar_today, text: '每日签到: +1 积分'),
            const _RuleItem(
              icon: Icons.local_fire_department,
              text: '连续7天: +10 积分',
            ),
            const _RuleItem(icon: Icons.emoji_events, text: '连续30天: +50 积分'),
            const Divider(),
            const Text('积分可用于：', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('• 优先匹配志愿者'),
            const Text('• 解锁专属功能'),
            const Text('• 兑换平台福利'),
          ],
        ),
      ),
    );
  }
}

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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 显示设置
        _buildSectionTitle('显示设置'),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('高对比度模式'),
                subtitle: const Text('增强界面元素对比度'),
                value: _highContrast,
                onChanged: (value) => setState(() => _highContrast = value),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('字体大小'),
                subtitle: Text('${_fontScale.toStringAsFixed(1)}x'),
                trailing: SizedBox(
                  width: 200,
                  child: Slider(
                    value: _fontScale,
                    min: 0.8,
                    max: 2.0,
                    divisions: 12,
                    onChanged: (value) => setState(() => _fontScale = value),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 语音设置
        _buildSectionTitle('语音设置'),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('语音引导'),
                subtitle: const Text('自动朗读界面内容'),
                value: _voiceGuidance,
                onChanged: (value) => setState(() => _voiceGuidance = value),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('自动朗读结果'),
                subtitle: const Text('AI识别后自动朗读'),
                value: _autoReadResults,
                onChanged: (value) => setState(() => _autoReadResults = value),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('语音速度'),
                subtitle: Text('${_voiceSpeed.toStringAsFixed(1)}x'),
                trailing: SizedBox(
                  width: 200,
                  child: Slider(
                    value: _voiceSpeed,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    onChanged: (value) => setState(() => _voiceSpeed = value),
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('语音性别'),
                trailing: DropdownButton<String>(
                  value: _voiceGender,
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
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 触觉反馈
        _buildSectionTitle('触觉反馈'),
        Card(
          child: SwitchListTile(
            title: const Text('启用触觉反馈'),
            subtitle: const Text('操作时使用振动反馈'),
            value: _hapticFeedback,
            onChanged: (value) => setState(() => _hapticFeedback = value),
          ),
        ),

        const SizedBox(height: 32),

        // 保存按钮
        ElevatedButton.icon(
          onPressed: _savePreferences,
          icon: const Icon(Icons.save),
          label: const Text('保存设置'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('设置已保存')));
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

class _PointsCard extends StatelessWidget {
  final int points;
  final VoidCallback? onCheckIn;

  const _PointsCard({required this.points, this.onCheckIn});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.amber[400]!, Colors.orange[500]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.stars, size: 48, color: Colors.white),
            const SizedBox(height: 12),
            const Text(
              '我的安心积分',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              points.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (onCheckIn != null)
              ElevatedButton.icon(
                onPressed: onCheckIn,
                icon: const Icon(Icons.check_circle),
                label: const Text('立即签到'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('今日已签到', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RuleItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}

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
