import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/extensions.dart';
import '../../models/user_model.dart';
import '../../services/app_session_service.dart';
import '../../services/security/emergency_contact_service.dart';
import '../../services/security/safety_settings_service.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_motion.dart';
import '../../widgets/demo/demo_overlays.dart';
import '../../widgets/demo/demo_routes.dart';
import '../../widgets/demo/demo_stage.dart';
import '../auth/login_screen.dart';
import '../auth/preference_screen.dart';
import '../security/emergency_contacts_screen.dart';
import '../security/location_sharing_screen.dart';
import '../user_center/seeker_center_screen.dart';

/// 个人中心页面
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _refreshSafetyState() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = AppSessionService.instance;

    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final user = session.userProfile;
        final preferences = session.preferences;
        final helpCount = session.getRecentHelpHistory(limit: 20).length;
        final userId = user?.id ?? 'demo-seeker';
        final safetySnapshotFuture = _loadSafetySnapshot(userId);

        return DemoStageScaffold(
          title: '我的',
          subtitle: '登录、偏好、安全准备和帮助档案都在这里收口',
          showBackButton: false,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingL,
              AppTheme.spacingL,
              AppTheme.spacingL,
              120,
            ),
            children: [
              DemoReveal(
                child: _ProfileHero(
                  user: user,
                  preferences: preferences,
                  onEditPreferences: () {
                    pushDemoStageRoute(context, page: const PreferenceScreen());
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              DemoReveal(
                delay: const Duration(milliseconds: 70),
                child: Wrap(
                  spacing: AppTheme.spacingS,
                  runSpacing: AppTheme.spacingS,
                  children: [
                    _ProfileTag(
                      icon: session.isDayStageMode
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      label: session.isDayStageMode ? '日间模式' : '深夜模式',
                    ),
                    _ProfileTag(
                      icon: Icons.contrast_outlined,
                      label: preferences.highContrastMode ? '高对比度' : '标准显示',
                    ),
                    _ProfileTag(
                      icon: Icons.text_fields_outlined,
                      label: '字体 ${preferences.fontScale.toStringAsFixed(1)}x',
                    ),
                    _ProfileTag(
                      icon: Icons.volume_up_outlined,
                      label: '语速 ${preferences.voiceSpeed.toStringAsFixed(1)}x',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingXL),
              DemoReveal(
                delay: Duration(milliseconds: 110),
                child: DemoSectionTitle(
                  title: '无障碍设置',
                  subtitle: 'F33 与 F36 的关键偏好都收口在这里。',
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              DemoReveal(
                delay: const Duration(milliseconds: 140),
                child: _MenuItem(
                  icon: Icons.settings_accessibility,
                  title: '编辑无障碍偏好',
                  subtitle: _buildPreferenceSummary(preferences),
                  onTap: () {
                    pushDemoStageRoute(context, page: const PreferenceScreen());
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              DemoReveal(
                delay: const Duration(milliseconds: 170),
                child: _MenuItem(
                  icon: session.isDayStageMode
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                  title: '切换界面模式',
                  subtitle: session.isDayStageMode
                      ? '当前为日间模式，点击切回深夜模式'
                      : '当前为深夜模式，点击切到日间模式',
                  onTap: () async {
                    await session.toggleStageMode();
                    if (!context.mounted) return;
                    showDemoStageSnackBar(
                      context,
                      message: session.isDayStageMode ? '已切换到日间模式' : '已切换到深夜模式',
                      icon: session.isDayStageMode
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      accentColor: AppTheme.stageAccent,
                    );
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              DemoReveal(
                delay: const Duration(milliseconds: 200),
                child: _MenuItem(
                  icon: Icons.record_voice_over_outlined,
                  title: '自动朗读与触觉反馈',
                  subtitle: preferences.autoReadResults ? '自动朗读开启' : '自动朗读关闭',
                  onTap: () {
                    pushDemoStageRoute(context, page: const PreferenceScreen());
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacingXL),
              DemoReveal(
                delay: const Duration(milliseconds: 230),
                child: DemoSectionTitle(
                  title: '安全与记录',
                  subtitle: 'SOS 就绪度、联系人和帮助档案的统一入口。',
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              DemoReveal(
                delay: const Duration(milliseconds: 260),
                child: FutureBuilder<_SafetySnapshot>(
                  future: safetySnapshotFuture,
                  builder: (context, snapshot) {
                    final safety = snapshot.data;
                    return _SafetyReadinessCard(
                      title: safety == null
                          ? '正在读取 SOS 就绪状态'
                          : _buildSafetyTitle(safety),
                      summary: safety == null
                          ? '正在读取位置共享与联系人配置。'
                          : _buildSafetySummary(safety),
                      chips: safety == null
                          ? const ['读取中']
                          : [
                              safety.settings.locationModeLabel,
                              safety.contactCount == 0
                                  ? '联系人待补充'
                                  : '联系人 ${safety.contactCount} 位',
                              safety.settings.enableVoiceTrigger
                                  ? '语音提示开启'
                                  : '仅手动触发',
                            ],
                    );
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              _MenuItem(
                icon: Icons.history_rounded,
                title: '帮助档案与积分',
                subtitle: '最近已保存 $helpCount 条记录，进入求助者中心查看',
                onTap: () {
                  pushDemoStageRoute(context, page: const SeekerCenterScreen());
                },
              ),
              const SizedBox(height: AppTheme.spacingM),
              FutureBuilder<int>(
                future: EmergencyContactService().getContactCount(userId),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  final subtitle = count == 0
                      ? '尚未设置联系人，建议至少添加 1 位'
                      : '已设置 $count / 3 位联系人，SOS 时会自动通知';

                  return _MenuItem(
                    icon: Icons.contacts_outlined,
                    title: '紧急联系人',
                    subtitle: subtitle,
                    onTap: () async {
                      await pushDemoStageRoute(
                        context,
                        page: EmergencyContactsScreen(userId: userId),
                      );
                      _refreshSafetyState();
                    },
                  );
                },
              ),
              const SizedBox(height: AppTheme.spacingM),
              FutureBuilder<_SafetySnapshot>(
                future: safetySnapshotFuture,
                builder: (context, snapshot) {
                  return _MenuItem(
                    icon: Icons.location_on_outlined,
                    title: '位置共享',
                    subtitle: snapshot.hasData
                        ? _buildLocationSharingSummary(snapshot.data!)
                        : '配置 SOS 时的位置信息与通知范围',
                    onTap: () async {
                      await pushDemoStageRoute(
                        context,
                        page: LocationSharingScreen(userId: userId),
                      );
                      _refreshSafetyState();
                    },
                  );
                },
              ),
              const SizedBox(height: AppTheme.spacingXL),
              const DemoSectionTitle(
                title: '演示说明',
                subtitle: '只展示 MVP 主线，避免半成品功能干扰评审。',
              ),
              const SizedBox(height: AppTheme.spacingM),
              _MenuItem(
                icon: Icons.rocket_launch_outlined,
                title: '当前可演示功能',
                subtitle: '首页、AI、通话、SOS、我的与帮助档案已联通',
                onTap: () {
                  _showInfoSheet(
                    context,
                    title: '当前演示范围',
                    message:
                        '当前主前端已覆盖 onboarding、登录、首页求助入口、个人中心、帮助档案、无障碍偏好编辑和紧急联系人管理。真实认证、消息推送、SOS 通知链路和稳定实时通话仍属于后续工作。',
                  );
                },
              ),
              const SizedBox(height: AppTheme.spacingM),
              _MenuItem(
                icon: Icons.info_outline,
                title: '关于 LinkLab',
                subtitle: '版本 1.0.0 Demo',
                onTap: () {
                  _showInfoSheet(
                    context,
                    title: '关于 LinkLab',
                    message: '这是一个面向无障碍互助场景的主前端演示版，重点展示从登录到求助、再到个人档案沉淀的用户旅程。',
                  );
                },
              ),
              const SizedBox(height: AppTheme.spacingXL),
              AccessibleButton(
                label: '退出登录',
                semanticLabel: '退出当前账号',
                backgroundColor: AppTheme.stageSurfaceStrong,
                foregroundColor: AppTheme.stageDanger,
                onPressed: () {
                  _showLogoutDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _buildPreferenceSummary(AccessibilityPreferences preferences) {
    final contrast = preferences.highContrastMode ? '高对比度' : '标准显示';
    final autoRead = preferences.autoReadResults ? '自动朗读开启' : '自动朗读关闭';
    return '$contrast · 字体 ${preferences.fontScale.toStringAsFixed(1)}x · $autoRead';
  }

  Future<_SafetySnapshot> _loadSafetySnapshot(String userId) async {
    final count = await EmergencyContactService().getContactCount(userId);
    final settings = await SafetySettingsService().getSettings(userId);
    return _SafetySnapshot(contactCount: count, settings: settings);
  }

  String _buildSafetyTitle(_SafetySnapshot safety) {
    if (!safety.settings.autoShareLocation) {
      return 'SOS 位置共享未开启';
    }
    if (safety.contactCount == 0 &&
        safety.settings.shareWithEmergencyContacts) {
      return 'SOS 基础流程已就绪';
    }
    return 'SOS 演示链路已就绪';
  }

  String _buildSafetySummary(_SafetySnapshot safety) {
    if (!safety.settings.autoShareLocation) {
      return '当前触发 SOS 时不会自动附带位置，建议开启后再演示。';
    }
    if (safety.contactCount == 0 &&
        safety.settings.shareWithEmergencyContacts) {
      return '位置共享已开启，但联系人通知还没有实际接收对象。';
    }
    return '当前位置、联系人通知和志愿者广播的前端状态都可以完整展示。';
  }

  String _buildLocationSharingSummary(_SafetySnapshot safety) {
    if (!safety.settings.autoShareLocation) {
      return '自动位置共享已关闭，SOS 仅展示基础广播流程';
    }
    if (!safety.settings.shareWithEmergencyContacts) {
      return '已开启${safety.settings.usePreciseLocation ? '精确' : '大致'}位置，仅同步给志愿者广播';
    }
    if (safety.contactCount == 0) {
      return '位置共享已开启，联系人通知仍待补充';
    }
    return '已开启${safety.settings.usePreciseLocation ? '精确' : '大致'}位置，同步给 $safety.contactCount 位联系人';
  }

  void _showInfoSheet(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    showDemoStageBottomSheet<void>(
      context,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AccessibleText(
            title,
            style: TextStyle(
              color: AppTheme.stageTextPrimary,
              fontSize: AppTheme.fontSizeLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          AccessibleText(
            message,
            style: TextStyle(
              color: AppTheme.stageTextSecondary,
              fontSize: AppTheme.fontSizeNormal,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(sheetContext).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.stageAccent,
                foregroundColor: AppTheme.stageBackground,
              ),
              child: Text('知道了'),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDemoStageDialog<void>(
      context,
      builder: (dialogContext) => DemoDialog(
        title: '确认退出登录？',
        icon: Icons.logout_rounded,
        accentColor: AppTheme.stageDanger,
        description: '退出后将回到登录页，但本地无障碍偏好会保留。',
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
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
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await AppSessionService.instance.logout();
              if (!context.mounted) return;
              pushAndRemoveUntilDemoStageRoute(
                context,
                page: const LoginScreen(),
                predicate: (route) => false,
              );
            },
            child: Text('确认退出'),
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.user,
    required this.preferences,
    required this.onEditPreferences,
  });

  final UserModel? user;
  final AccessibilityPreferences preferences;
  final VoidCallback onEditPreferences;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: AppTheme.stagePanelGradient,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + 8),
        border: Border.all(color: AppTheme.stageBorder.withValues(alpha: 0.78)),
        boxShadow: AppTheme.stageShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              gradient: AppTheme.stageAccentGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline,
              size: 42,
              color: AppTheme.stageBackground,
            ),
          ),
          const SizedBox(width: AppTheme.spacingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccessibleText(
                  user?.displayName ?? '演示用户',
                  style: TextStyle(
                    color: AppTheme.stageTextPrimary,
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                AccessibleText(
                  user?.phone.maskedPhone ?? '未绑定手机号',
                  style: TextStyle(
                    color: AppTheme.stageTextSecondary,
                    fontSize: AppTheme.fontSizeNormal,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                AccessibleText(
                  '${_buildRoleText(user)} · ${_buildDisabilityText(user)}',
                  style: TextStyle(
                    color: AppTheme.stageTextSecondary,
                    fontSize: AppTheme.fontSizeSmall,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                DemoPill(
                  icon: Icons.auto_awesome_outlined,
                  label: preferences.autoReadResults ? '自动朗读开启' : '自动朗读关闭',
                  color: AppTheme.stageSuccess,
                ),
              ],
            ),
          ),
          AccessibleIconButton(
            icon: Icons.tune_rounded,
            semanticLabel: '编辑无障碍偏好',
            backgroundColor: AppTheme.stageSurfaceStrong,
            iconColor: AppTheme.stageTextPrimary,
            onPressed: onEditPreferences,
          ),
        ],
      ),
    );
  }

  String _buildRoleText(UserModel? user) {
    if (user == null) return '演示账号';
    if (user.isSeeker && user.isVolunteer) return '求助者 / 志愿者';
    if (user.isVolunteer) return '志愿者';
    return '求助者';
  }

  String _buildDisabilityText(UserModel? user) {
    if (user == null || user.disabilityType.isEmpty) return '未填写障碍类型';

    const labels = {
      'visual': '视力障碍',
      'hearing': '听力障碍',
      'physical': '肢体障碍',
      'elderly': '老年用户',
      'temporary': '临时需要帮助',
    };

    return user.disabilityType.map((type) => labels[type] ?? type).join(' / ');
  }
}

class _SafetySnapshot {
  const _SafetySnapshot({required this.contactCount, required this.settings});

  final int contactCount;
  final SafetySettings settings;
}

class _ProfileTag extends StatelessWidget {
  const _ProfileTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DemoPill(icon: icon, label: label, color: AppTheme.stageInfo);
  }
}

class _SafetyReadinessCard extends StatelessWidget {
  const _SafetyReadinessCard({
    required this.title,
    required this.summary,
    required this.chips,
  });

  final String title;
  final String summary;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    return DemoSurfaceCard(
      color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: AppTheme.stageAccent),
              SizedBox(width: AppTheme.spacingS),
              AccessibleText(
                '安全就绪度',
                style: TextStyle(
                  color: AppTheme.stageTextPrimary,
                  fontSize: AppTheme.fontSizeNormal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          AccessibleText(
            title,
            style: TextStyle(
              color: AppTheme.stageTextPrimary,
              fontSize: AppTheme.fontSizeLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          AccessibleText(
            summary,
            style: TextStyle(
              color: AppTheme.stageTextSecondary,
              fontSize: AppTheme.fontSizeSmall,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Wrap(
            spacing: AppTheme.spacingS,
            runSpacing: AppTheme.spacingS,
            children: chips
                .map(
                  (item) => DemoPill(
                    icon: Icons.check_circle_outline,
                    label: item,
                    color: AppTheme.stageAccent,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DemoSurfaceCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.stageAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppTheme.stageAccent),
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
          const SizedBox(width: AppTheme.spacingS),
          Icon(Icons.arrow_forward_rounded, color: AppTheme.stageTextPrimary),
        ],
      ),
    );
  }
}
