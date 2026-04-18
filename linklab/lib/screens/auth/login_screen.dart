import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_auth.dart';
import '../../widgets/demo/demo_motion.dart';
import '../../widgets/demo/demo_routes.dart';
import '../../widgets/demo/demo_stage.dart';
import 'onboarding_screen.dart';
import 'phone_login_screen.dart';

/// 登录选择页面
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DemoStageScaffold(
      title: '欢迎使用',
      subtitle: '竞赛版默认从手机号登录或首次引导进入',
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
              chips: [
                DemoPill(label: 'Demo 主线锁定', color: AppTheme.stageAccent),
                DemoPill(label: '无障碍优先', color: AppTheme.stageSuccess),
              ],
            ),
          ),
          SizedBox(height: AppTheme.spacingL),
          DemoReveal(
            delay: Duration(milliseconds: 90),
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
                  SizedBox(height: AppTheme.spacingM),
                  _BenefitRow(
                    icon: Icons.smart_toy_outlined,
                    title: 'AI 快速响应',
                    subtitle: '适合文字识别、场景描述、颜色识别等高频需求。',
                  ),
                  SizedBox(height: AppTheme.spacingM),
                  _BenefitRow(
                    icon: Icons.hearing_outlined,
                    title: '读屏友好',
                    subtitle: '高对比、明确语义和大触控目标贯穿整个主流程。',
                  ),
                  SizedBox(height: AppTheme.spacingM),
                  _BenefitRow(
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
            label: '手机号登录',
            semanticLabel: '使用手机号和验证码登录',
            hint: '双击进入手机号登录页面',
            icon: Icons.phone_android_rounded,
            backgroundColor: AppTheme.stageAccent,
            foregroundColor: AppTheme.stageBackground,
            onPressed: () {
              pushDemoStageRoute(context, page: const PhoneLoginScreen());
            },
          ),
          const SizedBox(height: AppTheme.spacingM),
          AccessibleButton(
            label: '首次使用',
            semanticLabel: '首次使用，查看功能引导',
            hint: '双击查看应用功能引导',
            icon: Icons.arrow_outward_rounded,
            backgroundColor: AppTheme.stageSurfaceStrong,
            foregroundColor: AppTheme.stageTextPrimary,
            onPressed: () {
              pushDemoStageRoute(context, page: const OnboardingScreen());
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
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.stageAccent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppTheme.stageAccent),
        ),
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
