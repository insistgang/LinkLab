import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/accessible/index.dart';
import '../home/main_screen.dart';

/// 无障碍偏好设置页面
class PreferenceScreen extends StatefulWidget {
  const PreferenceScreen({super.key});

  @override
  State<PreferenceScreen> createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends State<PreferenceScreen> {
  bool _highContrastMode = false;
  double _fontScale = 1.0;
  double _voiceSpeed = 1.0;
  bool _hapticFeedback = true;
  bool _autoReadResults = true;

  void _onComplete() {
    // TODO: 保存偏好设置到本地存储

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
              const AccessibleText(
                '这些设置可以随时在"我的"页面修改',
                style: TextStyle(
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
                label: '开始使用',
                semanticLabel: '完成设置，进入应用',
                hint: '双击开始使用共感LinkAble',
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
