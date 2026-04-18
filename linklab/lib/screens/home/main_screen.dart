import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/demo/demo_motion.dart';
import 'home_screen.dart';
import 'ai_chat_screen.dart';
import 'profile_screen.dart';

/// 主页面（带底部导航）
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // AGENTS.md: 竞赛版默认导航只保留 MVP 主线入口。
  // 社群/社区模块已降级，不再进入默认底部导航。
  final List<Widget> _screens = const [
    HomeScreen(),
    AIChatScreen(),
    ProfileScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(label: '首页', icon: Icons.home_outlined, activeIcon: Icons.home),
    _NavItem(
      label: 'AI助手',
      icon: Icons.smart_toy_outlined,
      activeIcon: Icons.smart_toy,
    ),
    _NavItem(label: '我的', icon: Icons.person_outline, activeIcon: Icons.person),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(
      !AppConfig.isCompetitionDemoOnly || AppConfig.demoMode,
      'AGENTS.md §4.2：竞赛版默认底部导航只允许暴露 Demo 主线入口',
    );

    return Scaffold(
      backgroundColor: AppTheme.stageBackground,
      body: Stack(
        fit: StackFit.expand,
        children: List.generate(_screens.length, (index) {
          final isActive = index == _currentIndex;
          final isBeforeActive = index < _currentIndex;

          return IgnorePointer(
            ignoring: !isActive,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              offset: isActive
                  ? Offset.zero
                  : Offset(isBeforeActive ? -0.02 : 0.02, 0),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                opacity: isActive ? 1 : 0,
                child: KeyedSubtree(
                  key: ValueKey('main-tab-$index'),
                  child: _screens[index],
                ),
              ),
            ),
          );
        }),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Semantics(
            label: '底部导航栏',
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: AppTheme.stageCardDecoration(
                color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    alignment: _navIndicatorAlignment(),
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: AppTheme.stageAccentGradient,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(_navItems.length, (index) {
                      final item = _navItems[index];
                      final isActive = index == _currentIndex;
                      return Expanded(
                        child: _DemoNavButton(
                          item: item,
                          isActive: isActive,
                          onTap: () => _onTabTapped(index),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Alignment _navIndicatorAlignment() {
    switch (_currentIndex) {
      case 0:
        return Alignment.centerLeft;
      case 1:
        return Alignment.center;
      case 2:
        return Alignment.centerRight;
      default:
        return Alignment.center;
    }
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class _DemoNavButton extends StatelessWidget {
  const _DemoNavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isActive,
      label: item.label,
      hint: '双击切换到${item.label}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            gradient: isActive ? AppTheme.stageAccentGradient : null,
            color: isActive
                ? null
                : AppTheme.stageSurface.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isActive
                  ? Colors.transparent
                  : AppTheme.stageBorder.withValues(alpha: 0.36),
            ),
          ),
          child: DemoReveal(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: isActive ? 38 : 32,
                  height: isActive ? 38 : 32,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withValues(alpha: 0.18)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isActive ? item.activeIcon : item.icon,
                    color: isActive
                        ? AppTheme.stageBackground
                        : AppTheme.stageTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    color: isActive
                        ? AppTheme.stageBackground
                        : AppTheme.stageTextSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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
