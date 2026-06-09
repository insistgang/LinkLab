import 'package:flutter/material.dart';
import '../../models/demo_help_request_model.dart';
import '../../models/volunteer_level_model.dart';
// MVP: badge_model, timeline_model, schedule_model, point_transaction_model 已砍 (F20/F21/F23)
// import '../../models/badge_model.dart';
import '../../models/skill_model.dart';
// import '../../models/timeline_model.dart';
// import '../../models/schedule_model.dart';
import '../../models/help_request_model.dart';
// import '../../models/point_transaction_model.dart';
// ignore: deprecated_member_use_from_same_package
import '../../services/app_session_service.dart';
import '../../services/user_center/volunteer_level_service.dart';
// MVP: badge_service, timeline_service, schedule_service 已砍 (F20/F21/F23)
// import '../../services/user_center/badge_service.dart';
import '../../services/user_center/skill_tag_service.dart';
// import '../../services/user_center/timeline_service.dart';
// import '../../services/user_center/schedule_service.dart';
import '../../services/user_center/async_task_service.dart';
import '../../services/user_center/demo_help_request_service.dart';
import '../../core/utils/extensions.dart';

// ignore: deprecated_member_use_from_same_package
String _resolveVolunteerId() {
  return AppSessionService.instance.userProfile?.id ?? 'demo-volunteer-id';
}

/// 志願者中心頁面 (F18-F23)
/// MVP: 只保留等級、技能、任務三項；時間線、徽章、排班已砍 (F20/F21/F23)
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
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('志願者中心'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.military_tech), text: '等級'),
            Tab(icon: Icon(Icons.local_offer), text: '技能'),
            Tab(icon: Icon(Icons.assignment), text: '任務'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          LevelPointsTab(),
          SkillTagsTab(),
          AsyncTasksTab(),
        ],
      ),
    );
  }
}

/// F18: 等級積分標籤頁
class LevelPointsTab extends StatefulWidget {
  const LevelPointsTab({super.key});

  @override
  State<LevelPointsTab> createState() => _LevelPointsTabState();
}

class _LevelPointsTabState extends State<LevelPointsTab> {
  final VolunteerLevelService _levelService = VolunteerLevelService();

  VolunteerLevelInfo? _levelInfo;
  // MVP: point_transaction_model 已砍 (F15/F20)
  // List<PointTransactionModel> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final volunteerId = _resolveVolunteerId();

    final levelInfo = await _levelService.getLevelInfo(volunteerId);
    // MVP: point_transaction_model 已砍 (F15/F20)
    // final transactions = await _levelService.getPointTransactions(volunteerId);

    setState(() {
      _levelInfo = levelInfo;
      // _transactions = transactions;
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
      return const Center(child: Text('加載失敗'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 等級卡片
          _LevelCard(levelInfo: levelInfo),

          const SizedBox(height: 24),

          // 等級進度
          _LevelProgress(levelInfo: levelInfo),

          const SizedBox(height: 24),

          // 權益說明
          _PrivilegesCard(levelInfo: levelInfo),

          const SizedBox(height: 24),

          // MVP: 積分流水已砍 (F15/F20)
          // _TransactionsList(transactions: _transactions),
        ],
      ),
    );
  }
}

