import 'package:flutter/material.dart';
import '../../models/volunteer_level_model.dart';
import '../../models/badge_model.dart';
import '../../models/skill_model.dart';
import '../../models/timeline_model.dart';
import '../../models/schedule_model.dart';
import '../../models/help_request_model.dart';
import '../../models/point_transaction_model.dart';
import '../../services/user_center/volunteer_level_service.dart';
import '../../services/user_center/badge_service.dart';
import '../../services/user_center/skill_tag_service.dart';
import '../../services/user_center/timeline_service.dart';
import '../../services/user_center/schedule_service.dart';
import '../../services/user_center/async_task_service.dart';
import '../../services/user_center/points_service.dart';
import '../../core/utils/extensions.dart';

/// 志愿者中心页面 (F18-F23)
/// 整合等级积分、技能标签、善意时间线、徽章成就、异步任务、排班管理
class VolunteerCenterScreen extends StatefulWidget {
  const VolunteerCenterScreen({super.key});

  @override
  State<VolunteerCenterScreen> createState() => _VolunteerCenterScreenState();
}

class _VolunteerCenterScreenState extends State<VolunteerCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
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
        title: const Text('志愿者中心'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.military_tech), text: '等级'),
            Tab(icon: Icon(Icons.local_offer), text: '技能'),
            Tab(icon: Icon(Icons.timeline), text: '时间线'),
            Tab(icon: Icon(Icons.emoji_events), text: '徽章'),
            Tab(icon: Icon(Icons.assignment), text: '任务'),
            Tab(icon: Icon(Icons.schedule), text: '排班'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          LevelPointsTab(),
          SkillTagsTab(),
          TimelineTab(),
          BadgesTab(),
          AsyncTasksTab(),
          ScheduleTab(),
        ],
      ),
    );
  }
}

/// F18: 等级积分标签页
class LevelPointsTab extends StatefulWidget {
  const LevelPointsTab({super.key});

  @override
  State<LevelPointsTab> createState() => _LevelPointsTabState();
}

class _LevelPointsTabState extends State<LevelPointsTab> {
  final VolunteerLevelService _levelService = VolunteerLevelService();
  final PointsService _pointsService = PointsService();

  VolunteerLevelInfo? _levelInfo;
  List<PointTransactionModel> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    const volunteerId = 'demo-volunteer-id';

    final levelInfo = await _levelService.getLevelInfo(volunteerId);
    final transactions = await _levelService.getPointTransactions(volunteerId);

    setState(() {
      _levelInfo = levelInfo;
      _transactions = transactions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final levelInfo = _levelInfo;
    if (levelInfo == null) {
      return const Center(child: Text('加载失败'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 等级卡片
          _LevelCard(levelInfo: levelInfo),

          const SizedBox(height: 24),

          // 等级进度
          _LevelProgress(levelInfo: levelInfo),

          const SizedBox(height: 24),

          // 权益说明
          _PrivilegesCard(levelInfo: levelInfo),

          const SizedBox(height: 24),

          // 积分流水
          _TransactionsList(transactions: _transactions),
        ],
      ),
    );
  }
}

/// F19: 技能标签标签页
class SkillTagsTab extends StatefulWidget {
  const SkillTagsTab({super.key});

  @override
  State<SkillTagsTab> createState() => _SkillTagsTabState();
}

class _SkillTagsTabState extends State<SkillTagsTab> {
  final SkillTagService _skillService = SkillTagService();

  List<SkillModel> _mySkills = [];
  List<SkillVerificationRequest> _pendingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    const volunteerId = 'demo-volunteer-id';

    final mySkills = await _skillService.getMySkills(volunteerId);
    final pendingRequests = await _skillService.getPendingRequests(volunteerId);

