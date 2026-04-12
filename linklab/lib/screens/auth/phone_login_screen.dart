import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/accessible/index.dart';
import 'verification_screen.dart';

/// 手机号登录页面
class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorText = null;
      });

      // TODO: 调用发送验证码API
      // 模拟网络请求
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => VerificationScreen(
                phone: _phoneController.text,
              ),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AccessibleScaffold(
      title: '手机号登录',
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
                const AccessibleText(
                  '请输入您的手机号',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                const AccessibleText(
                  '我们将向您的手机发送验证码',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeNormal,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXXL),
                // 手机号输入
                AccessiblePhoneField(
                  controller: _phoneController,
                  autofocus: true,
                  onSubmitted: (_) => _onNext(),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: AppTheme.spacingS),
                  AccessibleErrorText(_errorText!),
                ],
                const Spacer(),
                // 下一步按钮
                AccessibleButton(
                  label: '下一步',
                  semanticLabel: '获取验证码',
                  hint: '双击获取短信验证码',
                  isLoading: _isLoading,
                  onPressed: _onNext,
                ),
                const SizedBox(height: AppTheme.spacingL),
                // 隐私说明
                Semantics(
                  label: '隐私说明',
                  child: const AccessibleText(
                    '点击"下一步"即表示您同意我们的服务条款和隐私政策',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.textHint,
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
