import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/accessible/index.dart';
import 'preference_screen.dart';

/// 障碍类型选择页面
class DisabilitySelectScreen extends StatefulWidget {
  const DisabilitySelectScreen({
    super.key,
    required this.role,
  });

  final String role;

  @override
  State<DisabilitySelectScreen> createState() => _DisabilitySelectScreenState();
}

class _DisabilitySelectScreenState extends State<DisabilitySelectScreen> {
  final List<String> _selectedTypes = [];

  final List<_DisabilityOption> _options = const [
    _DisabilityOption(
      value: 'visual',
      label: '视力障碍',
      description: '包括全盲、低视力、色盲等',
      icon: Icons.visibility_off,
    ),
    _DisabilityOption(
      value: 'hearing',
      label: '听力障碍',
      description: '包括聋人、听力减退等',
      icon: Icons.hearing_disabled,
    ),
    _DisabilityOption(
      value: 'physical',
      label: '肢体障碍',
      description: '行动不便、轮椅使用者等',
      icon: Icons.accessible,
    ),
    _DisabilityOption(
      value: 'elderly',
      label: '老年人',
      description: '需要额外帮助的老年用户',
      icon: Icons.elderly,
    ),
    _DisabilityOption(
      value: 'temporary',
      label: '临时需要帮助',
      description: '受伤、生病等临时情况',
      icon: Icons.medical_services,
    ),
  ];

  void _onContinue() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PreferenceScreen(),
      ),
    );
  }

  void _onSkip() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PreferenceScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AccessibleScaffold(
      title: '障碍类型',
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppTheme.spacingXL),
              const AccessibleText(
                '请选择您的障碍类型',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              const AccessibleText(
                '这将帮助我们为您提供更好的服务',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeNormal,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXXL),
              // 障碍类型选项
              Expanded(
                child: ListView.builder(
                  itemCount: _options.length,
                  itemBuilder: (context, index) {
                    final option = _options[index];
                    final isSelected = _selectedTypes.contains(option.value);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                      child: Semantics(
                        button: true,
                        label: option.label,
                        hint: option.description,
                        selected: isSelected,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedTypes.remove(option.value);
                              } else {
                                _selectedTypes.add(option.value);
                              }
                            });
                          },
                          borderRadius:
                              BorderRadius.circular(AppTheme.borderRadiusLarge),
                          child: Container(
                            padding: const EdgeInsets.all(AppTheme.spacingL),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryLight
                                  : AppTheme.cardColor,
                              borderRadius: BorderRadius.circular(
                                  AppTheme.borderRadiusLarge),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.borderColor,
                                width: isSelected ? 3 : 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: AppTheme.minTouchTarget * 1.2,
                                  height: AppTheme.minTouchTarget * 1.2,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : AppTheme.surfaceColor,
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.borderRadiusMedium),
                                  ),
                                  child: Icon(
                                    option.icon,
                                    size: AppTheme.fontSizeXLarge,
                                    color: isSelected
                                        ? AppTheme.textOnPrimary
                                        : AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingL),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AccessibleText(
                                        option.label,
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
                                        option.description,
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
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              // 跳过按钮
              Center(
                child: TextButton(
                  onPressed: _onSkip,
                  child: const AccessibleText(
                    '跳过此步骤',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeNormal,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              // 继续按钮
              AccessibleButton(
                label: '继续',
                semanticLabel: '继续下一步',
                hint: '双击继续设置无障碍偏好',
                onPressed: _onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DisabilityOption {
  final String value;
  final String label;
  final String description;
  final IconData icon;

  const _DisabilityOption({
    required this.value,
    required this.label,
    required this.description,
    required this.icon,
  });
}
