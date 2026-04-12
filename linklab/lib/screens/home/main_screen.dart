import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'home_screen.dart';
import 'ai_chat_screen.dart';
import 'community_screen.dart';
import 'profile_screen.dart';

/// 主页面（带底部导航）
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    AIChatScreen(),
    CommunityScreen(),
    ProfileScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(
      label: '首页',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
    ),
    _NavItem(
      label: 'AI助手',
      icon: Icons.smart_toy_outlined,
      activeIcon: Icons.smart_toy,
    ),
    _NavItem(
      label: '社群',
      icon: Icons.people_outline,
      activeIcon: Icons.people,
    ),
    _NavItem(
      label: '我的',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
    ),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Semantics(
        label: '底部导航栏',
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          items: _navItems.map((item) {
            return BottomNavigationBarItem(
              icon: Semantics(
                excludeSemantics: true,
                child: Icon(item.icon),
              ),
              activeIcon: Semantics(
                excludeSemantics: true,
                child: Icon(item.activeIcon),
              ),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
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
