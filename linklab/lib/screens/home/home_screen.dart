import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/accessible/index.dart';
import '../../demo_flow/demo_flow_controller.dart';
import '../../demo_flow/demo_matching_flow.dart';
import '../ai_chat/demo_ai_chat_screen.dart';
import '../call/demo_exports.dart';

/// 首页
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AccessibleScaffold(
      title: '共感LinkAble',
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 欢迎语
              Semantics(
                label: '欢迎回来',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AccessibleText(
                      '您好，',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeNormal,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const AccessibleText(
                      '今天需要什么帮助？',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeXLarge,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingXXL),
              // 紧急求助按钮（超大按钮）
              Semantics(
                button: true,
                label: '紧急求助按钮',
                hint: '双击触发紧急求助，将向附近志愿者和紧急联系人发送求助信息',
                child: InkWell(
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    _showEmergencyDialog(context);
                  },
                  onDoubleTap: () {
                    // 双击直接触发SOS（演示用）
                    DemoFlowNavigator.onSOSButtonPressed(context);
                  },
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusLarge),
                  child: Container(
                    width: double.infinity,
                    height: AppTheme.emergencyButtonHeight,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppTheme.emergencyColor,
                          AppTheme.warningColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusLarge),
                      boxShadow: AppTheme.elevatedShadow,
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emergency,
                          color: AppTheme.textOnPrimary,
                          size: 48,
                        ),
                        SizedBox(height: AppTheme.spacingS),
                        Text(
                          '紧急求助',
                          style: TextStyle(
                            color: AppTheme.textOnPrimary,
                            fontSize: AppTheme.fontSizeXXLarge,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingXL),
              // 大按钮"我需要帮助"
              AccessibleButton(
                label: '我需要帮助',
                semanticLabel: '我需要帮助按钮，进入AI对话',
                hint: '双击进入AI助手对话界面',
                height: 100,
                icon: Icons.help_outline,
                onPressed: () {
                  DemoFlowNavigator.onHomeBigButtonPressed(context);
                },
              ),
              const SizedBox(height: AppTheme.spacingXL),

              // 快捷工具栏
              const AccessibleText(
                '快捷工具',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              Row(
                children: [
                  Expanded(
                    child: _QuickToolButton(
                      label: '文字识别',
                      icon: Icons.document_scanner,
                      semanticLabel: 'OCR文字识别',
                      onTap: () {
                        // 直接进入AI对话，并触发拍照
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DemoAIChatScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: _QuickToolButton(
                      label: '颜色识别',
                      icon: Icons.color_lens,
                      semanticLabel: '颜色识别',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DemoAIChatScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: _QuickToolButton(
                      label: 'AI对话',
                      icon: Icons.chat,
                      semanticLabel: '智能对话',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DemoAIChatScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingXL),
              // 志愿者呼叫
              AccessibleCard(
                semanticLabel: '呼叫志愿者',
                hint: '双击连接真人志愿者获取帮助',
                onTap: () {
                  // 演示：直接进入匹配等待
                  DemoMatchingFlow.startMatching(context);
                },
                child: Row(
                  children: [
                    Container(
                      width: AppTheme.minTouchTarget * 1.5,
                      height: AppTheme.minTouchTarget * 1.5,
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryLight.withOpacity(0.3),
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusMedium),
                      ),
                      child: const Icon(
                        Icons.volunteer_activism,
                        size: AppTheme.fontSizeXXLarge,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingL),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AccessibleText(
                            '呼叫志愿者',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeLarge,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: AppTheme.spacingXS),
                          AccessibleText(
                            '连接真人志愿者获取帮助',
                            style: TextStyle(
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
              ),
              const SizedBox(height: AppTheme.spacingL),
              // AI助手入口
              AccessibleCard(
                semanticLabel: 'AI智能助手',
                hint: '双击与AI助手对话',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DemoAIChatScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      width: AppTheme.minTouchTarget * 1.5,
                      height: AppTheme.minTouchTarget * 1.5,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withOpacity(0.3),
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusMedium),
                      ),
                      child: const Icon(
                        Icons.smart_toy,
                        size: AppTheme.fontSizeXXLarge,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingL),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AccessibleText(
                            'AI智能助手',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeLarge,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: AppTheme.spacingXS),
                          AccessibleText(
                            '文字识别、场景描述、智能对话',
                            style: TextStyle(
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
              ),
              const SizedBox(height: AppTheme.spacingXL),
              // 最近帮助记录
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AccessibleText(
                    '最近帮助',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: 查看全部记录
                    },
                    child: const AccessibleText('查看全部'),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingS),
              // 示例记录
              _HelpHistoryItem(
                title: '文字识别',
                subtitle: '识别药品说明书',
                time: '今天 10:30',
                type: 'ai',
              ),
              const SizedBox(height: AppTheme.spacingS),
              _HelpHistoryItem(
                title: '志愿者帮助',
                subtitle: '协助查看快递单',
                time: '昨天 15:20',
                type: 'volunteer',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const AccessibleText(
          '确认紧急求助？',
          style: TextStyle(
            fontSize: AppTheme.fontSizeXLarge,
            fontWeight: FontWeight.bold,
            color: AppTheme.emergencyColor,
          ),
        ),
        content: const AccessibleText(
          '这将向附近的志愿者和您的紧急联系人发送求助信息，并共享您的位置。',
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
              // 触发SOS演示流程
              DemoFlowNavigator.onSOSButtonPressed(context);
            },
            child: const AccessibleText('确认求助'),
          ),
        ],
      ),
    );
  }
}

/// 快捷工具按钮
class _QuickToolButton extends StatelessWidget {
  const _QuickToolButton({
    required this.label,
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      hint: '双击打开$label',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: AppTheme.fontSizeXXLarge,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: AppTheme.spacingS),
              AccessibleText(
                label,
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeNormal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 帮助记录项
class _HelpHistoryItem extends StatelessWidget {
  const _HelpHistoryItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.type,
  });

  final String title;
  final String subtitle;
  final String time;
  final String type;

  @override
  Widget build(BuildContext context) {
    return AccessibleListTile(
      title: AccessibleText(
        title,
        style: const TextStyle(
          fontSize: AppTheme.fontSizeNormal,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: AccessibleText(
        '$subtitle · $time',
        style: const TextStyle(
          fontSize: AppTheme.fontSizeSmall,
          color: AppTheme.textSecondary,
        ),
      ),
      leading: Icon(
        type == 'ai' ? Icons.smart_toy : Icons.volunteer_activism,
        color: type == 'ai' ? AppTheme.primaryColor : AppTheme.secondaryColor,
      ),
      onTap: () {
        // TODO: 查看详情
      },
    );
  }
}
