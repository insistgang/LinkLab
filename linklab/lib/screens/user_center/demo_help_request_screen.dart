import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/extensions.dart';
import '../../models/demo_help_request_model.dart';
import '../../providers/app_session_provider.dart';
import '../../services/user_center/demo_help_request_service.dart';
import 'seeker_center_screen.dart';

class DemoHelpRequestScreen extends ConsumerStatefulWidget {
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
  ConsumerState<DemoHelpRequestScreen> createState() => _DemoHelpRequestScreenState();
}

class _DemoHelpRequestScreenState extends ConsumerState<DemoHelpRequestScreen> {
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
        (ref.read(appSessionProvider).userProfile?.disabilityType ?? const [])
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
      appBar: AppBar(title: const Text('發起求助')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
          children: [
            Card(
              color: Colors.teal.withAlpha(15),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('演示態提交後，會同時寫入"我的求助"和志願者側"待處理任務"，方便直接展示完整閉環。'),
              ),
            ),
            const SizedBox(height: 16),
            _buildVolunteerCard(),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: _inputDecoration('求助類型'),
              items: const [
                DropdownMenuItem(value: 'companion_chat', child: Text('陪伴聊天')),
                DropdownMenuItem(value: 'reading_support', child: Text('讀屏識別')),
                DropdownMenuItem(value: 'travel_assist', child: Text('出行協助')),
                DropdownMenuItem(value: 'medical_support', child: Text('醫療陪護')),
                DropdownMenuItem(value: 'device_help', child: Text('設備使用')),
                DropdownMenuItem(value: 'other', child: Text('其他幫助')),
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
                '標題',
              ).copyWith(hintText: '例如：今晚想找人幫我確認藥盒標籤'),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '請填寫一個簡短標題，方便志願者快速理解需求';
                }
                if (value.trim().length < 4) {
                  return '標題至少 4 個字';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: _inputDecoration(
                '詳細描述',
              ).copyWith(hintText: '請描述需要什麼幫助、是否緊急、希望怎樣協助'),
              minLines: 4,
              maxLines: 6,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '請補充詳細描述，便於志願者提前準備';
                }
                if (value.trim().length < 10) {
                  return '描述再具體一些，至少 10 個字';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _scheduleController,
              decoration: _inputDecoration(
                '時間偏好',
              ).copyWith(hintText: '例如：今天晚上 19:00 後 / 本週六上午'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '請告訴我們您希望的時間安排';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedLocationMode,
              decoration: _inputDecoration('地點 / 線上線下'),
              items: const [
                DropdownMenuItem(
                  value: DemoHelpLocationMode.online,
                  child: Text('線上'),
                ),
                DropdownMenuItem(
                  value: DemoHelpLocationMode.offline,
                  child: Text('線下'),
                ),
                DropdownMenuItem(
                  value: DemoHelpLocationMode.flexible,
                  child: Text('線上 / 線下皆可'),
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
                title: const Text('需要無障礙支持'),
                subtitle: Text(_accessibilityNeeded ? '已標記無障礙支持需求' : '常規支持即可'),
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
        title: const Text('指定志願者'),
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
        ref.read(appSessionProvider).userProfile?.id ?? 'demo-user-id';

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
      ).showSnackBar(const SnackBar(content: Text('求助已提交，可在"我的求助"和志願者任務中查看')));

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
      ).showSnackBar(const SnackBar(content: Text('提交失敗，請稍後重試')));
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
