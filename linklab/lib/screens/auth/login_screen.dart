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

/// 登錄選擇頁面
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isRealMode = AppConfig.isRealMode;

    return DemoStageLiveBuilder(
      builder: (context) {
        return DemoStageScaffold(
          title: '歡迎使用',
          subtitle: isRealMode
              ? 'RealMode 使用 Supabase Auth 登錄'
              : 'DemoMode 使用本地登錄流程',
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
                  subtitle: 'AI 驅動的無障礙互助平臺。先解決 80% 標準化問題，再把複雜場景交給真人。',
                  icon: Icons.accessibility_new_rounded,
                  useLogo: true,
                  chips: [
                    DemoPill(
                      label: isRealMode ? 'RealMode' : 'DemoMode',
                      color: AppTheme.stageAccent,
                    ),
                    DemoPill(label: '無障礙優先', color: AppTheme.stageSuccess),
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
                        '爲什麼這樣設計',
                        style: TextStyle(
                          color: AppTheme.stageTextPrimary,
                          fontSize: AppTheme.fontSizeNormal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      const _BenefitRow(
                        icon: Icons.smart_toy_outlined,
                        title: 'AI 快速響應',
                        subtitle: '適合文字識別、場景描述、顏色識別等高頻需求。',
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      const _BenefitRow(
                        icon: Icons.hearing_outlined,
                        title: '讀屏友好',
                        subtitle: '高對比、明確語義和大觸控目標貫穿整個主流程。',
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      const _BenefitRow(
                        icon: Icons.volunteer_activism_outlined,
                        title: '真人可兜底',
                        subtitle: '複雜需求隨時轉志願者，不讓 AI 失敗後無路可走。',
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
                label: isRealMode ? '郵箱登錄' : '手機號登錄',
                semanticLabel: isRealMode ? '使用郵箱和密碼登錄' : '使用手機號和驗證碼登錄',
                hint: isRealMode ? '雙擊進入郵箱登錄頁面' : '雙擊進入手機號登錄頁面',
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
              if (isRealMode)
                AccessibleButton(
                  label: '手機號界面保留',
                  semanticLabel: '手機號驗證碼界面保留，本階段不接真實短信',
                  hint: '雙擊查看保留的手機號界面',
                  icon: Icons.phone_android_rounded,
                  backgroundColor: AppTheme.stageSurfaceStrong,
                  foregroundColor: AppTheme.stageTextPrimary,
                  onPressed: () {
                    pushDemoStageRoute(context, page: const PhoneLoginScreen());
                  },
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale = MediaQuery.textScalerOf(context).scale(1);
                    final useVerticalLayout =
                        constraints.maxWidth < 360 || textScale > 1.35;
                    final emailButton = _SecondaryLoginButton(
                      label: '郵箱登錄',
                      semanticLabel: '使用郵箱和密碼登錄',
                      hint: '雙擊進入郵箱登錄頁面',
                      icon: Icons.alternate_email_rounded,
                      onPressed: () {
                        pushDemoStageRoute(
                          context,
                          page: const EmailLoginScreen(),
                        );
                      },
                    );
                    final onboardingButton = _SecondaryLoginButton(
                      label: '首次使用',
                      semanticLabel: '首次使用，查看功能引導',
                      hint: '雙擊查看應用功能引導',
                      icon: Icons.arrow_outward_rounded,
                      onPressed: () {
                        pushDemoStageRoute(
                          context,
                          page: const OnboardingScreen(),
                        );
                      },
                    );

                    if (useVerticalLayout) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          emailButton,
                          const SizedBox(height: AppTheme.spacingS),
                          onboardingButton,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: emailButton),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(child: onboardingButton),
                      ],
                    );
                  },
                ),
              const SizedBox(height: AppTheme.spacingM),
              AccessibleText(
                '本應用已針對屏幕閱讀器優化。開啓手機無障礙功能即可使用語音引導。',
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

class _SecondaryLoginButton extends StatelessWidget {
  const _SecondaryLoginButton({
    required this.label,
    required this.semanticLabel,
    required this.hint,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final String semanticLabel;
  final String hint;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      hint: hint,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.stageTextPrimary,
          backgroundColor: AppTheme.stageSurfaceStrong,
          side: BorderSide(color: AppTheme.stageBorder),
          minimumSize: const Size(double.infinity, 56),
          textStyle: const TextStyle(
            fontSize: AppTheme.fontSizeNormal,
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
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
