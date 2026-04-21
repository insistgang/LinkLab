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
import '../../widgets/demo/demo_motion.dart';
import '../../widgets/demo/demo_overlays.dart';
import '../../widgets/demo/demo_routes.dart';
import '../../widgets/demo/demo_stage.dart';
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

    return DemoStageLiveBuilder(
      builder: (context) {
        return DemoStageScaffold(
          title: '共感 LinkAble',
          subtitle: 'AI 先处理标准化问题，复杂需求再转真人志愿者',
          showBackButton: false,
          body: RefreshIndicator(
            color: AppTheme.stageAccent,
            onRefresh: _loadContent,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingL,
                AppTheme.spacingL,
                AppTheme.spacingL,
                112,
              ),
              children: [
                DemoReveal(
                  child: _HeroPanel(
                    session: session,
                    profile: profile,
                    dateLabel: _buildDateLabel(now),
                    weatherLabel: _buildWeatherLabel(now),
                    preferenceSummary: preferenceSummary,
                    onHelpPressed: () {
                      DemoFlowNavigator.onHomeBigButtonPressed(context);
                    },
                    onVolunteerPressed: () {
                      DemoMatchingFlow.startMatching(context);
                    },
                    onEmergencyPressed: () {
                      HapticFeedback.heavyImpact();
                      _showEmergencyDialog(context);
                    },
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),
                if (AppConfig.demoMode) ...[
                  const DemoReveal(
                    delay: Duration(milliseconds: 80),
                    child: _CompetitionDemoNoticeCard(),
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                ],
                DemoReveal(
                  delay: const Duration(milliseconds: 130),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryStatCard(
                          eyebrow: '最近求助',
                          value: '${_recentHistory.length} 条',
                          description: '本地演示档案已同步',
                          color: AppTheme.stageAccent,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: _SummaryStatCard(
                          eyebrow: '当前角色',
                          value: _buildRoleSummary(profile),
                          description: '可在“我的”调整偏好',
                          color: AppTheme.stageSuccess,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),
                DemoReveal(
                  delay: const Duration(milliseconds: 180),
                  child: _SafetyReadyCard(
                    settings: _safetySettings,
                    contactCount: _emergencyContactCount,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXL),
                const DemoSectionTitle(
                  title: '快捷工具',
                  subtitle: '保留 3 个最高频入口，避免首屏功能过载。',
                ),
                const SizedBox(height: AppTheme.spacingM),
                DemoReveal(
                  delay: const Duration(milliseconds: 230),
                  child: Row(
                    children: [
                      Expanded(
                        child: _QuickToolButton(
                          label: '文字识别',
                          description: '读说明书、菜单、票据',
                          icon: Icons.document_scanner_outlined,
                          semanticLabel: 'OCR文字识别',
                          onTap: () {
                            pushDemoStageRoute(
                              context,
                              page: const DemoAIChatScreen(),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: _QuickToolButton(
                          label: '颜色识别',
                          description: '区分衣物与物品颜色',
                          icon: Icons.color_lens_outlined,
                          semanticLabel: '颜色识别',
                          onTap: () {
                            pushDemoStageRoute(
                              context,
                              page: const DemoAIChatScreen(),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: _QuickToolButton(
                          label: 'AI 对话',
                          description: '直接输入复杂需求',
                          icon: Icons.chat_bubble_outline_rounded,
                          semanticLabel: '智能对话',
                          onTap: () {
                            pushDemoStageRoute(
                              context,
                              page: const DemoAIChatScreen(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXL),
                DemoReveal(
                  delay: const Duration(milliseconds: 280),
                  child: DemoSurfaceCard(
                    semanticLabel: '连接真人志愿者',
                    hint: '双击进入匹配页',
                    onTap: () {
                      DemoMatchingFlow.startMatching(context);
                    },
                    child: Row(
                      children: [
                        const DemoGlassIconBadge(
                          icon: Icons.volunteer_activism_outlined,
                          size: 56,
                          iconSize: 26,
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AccessibleText(
                                '呼叫志愿者',
                                style: TextStyle(
                                  color: AppTheme.stageTextPrimary,
                                  fontSize: AppTheme.fontSizeLarge,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingXS),
                              AccessibleText(
                                'AI 无法处理时，30 秒内尝试匹配附近在线志愿者。',
                                style: TextStyle(
                                  color: AppTheme.stageTextSecondary,
                                  fontSize: AppTheme.fontSizeSmall,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: AppTheme.stageTextPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXL),
                DemoSectionTitle(
                  title: '最近帮助',
                  subtitle: '展示主链路的终态与回看落点。',
                  trailing: TextButton(
                    onPressed: () {
                      pushDemoStageRoute(
                        context,
                        page: const SeekerCenterScreen(),
                      );
                    },
                    child: Text(
                      '查看全部',
                      style: TextStyle(color: AppTheme.stageAccent),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                if (_isLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacingL,
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.stageAccent,
                      ),
                    ),
                  )
                else if (_recentHistory.isEmpty)
                  const _EmptyHistoryCard()
                else
                  ..._recentHistory.map(
                    (request) => Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                      child: _HelpHistoryItem(
                        request: request,
                        onTap: () {
                          pushDemoStageRoute(
                            context,
                            page: const SeekerCenterScreen(),
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: AppTheme.spacingXL),
                DemoSectionTitle(
                  title: '每日精选故事',
                  subtitle: '社群已降级为静态精选故事，不进入独立交互主线。',
                  trailing: TextButton(
                    onPressed: _loadContent,
                    child: Text(
                      '刷新内容',
                      style: TextStyle(color: AppTheme.stageAccent),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                if (_featuredStories.isEmpty && !_isLoading)
                  DemoSurfaceCard(
                    child: Row(
                      children: [
                        const DemoGlassIconBadge(
                          icon: Icons.auto_stories_outlined,
                          size: 44,
                          iconSize: 20,
                          shape: DemoGlassIconShape.circle,
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: AccessibleText(
                            '社区故事正在准备中，稍后会自动展示。',
                            style: TextStyle(
                              color: AppTheme.stageTextSecondary,
                              fontSize: AppTheme.fontSizeNormal,
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
                          pushDemoStageRoute(
                            context,
                            page: StoryDetailScreen(story: story),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEmergencyDialog(BuildContext context) {
    showDemoStageDialog<void>(
      context,
      barrierDismissible: false,
      builder: (context) => DemoDialog(
        title: '确认紧急求助？',
        icon: Icons.emergency_outlined,
        accentColor: AppTheme.stageDanger,
        description: _buildEmergencyDialogMessage(),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '取消',
              style: TextStyle(color: AppTheme.stageTextSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.stageDanger,
              foregroundColor: AppTheme.stageTextPrimary,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              DemoFlowNavigator.onSOSButtonPressed(context);
            },
            child: const Text('确认求助'),
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

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.session,
    required this.profile,
    required this.dateLabel,
    required this.weatherLabel,
    required this.preferenceSummary,
    required this.onHelpPressed,
    required this.onVolunteerPressed,
    required this.onEmergencyPressed,
  });

  final AppSessionService session;
  final UserModel? profile;
  final String dateLabel;
  final String weatherLabel;
  final String preferenceSummary;
  final VoidCallback onHelpPressed;
  final VoidCallback onVolunteerPressed;
  final VoidCallback onEmergencyPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: AppTheme.stagePanelGradient,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + 8),
        border: Border.all(color: AppTheme.stageBorder.withValues(alpha: 0.72)),
        boxShadow: AppTheme.stageShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppTheme.spacingS,
            runSpacing: AppTheme.spacingS,
            children: [
              DemoPill(
                icon: Icons.calendar_today_outlined,
                label: dateLabel,
                color: AppTheme.stageTextPrimary,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
              ),
              DemoPill(
                icon: Icons.wb_sunny_outlined,
                label: weatherLabel,
                color: AppTheme.stageAccentLight,
              ),
              DemoPill(
                icon: Icons.settings_accessibility_outlined,
                label: preferenceSummary,
                color: AppTheme.stageSuccess,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          AccessibleText(
            '您好，${session.greetingName}',
            style: TextStyle(
              color: AppTheme.stageTextPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          AccessibleText(
            profile?.isVolunteer == true
                ? '今天想先帮助别人，还是先处理自己的需求？'
                : '把标准化需求先交给 AI，复杂问题再转真人。',
            style: TextStyle(
              color: AppTheme.stageTextSecondary,
              fontSize: AppTheme.fontSizeNormal,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _HeroMetric(
                    label: 'Demo 主线',
                    value: '100% 可跑通',
                    color: AppTheme.stageAccentLight,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: _HeroMetric(
                    label: '无障碍',
                    value: '语义 + 高对比',
                    color: AppTheme.stageSuccess,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          AccessibleButton(
            label: '我需要帮助',
            semanticLabel: '我需要帮助按钮，进入AI对话',
            hint: '双击进入AI助手对话界面',
            height: 84,
            icon: Icons.arrow_outward_rounded,
            backgroundColor: AppTheme.stageAccent,
            foregroundColor: AppTheme.stageBackground,
            onPressed: onHelpPressed,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onVolunteerPressed,
                  icon: const Icon(Icons.volunteer_activism_outlined),
                  label: const Text('直接匹配志愿者'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.stageTextPrimary,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Semantics(
                button: true,
                label: '紧急求助按钮',
                hint: '双击进入紧急求助确认',
                child: InkWell(
                  onTap: onEmergencyPressed,
                  borderRadius: BorderRadius.circular(22),
                  child: Ink(
                    height: 56,
                    width: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.stageDanger.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppTheme.stageDanger.withValues(alpha: 0.32),
                      ),
                    ),
                    child: Icon(
                      Icons.emergency_outlined,
                      color: AppTheme.stageDanger,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AccessibleText(
          label,
          style: TextStyle(
            color: color,
            fontSize: AppTheme.fontSizeSmall,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXS),
        AccessibleText(
          value,
          style: TextStyle(
            color: AppTheme.stageTextPrimary,
            fontSize: AppTheme.fontSizeNormal,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SummaryStatCard extends StatelessWidget {
  const _SummaryStatCard({
    required this.eyebrow,
    required this.value,
    required this.description,
    required this.color,
  });

  final String eyebrow;
  final String value;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DemoSurfaceCard(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AccessibleText(
            eyebrow,
            style: TextStyle(
              color: color,
              fontSize: AppTheme.fontSizeSmall,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          AccessibleText(
            value,
            style: TextStyle(
              color: AppTheme.stageTextPrimary,
              fontSize: AppTheme.fontSizeLarge,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          AccessibleText(
            description,
            style: TextStyle(
              color: AppTheme.stageTextSecondary,
              fontSize: AppTheme.fontSizeSmall,
              height: 1.5,
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
    return DemoSurfaceCard(
      semanticLabel: '竞赛演示模式说明',
      hint: '当前默认只展示 MVP 主线，真实后端与社群页不进入默认导航',
      color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.94),
      borderColor: AppTheme.stageAccent.withValues(alpha: 0.28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DemoGlassIconBadge(
            icon: Icons.rocket_launch_outlined,
            size: AppTheme.minTouchTarget,
            iconSize: 22,
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccessibleText(
                  '竞赛演示模式已锁定',
                  style: TextStyle(
                    color: AppTheme.stageTextPrimary,
                    fontSize: AppTheme.fontSizeNormal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                AccessibleText(
                  '当前默认仅展示 AI 对话、真人匹配、实时通话、SOS、登录偏好与无障碍能力。真实后端与社群模块不会进入默认导航或演示脚本。',
                  style: TextStyle(
                    color: AppTheme.stageTextSecondary,
                    fontSize: AppTheme.fontSizeSmall,
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

class _QuickToolButton extends StatelessWidget {
  const _QuickToolButton({
    required this.label,
    required this.description,
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final String label;
  final String description;
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DemoSurfaceCard(
      semanticLabel: semanticLabel,
      hint: '双击打开$label',
      onTap: onTap,
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: SizedBox(
        height: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DemoGlassIconBadge(icon: icon, size: 48, iconSize: 22),
                const Spacer(),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.82),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.stageBorder.withValues(alpha: 0.32),
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_outward_rounded,
                    size: 16,
                    color: AppTheme.stageTextSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            AccessibleText(
              label,
              style: TextStyle(
                color: AppTheme.stageTextPrimary,
                fontSize: AppTheme.fontSizeNormal,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXS),
            AccessibleText(
              description,
              style: TextStyle(
                color: AppTheme.stageTextSecondary,
                fontSize: AppTheme.fontSizeSmall,
                height: 1.4,
              ),
            ),
            const Spacer(),
            AccessibleText(
              '点击进入',
              style: TextStyle(
                color: AppTheme.stageTextHint,
                fontSize: AppTheme.fontSizeSmall,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard();

  @override
  Widget build(BuildContext context) {
    return DemoSurfaceCard(
      child: Column(
        children: [
          Icon(
            Icons.history_toggle_off,
            size: AppTheme.fontSizeXXLarge,
            color: AppTheme.stageTextHint,
          ),
          const SizedBox(height: AppTheme.spacingS),
          AccessibleText(
            '还没有历史求助记录',
            style: TextStyle(
              color: AppTheme.stageTextPrimary,
              fontSize: AppTheme.fontSizeNormal,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          AccessibleText(
            '完成一次 AI 或志愿者协助后，这里会自动更新。',
            style: TextStyle(
              color: AppTheme.stageTextSecondary,
              fontSize: AppTheme.fontSizeSmall,
            ),
          ),
        ],
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
    return DemoSurfaceCard(
      onTap: onTap,
      semanticLabel: '帮助记录 ${request.intent ?? '未命名求助'}',
      hint: '双击查看帮助档案',
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _typeColor(request).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(_buildTypeIcon(request), color: _typeColor(request)),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccessibleText(
                  _buildTypeLabel(request),
                  style: TextStyle(
                    color: AppTheme.stageTextPrimary,
                    fontSize: AppTheme.fontSizeNormal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                AccessibleText(
                  '${request.intent ?? '未命名求助'} · ${request.createdAt?.formatRelative() ?? '刚刚'}',
                  style: TextStyle(
                    color: AppTheme.stageTextSecondary,
                    fontSize: AppTheme.fontSizeSmall,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingS),
          AccessibleText(
            request.statusLabel,
            style: TextStyle(
              color: AppTheme.stageAccentLight,
              fontSize: AppTheme.fontSizeSmall,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
        return Icons.smart_toy_outlined;
      case 'realtime_voice':
        return Icons.phone_in_talk_outlined;
      case 'realtime_video':
        return Icons.videocam_outlined;
      case 'sos':
        return Icons.emergency_outlined;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _typeColor(HelpRequestModel request) {
    switch (request.type) {
      case 'ai_auto':
        return AppTheme.stageInfo;
      case 'sos':
        return AppTheme.stageDanger;
      default:
        return AppTheme.stageAccent;
    }
  }
}

class _FeaturedStoryPreview extends StatelessWidget {
  const _FeaturedStoryPreview({required this.story, required this.onTap});

  final FeaturedStory story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DemoSurfaceCard(
      semanticLabel: '精选故事 ${story.title}',
      hint: '双击查看故事详情',
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const DemoGlassIconBadge(
                icon: Icons.auto_stories_outlined,
                size: 52,
                iconSize: 24,
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AccessibleText(
                      story.title,
                      style: TextStyle(
                        color: AppTheme.stageTextPrimary,
                        fontSize: AppTheme.fontSizeLarge,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    AccessibleText(
                      '${story.authorType == 'anonymous' ? '匿名用户' : (story.authorName ?? '社区用户')} · ${story.createdAt?.toDateString() ?? '今天'}',
                      style: TextStyle(
                        color: AppTheme.stageTextSecondary,
                        fontSize: AppTheme.fontSizeSmall,
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
            style: TextStyle(
              color: AppTheme.stageTextSecondary,
              fontSize: AppTheme.fontSizeNormal,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              _StoryMetric(
                icon: Icons.favorite_border,
                value: '${story.likeCount}',
              ),
              const SizedBox(width: AppTheme.spacingM),
              _StoryMetric(
                icon: Icons.remove_red_eye_outlined,
                value: '${story.readCount}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StoryMetric extends StatelessWidget {
  const _StoryMetric({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.stageTextHint),
        const SizedBox(width: AppTheme.spacingXS),
        AccessibleText(
          value,
          style: TextStyle(
            color: AppTheme.stageTextHint,
            fontSize: AppTheme.fontSizeSmall,
          ),
        ),
      ],
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

    return DemoSurfaceCard(
      color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.96),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppTheme.minTouchTarget,
            height: AppTheme.minTouchTarget,
            decoration: BoxDecoration(
              color: AppTheme.stageDanger.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.shield_outlined, color: AppTheme.stageDanger),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccessibleText(
                  title,
                  style: TextStyle(
                    color: AppTheme.stageTextPrimary,
                    fontSize: AppTheme.fontSizeNormal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                AccessibleText(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.stageTextSecondary,
                    fontSize: AppTheme.fontSizeSmall,
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
