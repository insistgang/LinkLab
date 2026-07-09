import 'package:flutter/material.dart';
import '../constants/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('系统设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Account Settings
          _buildSection(
            title: '账户设置',
            children: [
              _buildListTile(
                icon: Icons.person_outline,
                title: '个人信息',
                subtitle: '修改您的个人信息',
                onTap: () {},
              ),
              _buildListTile(
                icon: Icons.lock_outline,
                title: '修改密码',
                subtitle: '定期更换密码保护账户安全',
                onTap: () {},
              ),
              _buildListTile(
                icon: Icons.notifications_outlined,
                title: '通知设置',
                subtitle: '配置系统通知方式',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          // System Settings
          _buildSection(
            title: '系统设置',
            children: [
              _buildListTile(
                icon: Icons.security_outlined,
                title: '安全设置',
                subtitle: '配置登录安全策略',
                onTap: () {},
              ),
              _buildListTile(
                icon: Icons.backup_outlined,
                title: '数据备份',
                subtitle: '配置自动备份策略',
                onTap: () {},
              ),
              _buildListTile(
                icon: Icons.analytics_outlined,
                title: '日志管理',
                subtitle: '查看系统操作日志',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          // About
          _buildSection(
            title: '关于',
            children: [
              _buildListTile(
                icon: Icons.info_outline,
                title: '版本信息',
                subtitle: '当前版本: 1.0.0',
                onTap: () {},
              ),
              _buildListTile(
                icon: Icons.help_outline,
                title: '帮助文档',
                subtitle: '查看使用帮助',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
