import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_auth.dart';
import '../../widgets/demo/demo_motion.dart';
import '../../widgets/demo/demo_routes.dart';
import '../../widgets/demo/demo_stage.dart';
import 'phone_login_screen.dart';

/// 首次引導頁面
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      title: '歡迎來到共感LinkAble',
      description: 'AI 驅動的無障礙互助平臺，讓標準化需求先被快速解決。',
      icon: Icons.accessibility_new_rounded,
      highlights: ['AI 先響應', '真人可兜底'],
    ),
    _OnboardingPage(
      title: 'AI智能助手',
      description: '文字識別、場景描述、顏色識別等高頻場景，都可以在手機端快速完成。',
      icon: Icons.smart_toy_outlined,
      highlights: ['OCR', '場景描述', '顏色識別'],
    ),
    _OnboardingPage(
      title: '志願者互助',
      description: '遇到複雜問題時，一鍵轉接志願者，保持狀態清晰、流程可回看。',
      icon: Icons.volunteer_activism_outlined,
      highlights: ['30 秒內嘗試匹配', '語音協助'],
    ),
    _OnboardingPage(
      title: '緊急求助',
      description: 'SOS 支持 10 秒誤觸撤銷窗口，並展示廣播、聯繫人通知與演示響應。',
      icon: Icons.emergency_outlined,
      highlights: ['10 秒撤銷', 'Mock 廣播'],
    ),
  ];

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      replaceWithDemoStageRoute(context, page: const PhoneLoginScreen());
    }
  }

  void _onSkip() {
    replaceWithDemoStageRoute(context, page: const PhoneLoginScreen());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoStageLiveBuilder(
      builder: (context) {
        return DemoStageScaffold(
          title: '產品引導',
          subtitle: '用 4 頁解釋清楚競賽版真正能做什麼',
          showBackButton: false,
          actions: [
            TextButton(
              onPressed: _onSkip,
              child: Text(
                '跳過',
                style: TextStyle(color: AppTheme.stageTextSecondary),
              ),
            ),
          ],
          body: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.spacingL,
                        AppTheme.spacingL,
                        AppTheme.spacingL,
                        AppTheme.spacingL,
                      ),
                      child: Column(
                        children: [
                          DemoReveal(
                            key: ValueKey('onboarding-banner-$index'),
                            child: DemoAuthBanner(
                              title: page.title,
                              subtitle: page.description,
                              icon: page.icon,
                              useLogo: index == 0,
                              chips: page.highlights
                                  .map(
                                    (item) => DemoPill(
                                      label: item,
                                      color: AppTheme.stageAccent,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingL),
                          Expanded(
                            child: DemoReveal(
                              key: ValueKey('onboarding-hero-$index'),
                              delay: const Duration(milliseconds: 90),
                              child: Center(
                                child: Container(
                                  width: 230,
                                  height: 230,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.stageAccent.withValues(
                                      alpha: 0.08,
                                    ),
                                    border: Border.all(
                                      color: AppTheme.stageAccent.withValues(
                                        alpha: 0.18,
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 140,
                                      height: 140,
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.stageAccentGradient,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        page.icon,
                                        size: 64,
                                        color: AppTheme.stageBackground,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingL,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => Semantics(
                      label: '第${index + 1}頁，共${_pages.length}頁',
                      selected: index == _currentPage,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        width: index == _currentPage ? 28 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingXS,
                        ),
                        decoration: BoxDecoration(
                          gradient: index == _currentPage
                              ? AppTheme.stageAccentGradient
                              : null,
                          color: index == _currentPage
                              ? null
                              : AppTheme.stageBorder,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
            ],
          ),
          bottomBar: AccessibleButton(
            label: _currentPage == _pages.length - 1 ? '開始使用' : '下一步',
            semanticLabel: _currentPage == _pages.length - 1 ? '開始使用' : '下一頁',
            backgroundColor: AppTheme.stageAccent,
            foregroundColor: AppTheme.stageBackground,
            onPressed: _onNext,
          ),
        );
      },
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.highlights,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<String> highlights;
}
