import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/accessible/index.dart';
import 'disability_select_screen.dart';

/// 身份选择页面
class IdentitySelectScreen extends StatefulWidget {
  const IdentitySelectScreen({super.key});

  @override
  State<IdentitySelectScreen> createState() => _IdentitySelectScreenState();
}

class _IdentitySelectScreenState extends State<IdentitySelectScreen> {
  String? _selectedRole;

  void _onContinue() {
    if (_selectedRole != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DisabilitySelectScreen(role: _selectedRole!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AccessibleScaffold(
      title: '选择身份',
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppTheme.spacingXL),
              const AccessibleText(
                '您希望以什么身份使用本应用？',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              const AccessibleText(
                '您可以选择多个身份',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeNormal,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXXL),
              // 身份选项
              _RoleCard(
                title: '我需要帮助',
                subtitle: '我是视障人士或需要帮助的人',
                icon: Icons.accessibility_new,
                isSelected: _selectedRole == 'seeker',
                onTap: () {
                  setState(() {
                    _selectedRole = 'seeker';
                  });
                },
              ),
              const SizedBox(height: AppTheme.spacingM),
              _RoleCard(
                title: '我想帮助他人',
                subtitle: '我是志愿者，愿意提供帮助',
                icon: Icons.volunteer_activism,
                isSelected: _selectedRole == 'volunteer',
                onTap: () {
                  setState(() {
                    _selectedRole = 'volunteer';
                  });
                },
              ),
              const SizedBox(height: AppTheme.spacingM),
              _RoleCard(
                title: '两者皆是',
                subtitle: '我既需要帮助，也想帮助他人',
                icon: Icons.people,
                isSelected: _selectedRole == 'both',
                onTap: () {
                  setState(() {
                    _selectedRole = 'both';
                  });
                },
              ),
              const Spacer(),
              // 继续按钮
              AccessibleButton(
                label: '继续',
                semanticLabel: '继续下一步',
                hint: '双击继续设置',
                onPressed: _selectedRole != null ? _onContinue : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 身份选项卡片
class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      hint: subtitle,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryLight : AppTheme.cardColor,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
              width: isSelected ? 3 : 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: AppTheme.minTouchTarget * 1.5,
                height: AppTheme.minTouchTarget * 1.5,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.surfaceColor,
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: Icon(
                  icon,
                  size: AppTheme.fontSizeXXLarge,
                  color: isSelected
                      ? AppTheme.textOnPrimary
                      : AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AccessibleText(
                      title,
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeLarge,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? AppTheme.primaryDark
                            : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    AccessibleText(
                      subtitle,
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeNormal,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryColor,
                  size: AppTheme.fontSizeXLarge,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
