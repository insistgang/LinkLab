import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/app_session_service.dart';
import '../../widgets/accessible/index.dart';
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
  bool _highContrastMode = false;
  double _fontScale = 1.0;
  double _voiceSpeed = 1.0;
  bool _hapticFeedback = true;
  bool _autoReadResults = true;

  @override
  void initState() {
    super.initState();
    final prefs = AppSessionService.instance.preferences;
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
      await session.updatePreferences(prefs);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无障碍偏好已更新')),
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
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const MainScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AccessibleScaffold(
      title: '无障碍偏好',
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppTheme.spacingXL),
              const AccessibleText(
                '个性化您的使用体验',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              AccessibleText(
                widget.isEditMode
                    ? '这些设置会立即应用到当前会话'
                    : '这些设置可以随时在"我的"页面修改',
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeNormal,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXXL),
              // 设置选项
              Expanded(
                child: ListView(
                  children: [
                    // 高对比度模式
                    _SwitchTile(
                      title: '高对比度模式',
                      subtitle: '使用黑底黄字的高对比度显示',
                      value: _highContrastMode,
                      onChanged: (value) {
                        setState(() {
                          _highContrastMode = value;
                        });
                      },
                    ),
                    const Divider(),
                    // 字体大小
                    _SliderTile(
                      title: '字体大小',
                      subtitle: '调整应用内文字显示大小',
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
                    const Divider(),
                    // 语音速度
                    _SliderTile(
                      title: '语音播报速度',
                      subtitle: '调整AI语音播报的速度',
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
                    const Divider(),
                    // 触觉反馈
                    _SwitchTile(
                      title: '触觉反馈',
                      subtitle: '操作时提供振动反馈',
                      value: _hapticFeedback,
                      onChanged: (value) {
                        setState(() {
                          _hapticFeedback = value;
                        });
                      },
                    ),
                    const Divider(),
                    // 自动朗读结果
                    _SwitchTile(
                      title: '自动朗读结果',
                      subtitle: 'AI识别完成后自动语音播报',
                      value: _autoReadResults,
                      onChanged: (value) {
                        setState(() {
                          _autoReadResults = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              // 完成按钮
              AccessibleButton(
                label: widget.isEditMode ? '保存设置' : '开始使用',
                semanticLabel:
                    widget.isEditMode ? '保存无障碍偏好' : '完成设置，进入应用',
                hint: widget.isEditMode ? '双击保存偏好设置' : '双击开始使用共感LinkAble',
                onPressed: _onComplete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 开关选项
class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
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
    return Semantics(
      label: title,
      hint: subtitle,
      toggled: value,
      child: SwitchListTile(
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
        value: value,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

/// 滑块选项
class _SliderTile extends StatelessWidget {
  const _SliderTile({
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
    return Semantics(
      label: title,
      hint: subtitle,
      value: '${(value * 100).toInt()}%',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AccessibleText(
            title,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeNormal,
              fontWeight: FontWeight.w600,
            ),
          ),
          AccessibleText(
            subtitle,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Row(
            children: [
              AccessibleText(
                '${min}x',
                style: const TextStyle(fontSize: AppTheme.fontSizeSmall),
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
                '${max}x',
                style: const TextStyle(fontSize: AppTheme.fontSizeSmall),
              ),
            ],
          ),
          Center(
            child: AccessibleText(
              '当前: ${value.toStringAsFixed(1)}x',
              style: const TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
