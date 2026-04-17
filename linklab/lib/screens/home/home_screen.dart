import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/extensions.dart';
import '../../demo_flow/demo_flow_controller.dart';
import '../../demo_flow/demo_matching_flow.dart';
import '../../models/community_models.dart';
import '../../models/help_request_model.dart';
import '../../models/user_model.dart';
import '../../services/app_session_service.dart';
import '../../services/community/featured_story_service.dart';
import '../../services/security/emergency_contact_service.dart';
import '../../services/security/safety_settings_service.dart';
import '../../services/user_center/help_archive_service.dart';
import '../../widgets/accessible/index.dart';
import '../ai_chat/demo_ai_chat_screen.dart';
import '../community/story_detail_screen.dart';
import '../user_center/seeker_center_screen.dart';

/// 首页
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FeaturedStoryService _storyService = FeaturedStoryService();
  final HelpArchiveService _helpArchiveService = HelpArchiveService();
  final SafetySettingsService _safetySettingsService = SafetySettingsService();
  final EmergencyContactService _emergencyContactService =
      EmergencyContactService();

  List<HelpRequestModel> _recentHistory = const [];
  List<FeaturedStory> _featuredStories = const [];
  SafetySettings _safetySettings = const SafetySettings();
  int _emergencyContactCount = 0;
  bool _isLoading = true;

  String get _currentUserId =>
      AppSessionService.instance.currentUser?.id ?? 'demo-user-id';

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    final results = await Future.wait<dynamic>([
      _helpArchiveService.getHelpHistory(_currentUserId, limit: 3),
      _storyService.getDailyFeatured(limit: 2),
      _safetySettingsService.getSettings(_currentUserId),
      _emergencyContactService.getContactCount(_currentUserId),
    ]);

    if (!mounted) return;
    setState(() {
      _recentHistory = results[0] as List<HelpRequestModel>;
      _featuredStories = results[1] as List<FeaturedStory>;
      _safetySettings = results[2] as SafetySettings;
      _emergencyContactCount = results[3] as int;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = AppSessionService.instance;
    final now = DateTime.now();
    final profile = session.userProfile;
    final preferenceSummary = session.preferences.highContrastMode
        ? '高对比度已开启'
        : '标准显示模式';

    return AccessibleScaffold(
      title: '共感LinkAble',
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadContent,
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            children: [
              Semantics(
                label: '欢迎信息',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AccessibleText(
                      '您好，${session.greetingName}',
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeXLarge,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    AccessibleText(
                      profile?.isVolunteer == true
                          ? '今天想先帮助别人，还是先处理自己的需求？'
                          : '今天需要什么帮助？',
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeNormal,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              Wrap(
                spacing: AppTheme.spacingS,
                runSpacing: AppTheme.spacingS,
                children: [
                  _StatusChip(
                    icon: Icons.calendar_today,
                    label: _buildDateLabel(now),
                    color: AppTheme.primaryColor,
                  ),
                  _StatusChip(
                    icon: Icons.wb_sunny_outlined,
                    label: _buildWeatherLabel(now),
                    color: AppTheme.accentColor,
                  ),
                  _StatusChip(
                    icon: Icons.settings_accessibility,
                    label: preferenceSummary,
                    color: AppTheme.secondaryColor,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              // AGENTS.md §8：首页只展示可本地复现、可重复执行的 Demo 主线入口。
              if (AppConfig.demoMode) const _CompetitionDemoNoticeCard(),
              const SizedBox(height: AppTheme.spacingL),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: '最近求助',
                      value: '${_recentHistory.length} 条',
                      subtitle: '本地档案已同步',
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: _SummaryCard(
                      title: '当前角色',
                      value: _buildRoleSummary(profile),
                      subtitle: '可在“我的”中调整偏好',
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              _SafetyReadyCard(
                settings: _safetySettings,
                contactCount: _emergencyContactCount,
              ),
              const SizedBox(height: AppTheme.spacingXXL),
              Semantics(
                button: true,
                label: '紧急求助按钮',
                hint: '双击触发紧急求助，将向附近志愿者和紧急联系人发送求助信息',
                child: InkWell(
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    _showEmergencyDialog(context);
                  },
                  onDoubleTap: () {
                    DemoFlowNavigator.onSOSButtonPressed(context);
                  },
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusLarge,
                  ),
                  child: Container(
                    width: double.infinity,
                    height: AppTheme.emergencyButtonHeight,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppTheme.emergencyColor,
                          AppTheme.warningColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadiusLarge,
                      ),
                      boxShadow: AppTheme.elevatedShadow,
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emergency,
                          color: AppTheme.textOnPrimary,
                          size: 48,
                        ),
                        SizedBox(height: AppTheme.spacingS),
                        Text(
                          '紧急求助',
                          style: TextStyle(
                            color: AppTheme.textOnPrimary,
                            fontSize: AppTheme.fontSizeXXLarge,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingXL),
              AccessibleButton(
                label: '我需要帮助',
                semanticLabel: '我需要帮助按钮，进入AI对话',
                hint: '双击进入AI助手对话界面',
                height: 100,
                icon: Icons.help_outline,
                onPressed: () {
                  DemoFlowNavigator.onHomeBigButtonPressed(context);
                },
              ),
              const SizedBox(height: AppTheme.spacingXL),
              const AccessibleText(
                '快捷工具',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              Row(
                children: [
                  Expanded(
                    child: _QuickToolButton(
                      label: '文字识别',
                      icon: Icons.document_scanner,
                      semanticLabel: 'OCR文字识别',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DemoAIChatScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: _QuickToolButton(
                      label: '颜色识别',
                      icon: Icons.color_lens,
                      semanticLabel: '颜色识别',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DemoAIChatScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: _QuickToolButton(
                      label: 'AI对话',
                      icon: Icons.chat,
                      semanticLabel: '智能对话',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DemoAIChatScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingXL),
              AccessibleCard(
                semanticLabel: '呼叫志愿者',
                hint: '双击连接真人志愿者获取帮助',
                onTap: () {
                  DemoMatchingFlow.startMatching(context);
                },
                margin: EdgeInsets.zero,
                child: Row(
                  children: [
                    Container(
                      width: AppTheme.minTouchTarget * 1.5,
                      height: AppTheme.minTouchTarget * 1.5,
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryLight.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusMedium,
                        ),
                      ),
                      child: const Icon(
                        Icons.volunteer_activism,
                        size: AppTheme.fontSizeXXLarge,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingL),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AccessibleText(
                            '呼叫志愿者',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeLarge,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: AppTheme.spacingXS),
                          AccessibleText(
                            '连接真人志愿者获取帮助',
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
              const SizedBox(height: AppTheme.spacingL),
              AccessibleCard(
                semanticLabel: 'AI智能助手',
                hint: '双击与AI助手对话',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DemoAIChatScreen()),
                  );
                },
                margin: EdgeInsets.zero,
                child: Row(
                  children: [
                    Container(
                      width: AppTheme.minTouchTarget * 1.5,
                      height: AppTheme.minTouchTarget * 1.5,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusMedium,
                        ),
                      ),
                      child: const Icon(
                        Icons.smart_toy,
                        size: AppTheme.fontSizeXXLarge,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingL),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AccessibleText(
                            'AI智能助手',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeLarge,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: AppTheme.spacingXS),
                          AccessibleText(
                            '文字识别、场景描述、智能对话',
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
              const SizedBox(height: AppTheme.spacingL),
              const SizedBox(height: AppTheme.spacingXL),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AccessibleText(
                    '最近帮助',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SeekerCenterScreen(),
                        ),
                      );
                    },
                    child: const AccessibleText('查看全部'),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingS),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.spacingL),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_recentHistory.isEmpty)
                AccessibleCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: const [
                      Icon(
                        Icons.history_toggle_off,
                        size: AppTheme.fontSizeXXLarge,
                        color: AppTheme.textHint,
                      ),
                      SizedBox(height: AppTheme.spacingS),
                      AccessibleText(
                        '还没有历史求助记录',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeNormal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacingXS),
                      AccessibleText(
                        '完成一次 AI 或志愿者协助后，这里会自动更新。',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._recentHistory.map(
                  (request) => Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
                    child: _HelpHistoryItem(
                      request: request,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SeekerCenterScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              const SizedBox(height: AppTheme.spacingXL),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AccessibleText(
                    '每日精选故事',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: _loadContent,
                    child: const AccessibleText('刷新内容'),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingS),
              if (_featuredStories.isEmpty && !_isLoading)
                AccessibleCard(
                  margin: EdgeInsets.zero,
                  child: Row(
                    children: const [
                      Icon(Icons.auto_stories, color: AppTheme.accentColor),
                      SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: AccessibleText(
                          '社区故事正在准备中，稍后会自动展示。',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeNormal,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._featuredStories.map(
                  (story) => Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                    child: _FeaturedStoryPreview(
                      story: story,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StoryDetailScreen(story: story),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const AccessibleText(
          '确认紧急求助？',
          style: TextStyle(
            fontSize: AppTheme.fontSizeXLarge,
            fontWeight: FontWeight.bold,
            color: AppTheme.emergencyColor,
          ),
        ),
        content: AccessibleText(
          _buildEmergencyDialogMessage(),
          style: TextStyle(fontSize: AppTheme.fontSizeNormal),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const AccessibleText('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emergencyColor,
              foregroundColor: AppTheme.textOnPrimary,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              DemoFlowNavigator.onSOSButtonPressed(context);
            },
            child: const AccessibleText('确认求助'),
          ),
        ],
      ),
    );
  }

  String _buildDateLabel(DateTime now) {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return '${now.month}月${now.day}日 周${weekdays[now.weekday - 1]} ${now.toTimeString()}';
  }

  String _buildWeatherLabel(DateTime now) {
    if (now.hour < 12) {
      return '演示天气 晴 24°C';
    }
    if (now.hour < 18) {
      return '演示天气 多云 26°C';
    }
    return '演示天气 夜间 21°C';
  }

  String _buildRoleSummary(UserModel? profile) {
    if (profile == null) {
      return '演示账号';
    }
    if (profile.isVolunteer && profile.isSeeker) {
      return '互助双角色';
    }
    if (profile.isVolunteer) {
      return '志愿者';
    }
    return '求助者';
  }

  String _buildEmergencyDialogMessage() {
    final locationText = !_safetySettings.autoShareLocation
        ? '不会自动共享位置'
        : '将共享${_safetySettings.usePreciseLocation ? '精确' : '大致'}位置';
    final contactText = _safetySettings.shareWithEmergencyContacts
        ? (_emergencyContactCount > 0
              ? '并通知 $_emergencyContactCount 位紧急联系人'
              : '但当前还没有可通知的紧急联系人')
        : '且不会同步给紧急联系人';
    return '这将向附近的志愿者发送求助信息，$locationText，$contactText。';
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AccessibleText(
            title,
            style: TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          AccessibleText(
            value,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          AccessibleText(
            subtitle,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppTheme.spacingXS),
          AccessibleText(
            label,
            style: TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompetitionDemoNoticeCard extends StatelessWidget {
  const _CompetitionDemoNoticeCard();

  @override
  Widget build(BuildContext context) {
    return AccessibleCard(
      margin: EdgeInsets.zero,
      semanticLabel: '竞赛演示模式说明',
      hint: '当前默认只展示 MVP 主线，真实后端与社群页不进入默认导航',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppTheme.minTouchTarget,
            height: AppTheme.minTouchTarget,
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            ),
            child: const Icon(
              Icons.rocket_launch_outlined,
              color: AppTheme.secondaryColor,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccessibleText(
                  '竞赛演示模式已锁定',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeNormal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: AppTheme.spacingXS),
                AccessibleText(
                  '当前默认仅展示 AI 对话、真人匹配、实时通话、SOS、登录偏好与无障碍能力。AppConfig.demoMode 已强制开启，真实后端与社群模块不会进入默认导航或演示脚本。',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 快捷工具按钮
class _QuickToolButton extends StatelessWidget {
  const _QuickToolButton({
    required this.label,
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      hint: '双击打开$label',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: AppTheme.fontSizeXXLarge,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: AppTheme.spacingS),
              AccessibleText(
                label,
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeNormal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpHistoryItem extends StatelessWidget {
  const _HelpHistoryItem({required this.request, required this.onTap});

  final HelpRequestModel request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AccessibleListTile(
      title: AccessibleText(
        _buildTypeLabel(request),
        style: const TextStyle(
          fontSize: AppTheme.fontSizeNormal,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: AccessibleText(
        '${request.intent ?? '未命名求助'} · ${request.createdAt?.formatRelative() ?? '刚刚'}',
        style: const TextStyle(
          fontSize: AppTheme.fontSizeSmall,
          color: AppTheme.textSecondary,
        ),
      ),
      leading: Icon(
        _buildTypeIcon(request),
        color: request.volunteerId == null
            ? AppTheme.primaryColor
            : AppTheme.secondaryColor,
      ),
      trailing: AccessibleText(
        request.statusLabel,
        style: const TextStyle(
          fontSize: AppTheme.fontSizeSmall,
          color: AppTheme.textHint,
        ),
      ),
      onTap: onTap,
    );
  }

  String _buildTypeLabel(HelpRequestModel request) {
    switch (request.type) {
      case 'ai_auto':
        return 'AI自助';
      case 'realtime_voice':
        return '语音求助';
      case 'realtime_video':
        return '视频求助';
      case 'sos':
        return '紧急求助';
      default:
        return '帮助记录';
    }
  }

  IconData _buildTypeIcon(HelpRequestModel request) {
    switch (request.type) {
      case 'ai_auto':
        return Icons.smart_toy;
      case 'realtime_voice':
        return Icons.phone_in_talk;
      case 'realtime_video':
        return Icons.videocam;
      case 'sos':
        return Icons.emergency;
      default:
        return Icons.help_outline;
    }
  }
}

class _FeaturedStoryPreview extends StatelessWidget {
  const _FeaturedStoryPreview({required this.story, required this.onTap});

  final FeaturedStory story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AccessibleCard(
      semanticLabel: '精选故事 ${story.title}',
      hint: '双击查看故事详情',
      onTap: onTap,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusMedium,
                  ),
                ),
                child: const Icon(
                  Icons.auto_stories,
                  color: AppTheme.accentColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AccessibleText(
                      story.title,
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeLarge,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    AccessibleText(
                      '${story.authorType == 'anonymous' ? '匿名用户' : (story.authorName ?? '社区用户')} · ${story.createdAt?.toDateString() ?? '今天'}',
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          AccessibleText(
            (story.summary ?? story.content).truncate(72),
            style: const TextStyle(
              fontSize: AppTheme.fontSizeNormal,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              const Icon(
                Icons.favorite_border,
                size: 18,
                color: AppTheme.textHint,
              ),
              const SizedBox(width: AppTheme.spacingXS),
              AccessibleText(
                '${story.likeCount}',
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeSmall,
                  color: AppTheme.textHint,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              const Icon(
                Icons.remove_red_eye_outlined,
                size: 18,
                color: AppTheme.textHint,
              ),
              const SizedBox(width: AppTheme.spacingXS),
              AccessibleText(
                '${story.readCount}',
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeSmall,
                  color: AppTheme.textHint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SafetyReadyCard extends StatelessWidget {
  const _SafetyReadyCard({required this.settings, required this.contactCount});

  final SafetySettings settings;
  final int contactCount;

  @override
  Widget build(BuildContext context) {
    final title = !settings.autoShareLocation
        ? 'SOS 位置信息未开启'
        : settings.shareWithEmergencyContacts && contactCount == 0
        ? 'SOS 基础广播已就绪'
        : 'SOS 演示链路已就绪';

    final subtitle = !settings.autoShareLocation
        ? '建议先到“我的 > 位置共享”开启位置同步。'
        : settings.shareWithEmergencyContacts && contactCount == 0
        ? '已开启位置共享，但联系人通知还没有接收对象。'
        : '当前位置、联系人通知和志愿者广播都可在演示中展示。';

    return AccessibleCard(
      margin: EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppTheme.minTouchTarget,
            height: AppTheme.minTouchTarget,
            decoration: BoxDecoration(
              color: AppTheme.emergencyColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppTheme.emergencyColor,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccessibleText(
                  title,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeNormal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                AccessibleText(
                  subtitle,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
