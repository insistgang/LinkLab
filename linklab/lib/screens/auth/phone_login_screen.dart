import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_auth.dart';
import '../../widgets/demo/demo_motion.dart';
import '../../widgets/demo/demo_routes.dart';
import '../../widgets/demo/demo_stage.dart';
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

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });

        pushDemoStageRoute(
          context,
          page: VerificationScreen(phone: _phoneController.text),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DemoStageLiveBuilder(
      builder: (context) {
        return DemoStageScaffold(
          title: '手机号登录',
          subtitle: '默认登录方式，保证竞赛现场不依赖第三方复杂认证',
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
                    title: '请输入您的手机号',
                    subtitle: '我们将向您的手机发送验证码。演示版使用本地稳定流程，避免现场卡在外部服务。',
                    icon: Icons.phone_android_rounded,
                    chips: [
                      DemoPill(label: '验证码登录', color: AppTheme.stageAccent),
                      DemoPill(label: '90 秒内完成', color: AppTheme.stageSuccess),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),
                DemoReveal(
                  delay: Duration(milliseconds: 80),
                  child: DemoMetricStrip(
                    items: [
                      DemoMetricItem(
                        label: '验证方式',
                        value: '本地稳定短信',
                        color: AppTheme.stageAccent,
                      ),
                      DemoMetricItem(
                        label: '输入支持',
                        value: '读屏逐位输入',
                        color: AppTheme.stageInfo,
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
                            '我们将向您的手机发送验证码',
                            style: TextStyle(
                              color: AppTheme.stageTextSecondary,
                              fontSize: AppTheme.fontSizeNormal,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingL),
                          DemoPill(
                            label: '支持读屏逐位输入',
                            icon: Icons.record_voice_over_outlined,
                            color: AppTheme.stageInfo,
                          ),
                          const SizedBox(height: AppTheme.spacingL),
                          AccessiblePhoneField(
                            controller: _phoneController,
                            autofocus: true,
                            onSubmitted: (_) => _onNext(),
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
                  child: DemoSurfaceCard(
                    color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.96),
                    child: AccessibleText(
                      '点击“下一步”即表示您同意我们的服务条款和隐私政策。',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.stageTextHint,
                        fontSize: AppTheme.fontSizeSmall,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomBar: AccessibleButton(
            label: '下一步',
            semanticLabel: '获取验证码',
            hint: '双击获取短信验证码',
            isLoading: _isLoading,
            backgroundColor: AppTheme.stageAccent,
            foregroundColor: AppTheme.stageBackground,
            onPressed: _onNext,
          ),
        );
      },
    );
  }
}
