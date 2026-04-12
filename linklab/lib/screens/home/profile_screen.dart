import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/accessible/index.dart';
import '../auth/login_screen.dart';

/// 个人中心页面
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AccessibleScaffold(
      title: '我的',
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 用户信息卡片
              Semantics(
                label: '用户信息',
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryLight,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.textOnPrimary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.textOnPrimary,
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 48,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingL),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AccessibleText(
                              '用户138****8888',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeLarge,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textOnPrimary,
                              ),
                            ),
                            SizedBox(height: AppTheme.spacingXS),
                            AccessibleText(
                              '求助者 · 视力障碍',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeNormal,
                                color: AppTheme.textOnPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // TODO: 编辑个人资料
                        },
                        icon: const Icon(
                          Icons.edit,
                          color: AppTheme.textOnPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingXL),
              // 功能菜单
              const AccessibleText(
                '无障碍设置',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              _MenuItem(
                icon: Icons.contrast,
                title: '高对比度模式',
                subtitle: '黑底黄字显示',
                onTap: () {
                  // TODO: 切换高对比度模式
                },
              ),
              _MenuItem(
                icon: Icons.text_fields,
                title: '字体大小',
                subtitle: '当前：标准',
                onTap: () {
                  // TODO: 调整字体大小
                },
              ),
              _MenuItem(
                icon: Icons.speed,
                title: '语音速度',
                subtitle: '当前：1.0x',
                onTap: () {
                  // TODO: 调整语音速度
                },
              ),
              _MenuItem(
                icon: Icons.vibration,
                title: '触觉反馈',
                subtitle: '开启',
                onTap: () {
                  // TODO: 切换触觉反馈
                },
              ),
              const Divider(),
              const SizedBox(height: AppTheme.spacingM),
              const AccessibleText(
                '安全设置',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              _MenuItem(
                icon: Icons.contacts,
                title: '紧急联系人',
                subtitle: '已设置2人',
                onTap: () {
                  // TODO: 管理紧急联系人
                },
              ),
              _MenuItem(
                icon: Icons.location_on,
                title: '位置共享',
                subtitle: '求助时自动共享',
                onTap: () {
                  // TODO: 位置设置
                },
              ),
              const Divider(),
              const SizedBox(height: AppTheme.spacingM),
              const AccessibleText(
                '其他',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              _MenuItem(
                icon: Icons.history,
                title: '帮助记录',
                subtitle: '查看历史求助',
                onTap: () {
                  // TODO: 查看帮助记录
                },
              ),
              _MenuItem(
                icon: Icons.help,
                title: '使用帮助',
                subtitle: '查看操作指南',
                onTap: () {
                  // TODO: 打开帮助页面
                },
              ),
              _MenuItem(
                icon: Icons.info,
                title: '关于',
                subtitle: '版本 1.0.0',
                onTap: () {
                  // TODO: 关于页面
                },
              ),
              const SizedBox(height: AppTheme.spacingXL),
              // 退出登录
              AccessibleButton(
                label: '退出登录',
                semanticLabel: '退出当前账号',
                backgroundColor: AppTheme.surfaceColor,
                foregroundColor: AppTheme.emergencyColor,
                onPressed: () {
                  _showLogoutDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const AccessibleText(
          '确认退出登录？',
          style: TextStyle(
            fontSize: AppTheme.fontSizeXLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const AccessibleText(
          '退出后将需要重新登录',
          style: TextStyle(fontSize: AppTheme.fontSizeNormal),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const AccessibleText('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emergencyColor,
              foregroundColor: AppTheme.textOnPrimary,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 清除登录状态
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
                (route) => false,
              );
            },
            child: const AccessibleText('确认退出'),
          ),
        ],
      ),
    );
  }
}

/// 菜单项
class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AccessibleListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: AccessibleText(
        title,
        style: const TextStyle(
          fontSize: AppTheme.fontSizeNormal,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: AccessibleText(
        subtitle,
        style: const TextStyle(
          fontSize: AppTheme.fontSizeSmall,
          color: AppTheme.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: AppTheme.textHint,
        size: AppTheme.fontSizeNormal,
      ),
      onTap: onTap,
    );
  }
}
