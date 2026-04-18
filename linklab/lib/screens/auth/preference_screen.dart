import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/app_session_service.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_auth.dart';
import '../../widgets/demo/demo_motion.dart';
import '../../widgets/demo/demo_overlays.dart';
import '../../widgets/demo/demo_routes.dart';
import '../../widgets/demo/demo_stage.dart';
import '../home/main_screen.dart';

/// 无障碍偏好设置页面
class PreferenceScreen extends StatefulWidget {
  const PreferenceScreen({
    super.key,
    this.phone,
    this.role,
    this.disabilityTypes = const [],
  });

  final String? phone;
  final String? role;
  final List<String> disabilityTypes;

  bool get isEditMode => phone == null || role == null;

  @override
  State<PreferenceScreen> createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends State<PreferenceScreen> {
  DemoStageMode _stageMode = DemoStageMode.night;
  bool _highContrastMode = false;
  double _fontScale = 1.0;
  double _voiceSpeed = 1.0;
  bool _hapticFeedback = true;
  bool _autoReadResults = true;

  @override
  void initState() {
    super.initState();
    final session = AppSessionService.instance;
    final prefs = session.preferences;
    _stageMode = session.stageMode;
    _highContrastMode = prefs.highContrastMode;
    _fontScale = prefs.fontScale;
    _voiceSpeed = prefs.voiceSpeed;
    _hapticFeedback = prefs.hapticFeedback;
    _autoReadResults = prefs.autoReadResults;
  }

  Future<void> _onComplete() async {
    final prefs = AccessibilityPreferences(
      highContrastMode: _highContrastMode,
      fontScale: _fontScale,
      voiceSpeed: _voiceSpeed,
      hapticFeedback: _hapticFeedback,
      autoReadResults: _autoReadResults,
    );

    final session = AppSessionService.instance;

    if (widget.isEditMode) {
      await session.setStageMode(_stageMode);
      await session.updatePreferences(prefs);
      if (!mounted) return;
      showDemoStageSnackBar(
        context,
        message: '显示与无障碍偏好已更新',
        icon: Icons.check_circle_outline,
        accentColor: AppTheme.stageSuccess,
      );
      Navigator.of(context).pop();
      return;
    }

    await session.completeOnboarding(
      phone: widget.phone!,
      role: widget.role!,
      disabilityTypes: widget.disabilityTypes,
      preferences: prefs,
    );
    await session.setStageMode(_stageMode);
    if (!mounted) return;

    pushAndRemoveUntilDemoStageRoute(
      context,
      page: const MainScreen(),
      predicate: (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DemoStageScaffold(
      title: '无障碍偏好',
      subtitle: widget.isEditMode ? '当前修改会立即生效' : '最后一步，完成后进入主线演示',
      body: DemoAuthFormTheme(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingL,
            AppTheme.spacingL,
            AppTheme.spacingL,
            120,
          ),
          children: [
            DemoReveal(
              child: DemoAuthBanner(
                title: '个性化您的使用体验',
                subtitle: widget.isEditMode
                    ? '这些设置会立即应用到当前会话。'
                    : '这些设置可以随时在“我的”页面修改。',
                icon: Icons.settings_accessibility_rounded,
                chips: [
                  DemoPill(
                    label: _stageMode == DemoStageMode.day ? '日间模式' : '深夜模式',
                    color: _stageMode == DemoStageMode.day
                        ? AppTheme.stageInfo
                        : AppTheme.stageAccent,
                  ),
                  DemoPill(
                    label: _highContrastMode ? '高对比度开启' : '标准显示',
                    color: _highContrastMode
                        ? AppTheme.stageWarning
                        : AppTheme.stageAccent,
                  ),
                  DemoPill(
                    label: '字体 ${_fontScale.toStringAsFixed(1)}x',
                    color: AppTheme.stageInfo,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            DemoReveal(
              delay: const Duration(milliseconds: 80),
              child: DemoMetricStrip(
                items: [
                  DemoMetricItem(
                    label: '界面',
                    value: _stageMode == DemoStageMode.day ? '白天' : '深夜',
                    color: _stageMode == DemoStageMode.day
                        ? AppTheme.stageInfo
                        : AppTheme.stageAccent,
                  ),
                  DemoMetricItem(
                    label: '朗读',
                    value: _autoReadResults ? '自动开启' : '手动触发',
                    color: AppTheme.stageInfo,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            DemoReveal(
              delay: const Duration(milliseconds: 110),
              child: _StageModeCard(
                mode: _stageMode,
                onModeChanged: (mode) {
                  setState(() {
                    _stageMode = mode;
                  });
                },
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            DemoReveal(
              delay: const Duration(milliseconds: 140),
              child: _PreferenceSwitchCard(
                title: '高对比度模式',
                subtitle: '使用更强的明暗对比，提升弱视和读屏用户的识别效率。',
                value: _highContrastMode,
                onChanged: (value) {
                  setState(() {
                    _highContrastMode = value;
                  });
                },
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            DemoReveal(
              delay: const Duration(milliseconds: 170),
              child: _PreferenceSliderCard(
                title: '字体大小',
                subtitle: '调整应用内文字显示大小。',
                value: _fontScale,
                min: 0.8,
                max: 1.5,
                divisions: 7,
                onChanged: (value) {
                  setState(() {
                    _fontScale = value;
                  });
                },
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            DemoReveal(
              delay: const Duration(milliseconds: 200),
              child: _PreferenceSliderCard(
                title: '语音播报速度',
                subtitle: '调整 AI 语音播报的速度。',
                value: _voiceSpeed,
                min: 0.5,
                max: 2.0,
                divisions: 6,
                onChanged: (value) {
                  setState(() {
                    _voiceSpeed = value;
                  });
                },
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            DemoReveal(
              delay: const Duration(milliseconds: 230),
              child: _PreferenceSwitchCard(
                title: '触觉反馈',
                subtitle: '操作时提供振动反馈，帮助确认关键动作已触发。',
                value: _hapticFeedback,
                onChanged: (value) {
                  setState(() {
                    _hapticFeedback = value;
                  });
                },
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            DemoReveal(
              delay: const Duration(milliseconds: 260),
              child: _PreferenceSwitchCard(
                title: '自动朗读结果',
                subtitle: 'AI 识别完成后自动语音播报，减少额外点击。',
                value: _autoReadResults,
                onChanged: (value) {
                  setState(() {
                    _autoReadResults = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
      bottomBar: AccessibleButton(
        label: widget.isEditMode ? '保存设置' : '开始使用',
        semanticLabel: widget.isEditMode ? '保存无障碍偏好' : '完成设置，进入应用',
        hint: widget.isEditMode ? '双击保存偏好设置' : '双击开始使用共感LinkAble',
        backgroundColor: AppTheme.stageAccent,
        foregroundColor: AppTheme.stageBackground,
        onPressed: _onComplete,
      ),
    );
  }
}

class _StageModeCard extends StatelessWidget {
  const _StageModeCard({required this.mode, required this.onModeChanged});

  final DemoStageMode mode;
  final ValueChanged<DemoStageMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return DemoSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AccessibleText(
            '界面模式',
            style: TextStyle(
              color: AppTheme.stageTextPrimary,
              fontSize: AppTheme.fontSizeNormal,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          AccessibleText(
            '白天模式更适合明亮环境，深夜模式保留当前黑底荧光绿演示风格。',
            style: TextStyle(
              color: AppTheme.stageTextSecondary,
              fontSize: AppTheme.fontSizeSmall,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: _StageModeOptionButton(
                  icon: Icons.light_mode_outlined,
                  label: '白天',
                  isSelected: mode == DemoStageMode.day,
                  onTap: () => onModeChanged(DemoStageMode.day),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _StageModeOptionButton(
                  icon: Icons.dark_mode_outlined,
                  label: '深夜',
                  isSelected: mode == DemoStageMode.night,
                  onTap: () => onModeChanged(DemoStageMode.night),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StageModeOptionButton extends StatelessWidget {
  const _StageModeOptionButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label模式',
      hint: '双击切换到$label模式',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 88,
          decoration: BoxDecoration(
            gradient: isSelected ? AppTheme.stageAccentGradient : null,
            color: isSelected ? null : AppTheme.stageSurfaceStrong,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : AppTheme.stageBorder.withValues(alpha: 0.82),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppTheme.stageBackground
                    : AppTheme.stageTextPrimary,
              ),
              const SizedBox(height: AppTheme.spacingS),
              AccessibleText(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.stageBackground
                      : AppTheme.stageTextPrimary,
                  fontSize: AppTheme.fontSizeNormal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreferenceSwitchCard extends StatelessWidget {
  const _PreferenceSwitchCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return DemoSurfaceCard(
      child: Semantics(
        label: title,
        hint: subtitle,
        toggled: value,
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: AccessibleText(
            title,
            style: TextStyle(
              color: AppTheme.stageTextPrimary,
              fontSize: AppTheme.fontSizeNormal,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: AccessibleText(
            subtitle,
            style: TextStyle(
              color: AppTheme.stageTextSecondary,
              fontSize: AppTheme.fontSizeSmall,
              height: 1.5,
            ),
          ),
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _PreferenceSliderCard extends StatelessWidget {
  const _PreferenceSliderCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return DemoSurfaceCard(
      child: Semantics(
        label: title,
        hint: subtitle,
        value: '${value.toStringAsFixed(1)}x',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AccessibleText(
              title,
              style: TextStyle(
                color: AppTheme.stageTextPrimary,
                fontSize: AppTheme.fontSizeNormal,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXS),
            AccessibleText(
              subtitle,
              style: TextStyle(
                color: AppTheme.stageTextSecondary,
                fontSize: AppTheme.fontSizeSmall,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Row(
              children: [
                AccessibleText(
                  '${min.toStringAsFixed(1)}x',
                  style: TextStyle(
                    color: AppTheme.stageTextHint,
                    fontSize: AppTheme.fontSizeSmall,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: value,
                    min: min,
                    max: max,
                    divisions: divisions,
                    label: '${value.toStringAsFixed(1)}x',
                    onChanged: onChanged,
                  ),
                ),
                AccessibleText(
                  '${max.toStringAsFixed(1)}x',
                  style: TextStyle(
                    color: AppTheme.stageTextHint,
                    fontSize: AppTheme.fontSizeSmall,
                  ),
                ),
              ],
            ),
            Center(
              child: DemoPill(
                label: '当前: ${value.toStringAsFixed(1)}x',
                color: AppTheme.stageAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
