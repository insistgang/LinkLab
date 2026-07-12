import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/extensions.dart';
import '../../models/user_model.dart';
import '../../providers/app_session_provider.dart';
import '../../services/security/emergency_contact_service.dart';
import '../../services/security/safety_settings_service.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_motion.dart';
import '../../widgets/demo/demo_overlays.dart';
import '../../widgets/demo/demo_routes.dart';
import '../../widgets/demo/demo_stage.dart';
import '../../widgets/demo/linkable_icon.dart';
import '../auth/login_screen.dart';
import '../auth/preference_screen.dart';
import '../demo/demo_help_archive_screen.dart';
import '../security/emergency_contacts_screen.dart';
import '../security/location_sharing_screen.dart';

enum ProfileScreenMode { seeker, volunteer }

/// 个人中心页面
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.mode = ProfileScreenMode.seeker});

  final ProfileScreenMode mode;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  void _refreshSafetyState() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(appSessionProvider);
    final user = session.userProfile;
    final preferences = session.preferences;
    final helpCount = session.getRecentHelpHistory(limit: 20).length;
    final userId = user?.id ?? 'demo-seeker';
    final safetySnapshotFuture = _loadSafetySnapshot(userId);
    final isVolunteerMode = widget.mode == ProfileScreenMode.volunteer;
    final mediaQuery = MediaQuery.of(context);
    final compactLayout =
        mediaQuery.size.width < 430 || mediaQuery.textScaler.scale(1) > 1.15;

    return DemoStageScaffold(
      title: '我的',
      subtitle: isVolunteerMode
          ? (compactLayout ? '志愿者资料与接单准备' : '志愿者资料、接单准备和服务记录都在这里收口')
          : (compactLayout ? '登录、偏好与安全准备' : '登录、偏好、安全准备和帮助档案都在这里收口'),
      showBackButton: false,
      showStatusStrip: false,
      showThemeModeButton: false,
      headerTopPadding: AppTheme.spacingXS,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          compactLayout ? AppTheme.spacingM : AppTheme.spacingL,
          AppTheme.spacingS,
          compactLayout ? AppTheme.spacingM : AppTheme.spacingL,
          compactLayout ? 96 : 120,
        ),
        children: [
          DemoReveal(
            child: _ProfileHero(
              user: user,
              preferences: preferences,
              mode: widget.mode,
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
                  icon: isVolunteerMode
                      ? Icons.volunteer_activism_outlined
                      : Icons.accessibility_new_outlined,
                  label: isVolunteerMode ? '志愿者模式' : '求助者模式',
                ),
                _ProfileTag(
                  icon: session.isDayStageMode
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  label: session.isDayStageMode ? '荧光日间' : '深夜模式',
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
          const DemoReveal(
            delay: Duration(milliseconds: 110),
            child: DemoSectionTitle(
              title: '无障碍设置',
              subtitle: '在这里调整显示、朗读和操作方式。',
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          DemoReveal(
            delay: const Duration(milliseconds: 140),
            child: _MenuItem(
              icon: LinkableIconName.settings,
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
                  ? LinkableIconName.darkMode
                  : LinkableIconName.lightMode,
              title: '切换界面模式',
              subtitle: session.isDayStageMode
                  ? '当前使用荧光日间模式，点击切换为深夜模式'
                  : '当前使用深夜模式，点击切换为荧光日间模式',
              onTap: () async {
                await ref.read(appSessionProvider.notifier).toggleStageMode();
                if (!context.mounted) return;
                final updatedSession = ref.read(appSessionProvider);
                showDemoStageSnackBar(
                  context,
                  message: updatedSession.isDayStageMode
                      ? '已切换到荧光日间风格'
                      : '已切换到深夜模式',
                  icon: updatedSession.isDayStageMode
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
              icon: LinkableIconName.tts,
              secondaryIcon: LinkableIconName.haptic,
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
              title: isVolunteerMode ? '接单与记录' : '安全与记录',
              subtitle: isVolunteerMode
                  ? '管理接单准备与服务记录。'
                  : 'SOS 就绪度、联系人和帮助档案的统一入口。',
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          DemoReveal(
            delay: const Duration(milliseconds: 260),
            child: isVolunteerMode
                ? _VolunteerReadinessCard(helpCount: helpCount)
                : FutureBuilder<_SafetySnapshot>(
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
            icon: LinkableIconName.helpHistory,
            title: isVolunteerMode ? '服务记录' : '帮助档案',
            subtitle: isVolunteerMode
                ? '已保存 $helpCount 条协助记录'
                : '最近已保存 $helpCount 条求助记录，进入帮助档案查看',
            onTap: () {
              pushDemoStageRoute(context, page: const DemoHelpArchiveScreen());
            },
          ),
          const SizedBox(height: AppTheme.spacingM),
          FutureBuilder<int>(
            future: EmergencyContactService().getContactCount(userId),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              final subtitle = count == 0
                  ? '尚未设置联系人，建议至少添加 1 位'
                  : '已设置 $count / 3 位紧急联系人';

              return _MenuItem(
                icon: LinkableIconName.emergencyContact,
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
                icon: LinkableIconName.locationShare,
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
          const DemoSectionTitle(title: '关于与服务', subtitle: '查看当前服务状态与版本信息。'),
          const SizedBox(height: AppTheme.spacingM),
          _MenuItem(
            icon: LinkableIconName.needHelp,
            title: '服务状态',
            subtitle: isVolunteerMode
                ? '待帮助、接单、通话与服务记录可用'
                : 'AI 助手、通话体验、SOS 设置与帮助档案可用',
            onTap: () {
              _showInfoSheet(
                context,
                title: '服务状态',
                message: isVolunteerMode
                    ? '待帮助、接单、通话体验和服务记录可使用；在线排班、消息推送与专业认证尚未接入。'
                    : '首页求助、AI 助手、通话体验、SOS 设置与帮助档案可使用；真实短信、消息推送和外部紧急通知尚未接入。',
              );
            },
          ),
          const SizedBox(height: AppTheme.spacingM),
          _MenuItem(
            icon: LinkableIconName.help,
            title: '关于 LinkAble',
            subtitle: '版本 ${AppConstants.appVersion}',
            onTap: () {
              _showInfoSheet(
                context,
                title: '关于 LinkAble',
                message: isVolunteerMode
                    ? 'LinkAble 是面向无障碍互助场景的 AI 与真人协作应用，帮助志愿者查看需求、提供协助并保存服务记录。'
                    : 'LinkAble 是面向无障碍互助场景的 AI 与真人协作应用，先用 AI 处理常见问题，需要时再连接真人志愿者。',
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
      return 'SOS 联系人待添加';
    }
    return 'SOS 安全设置已完成';
  }

  String _buildSafetySummary(_SafetySnapshot safety) {
    if (!safety.settings.autoShareLocation) {
      return '触发 SOS 时不会自动附带位置，可在“位置共享”中开启。';
    }
    if (safety.contactCount == 0 &&
        safety.settings.shareWithEmergencyContacts) {
      return '位置共享已开启；添加紧急联系人后可完善求助信息。';
    }
    return '位置共享与联系人信息已配置，可随时启动求助。';
  }

  String _buildLocationSharingSummary(_SafetySnapshot safety) {
    if (!safety.settings.autoShareLocation) {
      return '自动位置共享已关闭';
    }
    if (!safety.settings.shareWithEmergencyContacts) {
      return '已开启${safety.settings.usePreciseLocation ? '精确' : '大致'}位置，用于查找附近志愿者';
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
              child: const Text('知道了'),
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
              await ref.read(appSessionProvider.notifier).logout();
              if (!context.mounted) return;
              pushAndRemoveUntilDemoStageRoute(
                context,
                page: const LoginScreen(),
                predicate: (route) => false,
              );
            },
            child: const Text('确认退出'),
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
    required this.mode,
    required this.onEditPreferences,
  });

  final UserModel? user;
  final AccessibilityPreferences preferences;
  final ProfileScreenMode mode;
  final VoidCallback onEditPreferences;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final compactLayout =
        mediaQuery.size.width < 430 || mediaQuery.textScaler.scale(1) > 1.15;
    return Container(
      padding: EdgeInsets.all(
        compactLayout ? AppTheme.spacingM : AppTheme.spacingL,
      ),
      decoration: BoxDecoration(
        gradient: AppTheme.stagePanelGradient,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + 8),
        border: Border.all(color: AppTheme.stageBorder.withValues(alpha: 0.78)),
        boxShadow: AppTheme.stageShadow,
      ),
      child: Row(
        children: [
          _ProfileIdentityAvatar(user: user, mode: mode),
          SizedBox(
            width: compactLayout ? AppTheme.spacingM : AppTheme.spacingL,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccessibleText(
                  user?.displayName ?? 'LinkAble 用户',
                  style: TextStyle(
                    color: AppTheme.stageTextPrimary,
                    fontSize: compactLayout
                        ? AppTheme.fontSizeNormal
                        : AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                AccessibleText(
                  user?.phone.maskedPhone ?? '未绑定手机号',
                  style: TextStyle(
                    color: AppTheme.stageTextSecondary,
                    fontSize: compactLayout
                        ? AppTheme.fontSizeSmall
                        : AppTheme.fontSizeNormal,
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
                  color: AppTheme.stageAccentLight,
                ),
              ],
            ),
          ),
          AccessibleIconButton(
            icon: Icons.tune_rounded,
            semanticLabel: '编辑无障碍偏好',
            backgroundColor: AppTheme.stageSurfaceStrong,
            iconColor: AppTheme.stageTextPrimary,
            size: AppTheme.minTouchTarget,
            iconSize: compactLayout
                ? AppTheme.fontSizeNormal
                : AppTheme.fontSizeLarge,
            onPressed: onEditPreferences,
          ),
        ],
      ),
    );
  }

  String _buildRoleText(UserModel? user) {
    if (mode == ProfileScreenMode.volunteer) return '志愿者';
    if (user == null) return '用户';
    if (user.isSeeker && user.isVolunteer) return '求助者 / 志愿者';
    if (user.isVolunteer) return '志愿者';
    return '求助者';
  }

  String _buildDisabilityText(UserModel? user) {
    if (mode == ProfileScreenMode.volunteer) {
      return '视障协助 / 医院导诊 / 听障转译';
    }

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

class _ProfileIdentityAvatar extends StatelessWidget {
  const _ProfileIdentityAvatar({required this.user, required this.mode});

  final UserModel? user;
  final ProfileScreenMode mode;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final compactLayout =
        mediaQuery.size.width < 430 || mediaQuery.textScaler.scale(1) > 1.15;
    final avatarSize = compactLayout ? 78.0 : 96.0;
    final outerRadius = compactLayout ? 22.0 : 28.0;
    final innerRadius = compactLayout ? 19.0 : 24.0;
    final displayName = user?.displayName.trim();
    final initials = _buildInitials(displayName);
    final roleLabel = _buildRoleBadge(user);

    return Semantics(
      image: true,
      label:
          '个人头像，$roleLabel，名称 ${displayName?.isNotEmpty == true ? displayName : 'LinkAble 用户'}',
      child: ExcludeSemantics(
        child: SizedBox(
          width: avatarSize,
          height: avatarSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(outerRadius),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.72),
                        AppTheme.stageSurfaceStrong.withValues(alpha: 0.92),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: AppTheme.stageAccent.withValues(alpha: 0.64),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.stageAccent.withValues(alpha: 0.18),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(compactLayout ? 7 : 9),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(innerRadius),
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.stageAccent,
                          AppTheme.stageAccentLight,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            initials,
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: compactLayout ? 28 : 34,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: compactLayout ? 10 : 13,
                top: compactLayout ? 10 : 13,
                child: Container(
                  width: compactLayout ? 14 : 16,
                  height: compactLayout ? 14 : 16,
                  decoration: BoxDecoration(
                    color: AppTheme.stageAccentLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  constraints: BoxConstraints(
                    minWidth: compactLayout ? 38 : 42,
                    minHeight: compactLayout ? 30 : 34,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: compactLayout ? 8 : 10,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.stageAccent,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.72),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      roleLabel,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: AppTheme.fontSizeXSmall,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildInitials(String? displayName) {
    final name = displayName?.trim();
    if (name == null || name.isEmpty) {
      return 'LA';
    }

    final first = name.characters.first;
    if (RegExp(r'[A-Za-z]').hasMatch(first)) {
      return first.toUpperCase();
    }
    return first;
  }

  String _buildRoleBadge(UserModel? user) {
    if (mode == ProfileScreenMode.volunteer) return '志愿者';
    if (user == null) return '用户';
    if (user.isSeeker && user.isVolunteer) return '互助';
    if (user.isVolunteer) return '志愿者';
    return '求助者';
  }
}

class _SafetySnapshot {
  const _SafetySnapshot({required this.contactCount, required this.settings});

  final int contactCount;
  final SafetySettings settings;
}

class _VolunteerReadinessCard extends StatelessWidget {
  const _VolunteerReadinessCard({required this.helpCount});

  final int helpCount;

  @override
  Widget build(BuildContext context) {
    return DemoSurfaceCard(
      color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const LinkableSvgIcon(
                icon: LinkableIconName.volunteerRole,
                size: 24,
                semanticLabel: '志愿者接单准备',
              ),
              const SizedBox(width: AppTheme.spacingS),
              AccessibleText(
                '志愿者资料',
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
            '志愿者模式已就绪',
            style: TextStyle(
              color: AppTheme.stageTextPrimary,
              fontSize: AppTheme.fontSizeLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          AccessibleText(
            '可以从待帮助列表查看需求、接单并完成语音协助；服务结束后会自动保存记录。',
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
            children: [
              DemoPill(
                icon: Icons.radio_button_checked,
                label: '准备接单',
                color: AppTheme.stageAccentLight,
              ),
              DemoPill(
                icon: Icons.verified_user_outlined,
                label: '技能已配置',
                color: AppTheme.stageAccentLight,
              ),
              DemoPill(
                icon: Icons.history_outlined,
                label: '记录 $helpCount 条',
                color: AppTheme.stageAccentLight,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileTag extends StatelessWidget {
  const _ProfileTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DemoPill(icon: icon, label: label, color: AppTheme.stageAccentLight);
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
              const LinkableSvgIcon(
                icon: LinkableIconName.safetyReady,
                size: 24,
                semanticLabel: '安全就绪度',
              ),
              const SizedBox(width: AppTheme.spacingS),
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
                    color: AppTheme.stageAccentLight,
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
    this.secondaryIcon,
  });

  final LinkableIconName icon;
  final LinkableIconName? secondaryIcon;
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
            child: _MenuItemIcon(
              icon: icon,
              secondaryIcon: secondaryIcon,
              title: title,
            ),
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
          LinkableSvgIcon(
            icon: LinkableIconName.navigationGuide,
            size: 24,
            semanticLabel: '进入$title',
          ),
        ],
      ),
    );
  }
}

class _MenuItemIcon extends StatelessWidget {
  const _MenuItemIcon({
    required this.icon,
    required this.title,
    this.secondaryIcon,
  });

  final LinkableIconName icon;
  final LinkableIconName? secondaryIcon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final secondary = secondaryIcon;
    if (secondary == null) {
      return LinkableSvgIcon(icon: icon, size: 24, semanticLabel: title);
    }

    return ExcludeSemantics(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 9,
            bottom: 10,
            child: LinkableSvgIcon(icon: icon, size: 25),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.88),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.stageAccent.withValues(alpha: 0.28),
                ),
              ),
              child: Center(child: LinkableSvgIcon(icon: secondary, size: 18)),
            ),
          ),
        ],
      ),
    );
  }
}