/// F19: 技能標籤標籤頁
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

    final volunteerId = _resolveVolunteerId();

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

          // 待認證申請
          if (_pendingRequests.isNotEmpty) _buildPendingSection(),

          const SizedBox(height: 24),

          // 添加技能按鈕
          ElevatedButton.icon(
            onPressed: _showAddSkillDialog,
            icon: const Icon(Icons.add),
            label: const Text('添加技能標籤'),
          ),
        ],
      ),
    );
  }

  Widget _buildMySkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('我的技能標籤', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (_mySkills.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.label_outline,
                      size: 48,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 8),
                    Text('暫無技能標籤', style: TextStyle(color: Colors.grey[600])),
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
        Text('認證中', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ..._pendingRequests.map((request) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.hourglass_empty, color: Colors.orange),
              title: Text(request.skillName ?? '未知技能'),
              subtitle: Text(
                '提交於 ${request.submittedAt?.formatRelative() ?? ''}',
              ),
              trailing: const Chip(
                label: Text('審覈中'),
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
    final volunteerId = _resolveVolunteerId();

    if (skill.requiresVerification) {
      final description = await _showVerificationDialog(skill);
      if (description != null) {
        final success = await _skillService.submitVerificationRequest(
          volunteerId,
          skill.id,
          description: description,
        );
        if (success && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${skill.name} 認證申請已提交')));
        }
        _loadData();
      }
    } else {
      // 直接添加
      final success = await _skillService.addSkill(volunteerId, skill.id);
      if (success && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已添加 ${skill.name}')));
        _loadData();
      }
    }
  }

  Future<String?> _showVerificationDialog(SkillModel skill) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('認證 ${skill.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(skill.description ?? ''),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '證書/資質說明',
                hintText: '請描述您的相關資質',
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
            onPressed: () => Navigator.pop(
              context,
              controller.text.trim().isEmpty
                  ? '已提交資質說明'
                  : controller.text.trim(),
            ),
            child: const Text('提交認證'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeSkill(String skillId) async {
    final volunteerId = _resolveVolunteerId();
    final success = await _skillService.removeSkill(volunteerId, skillId);
    if (success) {
      _loadData();
    }
  }
}

// MVP: F20 善意時間線標籤頁已砍
// class TimelineTab ... 整個類及相關組件已移除

// MVP: F21 徽章成就標籤頁已砍
// class BadgesTab ... 整個類及相關組件已移除

/// F22: 異步任務標籤頁
class AsyncTasksTab extends StatefulWidget {
  const AsyncTasksTab({super.key});

  @override
  State<AsyncTasksTab> createState() => _AsyncTasksTabState();
}

class _AsyncTasksTabState extends State<AsyncTasksTab> {
  final AsyncTaskService _taskService = AsyncTaskService();
  final DemoHelpRequestService _demoHelpRequestService =
      DemoHelpRequestService();
  final VolunteerLevelService _levelService = VolunteerLevelService();
  // MVP: badge_service 已砍 (F21)
  // final BadgeService _badgeService = BadgeService();

  List<DemoHelpRequestModel> _pendingHelpRequests = [];
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

    final volunteerId = _resolveVolunteerId();

    final pendingHelpRequests = await _demoHelpRequestService
        .getVolunteerRequests(volunteerId, pendingOnly: true);
    final availableTasks = await _taskService.getAvailableTasks(volunteerId);
    final myTasks = await _taskService.getMyTasks(volunteerId);

    setState(() {
      _pendingHelpRequests = pendingHelpRequests;
      _availableTasks = availableTasks;
      _myTasks = myTasks;
      _isLoading = false;
    });
  }

  Future<void> _claimTask(String taskId) async {
    final volunteerId = _resolveVolunteerId();
    final success = await _taskService.claimTask(taskId, volunteerId);

    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('領取成功')));
      _loadData();
    }
  }

  Future<void> _completeTask(String taskId, String result) async {
    final volunteerId = _resolveVolunteerId();
    final success = await _taskService.completeTask(taskId, result);

    if (success && mounted) {
      await _levelService.onAsyncHelpCompleted(volunteerId, taskId);
      // MVP: badge_service 已砍 (F21)
      // await _badgeService.checkAndAwardBadges(volunteerId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('任務已完成')));
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: '待處理求助'),
              Tab(text: '可領取'),
              Tab(text: '我的任務'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPendingHelpRequestsList(),
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
            Text('暫無可領取的任務', style: TextStyle(color: Colors.grey[600])),
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

  Widget _buildPendingHelpRequestsList() {
    if (_pendingHelpRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mark_email_unread_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text('暫無待處理求助', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(
              '求助者提交後，這裏會直接出現新的演示任務。',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingHelpRequests.length,
        itemBuilder: (context, index) {
          final request = _pendingHelpRequests[index];
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _RequestMetaChip(
                        icon: Icons.category_outlined,
                        label: request.typeLabel,
                      ),
                      _RequestMetaChip(
                        icon: Icons.schedule_outlined,
                        label: request.schedulePreference,
                      ),
                      _RequestMetaChip(
                        icon: Icons.accessibility_new_outlined,
                        label: request.accessibilityLabel,
                      ),
                      _RequestMetaChip(
                        icon: Icons.place_outlined,
                        label: request.locationModeLabel,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    request.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '提交於 ${request.createdAt.formatDateTime()}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
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
            Text('還沒有任務', style: TextStyle(color: Colors.grey[600])),
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
        title: const Text('完成任務'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('任務: ${task.description}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '處理結果',
                hintText: '請描述您的處理結果',
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

// MVP: F23 排班管理標籤頁已砍
// class ScheduleTab ... 整個類及相關組件已移除

// ==================== 輔助組件 ====================

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
            Text(currentDef.emoji, style: const TextStyle(fontSize: 64)),
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
              '${levelInfo.currentPoints} 積分',
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
              '等級進度',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: levelInfo.progressPercent,
              minHeight: 12,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
            ),
            const SizedBox(height: 8),
            if (nextLevel != null)
              Text(
                '距離 ${nextLevel.name} 還需 ${levelInfo.pointsToNextLevel} 積分',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              const Text('已達到最高等級！', style: TextStyle(color: Colors.green)),
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
              '當前權益',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...privileges.map((privilege) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
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

// MVP: F20 積分流水組件已砍 (point_transaction_model)
// class _TransactionsList extends StatelessWidget { ... }

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
            '選擇技能標籤',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final skills = SkillDefinitions.getByCategory(
                  category,
                ).where((s) => !existingSkills.contains(s.id)).toList();

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

// MVP: F20 時間線統計卡片已砍
// class _TimelineStatCard extends StatelessWidget { ... }

// MVP: F21 徽章卡片組件已砍
// class _BadgeCard extends StatelessWidget { ... }

class _RequestMetaChip extends StatelessWidget {
  const _RequestMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.teal),
      label: Text(label, overflow: TextOverflow.ellipsis),
      backgroundColor: Colors.teal.withAlpha(20),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                  ElevatedButton(onPressed: onClaim, child: const Text('領取'))
                else if (task.status == 'processing')
                  ElevatedButton(onPressed: onComplete, child: const Text('完成'))
                else
                  Chip(
                    label: Text(task.status ?? '未知'),
                    backgroundColor: Colors.grey[200],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(task.description, style: const TextStyle(fontSize: 16)),
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
              '創建於 ${task.createdAt?.formatRelative() ?? ''}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

// MVP: F23 排班相關組件已砍
// class _DayScheduleCard extends StatelessWidget { ... }
// class _ScheduleEditorDialog extends StatefulWidget { ... }
