import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/extensions.dart';
import '../../models/emergency_contact_model.dart';
import '../../services/security/emergency_contact_service.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_overlays.dart';
import '../../widgets/demo/demo_stage.dart';
import '../../widgets/demo/linkable_icon.dart';

/// 緊急聯繫人管理頁面
class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key, required this.userId});

  final String userId;

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final EmergencyContactService _contactService = EmergencyContactService();

  List<EmergencyContactModel> _contacts = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try {
      final contacts = await _contactService.getContacts(widget.userId);
      if (!mounted) return;
      setState(() => _contacts = contacts);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openEditor({EmergencyContactModel? contact}) async {
    if (contact == null && _contacts.length >= 3) {
      if (!mounted) return;
      showDemoStageSnackBar(
        context,
        message: '最多隻能添加 3 個緊急聯繫人',
        icon: Icons.info_outline,
        accentColor: AppTheme.stageAccent,
      );
      return;
    }

    final draft = await showDialog<_ContactDraft>(
      context: context,
      builder: (context) => _ContactEditorDialog(
        initialContact: contact,
        relationshipOptions: _contactService.getRelationshipOptions(),
      ),
    );

    if (draft == null) return;

    try {
      if (contact == null) {
        await _contactService.addContact(
          userId: widget.userId,
          name: draft.name,
          phone: draft.phone,
          relationship: draft.relationship,
          priority: _contacts.length,
        );
      } else {
        await _contactService.updateContact(
          contactId: contact.id,
          name: draft.name,
          phone: draft.phone,
          relationship: draft.relationship,
        );
      }

      await _loadContacts();
      if (!mounted) return;
      showDemoStageSnackBar(
        context,
        message: contact == null ? '緊急聯繫人已添加' : '緊急聯繫人已更新',
        icon: Icons.check_circle_outline,
        accentColor: AppTheme.stageAccent,
      );
    } catch (e) {
      if (!mounted) return;
      showDemoStageSnackBar(
        context,
        message: '操作失敗：$e',
        icon: Icons.error_outline,
        accentColor: AppTheme.stageAccent,
      );
    }
  }

  Future<void> _deleteContact(EmergencyContactModel contact) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const AccessibleText(
              '刪除緊急聯繫人？',
              style: TextStyle(
                fontSize: AppTheme.fontSizeLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: AccessibleText(
              '刪除後，${contact.name} 將不會在 SOS 觸發時收到通知。',
              style: const TextStyle(fontSize: AppTheme.fontSizeNormal),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const AccessibleText('取消'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.stageAccent,
                  foregroundColor: AppTheme.textOnPrimary,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const AccessibleText('刪除'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await _contactService.deleteContact(contact.id);
      await _loadContacts();
      if (!mounted) return;
      showDemoStageSnackBar(
        context,
        message: '聯繫人已刪除',
        icon: Icons.check_circle_outline,
        accentColor: AppTheme.stageAccent,
      );
    } catch (e) {
      if (!mounted) return;
      showDemoStageSnackBar(
        context,
        message: '刪除失敗：$e',
        icon: Icons.error_outline,
        accentColor: AppTheme.stageAccent,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DemoStageScaffold(
      title: '緊急聯繫人',
      subtitle: '配置 SOS 時同步通知的家人或看護人',
      body: RefreshIndicator(
        onRefresh: _loadContacts,
        color: AppTheme.stageAccent,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingL,
            AppTheme.spacingL,
            AppTheme.spacingL,
            AppTheme.spacingXXL,
          ),
          children: [
            _SummaryBanner(contactCount: _contacts.length),
            const SizedBox(height: AppTheme.spacingL),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.spacingXXL),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.stageAccent),
                ),
              )
            else if (_contacts.isEmpty)
              _EmptyState(onAddPressed: () => _openEditor())
            else ...[
              AccessibleText(
                '已設置聯繫人',
                style: TextStyle(
                  color: AppTheme.stageTextPrimary,
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              ..._contacts.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                  child: _ContactCard(
                    contact: entry.value,
                    displayPriority: entry.key + 1,
                    onEdit: () => _openEditor(contact: entry.value),
                    onDelete: () => _deleteContact(entry.value),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              if (_contacts.length < 3)
                AccessibleButton(
                  label: '添加緊急聯繫人',
                  semanticLabel: '添加緊急聯繫人',
                  icon: Icons.person_add_alt_1,
                  backgroundColor: AppTheme.stageAccent,
                  onPressed: () => _openEditor(),
                )
              else
                DemoSurfaceCard(
                  child: Row(
                    children: [
                      LinkableMaterialIcon(
                        icon: Icons.verified_user_outlined,
                        color: AppTheme.stageAccent,
                        semanticLabel: '聯繫人上限',
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: AccessibleText(
                          '已達到 3 位聯繫人上限。SOS 將按優先級從上到下通知。',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeNormal,
                            color: AppTheme.stageTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({required this.contactCount});

  final int contactCount;

  @override
  Widget build(BuildContext context) {
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
                  icon: contactCount == 0
                      ? Icons.contact_emergency_outlined
                      : Icons.verified_user_outlined,
                  color: AppTheme.textOnPrimary,
                  semanticLabel: contactCount == 0 ? '待添加緊急聯繫人' : '緊急聯繫人已配置',
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              const Expanded(
                child: AccessibleText(
                  'SOS 安全通知',
                  style: TextStyle(
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
            contactCount == 0
                ? '還沒有配置聯繫人。建議至少添加 1 位家人或看護人。'
                : '當前已配置 $contactCount / 3 位聯繫人，觸發 SOS 時會按優先級通知。',
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
              _SummaryChip(label: contactCount == 0 ? '待補充聯繫人' : '聯繫人已就緒'),
              _SummaryChip(label: '$contactCount / 3 位聯繫人'),
              const _SummaryChip(label: 'SOS 時同步展示'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label});

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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddPressed});

  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return DemoSurfaceCard(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      child: Column(
        children: [
          LinkableMaterialIcon(
            icon: Icons.contact_emergency_outlined,
            size: 72,
            color: AppTheme.stageAccent,
            semanticLabel: '暫無緊急聯繫人',
          ),
          const SizedBox(height: AppTheme.spacingM),
          AccessibleText(
            '暫無緊急聯繫人',
            style: TextStyle(
              color: AppTheme.stageTextPrimary,
              fontSize: AppTheme.fontSizeLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          AccessibleText(
            '添加聯繫人後，演示版 SOS 頁面會顯示這些聯繫人將同步收到通知。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTheme.fontSizeNormal,
              color: AppTheme.stageTextSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          AccessibleButton(
            label: '添加第一位聯繫人',
            semanticLabel: '添加第一位緊急聯繫人',
            icon: Icons.add,
            backgroundColor: AppTheme.stageAccent,
            onPressed: onAddPressed,
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.contact,
    required this.displayPriority,
    required this.onEdit,
    required this.onDelete,
  });

  final EmergencyContactModel contact;
  final int displayPriority;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return DemoSurfaceCard(
      semanticLabel: '緊急聯繫人 ${contact.name}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.stageAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusMedium,
                  ),
                  border: Border.all(
                    color: AppTheme.stageAccent.withValues(alpha: 0.18),
                  ),
                ),
                child: Center(
                  child: AccessibleText(
                    '$displayPriority',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.stageAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AccessibleText(
                      contact.name,
                      style: TextStyle(
                        color: AppTheme.stageTextPrimary,
                        fontSize: AppTheme.fontSizeLarge,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    AccessibleText(
                      contact.phone.maskedPhone,
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeNormal,
                        color: AppTheme.stageTextSecondary,
                      ),
                    ),
                    if (contact.relationship != null) ...[
                      const SizedBox(height: AppTheme.spacingXS),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingS,
                          vertical: AppTheme.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.stageAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: AccessibleText(
                          contact.relationshipLabel,
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeSmall,
                            color: AppTheme.stageAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onEdit,
                    icon: const LinkableMaterialIcon(
                      icon: Icons.edit_outlined,
                      semanticLabel: '編輯聯繫人',
                    ),
                    tooltip: '編輯聯繫人',
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: LinkableMaterialIcon(
                      icon: Icons.delete_outline,
                      color: AppTheme.stageAccent,
                      semanticLabel: '刪除聯繫人',
                    ),
                    tooltip: '刪除聯繫人',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          const Divider(height: 1),
          const SizedBox(height: AppTheme.spacingM),
          AccessibleText(
            '通知順序：第 $displayPriority 位',
            style: TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              color: AppTheme.stageTextHint,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactEditorDialog extends StatefulWidget {
  const _ContactEditorDialog({
    this.initialContact,
    required this.relationshipOptions,
  });

  final EmergencyContactModel? initialContact;
  final List<Map<String, String>> relationshipOptions;

  @override
  State<_ContactEditorDialog> createState() => _ContactEditorDialogState();
}

class _ContactEditorDialogState extends State<_ContactEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  String? _relationship;

  bool get _isEdit => widget.initialContact != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialContact?.name ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.initialContact?.phone ?? '',
    );
    _relationship = widget.initialContact?.relationship;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    Navigator.of(context).pop(
      _ContactDraft(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        relationship: _relationship,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: AccessibleText(
        _isEdit ? '編輯緊急聯繫人' : '添加緊急聯繫人',
        style: const TextStyle(
          fontSize: AppTheme.fontSizeLarge,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AccessibleTextField(
                controller: _nameController,
                label: '姓名',
                hint: '請輸入聯繫人姓名',
                prefixIcon: const LinkableMaterialIcon(
                  icon: Icons.person_outline,
                  semanticLabel: '姓名',
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '請輸入聯繫人姓名';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingM),
              AccessiblePhoneField(controller: _phoneController),
              const SizedBox(height: AppTheme.spacingM),
              DropdownButtonFormField<String>(
                initialValue: _relationship,
                decoration: const InputDecoration(
                  labelText: '關係',
                  hintText: '請選擇關係（可選）',
                  prefixIcon: LinkableMaterialIcon(
                    icon: Icons.people_outline,
                    semanticLabel: '關係',
                  ),
                ),
                items: widget.relationshipOptions
                    .map(
                      (option) => DropdownMenuItem<String>(
                        value: option['value'],
                        child: Text(option['label'] ?? ''),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _relationship = value);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const AccessibleText('取消'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: AccessibleText(_isEdit ? '保存' : '添加'),
        ),
      ],
    );
  }
}

class _ContactDraft {
  const _ContactDraft({
    required this.name,
    required this.phone,
    this.relationship,
  });

  final String name;
  final String phone;
  final String? relationship;
}
