import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/app_session_provider.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_auth.dart';
import '../../widgets/demo/demo_overlays.dart';
import '../../widgets/demo/demo_routes.dart';
import '../../widgets/demo/demo_stage.dart';
import '../../widgets/demo/linkable_icon.dart';
import '../home/main_screen.dart';

/// 无障碍偏好设置页面
class PreferenceScreen extends ConsumerStatefulWidget {
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
  ConsumerState<PreferenceScreen> createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends ConsumerState<PreferenceScreen> {
  DemoStageMode _stageMode = DemoStageMode.day;
  bool _highContrastMode = false;
  double _fontScale = 1.0;
  double _voiceSpeed = 1.0;
  bool _hapticFeedback = true;
  bool _autoReadResults = true;

  @override
  void initState() {
    super.initState();
    final session = ref.read(appSessionProvider);
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

    final notifier = ref.read(appSessionProvider.notifier);

    if (widget.isEditMode) {
      await notifier.setStageMode(_stageMode);
      await notifier.updatePreferences(prefs);
      if (!mounted) return;
      showDemoStageSnackBar(
        context,
        message: '显示与无障碍偏好已更新',
        icon: Icons.check_circle_outline,
        accentColor: AppTheme.stageAccent,
      );
      Navigator.of(context).pop();
      return;
    }

    await notifier.completeOnboarding(
      phone: widget.phone!,
      role: widget.role!,
      disabilityTypes: widget.disabilityTypes,
      preferences: prefs,
    );
    await notifier.setStageMode(_stageMode);
    if (!mounted) return;

    pushAndRemoveUntilDemoStageRoute(
      context,
      page: const MainScreen(),
      predicate: (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DemoStageLiveBuilder(
      builder: (context) {
        final isEditMode = widget.isEditMode;
        return _PreferencePageShell(
          title: '无障碍偏好',
          subtitle: isEditMode ? '当前修改会立即生效' : '最后一步，完成后进入主线演示',
          body: DemoAuthFormTheme(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingL,
                AppTheme.spacingL,
                AppTheme.spacingL,
                AppTheme.spacingL,
              ),
              children: [
                if (isEditMode) ...[
                  DemoSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.stageAccent.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.stageAccent.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: const LinkableSvgIcon(
                                icon: LinkableIconName.personalizedExperience,
                                semanticLabel: '无障碍偏好',
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingM),
                            Expanded(
                              child: AccessibleText(
                                '编辑无障碍偏好',
                                style: TextStyle(
                                  color: AppTheme.stageTextPrimary,
                                  fontSize: AppTheme.fontSizeLarge,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        Wrap(
                          spacing: AppTheme.spacingS,
                          runSpacing: AppTheme.spacingS,
                          children: [
                            DemoPill(
                              label: _stageMode == DemoStageMode.day
                                  ? '荧光日间'
                                  : '深夜模式',
                              color: AppTheme.stageAccent,
                            ),
                            DemoPill(
                              label: _autoReadResults ? '自动朗读开' : '自动朗读关',
                              color: AppTheme.stageAccent,
                            ),
                            DemoPill(
                              label: _hapticFeedback ? '触觉反馈开' : '触觉反馈关',
                              color: AppTheme.stageAccent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                ] else ...[
                  DemoAuthBanner(
                    title: '个性化您的使用体验',
                    subtitle: '这些设置可以随时在"我的"页面修改。',
                    icon: Icons.settings_accessibility_rounded,
                    chips: [
                      DemoPill(
                        label: _stageMode == DemoStageMode.day
                            ? '荧光日间'
                            : '深夜模式',
                        color: AppTheme.stageAccentLight,
                      ),
                      DemoPill(
                        label: _highContrastMode ? '高对比度开启' : '标准显示',
                        color: AppTheme.stageAccentLight,
                      ),
                      DemoPill(
                        label: '字体 ${_fontScale.toStringAsFixed(1)}x',
                        color: AppTheme.stageAccentLight,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  DemoMetricStrip(
                    items: [
                      DemoMetricItem(
                        label: '界面',
                        value: _stageMode == DemoStageMode.day ? '日间' : '深夜',
                        color: AppTheme.stageAccent,
                      ),
                      DemoMetricItem(
                        label: '朗读',
                        value: _autoReadResults ? '自动开启' : '手动触发',
                        color: AppTheme.stageAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                ],
                _PreferenceSwitchCard(
                  title: '自动朗读结果',
                  subtitle: 'AI 识别完成后自动语音播报，减少额外点击。',
                  value: _autoReadResults,
                  leadingIcon: LinkableIconName.tts,
                  onChanged: (value) {
                    setState(() {
                      _autoReadResults = value;
                    });
                  },
                ),
                const SizedBox(height: AppTheme.spacingM),
                _PreferenceSwitchCard(
                  title: '触觉反馈',
                  subtitle: '操作时提供振动反馈，帮助确认关键动作已触发。',
                  value: _hapticFeedback,
                  leadingIcon: LinkableIconName.vibrationFlash,
                  onChanged: (value) {
                    setState(() {
                      _hapticFeedback = value;
                    });
                  },
                ),
                const SizedBox(height: AppTheme.spacingM),
                _StageModeCard(
                  mode: _stageMode,
                  onModeChanged: (mode) {
                    setState(() {
                      _stageMode = mode;
                    });
                  },
                ),
                const SizedBox(height: AppTheme.spacingM),
                _PreferenceSwitchCard(
                  title: '高对比度模式',
                  subtitle: '使用更强的明暗对比，提升弱视和读屏用户的识别效率。',
                  value: _highContrastMode,
                  leadingIcon: LinkableIconName.highContrast,
                  onChanged: (value) {
                    setState(() {
                      _highContrastMode = value;
                    });
                  },
                ),
                const SizedBox(height: AppTheme.spacingM),
                _PreferenceSliderCard(
                  title: '字体大小',
                  subtitle: '调整应用内文字显示大小。',
                  value: _fontScale,
                  min: 0.8,
                  max: 2.0,
                  divisions: 12,
                  leadingIcon: LinkableIconName.fontSize,
                  onChanged: (value) {
                    setState(() {
                      _fontScale = value;
                    });
                  },
                ),
                const SizedBox(height: AppTheme.spacingM),
                _PreferenceSliderCard(
                  title: '语音播报速度',
                  subtitle: '调整 AI 语音播报的速度。',
                  value: _voiceSpeed,
                  min: 0.5,
                  max: 2.0,
                  divisions: 6,
                  leadingIcon: LinkableIconName.voiceInput,
                  onChanged: (value) {
                    setState(() {
                      _voiceSpeed = value;
                    });
                  },
                ),
                const SizedBox(height: AppTheme.spacingM),
              ],
            ),
          ),
          bottomBar: AccessibleButton(
            label: isEditMode ? '保存设置' : '开始使用',
            semanticLabel: isEditMode ? '保存无障碍偏好' : '完成设置，进入应用',
            hint: isEditMode ? '双击保存偏好设置' : '双击开始使用共感LinkAble',
            backgroundColor: AppTheme.stageAccent,
            foregroundColor: AppTheme.stageBackground,
            onPressed: _onComplete,
          ),
        );
      },
    );
  }
}

class _PreferencePageShell extends StatelessWidget {
  const _PreferencePageShell({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.bottomBar,
  });

  final String title;
  final String subtitle;
  final Widget body;
  final Widget bottomBar;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final compactPhone = mediaQuery.size.width < 360;
    final horizontalPadding = compactPhone
        ? AppTheme.spacingM
        : AppTheme.spacingL;

    return Scaffold(
      backgroundColor: AppTheme.stageBackground,
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: AppTheme.stageHeroGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AppTheme.spacingS,
                  horizontalPadding,
                  AppTheme.spacingL,
                ),
                child: Column(
                  children: [
                    _PreferenceHeader(title: title, subtitle: subtitle),
                    const SizedBox(height: AppTheme.spacingM),
                    Expanded(child: ClipRect(child: body)),
                    const SizedBox(height: AppTheme.spacingM),
                    bottomBar,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PreferenceHeader extends StatelessWidget {
  const _PreferenceHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: canPop ? '返回' : '返回不可用',
          hint: canPop ? '双击返回上一页' : '当前已经是第一页',
          child: InkWell(
            onTap: canPop ? () => Navigator.of(context).pop() : null,
            borderRadius: BorderRadius.circular(999),
            child: Ink(
              width: AppTheme.minTouchTarget + 8,
              height: AppTheme.minTouchTarget + 8,
              decoration: BoxDecoration(
                gradient: canPop ? AppTheme.stageAccentGradient : null,
                color: canPop
                    ? null
                    : AppTheme.stageAccent.withValues(alpha: 0.24),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.stageBackground.withValues(alpha: 0.56),
                ),
              ),
              child: const LinkableSvgIcon(
                icon: LinkableIconName.back,
                size: 44,
                semanticLabel: '返回',
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacingXS),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccessibleText(
                  title,
                  isHeader: true,
                  style: TextStyle(
                    color: AppTheme.stageTextPrimary,
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.w800,
                    height: 1.18,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Container(
                  width: 46,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.stageAccent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                AccessibleText(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.stageTextSecondary,
                    fontSize: AppTheme.fontSizeSmall,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
            '日间模式采用高对比度荧光配色；深夜模式适合低光环境。',
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
                  icon: LinkableIconName.lightMode,
                  label: '日间',
                  isSelected: mode == DemoStageMode.day,
                  onTap: () => onModeChanged(DemoStageMode.day),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _StageModeOptionButton(
                  icon: LinkableIconName.darkMode,
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

  final LinkableIconName icon;
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
              LinkableSvgIcon(icon: icon, size: 24, semanticLabel: '$label模式'),
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
    this.leadingIcon,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final LinkableIconName? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return DemoSurfaceCard(
      child: Semantics(
        label: title,
        hint: subtitle,
        toggled: value,
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Row(
            children: [
              if (leadingIcon != null) ...[
                LinkableSvgIcon(
                  icon: leadingIcon!,
                  size: 20,
                  semanticLabel: title,
                ),
                const SizedBox(width: AppTheme.spacingS),
              ],
              Expanded(
                child: AccessibleText(
                  title,
                  style: TextStyle(
                    color: AppTheme.stageTextPrimary,
                    fontSize: AppTheme.fontSizeNormal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
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
          activeThumbColor: AppTheme.stageAccent,
          activeTrackColor: AppTheme.stageAccent.withValues(alpha: 0.38),
          inactiveThumbColor: AppTheme.stageTextHint,
          inactiveTrackColor: AppTheme.stageBorder.withValues(alpha: 0.46),
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
    this.leadingIcon,
  });

  final String title;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final LinkableIconName? leadingIcon;

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
            Row(
              children: [
                if (leadingIcon != null) ...[
                  LinkableSvgIcon(
                    icon: leadingIcon!,
                    size: 20,
                    semanticLabel: title,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                ],
                Expanded(
                  child: AccessibleText(
                    title,
                    style: TextStyle(
                      color: AppTheme.stageTextPrimary,
                      fontSize: AppTheme.fontSizeNormal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
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
                    activeColor: AppTheme.stageAccent,
                    inactiveColor: AppTheme.stageAccent.withValues(alpha: 0.18),
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
