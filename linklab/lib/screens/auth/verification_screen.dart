import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/app_session_service.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_auth.dart';
import '../../widgets/demo/demo_motion.dart';
import '../../widgets/demo/demo_overlays.dart';
import '../../widgets/demo/demo_routes.dart';
import '../../widgets/demo/demo_stage.dart';
import '../home/main_screen.dart';
import 'identity_select_screen.dart';

/// 验证码页面
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key, required this.phone});

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

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });

        final session = AppSessionService.instance;
        if (session.userProfile != null) {
          session.loginExistingUser(widget.phone).then((_) {
            if (!mounted) return;
            pushAndRemoveUntilDemoStageRoute(
              context,
              page: const MainScreen(),
              predicate: (route) => false,
            );
          });
          return;
        }

        pushAndRemoveUntilDemoStageRoute(
          context,
          page: IdentitySelectScreen(phone: widget.phone),
          predicate: (route) => false,
        );
      });
    }
  }

  void _onResendCode() {
    showDemoStageSnackBar(
      context,
      message: '验证码已发送',
      icon: Icons.sms_outlined,
      accentColor: AppTheme.stageInfo,
    );
  }

  void _showVerificationHelp() {
    showDemoStageDialog<void>(
      context,
      builder: (dialogContext) => DemoDialog(
        title: '验证码说明',
        icon: Icons.help_outline_rounded,
        accentColor: AppTheme.stageInfo,
        description:
            '竞赛演示版使用本地稳定验证流程，不依赖真实短信服务。若现场未收到短信，可直接点击“重新发送”，系统会继续按演示路径完成验证。',
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.stageAccent,
              foregroundColor: AppTheme.stageBackground,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('我知道了'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maskedPhone =
        '${widget.phone.substring(0, 3)}****${widget.phone.substring(7)}';

    return DemoStageScaffold(
      title: '输入验证码',
      subtitle: '验证码验证通过后，继续完成身份与偏好设置',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingL,
            AppTheme.spacingL,
            AppTheme.spacingL,
            120,
          ),
          children: [
            DemoReveal(
              child: DemoAuthBanner(
                title: '输入并验证验证码',
                subtitle: '请输入 6 位验证码。演示版保持流程稳定，验证成功后会继续完成首次资料设置。',
                icon: Icons.mark_email_read_outlined,
                chips: [
                  DemoPill(label: '6 位数字', color: AppTheme.stageAccent),
                  DemoPill(label: '可重新发送', color: AppTheme.stageInfo),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            DemoReveal(
              delay: const Duration(milliseconds: 80),
              child: DemoMetricStrip(
                items: [
                  DemoMetricItem(
                    label: '手机号',
                    value: maskedPhone,
                    color: AppTheme.stageInfo,
                  ),
                  DemoMetricItem(
                    label: '下一步',
                    value: '身份与偏好',
                    color: AppTheme.stageAccent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            DemoReveal(
              delay: const Duration(milliseconds: 140),
              child: DemoSurfaceCard(
                child: DemoAuthFormTheme(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AccessibleText(
                        '验证码已发送至 $maskedPhone',
                        style: TextStyle(
                          color: AppTheme.stageTextPrimary,
                          fontSize: AppTheme.fontSizeLarge,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      AccessibleText(
                        '请输入6位验证码',
                        style: TextStyle(
                          color: AppTheme.stageTextSecondary,
                          fontSize: AppTheme.fontSizeNormal,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingL),
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
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            DemoReveal(
              delay: const Duration(milliseconds: 190),
              child: Center(
                child: TextButton(
                  onPressed: _showVerificationHelp,
                  child: Text(
                    '收不到验证码？',
                    style: TextStyle(color: AppTheme.stageAccent),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomBar: AccessibleButton(
        label: '验证',
        semanticLabel: '验证验证码',
        hint: '双击完成验证并登录',
        isLoading: _isLoading,
        backgroundColor: AppTheme.stageAccent,
        foregroundColor: AppTheme.stageBackground,
        onPressed: _onVerify,
      ),
    );
  }
}
