import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_auth.dart';
import '../../widgets/demo/demo_motion.dart';
import '../../widgets/demo/demo_routes.dart';
import '../../widgets/demo/demo_stage.dart';
import 'email_login_screen.dart';
import 'onboarding_screen.dart';
import 'phone_login_screen.dart';

/// 登录选择页面
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isRealMode = AppConfig.isRealMode;

    return DemoStageLiveBuilder(
      builder: (context) {
        return DemoStageScaffold(
          title: '欢迎使用',
          subtitle: isRealMode
              ? 'RealMode 使用 Supabase Auth 登录'
              : 'DemoMode 使用本地登录流程',
          showBackButton: false,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingL,
              AppTheme.spacingL,
              AppTheme.spacingL,
              120,
            ),
            children: [
              DemoReveal(
                child: DemoAuthBanner(
                  title: '共感LinkAble',
                  subtitle: 'AI 驱动的无障碍互助平台。先解决 80% 标准化问题，再把复杂场景交给真人。',
                  icon: Icons.accessibility_new_rounded,
                  useLogo: true,
                  chips: [
                    DemoPill(
                      label: isRealMode ? 'RealMode' : 'DemoMode',
                      color: AppTheme.stageAccent,
                    ),
                    DemoPill(label: '无障碍优先', color: AppTheme.stageSuccess),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              DemoReveal(
                delay: const Duration(milliseconds: 90),
                child: DemoSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AccessibleText(
                        '为什么这样设计',
                        style: TextStyle(
                          color: AppTheme.stageTextPrimary,
                          fontSize: AppTheme.fontSizeNormal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      const _BenefitRow(
                        icon: Icons.smart_toy_outlined,
                        title: 'AI 快速响应',
                        subtitle: '适合文字识别、场景描述、颜色识别等高频需求。',
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      const _BenefitRow(
                        icon: Icons.hearing_outlined,
                        title: '读屏友好',
                        subtitle: '高对比、明确语义和大触控目标贯穿整个主流程。',
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      const _BenefitRow(
                        icon: Icons.volunteer_activism_outlined,
                        title: '真人可兜底',
                        subtitle: '复杂需求随时转志愿者，不让 AI 失败后无路可走。',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AccessibleButton(
                label: isRealMode ? '邮箱登录' : '手机号登录',
                semanticLabel: isRealMode ? '使用邮箱和密码登录' : '使用手机号和验证码登录',
                hint: isRealMode ? '双击进入邮箱登录页面' : '双击进入手机号登录页面',
                icon: isRealMode
                    ? Icons.alternate_email_rounded
                    : Icons.phone_android_rounded,
                backgroundColor: AppTheme.stageAccent,
                foregroundColor: AppTheme.stageBackground,
                onPressed: () {
                  pushDemoStageRoute(
                    context,
                    page: isRealMode
                        ? const EmailLoginScreen()
                        : const PhoneLoginScreen(),
                  );
                },
              ),
              const SizedBox(height: AppTheme.spacingM),
              AccessibleButton(
                label: isRealMode ? '手机号界面保留' : '首次使用',
                semanticLabel: isRealMode
                    ? '手机号验证码界面保留，本阶段不接真实短信'
                    : '首次使用，查看功能引导',
                hint: isRealMode ? '双击查看保留的手机号界面' : '双击查看应用功能引导',
                icon: isRealMode
                    ? Icons.phone_android_rounded
                    : Icons.arrow_outward_rounded,
                backgroundColor: AppTheme.stageSurfaceStrong,
                foregroundColor: AppTheme.stageTextPrimary,
                onPressed: () {
                  pushDemoStageRoute(
                    context,
                    page: isRealMode
                        ? const PhoneLoginScreen()
                        : const OnboardingScreen(),
                  );
                },
              ),
              const SizedBox(height: AppTheme.spacingM),
              AccessibleText(
                '本应用已针对屏幕阅读器优化。开启手机无障碍功能即可使用语音引导。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.stageTextHint,
                  fontSize: AppTheme.fontSizeSmall,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DemoGlassIconBadge(icon: icon, size: 44, iconSize: 22),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AccessibleText(
                title,
                style: TextStyle(
                  color: AppTheme.stageTextPrimary,
                  fontSize: AppTheme.fontSizeSmall,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXS),
              AccessibleText(
                subtitle,
                style: TextStyle(
                  color: AppTheme.stageTextSecondary,
                  fontSize: AppTheme.fontSizeSmall,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
