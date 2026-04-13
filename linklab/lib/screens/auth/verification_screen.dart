import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/app_session_service.dart';
import '../../widgets/accessible/index.dart';
import 'identity_select_screen.dart';
import '../home/main_screen.dart';

/// 验证码页面
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({
    super.key,
    required this.phone,
  });

  final String phone;

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _onVerify() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorText = null;
      });

      // TODO: 调用验证验证码API
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          final session = AppSessionService.instance;
          if (session.userProfile != null) {
            session.loginExistingUser(widget.phone).then((_) {
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const MainScreen(),
                ),
                (route) => false,
              );
            });
            return;
          }

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => IdentitySelectScreen(phone: widget.phone),
            ),
            (route) => false,
          );
        }
      });
    }
  }

  void _onResendCode() {
    // TODO: 重新发送验证码
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('验证码已发送'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AccessibleScaffold(
      title: '输入验证码',
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppTheme.spacingXL),
                // 说明文字
                AccessibleText(
                  '验证码已发送至 ${widget.phone.substring(0, 3)}****${widget.phone.substring(7)}',
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                const AccessibleText(
                  '请输入6位验证码',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeNormal,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXXL),
                // 验证码输入
                AccessibleCodeField(
                  controller: _codeController,
                  autofocus: true,
                  onSubmitted: (_) => _onVerify(),
                  onSendCode: _onResendCode,
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: AppTheme.spacingS),
                  AccessibleErrorText(_errorText!),
                ],
                const Spacer(),
                // 验证按钮
                AccessibleButton(
                  label: '验证',
                  semanticLabel: '验证验证码',
                  hint: '双击完成验证并登录',
                  isLoading: _isLoading,
                  onPressed: _onVerify,
                ),
                const SizedBox(height: AppTheme.spacingL),
                // 遇到问题
                Center(
                  child: TextButton(
                    onPressed: () {
                      // TODO: 显示帮助对话框
                    },
                    child: const AccessibleText(
                      '收不到验证码？',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeNormal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
