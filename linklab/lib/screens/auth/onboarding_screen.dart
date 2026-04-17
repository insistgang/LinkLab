import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/accessible/index.dart';
import 'phone_login_screen.dart';

/// 首次引导页面
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
      title: '欢迎来到共感LinkAble',
      description: 'AI驱动的视障人士智能互助平台，让科技成为您的眼睛',
      icon: Icons.accessibility_new,
    ),
    _OnboardingPage(
      title: 'AI智能助手',
      description: '文字识别、场景描述、颜色识别，AI助手随时为您解答',
      icon: Icons.smart_toy,
    ),
    _OnboardingPage(
      title: '志愿者互助',
      description: '遇到复杂问题？一键呼叫志愿者，真人语音实时帮助',
      icon: Icons.people,
    ),
    _OnboardingPage(
      title: '紧急求助',
      description: '紧急情况下，快速触发SOS，通知附近志愿者和紧急联系人',
      icon: Icons.emergency,
    ),
  ];

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const PhoneLoginScreen()),
      );
    }
  }

  void _onSkip() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const PhoneLoginScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AccessibleScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 跳过按钮
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: TextButton(
                  onPressed: _onSkip,
                  child: const AccessibleText(
                    '跳过',
                    style: TextStyle(fontSize: AppTheme.fontSizeNormal),
                  ),
                ),
              ),
            ),
            // 页面内容
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
                    padding: const EdgeInsets.all(AppTheme.spacingXL),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 图标
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            page.icon,
                            size: 80,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXXL),
                        // 标题
                        AccessibleHeading(
                          page.title,
                          level: 2,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        // 描述
                        AccessibleText(
                          page.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: AppTheme.fontSizeNormal,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // 指示器
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Semantics(
                  label: '第${index + 1}页，共${_pages.length}页',
                  selected: index == _currentPage,
                  child: Container(
                    width: index == _currentPage ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: index == _currentPage
                          ? AppTheme.primaryColor
                          : AppTheme.dividerColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXL),
            // 下一步按钮
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: AccessibleButton(
                label: _currentPage == _pages.length - 1 ? '开始使用' : '下一步',
                semanticLabel: _currentPage == _pages.length - 1
                    ? '开始使用'
                    : '下一页',
                onPressed: _onNext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final String title;
  final String description;
  final IconData icon;

  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
  });
}
