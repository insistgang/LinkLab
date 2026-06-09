import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/security/emergency_contact_service.dart';
import '../../services/security/safety_settings_service.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_overlays.dart';
import '../../widgets/demo/demo_routes.dart';
import '../../widgets/demo/demo_stage.dart';
import '../../widgets/demo/linkable_icon.dart';
import 'emergency_contacts_screen.dart';

class LocationSharingScreen extends StatefulWidget {
  const LocationSharingScreen({super.key, required this.userId});

  final String userId;

  @override
  State<LocationSharingScreen> createState() => _LocationSharingScreenState();
}

class _LocationSharingScreenState extends State<LocationSharingScreen> {
  final SafetySettingsService _settingsService = SafetySettingsService();
  final EmergencyContactService _contactService = EmergencyContactService();

  SafetySettings _settings = const SafetySettings();
  int _contactCount = 0;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait<dynamic>([
      _settingsService.getSettings(widget.userId),
      _contactService.getContactCount(widget.userId),
    ]);

    if (!mounted) return;
    setState(() {
      _settings = results[0] as SafetySettings;
      _contactCount = results[1] as int;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      final saved = await _settingsService.saveSettings(
        widget.userId,
        _settings,
      );
      if (!mounted) return;
      setState(() => _settings = saved);
      showDemoStageSnackBar(
        context,
        message: '位置共享設置已保存',
        icon: Icons.check_circle_outline,
        accentColor: AppTheme.stageAccent,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _openEmergencyContacts() async {
    await pushDemoStageRoute(
      context,
      page: EmergencyContactsScreen(userId: widget.userId),
    );
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return DemoStageScaffold(
      title: '位置共享',
      subtitle: '配置 SOS 時的位置同步、聯繫人通知與語音觸發提示',
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.stageAccent),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.stageAccent,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingL,
                  AppTheme.spacingL,
                  AppTheme.spacingL,
                  AppTheme.spacingXXL,
                ),
                children: [
                  _ReadinessBanner(
                    settings: _settings,
                    contactCount: _contactCount,
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  DemoSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AccessibleText(
                          'SOS 觸發預覽',
                          style: TextStyle(
                            color: AppTheme.stageTextPrimary,
                            fontSize: AppTheme.fontSizeLarge,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        AccessibleText(
                          '當前主前端會按以下順序演示安全流程。',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeNormal,
                            color: AppTheme.stageTextSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        _PreviewStep(
                          icon: _settings.autoShareLocation
                              ? Icons.my_location
                              : Icons.location_off_outlined,
                          title: _settings.autoShareLocation
                              ? '採集${_settings.usePreciseLocation ? '精確' : '大致'}位置'
                              : '跳過自動位置共享',
                          description: _settings.autoShareLocation
                              ? '演示頁會顯示當前位置已同步到 SOS 流程。'
                              : '仍可觸發 SOS，但聯繫人通知不會附帶實時位置。',
                        ),
                        _PreviewStep(
                          icon: _settings.shareWithEmergencyContacts
                              ? Icons.contacts
                              : Icons.contacts_outlined,
                          title: _settings.shareWithEmergencyContacts
                              ? '同步通知緊急聯繫人'
                              : '本次不通知緊急聯繫人',
                          description: _settings.shareWithEmergencyContacts
                              ? _contactCount == 0
                                    ? '你已開啓此選項，但還沒有聯繫人可通知。'
                                    : '當前將同步通知 $_contactCount 位聯繫人。'
                              : 'SOS 只展示志願者廣播與響應流程。',
                        ),
                        const _PreviewStep(
                          icon: Icons.campaign_outlined,
                          title: '向附近志願者廣播',
                          description: '演示版默認展示 5km 範圍內廣播與響應。',
                        ),
                        _PreviewStep(
                          icon: _settings.enableVoiceTrigger
                              ? Icons.mic_none
                              : Icons.mic_off_outlined,
                          title: _settings.enableVoiceTrigger
                              ? '保留語音觸發提示'
                              : '僅保留長按與快捷操作提示',
                          description: _settings.enableVoiceTrigger
                              ? '界面會提示可通過語音關鍵詞觸發。'
                              : '界面不會把語音作爲首選觸發方式展示。',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  DemoSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AccessibleText(
                          '共享設置',
                          style: TextStyle(
                            color: AppTheme.stageTextPrimary,
                            fontSize: AppTheme.fontSizeLarge,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        _SwitchTile(
                          title: 'SOS 時自動共享位置',
                          subtitle: '用於讓志願者和聯繫人更快確認你的位置。',
                          value: _settings.autoShareLocation,
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings.copyWith(
                                autoShareLocation: value,
                                usePreciseLocation: value
                                    ? _settings.usePreciseLocation
                                    : false,
                              );
                            });
                          },
                        ),
                        _StageDivider(),
                        _SwitchTile(
                          title: '使用精確位置',
                          subtitle: '關閉後，演示頁將只展示大致區域。',
                          value: _settings.usePreciseLocation,
                          onChanged: _settings.autoShareLocation
                              ? (value) {
                                  setState(() {
                                    _settings = _settings.copyWith(
                                      usePreciseLocation: value,
                                    );
                                  });
                                }
                              : null,
                        ),
                        _StageDivider(),
                        _SwitchTile(
                          title: '同步給緊急聯繫人',
                          subtitle: '聯繫人會收到當前狀態與位置摘要。',
                          value: _settings.shareWithEmergencyContacts,
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings.copyWith(
                                shareWithEmergencyContacts: value,
                              );
                            });
                          },
                        ),
                        _StageDivider(),
                        _SwitchTile(
                          title: '顯示語音觸發提示',
                          subtitle: '在 SOS 頁保留“緊急求助”等語音觸發說明。',
                          value: _settings.enableVoiceTrigger,
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings.copyWith(
                                enableVoiceTrigger: value,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  DemoSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AccessibleText(
                          '當前提醒',
                          style: TextStyle(
                            color: AppTheme.stageTextPrimary,
                            fontSize: AppTheme.fontSizeLarge,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        AccessibleText(
                          _contactCount == 0
                              ? '你還沒有設置緊急聯繫人。即使開啓了聯繫人同步，演示頁也不會顯示實際通知對象。'
                              : '已配置 $_contactCount 位聯繫人，SOS 時會按優先級展示通知。',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeNormal,
                            color: AppTheme.stageTextSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        AccessibleText(
                          '系統級定位權限、短信發送和真實後臺告警仍屬於後續能力，當前頁面聚焦主前端演示閉環。',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeSmall,
                            color: AppTheme.stageTextHint,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  OutlinedButton.icon(
                    onPressed: _openEmergencyContacts,
                    icon: LinkableMaterialIcon(
                      icon: Icons.contact_phone_outlined,
                      color: AppTheme.stageAccent,
                      semanticLabel: '管理緊急聯繫人',
                    ),
                    label: const Text('管理緊急聯繫人'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.stageAccent,
                      side: BorderSide(color: AppTheme.stageAccent, width: 2),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  AccessibleButton(
                    label: '保存設置',
                    semanticLabel: '保存位置共享設置',
                    icon: Icons.save_outlined,
                    backgroundColor: AppTheme.stageAccent,
                    isLoading: _isSaving,
                    onPressed: _saveSettings,
                  ),
                ],
              ),
            ),
    );
  }
}

class _ReadinessBanner extends StatelessWidget {
  const _ReadinessBanner({required this.settings, required this.contactCount});

  final SafetySettings settings;
  final int contactCount;

  @override
  Widget build(BuildContext context) {
    final title = !settings.autoShareLocation
        ? '位置共享未開啓'
        : contactCount == 0 && settings.shareWithEmergencyContacts
        ? '基礎 SOS 已就緒'
        : 'SOS 安全配置已就緒';

    final summary = !settings.autoShareLocation
        ? '當前觸發 SOS 時不會自動附帶位置。'
        : contactCount == 0 && settings.shareWithEmergencyContacts
        ? '位置共享可用，但建議先補充至少 1 位緊急聯繫人。'
        : '當前會共享${settings.usePreciseLocation ? '精確' : '大致'}位置，並展示聯繫人通知流程。';

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: AppTheme.stageAccentGradient,
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusMedium,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: LinkableMaterialIcon(
                  icon: settings.isReady
                      ? Icons.verified_user_outlined
                      : Icons.info_outline,
                  color: AppTheme.textOnPrimary,
                  semanticLabel: title,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: AccessibleText(
                  title,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeXLarge,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textOnPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          AccessibleText(
            summary,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeNormal,
              color: AppTheme.textOnPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Wrap(
            spacing: AppTheme.spacingS,
            runSpacing: AppTheme.spacingS,
            children: [
              _StatusChip(label: settings.isReady ? '安全閉環完整' : '建議補充設置'),
              _StatusChip(label: settings.locationModeLabel),
              _StatusChip(
                label: settings.shareWithEmergencyContacts
                    ? '聯繫人通知 ${contactCount > 0 ? '$contactCount 位' : '待補充'}'
                    : '聯繫人通知關閉',
              ),
              _StatusChip(
                label: settings.enableVoiceTrigger ? '語音提示開啓' : '僅手動觸發',
              ),
            ],
          ),
          if (settings.updatedAt != null) ...[
            const SizedBox(height: AppTheme.spacingM),
            AccessibleText(
              '最近更新：${_formatDateTime(settings.updatedAt!)}',
              style: const TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: AppTheme.textOnPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime value) {
    final minute = value.minute.toString().padLeft(2, '0');
    return '${value.month}月${value.day}日 ${value.hour}:$minute';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: AccessibleText(
        label,
        style: const TextStyle(
          fontSize: AppTheme.fontSizeSmall,
          fontWeight: FontWeight.w600,
          color: AppTheme.textOnPrimary,
        ),
      ),
    );
  }
}

class _PreviewStep extends StatelessWidget {
  const _PreviewStep({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.stageAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              border: Border.all(
                color: AppTheme.stageAccent.withValues(alpha: 0.18),
              ),
            ),
            child: LinkableMaterialIcon(
              icon: icon,
              color: AppTheme.stageAccent,
              semanticLabel: title,
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                AccessibleText(
                  description,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    color: AppTheme.stageTextSecondary,
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

class _StageDivider extends StatelessWidget {
  const _StageDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: AppTheme.spacingXL,
      color: AppTheme.stageBorder.withValues(alpha: 0.56),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: title,
      hint: subtitle,
      toggled: value,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.stageAccent,
        activeTrackColor: AppTheme.stageAccent.withValues(alpha: 0.38),
        inactiveThumbColor: AppTheme.stageTextHint,
        inactiveTrackColor: AppTheme.stageBorder.withValues(alpha: 0.46),
        title: AccessibleText(
          title,
          style: TextStyle(
            color: onChanged == null
                ? AppTheme.stageTextHint
                : AppTheme.stageTextPrimary,
            fontSize: AppTheme.fontSizeNormal,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: AccessibleText(
          subtitle,
          style: TextStyle(
            fontSize: AppTheme.fontSizeSmall,
            color: onChanged == null
                ? AppTheme.stageTextHint
                : AppTheme.stageTextSecondary,
          ),
        ),
      ),
    );
  }
}
