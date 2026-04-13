import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/security/emergency_contact_service.dart';
import '../../services/security/safety_settings_service.dart';
import '../../widgets/accessible/index.dart';
import 'emergency_contacts_screen.dart';

class LocationSharingScreen extends StatefulWidget {
  const LocationSharingScreen({
    super.key,
    required this.userId,
  });

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
      final saved = await _settingsService.saveSettings(widget.userId, _settings);
      if (!mounted) return;
      setState(() => _settings = saved);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('位置共享设置已保存')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _openEmergencyContacts() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmergencyContactsScreen(userId: widget.userId),
      ),
    );
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return AccessibleScaffold(
      title: '位置共享',
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  children: [
                    _ReadinessBanner(
                      settings: _settings,
                      contactCount: _contactCount,
                    ),
                    const SizedBox(height: AppTheme.spacingL),
                    AccessibleCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AccessibleText(
                            'SOS 触发预览',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeLarge,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingS),
                          const AccessibleText(
                            '当前主前端会按以下顺序演示安全流程。',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeNormal,
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          _PreviewStep(
                            icon: _settings.autoShareLocation
                                ? Icons.my_location
                                : Icons.location_off_outlined,
                            title: _settings.autoShareLocation
                                ? '采集${_settings.usePreciseLocation ? '精确' : '大致'}位置'
                                : '跳过自动位置共享',
                            description: _settings.autoShareLocation
                                ? '演示页会显示当前位置已同步到 SOS 流程。'
                                : '仍可触发 SOS，但联系人通知不会附带实时位置。',
                          ),
                          _PreviewStep(
                            icon: _settings.shareWithEmergencyContacts
                                ? Icons.contacts
                                : Icons.contacts_outlined,
                            title: _settings.shareWithEmergencyContacts
                                ? '同步通知紧急联系人'
                                : '本次不通知紧急联系人',
                            description: _settings.shareWithEmergencyContacts
                                ? _contactCount == 0
                                    ? '你已开启此选项，但还没有联系人可通知。'
                                    : '当前将同步通知 $_contactCount 位联系人。'
                                : 'SOS 只展示志愿者广播与响应流程。',
                          ),
                          const _PreviewStep(
                            icon: Icons.campaign_outlined,
                            title: '向附近志愿者广播',
                            description: '演示版默认展示 5km 范围内广播与响应。',
                          ),
                          _PreviewStep(
                            icon: _settings.enableVoiceTrigger
                                ? Icons.mic_none
                                : Icons.mic_off_outlined,
                            title: _settings.enableVoiceTrigger
                                ? '保留语音触发提示'
                                : '仅保留长按与快捷操作提示',
                            description: _settings.enableVoiceTrigger
                                ? '界面会提示可通过语音关键词触发。'
                                : '界面不会把语音作为首选触发方式展示。',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingL),
                    AccessibleCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AccessibleText(
                            '共享设置',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeLarge,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          _SwitchTile(
                            title: 'SOS 时自动共享位置',
                            subtitle: '用于让志愿者和联系人更快确认你的位置。',
                            value: _settings.autoShareLocation,
                            onChanged: (value) {
                              setState(() {
                                _settings = _settings.copyWith(
                                  autoShareLocation: value,
                                  usePreciseLocation:
                                      value ? _settings.usePreciseLocation : false,
                                );
                              });
                            },
                          ),
                          const Divider(),
                          _SwitchTile(
                            title: '使用精确位置',
                            subtitle: '关闭后，演示页将只展示大致区域。',
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
                          const Divider(),
                          _SwitchTile(
                            title: '同步给紧急联系人',
                            subtitle: '联系人会收到当前状态与位置摘要。',
                            value: _settings.shareWithEmergencyContacts,
                            onChanged: (value) {
                              setState(() {
                                _settings = _settings.copyWith(
                                  shareWithEmergencyContacts: value,
                                );
                              });
                            },
                          ),
                          const Divider(),
                          _SwitchTile(
                            title: '显示语音触发提示',
                            subtitle: '在 SOS 页保留“紧急求助”等语音触发说明。',
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
                    AccessibleCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AccessibleText(
                            '当前提醒',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeLarge,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingS),
                          AccessibleText(
                            _contactCount == 0
                                ? '你还没有设置紧急联系人。即使开启了联系人同步，演示页也不会显示实际通知对象。'
                                : '已配置 $_contactCount 位联系人，SOS 时会按优先级展示通知。 ',
                            style: const TextStyle(
                              fontSize: AppTheme.fontSizeNormal,
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingS),
                          AccessibleText(
                            '系统级定位权限、短信发送和真实后台告警仍属于后续能力，当前页面聚焦主前端演示闭环。',
                            style: const TextStyle(
                              fontSize: AppTheme.fontSizeSmall,
                              color: AppTheme.textHint,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingL),
                    OutlinedButton.icon(
                      onPressed: _openEmergencyContacts,
                      icon: const Icon(Icons.contact_phone_outlined),
                      label: const Text('管理紧急联系人'),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    AccessibleButton(
                      label: '保存设置',
                      semanticLabel: '保存位置共享设置',
                      icon: Icons.save_outlined,
                      isLoading: _isSaving,
                      onPressed: _saveSettings,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ReadinessBanner extends StatelessWidget {
  const _ReadinessBanner({
    required this.settings,
    required this.contactCount,
  });

  final SafetySettings settings;
  final int contactCount;

  @override
  Widget build(BuildContext context) {
    final title = !settings.autoShareLocation
        ? '位置共享未开启'
        : contactCount == 0 && settings.shareWithEmergencyContacts
            ? '基础 SOS 已就绪'
            : 'SOS 安全配置已就绪';

    final summary = !settings.autoShareLocation
        ? '当前触发 SOS 时不会自动附带位置。'
        : contactCount == 0 && settings.shareWithEmergencyContacts
            ? '位置共享可用，但建议先补充至少 1 位紧急联系人。'
            : '当前会共享${settings.usePreciseLocation ? '精确' : '大致'}位置，并展示联系人通知流程。';

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: settings.isReady
              ? const [AppTheme.primaryColor, AppTheme.secondaryColor]
              : const [AppTheme.warningColor, AppTheme.emergencyColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AccessibleText(
            title,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeXLarge,
              fontWeight: FontWeight.bold,
              color: AppTheme.textOnPrimary,
            ),
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
              _StatusChip(label: settings.locationModeLabel),
              _StatusChip(
                label: settings.shareWithEmergencyContacts
                    ? '联系人通知 ${contactCount > 0 ? '$contactCount 位' : '待补充'}'
                    : '联系人通知关闭',
              ),
              _StatusChip(
                label: settings.enableVoiceTrigger ? '语音提示开启' : '仅手动触发',
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
  const _StatusChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.24)),
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
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                AccessibleText(
                  description,
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
      ),
    );
  }
}
