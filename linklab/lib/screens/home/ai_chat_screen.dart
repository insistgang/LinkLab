import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/accessible/index.dart';

/// AI助手页面
class AIChatScreen extends StatelessWidget {
  const AIChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AccessibleScaffold(
      title: 'AI助手',
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AccessibleText(
                '我能为您做什么？',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              // AI功能列表
              Expanded(
                child: ListView(
                  children: [
                    _AIFeatureCard(
                      title: '文字识别',
                      subtitle: '拍照识别文字并朗读',
                      icon: Icons.document_scanner,
                      color: AppTheme.primaryColor,
                      onTap: () {
                        // TODO: 打开OCR
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    _AIFeatureCard(
                      title: '场景描述',
                      subtitle: '描述周围环境',
                      icon: Icons.camera_alt,
                      color: AppTheme.secondaryColor,
                      onTap: () {
                        // TODO: 打开场景描述
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    _AIFeatureCard(
                      title: '颜色识别',
                      subtitle: '识别物体颜色',
                      icon: Icons.color_lens,
                      color: Colors.purple,
                      onTap: () {
                        // TODO: 打开颜色识别
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    _AIFeatureCard(
                      title: '物体识别',
                      subtitle: '识别物体名称和位置',
                      icon: Icons.category,
                      color: Colors.orange,
                      onTap: () {
                        // TODO: 打开物体识别
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    _AIFeatureCard(
                      title: '智能对话',
                      subtitle: '语音问答，解答疑惑',
                      icon: Icons.chat,
                      color: Colors.teal,
                      onTap: () {
                        // TODO: 打开智能对话
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              // 语音唤醒提示
              Semantics(
                label: '语音唤醒提示',
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.mic,
                        color: AppTheme.primaryColor,
                        size: AppTheme.fontSizeXLarge,
                      ),
                      SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AccessibleText(
                              '语音唤醒',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            AccessibleText(
                              '说"Hey 智动"唤醒AI助手',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeSmall,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// AI功能卡片
class _AIFeatureCard extends StatelessWidget {
  const _AIFeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AccessibleCard(
      semanticLabel: title,
      hint: subtitle,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: AppTheme.minTouchTarget * 1.5,
            height: AppTheme.minTouchTarget * 1.5,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            ),
            child: Icon(
              icon,
              size: AppTheme.fontSizeXXLarge,
              color: color,
            ),
          ),
          const SizedBox(width: AppTheme.spacingL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccessibleText(
                  title,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.bold,
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
          const Icon(
            Icons.arrow_forward_ios,
            color: AppTheme.textHint,
          ),
        ],
      ),
    );
  }
}
