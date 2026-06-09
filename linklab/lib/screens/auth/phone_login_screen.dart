import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_auth.dart';
import '../../widgets/demo/demo_motion.dart';
import '../../widgets/demo/demo_routes.dart';
import '../../widgets/demo/demo_stage.dart';
import 'verification_screen.dart';

/// 手機號登錄頁面
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
      if (AppConfig.isRealMode) {
        setState(() {
          _errorText = 'RealMode Phase-2 暫未接入真實短信，請使用郵箱登錄。';
        });
        return;
      }

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
          title: '手機號登錄',
          subtitle: AppConfig.isRealMode
              ? '手機號界面保留，本階段不接真實短信'
              : 'DemoMode 使用本地穩定驗證碼流程',
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
                    title: '請輸入您的手機號',
                    subtitle: AppConfig.isRealMode
                        ? '真實短信需要單獨配置短信服務商。本階段請返回使用郵箱登錄。'
                        : '演示版使用本地穩定流程，避免現場卡在外部服務。',
                    icon: Icons.phone_android_rounded,
                    chips: [
                      DemoPill(label: '驗證碼登錄', color: AppTheme.stageAccent),
                      DemoPill(label: '90 秒內完成', color: AppTheme.stageSuccess),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),
                DemoReveal(
                  delay: const Duration(milliseconds: 80),
                  child: DemoMetricStrip(
                    items: [
                      DemoMetricItem(
                        label: '驗證方式',
                        value: AppConfig.isRealMode ? '暫未接入短信' : '本地穩定短信',
                        color: AppTheme.stageAccent,
                      ),
                      DemoMetricItem(
                        label: '輸入支持',
                        value: '讀屏逐位輸入',
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
                            '我們將向您的手機發送驗證碼',
                            style: TextStyle(
                              color: AppTheme.stageTextSecondary,
                              fontSize: AppTheme.fontSizeNormal,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingL),
                          DemoPill(
                            label: '支持讀屏逐位輸入',
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
                      '點擊“下一步”即表示您同意我們的服務條款和隱私政策。',
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
            semanticLabel: '獲取驗證碼',
            hint: '雙擊獲取短信驗證碼',
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
