import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_auth.dart';
import '../../widgets/demo/demo_motion.dart';
import '../../widgets/demo/demo_routes.dart';
import '../../widgets/demo/demo_stage.dart';
import '../../widgets/demo/linkable_icon.dart';
import 'preference_screen.dart';

/// 障礙類型選擇頁面
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
      label: '視力障礙',
      description: '包括全盲、低視力、色盲等',
      icon: Icons.visibility_off_outlined,
      svgIcon: LinkableIconName.visualImpairment,
    ),
    _DisabilityOption(
      value: 'hearing',
      label: '聽力障礙',
      description: '包括聾人、聽力減退等',
      icon: Icons.hearing_disabled_outlined,
      svgIcon: LinkableIconName.hearingImpairment,
    ),
    _DisabilityOption(
      value: 'physical',
      label: '肢體障礙',
      description: '行動不便、輪椅使用者等',
      icon: Icons.accessible_outlined,
      svgIcon: LinkableIconName.mobilityImpairment,
    ),
    _DisabilityOption(
      value: 'elderly',
      label: '老年人',
      description: '需要額外幫助的老年用戶',
      icon: Icons.elderly_outlined,
      svgIcon: LinkableIconName.elderly,
    ),
    _DisabilityOption(
      value: 'temporary',
      label: '臨時需要幫助',
      description: '受傷、生病等臨時情況',
      icon: Icons.medical_services_outlined,
      svgIcon: LinkableIconName.tempHelp,
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
          title: '障礙類型',
          subtitle: '這一步只用於改善默認體驗，不會阻塞你進入主流程',
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
                  title: '請選擇您的障礙類型',
                  subtitle: '這將幫助我們爲您提供更好的服務。您可以多選，也可以稍後再補充。',
                  icon: Icons.tune_rounded,
                  svgIcon: LinkableIconName.selectDisability,
                  chips: [
                    DemoPill(label: '支持多選', color: AppTheme.stageAccent),
                    DemoPill(label: '可稍後補充', color: AppTheme.stageInfo),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              DemoReveal(
                delay: const Duration(milliseconds: 80),
                child: DemoMetricStrip(
                  items: [
                    DemoMetricItem(
                      label: '已選類型',
                      value: '${_selectedTypes.length} 項',
                      color: _selectedTypes.isEmpty
                          ? AppTheme.stageTextHint
                          : AppTheme.stageAccent,
                    ),
                    DemoMetricItem(
                      label: '流程策略',
                      value: '可稍後補充',
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
                      '已選擇 ${_selectedTypes.length} 項。後續會基於這些信息給出更合適的默認字體、朗讀和提示方式，但不會限制你進入主流程。',
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
                    '跳過此步驟',
                    style: TextStyle(color: AppTheme.stageAccent),
                  ),
                ),
              ),
            ],
          ),
          bottomBar: AccessibleButton(
            label: '繼續',
            semanticLabel: '繼續下一步',
            hint: '雙擊繼續設置無障礙偏好',
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
      svgIcon: option.svgIcon,
      isSelected: isSelected,
      onTap: onTap,
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: AppTheme.stageAccent)
          : DemoPill(
              label: '點擊選擇',
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
    this.svgIcon,
  });

  final String value;
  final String label;
  final String description;
  final IconData icon;
  final LinkableIconName? svgIcon;
}
