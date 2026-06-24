import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// 個人中心頁面
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
          ? (compactLayout ? '志願者資料與接單準備' : '志願者資料、接單準備和服務記錄都在這裏收口')
          : (compactLayout ? '登錄、偏好與安全準備' : '登錄、偏好、安全準備和幫助檔案都在這裏收口'),
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
                  label: isVolunteerMode ? '志願者模式' : '求助者模式',
                ),
                _ProfileTag(
                  icon: session.isDayStageMode
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  label: session.isDayStageMode ? '熒光日間' : '深夜模式',
                ),
                _ProfileTag(
                  icon: Icons.contrast_outlined,
                  label: preferences.highContrastMode ? '高對比度' : '標準顯示',
                ),
                _ProfileTag(
                  icon: Icons.text_fields_outlined,
                  label: '字體 ${preferences.fontScale.toStringAsFixed(1)}x',
                ),
                _ProfileTag(
                  icon: Icons.volume_up_outlined,
                  label: '語速 ${preferences.voiceSpeed.toStringAsFixed(1)}x',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingXL),
          const DemoReveal(
            delay: Duration(milliseconds: 110),
            child: DemoSectionTitle(
              title: '無障礙設置',
              subtitle: 'F33 與 F36 的關鍵偏好都收口在這裏。',
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          DemoReveal(
            delay: const Duration(milliseconds: 140),
            child: _MenuItem(
              icon: LinkableIconName.settings,
              title: '編輯無障礙偏好',
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
              title: '切換界面模式',
              subtitle: session.isDayStageMode
                  ? '當前爲頁面稿的熒光日間風格，點擊切回深夜模式'
                  : '當前爲深夜模式，點擊切到熒光日間風格',
              onTap: () async {
                await ref.read(appSessionProvider.notifier).toggleStageMode();
                if (!context.mounted) return;
                final updatedSession = ref.read(appSessionProvider);
                showDemoStageSnackBar(
                  context,
                  message: updatedSession.isDayStageMode
                      ? '已切換到熒光日間風格'
                      : '已切換到深夜模式',
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
              title: '自動朗讀與觸覺反饋',
              subtitle: preferences.autoReadResults ? '自動朗讀開啓' : '自動朗讀關閉',
              onTap: () {
                pushDemoStageRoute(context, page: const PreferenceScreen());
              },
            ),
          ),
          const SizedBox(height: AppTheme.spacingXL),
          DemoReveal(
            delay: const Duration(milliseconds: 230),
            child: DemoSectionTitle(
              title: isVolunteerMode ? '接單與記錄' : '安全與記錄',
              subtitle: isVolunteerMode
                  ? '志願者接單準備、服務記錄和演示狀態的統一入口。'
                  : 'SOS 就緒度、聯繫人和幫助檔案的統一入口。',
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
                            ? '正在讀取 SOS 就緒狀態'
                            : _buildSafetyTitle(safety),
                        summary: safety == null
                            ? '正在讀取位置共享與聯繫人配置。'
                            : _buildSafetySummary(safety),
                        chips: safety == null
                            ? const ['讀取中']
                            : [
                                safety.settings.locationModeLabel,
                                safety.contactCount == 0
                                    ? '聯繫人待補充'
                                    : '聯繫人 ${safety.contactCount} 位',
                                safety.settings.enableVoiceTrigger
                                    ? '語音提示開啓'
                                    : '僅手動觸發',
                              ],
                      );
                    },
                  ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          _MenuItem(
            icon: LinkableIconName.helpHistory,
            title: isVolunteerMode ? '服務記錄' : '幫助檔案',
            subtitle: isVolunteerMode
                ? '已沉澱 $helpCount 條演示協助記錄，展示志願者服務閉環'
                : '最近已保存 $helpCount 條主線記錄，進入幫助檔案查看',
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
                  ? '尚未設置聯繫人，建議至少添加 1 位'
                  : '已設置 $count / 3 位聯繫人，SOS 時會自動通知';

              return _MenuItem(
                icon: LinkableIconName.emergencyContact,
                title: '緊急聯繫人',
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
                    : '配置 SOS 時的位置信息與通知範圍',
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
            title: '演示說明',
            subtitle: '只展示 MVP 主線，避免半成品功能幹擾評審。',
          ),
          const SizedBox(height: AppTheme.spacingM),
          _MenuItem(
            icon: LinkableIconName.needHelp,
            title: '當前可演示功能',
            subtitle: isVolunteerMode
                ? '待幫助、接單、通話和志願者我的頁已聯通'
                : '首頁、AI、通話、SOS、我的與幫助檔案已聯通',
            onTap: () {
              _showInfoSheet(
                context,
                title: '當前演示範圍',
                message: isVolunteerMode
                    ? '志願者側已覆蓋待幫助列表、演示接單、Demo 通話和志願者身份展示。真實在線狀態、排班、推送和專業認證仍屬於後續工作。'
                    : '當前主前端已覆蓋 onboarding、登錄、首頁求助入口、個人中心、幫助檔案、無障礙偏好編輯和緊急聯繫人管理。真實認證、消息推送、SOS 通知鏈路和穩定實時通話仍屬於後續工作。',
              );
            },
          ),
          const SizedBox(height: AppTheme.spacingM),
          _MenuItem(
            icon: LinkableIconName.help,
            title: '關於 LinkLab',
            subtitle: '版本 1.0.0 Demo',
            onTap: () {
              _showInfoSheet(
                context,
                title: '關於 LinkLab',
                message: isVolunteerMode
                    ? '這是一個面向無障礙互助場景的志願者側演示版，重點展示從待幫助列表到接單、通話和服務記錄沉澱的流程。'
                    : '這是一個面向無障礙互助場景的主前端演示版，重點展示從登錄到求助、再到個人檔案沉澱的用戶旅程。',
              );
            },
          ),
          const SizedBox(height: AppTheme.spacingXL),
          AccessibleButton(
            label: '退出登錄',
            semanticLabel: '退出當前賬號',
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
    final contrast = preferences.highContrastMode ? '高對比度' : '標準顯示';
    final autoRead = preferences.autoReadResults ? '自動朗讀開啓' : '自動朗讀關閉';
    return '$contrast · 字體 ${preferences.fontScale.toStringAsFixed(1)}x · $autoRead';
  }

  Future<_SafetySnapshot> _loadSafetySnapshot(String userId) async {
    final count = await EmergencyContactService().getContactCount(userId);
    final settings = await SafetySettingsService().getSettings(userId);
    return _SafetySnapshot(contactCount: count, settings: settings);
  }

  String _buildSafetyTitle(_SafetySnapshot safety) {
    if (!safety.settings.autoShareLocation) {
      return 'SOS 位置共享未開啓';
    }
    if (safety.contactCount == 0 &&
        safety.settings.shareWithEmergencyContacts) {
      return 'SOS 基礎流程已就緒';
    }
    return 'SOS 演示鏈路已就緒';
  }

  String _buildSafetySummary(_SafetySnapshot safety) {
    if (!safety.settings.autoShareLocation) {
      return '當前觸發 SOS 時不會自動附帶位置，建議開啓後再演示。';
    }
    if (safety.contactCount == 0 &&
        safety.settings.shareWithEmergencyContacts) {
      return '位置共享已開啓，但聯繫人通知還沒有實際接收對象。';
    }
    return '當前位置、聯繫人通知和志願者廣播的前端狀態都可以完整展示。';
  }

  String _buildLocationSharingSummary(_SafetySnapshot safety) {
    if (!safety.settings.autoShareLocation) {
      return '自動位置共享已關閉，SOS 僅展示基礎廣播流程';
    }
    if (!safety.settings.shareWithEmergencyContacts) {
      return '已開啓${safety.settings.usePreciseLocation ? '精確' : '大致'}位置，僅同步給志願者廣播';
    }
    if (safety.contactCount == 0) {
      return '位置共享已開啓，聯繫人通知仍待補充';
    }
    return '已開啓${safety.settings.usePreciseLocation ? '精確' : '大致'}位置，同步給 $safety.contactCount 位聯繫人';
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
        title: '確認退出登錄？',
        icon: Icons.logout_rounded,
        accentColor: AppTheme.stageDanger,
        description: '退出後將回到登錄頁，但本地無障礙偏好會保留。',
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
            child: const Text('確認退出'),
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
                  user?.displayName ?? '演示用戶',
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
                  user?.phone.maskedPhone ?? '未綁定手機號',
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
                  label: preferences.autoReadResults ? '自動朗讀開啓' : '自動朗讀關閉',
                  color: AppTheme.stageAccentLight,
                ),
              ],
            ),
          ),
          AccessibleIconButton(
            icon: Icons.tune_rounded,
            semanticLabel: '編輯無障礙偏好',
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
    if (mode == ProfileScreenMode.volunteer) return '志願者';
    if (user == null) return '演示賬號';
    if (user.isSeeker && user.isVolunteer) return '求助者 / 志願者';
    if (user.isVolunteer) return '志願者';
    return '求助者';
  }

  String _buildDisabilityText(UserModel? user) {
    if (mode == ProfileScreenMode.volunteer) {
      return '視障協助 / 醫院導診 / 聽障轉譯';
    }

    if (user == null || user.disabilityType.isEmpty) return '未填寫障礙類型';

    const labels = {
      'visual': '視力障礙',
      'hearing': '聽力障礙',
      'physical': '肢體障礙',
      'elderly': '老年用戶',
      'temporary': '臨時需要幫助',
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
          '個人頭像，$roleLabel，名稱 ${displayName?.isNotEmpty == true ? displayName : '演示用戶'}',
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
    if (mode == ProfileScreenMode.volunteer) return '志願者';
    if (user == null) return 'Demo';
    if (user.isSeeker && user.isVolunteer) return '互助';
    if (user.isVolunteer) return '志願者';
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
                semanticLabel: '志願者接單準備',
              ),
              const SizedBox(width: AppTheme.spacingS),
              AccessibleText(
                '志願者資料',
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
            '志願者模式已就緒',
            style: TextStyle(
              color: AppTheme.stageTextPrimary,
              fontSize: AppTheme.fontSizeLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          AccessibleText(
            '你現在看到的是志願者側「我的」。演示中可以從待幫助列表接單，進入 Demo 語音協助，再沉澱服務記錄。',
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
                label: '在線演示',
                color: AppTheme.stageAccentLight,
              ),
              DemoPill(
                icon: Icons.verified_user_outlined,
                label: '技能已配置',
                color: AppTheme.stageAccentLight,
              ),
              DemoPill(
                icon: Icons.history_outlined,
                label: '記錄 $helpCount 條',
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
                semanticLabel: '安全就緒度',
              ),
              const SizedBox(width: AppTheme.spacingS),
              AccessibleText(
                '安全就緒度',
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
            semanticLabel: '進入$title',
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
