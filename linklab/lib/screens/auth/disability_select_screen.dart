import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_auth.dart';
import '../../widgets/demo/demo_motion.dart';
import '../../widgets/demo/demo_routes.dart';
import '../../widgets/demo/demo_stage.dart';
import 'preference_screen.dart';

/// 障碍类型选择页面
class DisabilitySelectScreen extends StatefulWidget {
  const DisabilitySelectScreen({
    super.key,
    required this.phone,
    required this.role,
  });

  final String phone;
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
      icon: Icons.visibility_off_outlined,
    ),
    _DisabilityOption(
      value: 'hearing',
      label: '听力障碍',
      description: '包括聋人、听力减退等',
      icon: Icons.hearing_disabled_outlined,
    ),
    _DisabilityOption(
      value: 'physical',
      label: '肢体障碍',
      description: '行动不便、轮椅使用者等',
      icon: Icons.accessible_outlined,
    ),
    _DisabilityOption(
      value: 'elderly',
      label: '老年人',
      description: '需要额外帮助的老年用户',
      icon: Icons.elderly_outlined,
    ),
    _DisabilityOption(
      value: 'temporary',
      label: '临时需要帮助',
      description: '受伤、生病等临时情况',
      icon: Icons.medical_services_outlined,
    ),
  ];

  void _onContinue() {
    pushDemoStageRoute(
      context,
      page: PreferenceScreen(
        phone: widget.phone,
        role: widget.role,
        disabilityTypes: List<String>.from(_selectedTypes),
      ),
    );
  }

  void _onSkip() {
    pushDemoStageRoute(
      context,
      page: PreferenceScreen(phone: widget.phone, role: widget.role),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DemoStageLiveBuilder(
      builder: (context) {
        return DemoStageScaffold(
          title: '障碍类型',
          subtitle: '这一步只用于改善默认体验，不会阻塞你进入主流程',
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingL,
              AppTheme.spacingL,
              AppTheme.spacingL,
              140,
            ),
            children: [
              DemoReveal(
                child: DemoAuthBanner(
                  title: '请选择您的障碍类型',
                  subtitle: '这将帮助我们为您提供更好的服务。您可以多选，也可以稍后再补充。',
                  icon: Icons.tune_rounded,
                  chips: [
                    DemoPill(label: '支持多选', color: AppTheme.stageAccent),
                    DemoPill(label: '可稍后补充', color: AppTheme.stageInfo),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              DemoReveal(
                delay: const Duration(milliseconds: 80),
                child: DemoMetricStrip(
                  items: [
                    DemoMetricItem(
                      label: '已选类型',
                      value: '${_selectedTypes.length} 项',
                      color: _selectedTypes.isEmpty
                          ? AppTheme.stageTextHint
                          : AppTheme.stageAccent,
                    ),
                    DemoMetricItem(
                      label: '流程策略',
                      value: '可稍后补充',
                      color: AppTheme.stageInfo,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              for (final option in _options) ...[
                DemoReveal(
                  delay: Duration(
                    milliseconds: 120 + (_options.indexOf(option) * 35),
                  ),
                  child: _DisabilitySelectionCard(
                    option: option,
                    isSelected: _selectedTypes.contains(option.value),
                    onTap: () {
                      setState(() {
                        if (_selectedTypes.contains(option.value)) {
                          _selectedTypes.remove(option.value);
                        } else {
                          _selectedTypes.add(option.value);
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
              ],
              if (_selectedTypes.isNotEmpty) ...[
                DemoReveal(
                  delay: const Duration(milliseconds: 300),
                  child: DemoSurfaceCard(
                    color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.96),
                    child: AccessibleText(
                      '已选择 ${_selectedTypes.length} 项。后续会基于这些信息给出更合适的默认字体、朗读和提示方式，但不会限制你进入主流程。',
                      style: TextStyle(
                        color: AppTheme.stageTextSecondary,
                        fontSize: AppTheme.fontSizeSmall,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
              ],
              Center(
                child: TextButton(
                  onPressed: _onSkip,
                  child: Text(
                    '跳过此步骤',
                    style: TextStyle(color: AppTheme.stageAccent),
                  ),
                ),
              ),
            ],
          ),
          bottomBar: AccessibleButton(
            label: '继续',
            semanticLabel: '继续下一步',
            hint: '双击继续设置无障碍偏好',
            backgroundColor: AppTheme.stageAccent,
            foregroundColor: AppTheme.stageBackground,
            onPressed: _onContinue,
          ),
        );
      },
    );
  }
}

class _DisabilitySelectionCard extends StatelessWidget {
  const _DisabilitySelectionCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _DisabilityOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DemoSelectionCard(
      title: option.label,
      subtitle: option.description,
      icon: option.icon,
      isSelected: isSelected,
      onTap: onTap,
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: AppTheme.stageAccent)
          : DemoPill(
              label: '点击选择',
              color: AppTheme.stageTextHint,
              backgroundColor: AppTheme.stageSurface,
            ),
    );
  }
}

class _DisabilityOption {
  const _DisabilityOption({
    required this.value,
    required this.label,
    required this.description,
    required this.icon,
  });

  final String value;
  final String label;
  final String description;
  final IconData icon;
}
