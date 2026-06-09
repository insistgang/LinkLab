import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/security/auth_level_model.dart';
import '../../services/security/authentication_service.dart';
import '../../widgets/accessible/accessible_scaffold.dart';
import '../../widgets/accessible/accessible_button.dart';

/// 多級認證頁面
class AuthenticationScreen extends StatefulWidget {
  final String userId;

  const AuthenticationScreen({
    super.key,
    required this.userId,
  });

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final AuthenticationService _authService = AuthenticationService();
  UserAuthStatus? _authStatus;
  List<CertificationApplication> _applications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final status = await _authService.getUserAuthStatus(widget.userId);
      final applications = await _authService.getUserApplications(widget.userId);

      setState(() {
        _authStatus = status;
        _applications = applications;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AccessibleScaffold(
      title: '實名認證',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCurrentLevelCard(),
                    const SizedBox(height: 24),
                    _buildAuthLevelsList(),
                    const SizedBox(height: 24),
                    if (_applications.isNotEmpty) _buildApplicationsList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentLevelCard() {
    final level = _authStatus?.currentLevel ?? AuthLevel.phone;
    final progress = _calculateProgress();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple,
            Colors.deepPurple.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '當前認證等級',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            level.label,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            level.description,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateProgress() {
    if (_authStatus == null) return 0.25;
    if (_authStatus!.disabledCertVerified) return 1.0;
    if (_authStatus!.realNameVerified) return 0.75;
    if (_authStatus!.phoneVerified) return 0.5;
    return 0.25;
  }

  Widget _buildAuthLevelsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '認證等級',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildAuthLevelItem(
          level: AuthLevel.phone,
          isCompleted: _authStatus?.phoneVerified ?? false,
          isPending: false,
        ),
        _buildAuthLevelItem(
          level: AuthLevel.realName,
          isCompleted: _authStatus?.realNameVerified ?? false,
          isPending: _hasPendingApplication(AuthLevel.realName),
        ),
        _buildAuthLevelItem(
          level: AuthLevel.disabledCert,
          isCompleted: _authStatus?.disabledCertVerified ?? false,
          isPending: _hasPendingApplication(AuthLevel.disabledCert),
        ),
        _buildAuthLevelItem(
          level: AuthLevel.skillCert,
          isCompleted: (_authStatus?.verifiedSkills.length ?? 0) > 0,
          isPending: _hasPendingApplication(AuthLevel.skillCert),
        ),
      ],
    );
  }

  bool _hasPendingApplication(AuthLevel level) {
    return _applications.any(
      (app) => app.authLevel == level && app.status == CertificationStatus.pending,
    );
  }

  Widget _buildAuthLevelItem({
    required AuthLevel level,
    required bool isCompleted,
    required bool isPending,
  }) {
    IconData icon;
    String subtitle;

    switch (level) {
      case AuthLevel.phone:
        icon = Icons.phone_android;
        subtitle = '已完成手機號驗證';
      case AuthLevel.realName:
        icon = Icons.badge;
        subtitle = '提交身份證信息';
      case AuthLevel.disabledCert:
        icon = Icons.accessibility_new;
        subtitle = '上傳殘障證明，獲得優先匹配權';
      case AuthLevel.skillCert:
        icon = Icons.workspace_premium;
        subtitle = '提交專業技能證書';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isCompleted ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCompleted
              ? Colors.green
              : isPending
                  ? Colors.orange
                  : Colors.grey[300]!,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isCompleted
                ? Colors.green.withOpacity(0.1)
                : isPending
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isCompleted
                ? Colors.green
                : isPending
                    ? Colors.orange
                    : Colors.grey,
          ),
        ),
        title: Text(
          level.label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isCompleted ? Colors.green : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(subtitle),
            if (isPending) ...[
              const SizedBox(height: 4),
              const Text(
                '審覈中...',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        trailing: isCompleted
            ? const Icon(Icons.check_circle, color: Colors.green)
            : isPending
                ? const Icon(Icons.hourglass_empty, color: Colors.orange)
                : const Icon(Icons.chevron_right),
        onTap: isCompleted || isPending ? null : () => _onAuthLevelTap(level),
      ),
    );
  }

  void _onAuthLevelTap(AuthLevel level) {
    switch (level) {
      case AuthLevel.phone:
        // 手機號認證已在登錄時完成
        break;
      case AuthLevel.realName:
        _showRealNameDialog();
        break;
      case AuthLevel.disabledCert:
        _showDisabledCertUpload();
        break;
      case AuthLevel.skillCert:
        _showSkillCertUpload();
        break;
    }
  }

  void _showRealNameDialog() {
    showDialog(
      context: context,
      builder: (context) => _RealNameVerificationDialog(
        onSubmit: (name, idCard) async {
          try {
            await _authService.submitRealNameVerification(
              userId: widget.userId,
              name: name,
              idCard: idCard,
            );
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('實名認證申請已提交')),
              );
              _loadData();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('提交失敗: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showDisabledCertUpload() {
    _showImageUploadDialog(
      title: '上傳殘障證明',
      description: '請上傳您的殘障證明照片，支持身份證、殘疾證等有效證件',
      onUpload: (file) async {
        try {
          await _authService.uploadDisabledCertificate(
            userId: widget.userId,
            certificate: file,
          );
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('殘障證明上傳成功，等待審覈')),
            );
            _loadData();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('上傳失敗: $e')),
            );
          }
        }
      },
    );
  }

  void _showSkillCertUpload() {
    _showImageUploadDialog(
      title: '上傳技能證書',
      description: '請上傳您的專業技能證書，如手語證書、護理證書等',
      onUpload: (file) async {
        try {
          await _authService.submitSkillCertification(
            userId: widget.userId,
            skill: '專業技能',
            certificate: file,
          );
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('技能認證申請已提交')),
            );
            _loadData();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('上傳失敗: $e')),
            );
          }
        }
      },
    );
  }

  void _showImageUploadDialog({
    required String title,
    required String description,
    required Function(File) onUpload,
  }) {
    showDialog(
      context: context,
      builder: (context) => _ImageUploadDialog(
        title: title,
        description: description,
        onUpload: onUpload,
      ),
    );
  }

  Widget _buildApplicationsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '認證申請記錄',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._applications.map((app) => _buildApplicationItem(app)),
      ],
    );
  }

  Widget _buildApplicationItem(CertificationApplication app) {
    Color statusColor;
    String statusText;

    switch (app.status) {
      case CertificationStatus.pending:
        statusColor = Colors.orange;
        statusText = '審覈中';
      case CertificationStatus.approved:
        statusColor = Colors.green;
        statusText = '已通過';
      case CertificationStatus.rejected:
        statusColor = Colors.red;
        statusText = '已拒絕';
      case CertificationStatus.expired:
        statusColor = Colors.grey;
        statusText = '已過期';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.authLevel.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '提交時間: ${_formatDate(app.submittedAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (app.rejectReason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '原因: ${app.rejectReason}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[400],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// 實名認證對話框
class _RealNameVerificationDialog extends StatefulWidget {
  final Function(String name, String idCard) onSubmit;

  const _RealNameVerificationDialog({required this.onSubmit});

  @override
  State<_RealNameVerificationDialog> createState() =>
      _RealNameVerificationDialogState();
}

class _RealNameVerificationDialogState
    extends State<_RealNameVerificationDialog> {
  final _nameController = TextEditingController();
  final _idCardController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('實名認證'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '真實姓名',
                hintText: '請輸入您的真實姓名',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _idCardController,
              decoration: const InputDecoration(
                labelText: '身份證號',
                hintText: '請輸入18位身份證號',
                prefixIcon: Icon(Icons.credit_card),
              ),
              keyboardType: TextInputType.number,
              maxLength: 18,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            if (_nameController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('請輸入姓名')),
              );
              return;
            }
            if (_idCardController.text.length != 18) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('請輸入正確的身份證號')),
              );
              return;
            }
            widget.onSubmit(_nameController.text, _idCardController.text);
          },
          child: const Text('提交'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idCardController.dispose();
    super.dispose();
  }
}

/// 圖片上傳對話框
class _ImageUploadDialog extends StatefulWidget {
  final String title;
  final String description;
  final Function(File) onUpload;

  const _ImageUploadDialog({
    required this.title,
    required this.description,
    required this.onUpload,
  });

  @override
  State<_ImageUploadDialog> createState() => _ImageUploadDialogState();
}

class _ImageUploadDialogState extends State<_ImageUploadDialog> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '點擊選擇圖片',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AccessibleButton(
                    onPressed: () => _pickImage(ImageSource.camera),
                    label: '拍照',
                    icon: Icons.camera_alt,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AccessibleButton(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    label: '相冊',
                    icon: Icons.photo_library,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _selectedImage != null
              ? () => widget.onUpload(_selectedImage!)
              : null,
          child: const Text('上傳'),
        ),
      ],
    );
  }
}
