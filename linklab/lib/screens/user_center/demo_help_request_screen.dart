import 'package:flutter/material.dart';

import '../../core/utils/extensions.dart';
import '../../models/demo_help_request_model.dart';
import '../../services/app_session_service.dart';
import '../../services/user_center/demo_help_request_service.dart';
import 'seeker_center_screen.dart';

class DemoHelpRequestScreen extends StatefulWidget {
  const DemoHelpRequestScreen({
    super.key,
    required this.volunteerId,
    required this.volunteerName,
    this.volunteerAvatar,
  });

  final String volunteerId;
  final String volunteerName;
  final String? volunteerAvatar;

  @override
  State<DemoHelpRequestScreen> createState() => _DemoHelpRequestScreenState();
}

class _DemoHelpRequestScreenState extends State<DemoHelpRequestScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final DemoHelpRequestService _helpRequestService = DemoHelpRequestService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _scheduleController = TextEditingController();

  String _selectedType = 'companion_chat';
  String _selectedLocationMode = DemoHelpLocationMode.flexible;
  late bool _accessibilityNeeded;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _accessibilityNeeded =
        (AppSessionService.instance.userProfile?.disabilityType ?? const [])
            .isNotEmpty;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _scheduleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('发起求助')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
          children: [
            Card(
              color: Colors.teal.withAlpha(15),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('演示态提交后，会同时写入“我的求助”和志愿者侧“待处理任务”，方便直接展示完整闭环。'),
              ),
            ),
            const SizedBox(height: 16),
            _buildVolunteerCard(),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: _inputDecoration('求助类型'),
              items: const [
                DropdownMenuItem(value: 'companion_chat', child: Text('陪伴聊天')),
                DropdownMenuItem(value: 'reading_support', child: Text('读屏识别')),
                DropdownMenuItem(value: 'travel_assist', child: Text('出行协助')),
                DropdownMenuItem(value: 'medical_support', child: Text('医疗陪护')),
                DropdownMenuItem(value: 'device_help', child: Text('设备使用')),
                DropdownMenuItem(value: 'other', child: Text('其他帮助')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedType = value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration(
                '标题',
              ).copyWith(hintText: '例如：今晚想找人帮我确认药盒标签'),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请填写一个简短标题，方便志愿者快速理解需求';
                }
                if (value.trim().length < 4) {
                  return '标题至少 4 个字';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: _inputDecoration(
                '详细描述',
              ).copyWith(hintText: '请描述需要什么帮助、是否紧急、希望怎样协助'),
              minLines: 4,
              maxLines: 6,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请补充详细描述，便于志愿者提前准备';
                }
                if (value.trim().length < 10) {
                  return '描述再具体一些，至少 10 个字';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _scheduleController,
              decoration: _inputDecoration(
                '时间偏好',
              ).copyWith(hintText: '例如：今天晚上 19:00 后 / 本周六上午'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请告诉我们您希望的时间安排';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedLocationMode,
              decoration: _inputDecoration('地点 / 线上线下'),
              items: const [
                DropdownMenuItem(
                  value: DemoHelpLocationMode.online,
                  child: Text('线上'),
                ),
                DropdownMenuItem(
                  value: DemoHelpLocationMode.offline,
                  child: Text('线下'),
                ),
                DropdownMenuItem(
                  value: DemoHelpLocationMode.flexible,
                  child: Text('线上 / 线下皆可'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedLocationMode = value);
              },
            ),
            const SizedBox(height: 16),
            Card(
              child: SwitchListTile(
                value: _accessibilityNeeded,
                title: const Text('需要无障碍支持'),
                subtitle: Text(_accessibilityNeeded ? '已标记无障碍支持需求' : '常规支持即可'),
                onChanged: (value) {
                  setState(() => _accessibilityNeeded = value);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_outlined),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(_isSubmitting ? '提交中...' : '提交求助'),
          ),
        ),
      ),
    );
  }

  Widget _buildVolunteerCard() {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: _avatarImage(widget.volunteerAvatar),
          child: _avatarImage(widget.volunteerAvatar) == null
              ? Text(
                  widget.volunteerName.isEmpty
                      ? '?'
                      : widget.volunteerName.substring(0, 1),
                )
              : null,
        ),
        title: const Text('指定志愿者'),
        subtitle: Text(widget.volunteerName),
        trailing: const Chip(label: Text('已指定')),
      ),
    );
  }

  Future<void> _submit() async {
    context.hideKeyboard();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final seekerId =
        AppSessionService.instance.userProfile?.id ?? 'demo-user-id';

    setState(() => _isSubmitting = true);

    try {
      await _helpRequestService.createRequest(
        seekerId: seekerId,
        volunteerId: widget.volunteerId,
        volunteerName: widget.volunteerName,
        volunteerAvatar: widget.volunteerAvatar,
        type: _selectedType,
        title: _titleController.text,
        description: _descriptionController.text,
        schedulePreference: _scheduleController.text,
        locationMode: _selectedLocationMode,
        accessibilityNeeded: _accessibilityNeeded,
        status: DemoHelpRequestStatus.pending,
        assignedVolunteerAccountId: seekerId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('求助已提交，可在“我的求助”和志愿者任务中查看')));

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const SeekerCenterScreen(initialTabIndex: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('提交失败，请稍后重试')));
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      alignLabelWithHint: true,
    );
  }

  ImageProvider<Object>? _avatarImage(String? avatar) {
    if (avatar == null || avatar.isEmpty) return null;
    if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
      return NetworkImage(avatar);
    }
    return null;
  }
}
