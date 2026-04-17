import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/extensions.dart';
import '../../models/user_model.dart';
import '../../services/app_session_service.dart';
import '../../services/security/emergency_contact_service.dart';
import '../../services/security/safety_settings_service.dart';
import '../../widgets/accessible/index.dart';
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

        return AccessibleScaffold(
          title: '我的',
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    label: '用户信息',
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingL),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryLight,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusLarge,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppTheme.textOnPrimary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.textOnPrimary,
                                width: 3,
                              ),
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 48,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingL),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AccessibleText(
                                  user?.displayName ?? '演示用户',
                                  style: const TextStyle(
                                    fontSize: AppTheme.fontSizeLarge,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textOnPrimary,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacingXS),
                                AccessibleText(
                                  user?.phone.maskedPhone ?? '未绑定手机号',
                                  style: const TextStyle(
                                    fontSize: AppTheme.fontSizeNormal,
                                    color: AppTheme.textOnPrimary,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacingXS),
                                AccessibleText(
                                  '${_buildRoleText(user)} · ${_buildDisabilityText(user)}',
                                  style: const TextStyle(
                                    fontSize: AppTheme.fontSizeNormal,
                                    color: AppTheme.textOnPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const PreferenceScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.tune,
                              color: AppTheme.textOnPrimary,
                            ),
                            tooltip: '编辑无障碍偏好',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  Wrap(
                    spacing: AppTheme.spacingS,
                    runSpacing: AppTheme.spacingS,
                    children: [
                      _ProfileTag(
                        icon: Icons.contrast,
                        label: preferences.highContrastMode ? '高对比度' : '标准显示',
                      ),
                      _ProfileTag(
                        icon: Icons.text_fields,
                        label:
                            '字体 ${preferences.fontScale.toStringAsFixed(1)}x',
                      ),
                      _ProfileTag(
                        icon: Icons.volume_up,
                        label:
                            '语速 ${preferences.voiceSpeed.toStringAsFixed(1)}x',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingXL),
                  const AccessibleText(
                    '无障碍设置',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  _MenuItem(
                    icon: Icons.settings_accessibility,
                    title: '编辑无障碍偏好',
                    subtitle: _buildPreferenceSummary(preferences),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PreferenceScreen(),
                        ),
                      );
                    },
                  ),
                  _MenuItem(
                    icon: Icons.auto_awesome,
                    title: '自动朗读与触觉反馈',
                    subtitle: preferences.autoReadResults ? '自动朗读开启' : '自动朗读关闭',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PreferenceScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  const SizedBox(height: AppTheme.spacingM),
                  const AccessibleText(
                    '安全与记录',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  FutureBuilder<_SafetySnapshot>(
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
                  const SizedBox(height: AppTheme.spacingM),
                  _MenuItem(
                    icon: Icons.history,
                    title: '帮助档案与积分',
                    subtitle: '最近已保存 $helpCount 条记录，进入求助者中心查看',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SeekerCenterScreen(),
                        ),
                      );
                    },
                  ),
                  FutureBuilder<int>(
                    future: EmergencyContactService().getContactCount(userId),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      final subtitle = count == 0
                          ? '尚未设置联系人，建议至少添加 1 位'
                          : '已设置 $count / 3 位联系人，SOS 时会自动通知';

                      return _MenuItem(
                        icon: Icons.contacts,
                        title: '紧急联系人',
                        subtitle: subtitle,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  EmergencyContactsScreen(userId: userId),
                            ),
                          );
                          _refreshSafetyState();
                        },
                      );
                    },
                  ),
                  FutureBuilder<_SafetySnapshot>(
                    future: safetySnapshotFuture,
                    builder: (context, snapshot) {
                      return _MenuItem(
                        icon: Icons.location_on,
                        title: '位置共享',
                        subtitle: snapshot.hasData
                            ? _buildLocationSharingSummary(snapshot.data!)
                            : '配置 SOS 时的位置信息与通知范围',
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  LocationSharingScreen(userId: userId),
                            ),
                          );
                          _refreshSafetyState();
                        },
                      );
                    },
                  ),
                  const Divider(),
                  const SizedBox(height: AppTheme.spacingM),
                  const AccessibleText(
                    '演示说明',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  _MenuItem(
                    icon: Icons.help,
                    title: '当前可演示功能',
                    subtitle: '首页、社群精选、我的、帮助档案已联通',
                    onTap: () {
                      _showInfoSheet(
                        context,
                        title: '当前演示范围',
                        message:
                            '当前主前端已覆盖 onboarding、登录、首页求助入口、精选故事、个人中心、帮助档案、无障碍偏好编辑和紧急联系人管理。真实认证、消息推送、SOS 通知链路和稳定实时通话仍属于后续工作。',
                      );
                    },
                  ),
                  _MenuItem(
                    icon: Icons.info,
                    title: '关于 LinkLab',
                    subtitle: '版本 1.0.0 Demo',
                    onTap: () {
                      _showInfoSheet(
                        context,
                        title: '关于 LinkLab',
                        message:
                            '这是一个面向无障碍互助场景的主前端演示版，重点展示从登录到求助、再到个人档案沉淀的用户旅程。',
                      );
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingXL),
                  AccessibleButton(
                    label: '退出登录',
                    semanticLabel: '退出当前账号',
                    backgroundColor: AppTheme.surfaceColor,
                    foregroundColor: AppTheme.emergencyColor,
                    onPressed: () {
                      _showLogoutDialog(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AccessibleText(
              title,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            AccessibleText(
              message,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeNormal,
                height: 1.6,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const AccessibleText('知道了'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const AccessibleText(
          '确认退出登录？',
          style: TextStyle(
            fontSize: AppTheme.fontSizeXLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const AccessibleText(
          '退出后将回到登录页，但本地无障碍偏好会保留。',
          style: TextStyle(fontSize: AppTheme.fontSizeNormal),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const AccessibleText('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emergencyColor,
              foregroundColor: AppTheme.textOnPrimary,
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await AppSessionService.instance.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const AccessibleText('确认退出'),
          ),
        ],
      ),
    );
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: AppTheme.spacingXS),
          AccessibleText(
            label,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppTheme.primaryColor),
              SizedBox(width: AppTheme.spacingS),
              AccessibleText(
                '安全就绪度',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeNormal,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          AccessibleText(
            title,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          AccessibleText(
            summary,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Wrap(
            spacing: AppTheme.spacingS,
            runSpacing: AppTheme.spacingS,
            children: chips
                .map(
                  (item) => _ProfileTag(
                    icon: Icons.check_circle_outline,
                    label: item,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// 菜单项
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
    return AccessibleListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: AccessibleText(
        title,
        style: const TextStyle(
          fontSize: AppTheme.fontSizeNormal,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: AccessibleText(
        subtitle,
        style: const TextStyle(
          fontSize: AppTheme.fontSizeSmall,
          color: AppTheme.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: AppTheme.textHint,
        size: AppTheme.fontSizeNormal,
      ),
      onTap: onTap,
    );
  }
}
