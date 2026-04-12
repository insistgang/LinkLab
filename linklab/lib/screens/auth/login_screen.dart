import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/accessible/index.dart';
import 'phone_login_screen.dart';
import 'onboarding_screen.dart';

/// 登录选择页面
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AccessibleScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // Logo和应用名称
              Semantics(
                label: '共感LinkAble，AI驱动的视障人士智能互助平台',
                child: Column(
                  children: [
                    Icon(
                      Icons.accessibility_new,
                      size: 120,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: AppTheme.spacingL),
                    const AccessibleHeading(
                      '共感LinkAble',
                      level: 1,
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    AccessibleText(
                      'AI驱动的视障人士智能互助平台',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeNormal,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // 登录按钮
              AccessibleButton(
                label: '手机号登录',
                semanticLabel: '使用手机号和验证码登录',
                hint: '双击进入手机号登录页面',
                icon: Icons.phone_android,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PhoneLoginScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppTheme.spacingM),
              // 首次使用引导
              AccessibleButton(
                label: '首次使用',
                semanticLabel: '首次使用，查看功能引导',
                hint: '双击查看应用功能引导',
                icon: Icons.help_outline,
                backgroundColor: AppTheme.surfaceColor,
                foregroundColor: AppTheme.primaryColor,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const OnboardingScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppTheme.spacingXL),
              // 无障碍提示
              Semantics(
                label: '无障碍提示',
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.accessibility,
                            color: AppTheme.primaryColor,
                            size: AppTheme.fontSizeLarge,
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                          const AccessibleText(
                            '无障碍使用提示',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      const AccessibleText(
                        '本应用已针对屏幕阅读器优化。\n开启手机的无障碍功能即可使用语音引导。',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
            ],
          ),
        ),
      ),
    );
  }
}
