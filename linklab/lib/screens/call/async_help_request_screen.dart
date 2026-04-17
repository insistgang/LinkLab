import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/app_session_service.dart';
import '../../services/user_center/async_task_service.dart';
import '../../widgets/accessible/index.dart';
import '../user_center/seeker_center_screen.dart';

class AsyncHelpRequestScreen extends StatefulWidget {
  const AsyncHelpRequestScreen({
    super.key,
    this.initialTaskType,
    this.initialDescription,
    this.replaceWithSeekerCenterOnSubmit = false,
  });

  final String? initialTaskType;
  final String? initialDescription;
  final bool replaceWithSeekerCenterOnSubmit;

  @override
  State<AsyncHelpRequestScreen> createState() => _AsyncHelpRequestScreenState();
}

class _AsyncHelpRequestScreenState extends State<AsyncHelpRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final AsyncTaskService _taskService = AsyncTaskService();

  late final TextEditingController _descriptionController;

  String _selectedScenario = '读信件';
  String _contentMode = 'text';
  String? _selectedAttachment;
  double _voiceDurationSeconds = 30;
  bool _isSubmitting = false;

  String get _currentUserId =>
      AppSessionService.instance.currentUser?.id ?? 'demo-user-id';

  static const List<_ScenarioOption> _scenarios = [
    _ScenarioOption(
      title: '读信件',
      subtitle: '适合物业通知、快递单、账单等非紧急阅读需求',
    ),
    _ScenarioOption(
      title: '菜单翻译',
      subtitle: '把餐厅菜单、商品说明等内容留给志愿者稍后回复',
    ),
    _ScenarioOption(
      title: '药盒确认',
      subtitle: '适合让志愿者二次确认药品名称、剂量或服用提醒',
    ),
    _ScenarioOption(
      title: '照片辨认',
      subtitle: '请志愿者稍后帮你辨认图片里的物品、文字或场景',
    ),
  ];

  static const List<_AttachmentOption> _attachments = [
    _AttachmentOption(label: '信件照片', icon: Icons.mail_outline),
    _AttachmentOption(label: '药盒照片', icon: Icons.medication_outlined),
    _AttachmentOption(label: '菜单截图', icon: Icons.restaurant_menu_outlined),
    _AttachmentOption(label: '物品照片', icon: Icons.photo_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _selectedScenario = widget.initialTaskType ?? _selectedScenario;
    _descriptionController =
        TextEditingController(text: widget.initialDescription ?? '');
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);

    final description = _buildRequestDescription();
    final task = await _taskService.createTask(
      seekerId: _currentUserId,
      taskType: _selectedScenario,
      description: description,
      attachmentLabel: _buildAttachmentLabel(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (task == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('提交失败，请稍后重试')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('留言已提交，可在求助者中心查看进度')),
    );

    if (widget.replaceWithSeekerCenterOnSubmit) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const SeekerCenterScreen(initialTabIndex: 1),
        ),
      );
      return;
    }

    Navigator.of(context).pop(true);
  }

  String _buildRequestDescription() {
    final description = _descriptionController.text.trim();
    if (_contentMode == 'voice') {
      return '$description\n\n语音留言时长：约 ${_voiceDurationSeconds.toInt()} 秒';
    }
    return description;
  }

  String? _buildAttachmentLabel() {
    if (_contentMode == 'image') {
      return _selectedAttachment ?? '未选择附件';
    }
    if (_contentMode == 'voice') {
      return '语音留言';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AccessibleScaffold(
      title: '异步留言求助',
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            children: [
              _IntroBanner(contentMode: _contentMode),
              const SizedBox(height: AppTheme.spacingL),
              const AccessibleText(
                '选择需求场景',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              ..._scenarios.map(
                (scenario) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
                  child: _ScenarioCard(
                    option: scenario,
                    selected: _selectedScenario == scenario.title,
                    onTap: () {
                      setState(() => _selectedScenario = scenario.title);
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              AccessibleRadioGroup<String>(
                title: '留言方式',
                value: _contentMode,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _contentMode = value;
                    if (_contentMode != 'image') {
                      _selectedAttachment = null;
                    }
                  });
                },
                options: const [
                  AccessibleRadioOption(
                    value: 'text',
                    label: '文字留言',
                    description: '适合清晰描述需要志愿者完成的内容',
                  ),
                  AccessibleRadioOption(
                    value: 'voice',
                    label: '语音留言',
                    description: '用语音补充情况，演示中会保存为语音时长摘要',
                  ),
                  AccessibleRadioOption(
                    value: 'image',
                    label: '图片留言',
                    description: '选择演示附件标签，方便后续志愿者识别',
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingL),
              if (_contentMode == 'image') ...[
                const AccessibleText(
                  '选择演示附件',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeNormal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                Wrap(
                  spacing: AppTheme.spacingS,
                  runSpacing: AppTheme.spacingS,
                  children: _attachments.map((attachment) {
                    final selected = _selectedAttachment == attachment.label;
                    return ChoiceChip(
                      selected: selected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(attachment.icon, size: 16),
                          const SizedBox(width: 6),
                          Text(attachment.label),
                        ],
                      ),
                      onSelected: (_) {
                        setState(() => _selectedAttachment = attachment.label);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppTheme.spacingL),
              ],
              if (_contentMode == 'voice') ...[
                AccessibleCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AccessibleText(
                        '语音留言时长',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeNormal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXS),
                      AccessibleText(
                        '演示版会把语音记录为时长摘要，便于在 Web 端稳定展示。',
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Slider(
                        value: _voiceDurationSeconds,
                        min: 15,
                        max: 120,
                        divisions: 7,
                        label: '${_voiceDurationSeconds.toInt()} 秒',
                        onChanged: (value) {
                          setState(() => _voiceDurationSeconds = value);
                        },
                      ),
                      AccessibleText(
                        '当前：约 ${_voiceDurationSeconds.toInt()} 秒',
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),
              ],
              AccessibleTextField(
                controller: _descriptionController,
                label: '详细说明',
                hint: '例如：帮我读一下这封物业通知里说了什么，是否需要我明天去缴费。',
                maxLines: 6,
                minLines: 4,
                maxLength: 240,
                textInputAction: TextInputAction.newline,
                prefixIcon: const Icon(Icons.edit_note_outlined),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请先描述你希望志愿者帮你完成什么';
                  }
                  if (_contentMode == 'image' && _selectedAttachment == null) {
                    return '请选择一个演示附件';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingM),
              AccessibleCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AccessibleText(
                      '提交后会发生什么',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeNormal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    const _StepText('1. 留言会进入异步任务队列，状态显示为“待志愿者领取”。'),
                    const _StepText('2. 同时在帮助档案里生成一条异步求助记录。'),
                    const _StepText('3. 志愿者回复后，你可以在求助者中心回看结果。'),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingXL),
              AccessibleButton(
                label: '提交异步留言',
                semanticLabel: '提交异步留言求助',
                icon: Icons.send_outlined,
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroBanner extends StatelessWidget {
  const _IntroBanner({
    required this.contentMode,
  });

  final String contentMode;

  @override
  Widget build(BuildContext context) {
    final detail = switch (contentMode) {
      'voice' => '当前将以语音留言形式记录，并保留时长摘要。',
      'image' => '当前将附带演示附件标签，方便后续在任务列表中识别。',
      _ => '当前将以文字留言形式进入队列，适合不紧急的问题。',
    };

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AccessibleText(
            '适合非紧急问题',
            style: TextStyle(
              fontSize: AppTheme.fontSizeXLarge,
              fontWeight: FontWeight.bold,
              color: AppTheme.textOnPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          const AccessibleText(
            '如果你现在不需要立即连线志愿者，可以先把问题留在这里，稍后由合适的志愿者处理。',
            style: TextStyle(
              fontSize: AppTheme.fontSizeNormal,
              color: AppTheme.textOnPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          AccessibleText(
            detail,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              color: AppTheme.textOnPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _ScenarioOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AccessibleCard(
      margin: EdgeInsets.zero,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            selected ? Icons.check_circle : Icons.radio_button_unchecked,
            color: selected ? AppTheme.primaryColor : AppTheme.textHint,
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccessibleText(
                  option.title,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeNormal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                AccessibleText(
                  option.subtitle,
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

class _StepText extends StatelessWidget {
  const _StepText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
      child: AccessibleText(
        text,
        style: const TextStyle(
          fontSize: AppTheme.fontSizeSmall,
          color: AppTheme.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }
}

class _ScenarioOption {
  const _ScenarioOption({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
}

class _AttachmentOption {
  const _AttachmentOption({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}
