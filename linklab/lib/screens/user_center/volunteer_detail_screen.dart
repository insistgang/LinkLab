import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../demo_data/volunteers.dart';
import '../../models/badge_model.dart';
import '../../models/schedule_model.dart';
import '../../models/skill_model.dart';
import '../../models/user_model.dart';
import '../../models/volunteer_level_model.dart';
import '../../services/user_center/badge_service.dart';
import '../../services/user_center/schedule_service.dart';
import '../../services/user_center/skill_tag_service.dart';
import '../../services/user_center/volunteer_demo_store.dart';
import '../../services/user_center/volunteer_level_service.dart';
import 'demo_help_request_screen.dart';

class VolunteerDetailScreen extends StatefulWidget {
  const VolunteerDetailScreen({
    super.key,
    required this.volunteerId,
    this.volunteerName,
    this.volunteerAvatar,
  });

  final String volunteerId;
  final String? volunteerName;
  final String? volunteerAvatar;

  @override
  State<VolunteerDetailScreen> createState() => _VolunteerDetailScreenState();
}

class _VolunteerDetailScreenState extends State<VolunteerDetailScreen> {
  final VolunteerDemoStore _demoStore = VolunteerDemoStore();
  final VolunteerLevelService _levelService = VolunteerLevelService();
  final SkillTagService _skillTagService = SkillTagService();
  final BadgeService _badgeService = BadgeService();
  final ScheduleService _scheduleService = ScheduleService();

  bool _isLoading = true;
  VolunteerProfile? _profile;
  VolunteerLevelInfo? _levelInfo;
  List<SkillModel> _skills = [];
  List<BadgeModel> _badges = [];
  ScheduleModel? _schedule;
  DemoVolunteer? _demoVolunteer;
  int _serviceHours = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final demoVolunteer = getVolunteerById(widget.volunteerId);
    await _badgeService.checkAndAwardBadges(widget.volunteerId);

    final profile = await _demoStore.getProfile(widget.volunteerId);
    final activities = await _demoStore.getActivities(widget.volunteerId);
    final levelInfo = await _levelService.getLevelInfo(widget.volunteerId);
    final skills = await _skillTagService.getMySkills(widget.volunteerId);
    final badges = await _badgeService.getMyBadges(widget.volunteerId);
    final schedule = await _scheduleService.getSchedule(widget.volunteerId);

    final totalMinutes = activities.fold<int>(
      0,
      (sum, item) => sum + item.durationMinutes,
    );
    final seededHelpCount =
        demoVolunteer?.helpCount ?? profile.totalHelpCount ?? activities.length;
    final estimatedHours = math.max(
      (totalMinutes / 60).ceil(),
      (seededHelpCount / 4).ceil(),
    );

    if (!mounted) return;
    setState(() {
      _demoVolunteer = demoVolunteer;
      _profile = profile;
      _levelInfo = levelInfo;
      _skills = skills;
      _badges = badges;
      _schedule = schedule;
      _serviceHours = estimatedHours;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final levelInfo = _levelInfo;
    final profile = _profile;
    final schedule = _schedule;

    return Scaffold(
      appBar: AppBar(title: const Text('志愿者详情')),
      body:
          _isLoading || levelInfo == null || profile == null || schedule == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
                children: [
                  _buildHeaderCard(levelInfo, profile),
                  const SizedBox(height: 16),
                  _buildInfoSection(
                    title: '服务标签',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _serviceTags
                          .map(
                            (item) => Chip(
                              label: Text(item),
                              backgroundColor: Colors.teal.withAlpha(20),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoSection(
                    title: '擅长方向',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _skills.isEmpty
                          ? const [
                              Text(
                                '暂无技能标签',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ]
                          : _skills
                                .map(
                                  (skill) => Chip(
                                    avatar: Text(skill.iconEmoji),
                                    label: Text(skill.name),
                                  ),
                                )
                                .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoSection(
                    title: '荣誉徽章',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _badges.isEmpty
                          ? const [
                              Text(
                                '暂无徽章',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ]
                          : _badges
                                .map(
                                  (badge) => Chip(
                                    avatar: Text(badge.iconEmoji),
                                    label: Text(badge.name),
                                  ),
                                )
                                .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoSection(
                    title: '可服务时间',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _availableScheduleLines.isEmpty
                          ? const [
                              Text(
                                '暂未设置可服务时间',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ]
                          : _availableScheduleLines
                                .map(
                                  (line) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.schedule,
                                          size: 18,
                                          color: Colors.teal,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(line)),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _openHelpRequestComposer,
          icon: const Icon(Icons.volunteer_activism),
          label: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text('发起求助'),
          ),
        ),
      ),
    );
  }

  Future<void> _openHelpRequestComposer() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DemoHelpRequestScreen(
          volunteerId: widget.volunteerId,
          volunteerName: _displayName,
          volunteerAvatar: _displayAvatar,
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    VolunteerLevelInfo levelInfo,
    VolunteerProfile profile,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundImage: _avatarImage(_displayAvatar),
              child: _avatarImage(_displayAvatar) == null
                  ? Text(
                      _displayName.substring(0, 1),
                      style: const TextStyle(fontSize: 26),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              _displayName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              '${levelInfo.currentLevelDef.emoji} Lv${levelInfo.currentLevel} ${levelInfo.currentLevelDef.name}',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 4),
            Text(
              _demoVolunteer?.levelBadge != null
                  ? '${_demoVolunteer!.levelBadge} ${_demoVolunteer!.level}志愿者'
                  : '信用分 ${profile.creditScore.toStringAsFixed(1)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SummaryStat(
                    label: '志愿时长',
                    value: '$_serviceHours 小时',
                    icon: Icons.timer_outlined,
                  ),
                ),
                Expanded(
                  child: _SummaryStat(
                    label: '积分',
                    value: '${levelInfo.currentPoints}',
                    icon: Icons.stars_outlined,
                  ),
                ),
                Expanded(
                  child: _SummaryStat(
                    label: '等级',
                    value: 'Lv${levelInfo.currentLevel}',
                    icon: Icons.workspace_premium_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  List<String> get _serviceTags {
    final demoTags = _demoVolunteer?.skills ?? const <String>[];
    if (demoTags.isNotEmpty) {
      return demoTags;
    }
    return _skills.take(3).map((item) => item.name).toList();
  }

  List<String> get _availableScheduleLines {
    final schedule = _schedule;
    if (schedule == null) return const [];

    return WeekDay.values
        .where((day) => (schedule.weeklySchedule[day.key] ?? []).isNotEmpty)
        .map((day) {
          final slots = schedule.weeklySchedule[day.key] ?? [];
          final display = slots.map((slot) => slot.displayText).join(' / ');
          return '${day.displayName}  $display';
        })
        .toList();
  }

  String get _displayName {
    if (widget.volunteerName != null &&
        widget.volunteerName!.trim().isNotEmpty) {
      return widget.volunteerName!.trim();
    }
    if (_demoVolunteer != null) {
      return _demoVolunteer!.name;
    }
    return '志愿者';
  }

  String? get _displayAvatar {
    if (widget.volunteerAvatar != null &&
        widget.volunteerAvatar!.trim().isNotEmpty) {
      return widget.volunteerAvatar!.trim();
    }
    return _demoVolunteer?.avatar;
  }

  ImageProvider<Object>? _avatarImage(String? avatar) {
    if (avatar == null || avatar.isEmpty) return null;
    if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
      return NetworkImage(avatar);
    }
    return null;
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.teal),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
