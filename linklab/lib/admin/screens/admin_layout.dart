import 'package:flutter/material.dart';
import '../../widgets/brand/app_logo.dart';
import '../services/admin_auth_service.dart';
import 'admin_login_screen.dart';
import 'dashboard_page.dart';
import 'user_management_page.dart';
import 'content_management_page.dart';
import 'report_handling_page.dart';
import 'statistics_page.dart';

/// 管理後臺佈局
class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;
  final _authService = AdminAuthService();

  final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.dashboard,
      label: '數據看板',
      page: const DashboardPage(),
      permissions: [],
    ),
    _NavItem(
      icon: Icons.people,
      label: '用戶管理',
      page: const UserManagementPage(),
      permissions: ['users.view'],
    ),
    _NavItem(
      icon: Icons.article,
      label: '內容管理',
      page: const ContentManagementPage(),
      permissions: ['content.view'],
    ),
    _NavItem(
      icon: Icons.report_problem,
      label: '舉報處理',
      page: const ReportHandlingPage(),
      permissions: ['reports.view'],
    ),
    _NavItem(
      icon: Icons.analytics,
      label: '數據統計',
      page: const StatisticsPage(),
      permissions: ['stats.view'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _authService.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted && !_authService.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認退出'),
        content: const Text('確定要退出登錄嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('退出'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.logout();
    }
  }

  List<_NavItem> get _visibleNavItems {
    return _navItems.where((item) {
      if (item.permissions.isEmpty) return true;
      return _authService.hasAnyPermission(item.permissions);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _visibleNavItems;
    final currentPage = _selectedIndex < visibleItems.length
        ? visibleItems[_selectedIndex].page
        : visibleItems.first.page;

    return Scaffold(
      body: Row(
        children: [
          // 側邊導航欄
          NavigationRail(
            extended: MediaQuery.of(context).size.width > 1200,
            minExtendedWidth: 200,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            leading: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const AppLogo(size: 42, borderRadius: 10),
                  const SizedBox(height: 8),
                  if (MediaQuery.of(context).size.width > 1200)
                    Text(
                      'LinkLab',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: '退出登錄',
            ),
            destinations: visibleItems
                .map(
                  (item) => NavigationRailDestination(
                    icon: Icon(item.icon),
                    label: Text(item.label),
                  ),
                )
                .toList(),
          ),

          // 分隔線
          const VerticalDivider(thickness: 1, width: 1),

          // 主內容區
          Expanded(
            child: Column(
              children: [
                // 頂部欄
                _buildAppBar(),

                // 頁面內容
                Expanded(child: currentPage),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          Text(
            _visibleNavItems[_selectedIndex].label,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          // 管理員信息
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  _authService.currentUser?.username
                          .substring(0, 1)
                          .toUpperCase() ??
                      'A',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _authService.currentUser?.username ?? '管理員',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _getRoleName(_authService.currentUser?.role),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getRoleName(String? role) {
    switch (role) {
      case 'super_admin':
        return '超級管理員';
      case 'admin':
        return '管理員';
      case 'operator':
        return '操作員';
      case 'viewer':
        return '查看者';
      default:
        return '管理員';
    }
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Widget page;
  final List<String> permissions;

  _NavItem({
    required this.icon,
    required this.label,
    required this.page,
    required this.permissions,
  });
}