    setState(() {
      _mySkills = mySkills;
      _pendingRequests = pendingRequests;
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
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 我的技能
          _buildMySkillsSection(),

          const SizedBox(height: 24),

          // 待认证申请
          if (_pendingRequests.isNotEmpty) _buildPendingSection(),

          const SizedBox(height: 24),

          // 添加技能按钮
          ElevatedButton.icon(
            onPressed: _showAddSkillDialog,
            icon: const Icon(Icons.add),
            label: const Text('添加技能标签'),
          ),
        ],
      ),
    );
  }

  Widget _buildMySkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '我的技能标签',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        if (_mySkills.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.label_outline, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text(
                      '暂无技能标签',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _mySkills.map((skill) {
              return Chip(
                avatar: Text(skill.iconEmoji),
                label: Text(skill.name),
                backgroundColor: skill.isVerified
                    ? Colors.green[100]
                    : Colors.grey[200],
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: skill.requiresVerification && !skill.isVerified
                    ? null
                    : () => _removeSkill(skill.id),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildPendingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '认证中',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ..._pendingRequests.map((request) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.hourglass_empty, color: Colors.orange),
              title: Text(request.skillName ?? '未知技能'),
              subtitle: Text('提交于 ${request.submittedAt?.formatRelative() ?? ''}'),
              trailing: const Chip(
                label: Text('审核中'),
                backgroundColor: Colors.orange,
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showAddSkillDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return _SkillSelector(
            scrollController: scrollController,
            existingSkills: _mySkills.map((s) => s.id).toSet(),
            onSkillSelected: (skill) async {
              Navigator.pop(context);
              await _addSkill(skill);
            },
          );
        },
      ),
    );
  }

  Future<void> _addSkill(SkillModel skill) async {
    const volunteerId = 'demo-volunteer-id';

    if (skill.requiresVerification) {
      // 需要认证，跳转到认证申请
      final success = await _showVerificationDialog(skill);
      if (success == true) {
        _loadData();
      }
    } else {
      // 直接添加
      final success = await _skillService.addSkill(volunteerId, skill.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已添加 ${skill.name}')),
        );
        _loadData();
      }
    }
  }

  Future<bool?> _showVerificationDialog(SkillModel skill) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('认证 ${skill.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(skill.description ?? ''),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: '证书/资质说明',
                hintText: '请描述您的相关资质',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('提交认证'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeSkill(String skillId) async {
    const volunteerId = 'demo-volunteer-id';
    final success = await _skillService.removeSkill(volunteerId, skillId);
    if (success) {
      _loadData();
    }
  }
}

/// F20: 善意时间线标签页
class TimelineTab extends StatefulWidget {
  const TimelineTab({super.key});

  @override
  State<TimelineTab> createState() => _TimelineTabState();
}

class _TimelineTabState extends State<TimelineTab> {
  final TimelineService _timelineService = TimelineService();

  TimelineModel? _timeline;
  int _selectedYear = DateTime.now().year;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    const volunteerId = 'demo-volunteer-id';

    final timeline = await _timelineService.getTimeline(volunteerId, _selectedYear);

    setState(() {
      _timeline = timeline;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final timeline = _timeline;
    if (timeline == null) {
      return const Center(child: Text('加载失败'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          // 年份选择器
          SliverToBoxAdapter(
            child: _buildYearSelector(),
          ),

          // 统计卡片
          SliverToBoxAdapter(
            child: _buildStatsCards(timeline),
          ),

          // 热力图
          SliverToBoxAdapter(
            child: _buildHeatmap(timeline),
          ),

          // 最近活动
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '最近帮助记录',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // 活动列表
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final days = timeline.days.where((d) => d.events.isNotEmpty).toList();
                if (index >= days.length) return null;

                final day = days[index];
                return _buildDayCard(day);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearSelector() {
    final currentYear = DateTime.now().year;
    final years = List.generate(3, (i) => currentYear - i);

    return Container(
      padding: const EdgeInsets.all(16),
      child: SegmentedButton<int>(
        segments: years.map((year) {
          return ButtonSegment(
            value: year,
            label: Text('$year年'),
          );
        }).toList(),
        selected: {_selectedYear},
        onSelectionChanged: (selected) {
          setState(() {
            _selectedYear = selected.first;
          });
          _loadData();
        },
      ),
    );
  }

  Widget _buildStatsCards(TimelineModel timeline) {
    final stats = timeline.stats;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _TimelineStatCard(
              value: timeline.totalHelps.toString(),
              label: '总帮助次数',
              icon: Icons.favorite,
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _TimelineStatCard(
              value: '${timeline.totalMinutes ~/ 60}h',
              label: '志愿时长',
              icon: Icons.timer,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _TimelineStatCard(
              value: '${timeline.streakDays}天',
              label: '连续帮助',
              icon: Icons.local_fire_department,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmap(TimelineModel timeline) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '帮助热力图',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // 简化的热力图展示
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: timeline.days.length.clamp(0, 84), // 显示12周
              itemBuilder: (context, index) {
                final day = timeline.days[index];
                return Container(
                  decoration: BoxDecoration(
                    color: _getHeatmapColor(day.activityLevel),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('少', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(width: 4),
                ...List.generate(5, (i) {
                  return Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: _getHeatmapColor(i),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
                const SizedBox(width: 4),
                Text('多', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getHeatmapColor(int level) {
    final colors = [
      Colors.grey[200]!, // 0
      Colors.green[100]!, // 1
      Colors.green[300]!, // 2
      Colors.green[500]!, // 3
      Colors.green[700]!, // 4
    ];
    return colors[level.clamp(0, 4)];
  }

  Widget _buildDayCard(TimelineDay day) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        title: Text(day.date),
        subtitle: Text('${day.helpCount} 次帮助 · ${day.minutes} 分钟'),
        leading: CircleAvatar(
          backgroundColor: _getHeatmapColor(day.activityLevel),
          child: Text('${day.helpCount}'),
        ),
        children: day.events.map((event) {
          return ListTile(
            dense: true,
            leading: const Icon(Icons.favorite, size: 16, color: Colors.red),
            title: Text('帮助了 ${event.seekerName ?? '求助者'}'),
            subtitle: Text('${event.durationMinutes ?? 0} 分钟'),
            trailing: event.rating != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      event.rating!,
                      (i) => const Icon(Icons.star, size: 14, color: Colors.amber),
                    ),
                  )
                : null,
          );
        }).toList(),
      ),
    );
  }
}

/// F21: 徽章成就标签页
class BadgesTab extends StatefulWidget {
  const BadgesTab({super.key});

  @override
  State<BadgesTab> createState() => _BadgesTabState();
}

class _BadgesTabState extends State<BadgesTab> {
  final BadgeService _badgeService = BadgeService();

  List<BadgeModel> _myBadges = [];
  List<BadgeDefinition> _availableBadges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    const volunteerId = 'demo-volunteer-id';

    final myBadges = await _badgeService.getMyBadges(volunteerId);
    final availableBadges = await _badgeService.getAvailableBadges(volunteerId);

    setState(() {
      _myBadges = myBadges;
      _availableBadges = availableBadges;
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
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 已获得徽章
          Text(
            '已获得 (${_myBadges.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (_myBadges.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.emoji_events_outlined,
                          size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Text(
                        '还没有徽章',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.8,
              ),
              itemCount: _myBadges.length,
              itemBuilder: (context, index) {
                final badge = _myBadges[index];
                return _BadgeCard(
                  badge: badge,
                  isEarned: true,
                );
              },
            ),

          const SizedBox(height: 24),

          // 待解锁徽章
          Text(
            '待解锁',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
            ),
            itemCount: _availableBadges.length,
            itemBuilder: (context, index) {
              final badge = _availableBadges[index];
              return _BadgeCard(
                badge: BadgeModel(
                  id: badge.type.name,
                  userId: '',
                  type: badge.type,
                  name: badge.name,
                  description: badge.description,
                ),
                isEarned: false,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// F22: 异步任务标签页
class AsyncTasksTab extends StatefulWidget {
  const AsyncTasksTab({super.key});

  @override
  State<AsyncTasksTab> createState() => _AsyncTasksTabState();
}

class _AsyncTasksTabState extends State<AsyncTasksTab> {
  final AsyncTaskService _taskService = AsyncTaskService();

  List<AsyncTaskModel> _availableTasks = [];
  List<AsyncTaskModel> _myTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    const volunteerId = 'demo-volunteer-id';

    final availableTasks = await _taskService.getAvailableTasks(volunteerId);
    final myTasks = await _taskService.getMyTasks(volunteerId);

    setState(() {
      _availableTasks = availableTasks;
      _myTasks = myTasks;
      _isLoading = false;
    });
  }

  Future<void> _claimTask(String taskId) async {
    const volunteerId = 'demo-volunteer-id';
    final success = await _taskService.claimTask(taskId, volunteerId);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('领取成功')),
      );
      _loadData();
    }
  }

  Future<void> _completeTask(String taskId, String result) async {
    const volunteerId = 'demo-volunteer-id';
    final success = await _taskService.completeTask(taskId, result);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('任务已完成')),
      );
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: '可领取'),
              Tab(text: '我的任务'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildAvailableTasksList(),
                _buildMyTasksList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableTasksList() {
    if (_availableTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              '暂无可领取的任务',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _availableTasks.length,
        itemBuilder: (context, index) {
          final task = _availableTasks[index];
          return _TaskCard(
            task: task,
            isAvailable: true,
            onClaim: () => _claimTask(task.id),
          );
        },
      ),
    );
  }

  Widget _buildMyTasksList() {
    if (_myTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              '还没有任务',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myTasks.length,
        itemBuilder: (context, index) {
          final task = _myTasks[index];
          return _TaskCard(
            task: task,
            isAvailable: false,
            onComplete: () => _showCompleteDialog(task),
          );
        },
      ),
    );
  }

  void _showCompleteDialog(AsyncTaskModel task) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('完成任务'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('任务: ${task.description}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '处理结果',
                hintText: '请描述您的处理结果',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completeTask(task.id, controller.text);
            },
            child: const Text('提交'),
          ),
        ],
      ),
    );
  }
}

/// F23: 排班管理标签页
class ScheduleTab extends StatefulWidget {
  const ScheduleTab({super.key});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  final ScheduleService _scheduleService = ScheduleService();

  ScheduleModel? _schedule;
  bool _isOnline = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    const volunteerId = 'demo-volunteer-id';

    final schedule = await _scheduleService.getSchedule(volunteerId);
    final isOnline = await _scheduleService.isOnline(volunteerId);

    setState(() {
      _schedule = schedule;
      _isOnline = isOnline;
      _isLoading = false;
    });
  }

  Future<void> _toggleOnline(bool value) async {
    const volunteerId = 'demo-volunteer-id';

    final success = value
        ? await _scheduleService.goOnline(volunteerId)
        : await _scheduleService.goOffline(volunteerId);

    if (success) {
      setState(() => _isOnline = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final schedule = _schedule;
    if (schedule == null) {
      return const Center(child: Text('加载失败'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 在线状态开关
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _isOnline ? Icons.circle : Icons.circle_outlined,
                    color: _isOnline ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isOnline ? '在线' : '离线',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _isOnline
                              ? '您现在可以接收求助请求'
                              : '开启后可接收求助请求',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isOnline,
                    onChanged: _toggleOnline,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 本周排班
          Text(
            '本周排班',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          ...WeekDay.values.map((day) {
            final slots = schedule.weeklySchedule[day.key] ?? [];
            return _DayScheduleCard(
              day: day,
              slots: slots,
              onEdit: () => _editDaySchedule(day, slots),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _editDaySchedule(WeekDay day, List<TimeSlot> currentSlots) async {
    // 简化的编辑对话框
    final result = await showDialog<List<TimeSlot>>(
      context: context,
      builder: (context) => _ScheduleEditorDialog(
        day: day,
        initialSlots: currentSlots,
      ),
    );

    if (result != null) {
      const volunteerId = 'demo-volunteer-id';
      final success = await _scheduleService.updateDaySchedule(
        volunteerId,
        day.key,
        result,
      );

      if (success) {
        _loadData();
      }
    }
  }
}

// ==================== 辅助组件 ====================

class _LevelCard extends StatelessWidget {
  final VolunteerLevelInfo levelInfo;

  const _LevelCard({required this.levelInfo});

  @override
  Widget build(BuildContext context) {
    final currentDef = levelInfo.currentLevelDef;

    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.blue[400]!, Colors.purple[500]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Text(
              currentDef.emoji,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 12),
            Text(
              'Lv${levelInfo.currentLevel} ${currentDef.name}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              currentDef.description ?? '',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Text(
              '${levelInfo.currentPoints} 积分',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelProgress extends StatelessWidget {
  final VolunteerLevelInfo levelInfo;

  const _LevelProgress({required this.levelInfo});

  @override
  Widget build(BuildContext context) {
    final nextLevel = levelInfo.nextLevel;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '等级进度',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: levelInfo.progressPercent,
              minHeight: 12,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.blue[400]!,
              ),
            ),
            const SizedBox(height: 8),
            if (nextLevel != null)
              Text(
                '距离 ${nextLevel.name} 还需 ${levelInfo.pointsToNextLevel} 积分',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              const Text(
                '已达到最高等级！',
                style: TextStyle(color: Colors.green),
              ),
          ],
        ),
      ),
    );
  }
}

class _PrivilegesCard extends StatelessWidget {
  final VolunteerLevelInfo levelInfo;

  const _PrivilegesCard({required this.levelInfo});

  @override
  Widget build(BuildContext context) {
    final privileges = levelInfo.currentLevelDef.privileges;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '当前权益',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...privileges.map((privilege) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(privilege),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TransactionsList extends StatelessWidget {
  final List<PointTransactionModel> transactions;

  const _TransactionsList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('暂无积分记录'),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '积分记录',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ...transactions.take(10).map((transaction) {
            return ListTile(
              dense: true,
              leading: Icon(
                transaction.isPositive ? Icons.add_circle : Icons.remove_circle,
                color: transaction.isPositive ? Colors.green : Colors.red,
              ),
              title: Text(PointRules.getTypeDescription(transaction.type)),
              subtitle: Text(
                transaction.createdAt?.formatRelative() ?? '',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              trailing: Text(
                '${transaction.isPositive ? '+' : ''}${transaction.points}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: transaction.isPositive ? Colors.green : Colors.red,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SkillSelector extends StatelessWidget {
  final ScrollController scrollController;
  final Set<String> existingSkills;
  final Function(SkillModel) onSkillSelected;

  const _SkillSelector({
    required this.scrollController,
    required this.existingSkills,
    required this.onSkillSelected,
  });

  @override
  Widget build(BuildContext context) {
    final categories = SkillDefinitions.categories;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '选择技能标签',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final skills = SkillDefinitions.getByCategory(category)
                    .where((s) => !existingSkills.contains(s.id))
                    .toList();

                if (skills.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      SkillDefinitions.getCategoryDisplayName(category),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: skills.map((skill) {
                        return ActionChip(
                          avatar: Text(skill.iconEmoji),
                          label: Text(skill.name),
                          onPressed: () => onSkillSelected(skill),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineStatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _TimelineStatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final BadgeModel badge;
  final bool isEarned;

  const _BadgeCard({required this.badge, required this.isEarned});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isEarned ? null : Colors.grey[100],
      child: InkWell(
        onTap: () => _showBadgeDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                badge.iconEmoji,
                style: TextStyle(
                  fontSize: 40,
                  color: isEarned ? null : Colors.grey[400],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                badge.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isEarned ? null : Colors.grey[500],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (isEarned && badge.earnedAt != null)
                Text(
                  badge.earnedAt!.formatDate(),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBadgeDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          children: [
            Text(badge.iconEmoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(badge.name),
          ],
        ),
        content: Text(badge.description ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final AsyncTaskModel task;
  final bool isAvailable;
  final VoidCallback? onClaim;
  final VoidCallback? onComplete;

  const _TaskCard({
    required this.task,
    required this.isAvailable,
    this.onClaim,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(task.taskType),
                  backgroundColor: Colors.blue[100],
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const Spacer(),
                if (isAvailable)
                  ElevatedButton(
                    onPressed: onClaim,
                    child: const Text('领取'),
                  )
                else if (task.status == 'processing')
                  ElevatedButton(
                    onPressed: onComplete,
                    child: const Text('完成'),
                  )
                else
                  Chip(
                    label: Text(task.status ?? '未知'),
                    backgroundColor: Colors.grey[200],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              task.description,
              style: const TextStyle(fontSize: 16),
            ),
            if (task.imageUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  task.imageUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '创建于 ${task.createdAt?.formatRelative() ?? ''}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayScheduleCard extends StatelessWidget {
  final WeekDay day;
  final List<TimeSlot> slots;
  final VoidCallback onEdit;

  const _DayScheduleCard({
    required this.day,
    required this.slots,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = DateTime.now().weekday == day.index + 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isToday ? Colors.blue[50] : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isToday ? Colors.blue : Colors.grey,
          child: Text(
            day.displayName.substring(0, 2),
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
        ),
        title: Text(day.displayName),
        subtitle: slots.isEmpty
            ? const Text('无排班', style: TextStyle(color: Colors.grey))
            : Wrap(
                spacing: 4,
                children: slots.map((slot) {
                  return Chip(
                    label: Text(slot.displayText),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: onEdit,
        ),
      ),
    );
  }
}

class _ScheduleEditorDialog extends StatefulWidget {
  final WeekDay day;
  final List<TimeSlot> initialSlots;

  const _ScheduleEditorDialog({
    required this.day,
    required this.initialSlots,
  });

  @override
  State<_ScheduleEditorDialog> createState() => _ScheduleEditorDialogState();
}

class _ScheduleEditorDialogState extends State<_ScheduleEditorDialog> {
  late List<TimeSlot> _slots;

  @override
  void initState() {
    super.initState();
    _slots = List.from(widget.initialSlots);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('编辑 ${widget.day.displayName} 排班'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._slots.asMap().entries.map((entry) {
              final index = entry.key;
              final slot = entry.value;
              return ListTile(
                title: Text('${slot.start} - ${slot.end}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _slots.removeAt(index);
                    });
                  },
                ),
              );
            }),
            ListTile(
              leading: const Icon(Icons.add, color: Colors.blue),
              title: const Text('添加时段'),
              onTap: () => _addTimeSlot(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _slots),
          child: const Text('保存'),
        ),
      ],
    );
  }

  void _addTimeSlot() {
    // 简化版：添加默认时段
    setState(() {
      _slots.add(const TimeSlot(start: '09:00', end: '12:00'));
    });
  }
}
