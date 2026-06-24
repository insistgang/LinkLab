import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_session_provider.dart';
import '../../widgets/demo/demo_motion.dart';
import '../../widgets/demo/linkable_icon.dart';
import '../ai_chat/demo_ai_chat_screen.dart';
import 'community_screen.dart';
import 'home_screen.dart';
import 'pending_help_screen.dart';
import 'profile_screen.dart';
import 'seeker_home_screen.dart';

enum _MainArea { landing, seeker, volunteer }

/// 主頁面（帶底部導航）
/// 根據用戶身份顯示不同導航：
/// - 求助者模式：首頁、AI助手、社羣、我的
/// - 志願者模式：首頁、待幫助列表、社羣、我的
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key, this.startInSeekerArea = false});

  final bool startInSeekerArea;

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late _MainArea _area;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _area = widget.startInSeekerArea ? _MainArea.seeker : _MainArea.landing;
  }

  @override
  Widget build(BuildContext context) {
    assert(
      !AppConfig.isCompetitionDemoOnly || AppConfig.demoMode,
      'AGENTS.md §4.2：競賽版默認底部導航只允許暴露 Demo 主線入口',
    );

    final session = ref.watch(appSessionProvider);

    // 根據身份決定導航項和頁面
    final screens = _buildScreens(_area);
    final navItems = _buildNavItems(_area);

    // 確保當前索引不越界
    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    return KeyedSubtree(
      key: ValueKey(session.stageMode),
      child: Scaffold(
        backgroundColor: AppTheme.stageBackground,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(
            key: ValueKey('main-tab-${_area.name}-$_currentIndex'),
            child: screens[_currentIndex],
          ),
        ),
        bottomNavigationBar: _area == _MainArea.landing
            ? null
            : SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Semantics(
                    label: '底部導航欄',
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: AppTheme.stageCardDecoration(
                        color: AppTheme.stageSurfaceStrong.withValues(
                          alpha: 0.94,
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedAlign(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                            alignment: _navIndicatorAlignment(navItems.length),
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
                            children: List.generate(navItems.length, (index) {
                              final item = navItems[index];
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
      ),
    );
  }

  /// 根據身份構建頁面列表
  List<Widget> _buildScreens(_MainArea area) {
    switch (area) {
      case _MainArea.landing:
        return [
          HomeScreen(
            onSeekerSelected: () => _enterArea(_MainArea.seeker),
            onVolunteerSelected: () => _enterArea(_MainArea.volunteer),
          ),
        ];
      case _MainArea.volunteer:
        // 志願者模式：待幫助列表、AI 助手、社羣、我的
        return const [
          PendingHelpScreen(),
          DemoAIChatScreen(
            embeddedInTab: true,
            quickPrompts: ['布洛芬是什麼藥？', '藥盒有效期怎麼看？', '我需要真人志願者幫助'],
          ),
          CommunityScreen(),
          ProfileScreen(mode: ProfileScreenMode.volunteer),
        ];
      case _MainArea.seeker:
        // 求助者模式：首頁、AI 助手、社羣、我的
        return const [
          SeekerHomeScreen(),
          DemoAIChatScreen(
            embeddedInTab: true,
            quickPrompts: ['布洛芬是什麼藥？', '藥盒有效期怎麼看？', '我需要真人志願者幫助'],
          ),
          CommunityScreen(),
          ProfileScreen(mode: ProfileScreenMode.seeker),
        ];
    }
  }

  /// 根據當前應用區構建導航項
  List<_NavItem> _buildNavItems(_MainArea area) {
    switch (area) {
      case _MainArea.landing:
        return const [];
      case _MainArea.volunteer:
        return const [
          _NavItem(
            label: '待幫助',
            icon: Icons.handshake_outlined,
            activeIcon: Icons.handshake,
            semanticLabel: '查看待幫助列表',
          ),
          _NavItem(
            label: 'AI助手',
            icon: Icons.smart_toy_outlined,
            activeIcon: Icons.smart_toy,
            semanticLabel: '打開AI智能助手',
          ),
          _NavItem(
            label: '社羣',
            icon: Icons.forum_outlined,
            activeIcon: Icons.forum,
            semanticLabel: '查看社羣精選故事',
          ),
          _NavItem(
            label: '我的',
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            semanticLabel: '查看個人中心',
          ),
        ];
      case _MainArea.seeker:
        return const [
          _NavItem(
            label: '首頁',
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            semanticLabel: '查看求助者首頁',
          ),
          _NavItem(
            label: 'AI助手',
            icon: Icons.smart_toy_outlined,
            activeIcon: Icons.smart_toy,
            semanticLabel: '打開AI智能助手',
          ),
          _NavItem(
            label: '社羣',
            icon: Icons.forum_outlined,
            activeIcon: Icons.forum,
            semanticLabel: '查看社羣精選故事',
          ),
          _NavItem(
            label: '我的',
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            semanticLabel: '查看個人中心',
          ),
        ];
    }
  }

  void _enterArea(_MainArea area) {
    setState(() {
      _area = area;
      _currentIndex = 0;
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Alignment _navIndicatorAlignment(int itemCount) {
    final x = itemCount <= 1
        ? 0.0
        : -1.0 + (2.0 * _currentIndex / (itemCount - 1));
    return Alignment(x, 0);
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String? semanticLabel;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.semanticLabel,
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
      label: item.semanticLabel ?? item.label,
      hint: '雙擊切換到${item.label}',
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
                  child: LinkableMaterialIcon(
                    icon: isActive ? item.activeIcon : item.icon,
                    size: isActive ? 34 : 30,
                    color: isActive
                        ? Colors.white
                        : AppTheme.stageTextSecondary,
                    semanticLabel: item.semanticLabel ?? item.label,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
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
