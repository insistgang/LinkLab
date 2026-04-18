import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../demo_flow/demo_matching_flow.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_motion.dart';
import '../../widgets/demo/demo_routes.dart';
import '../../widgets/demo/demo_stage.dart';
import '../ai_chat/demo_ai_chat_screen.dart';

/// AI助手主入口
/// 对齐 PRD 的 F1/F2/F3/F4 主要能力，并作为手机端演示的统一入口。
class AIChatScreen extends StatelessWidget {
  const AIChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final presets = [
      const _AssistantPreset(
        label: '文字识别',
        subtitle: '读说明书、菜单、站牌',
        icon: Icons.document_scanner_outlined,
        color: AppTheme.primaryColor,
        title: 'AI文字识别',
        introMessage: '请告诉我需要读什么，或者直接上传一张图片。我会先尝试识别文字，再用更容易理解的方式读给您听。',
        initialPrompt: '帮我读一下这个说明书',
        quickPrompts: ['帮我读一下这个说明书', '帮我看一下菜单写了什么', '读一下公交站牌内容'],
      ),
      const _AssistantPreset(
        label: '场景描述',
        subtitle: '理解周围环境与障碍物',
        icon: Icons.camera_alt_outlined,
        color: AppTheme.secondaryColor,
        title: 'AI场景描述',
        introMessage: '您可以发一张现场照片，或者直接描述现在的困惑。我会按方位、距离和风险点来说明当前环境。',
        initialPrompt: '描述一下我周围的环境',
        quickPrompts: ['描述一下我周围的环境', '告诉我前面有没有障碍物', '我面前现在是什么样子'],
      ),
      const _AssistantPreset(
        label: '颜色识别',
        subtitle: '识别衣物和物品主色',
        icon: Icons.color_lens_outlined,
        color: AppTheme.accentColor,
        title: 'AI颜色识别',
        introMessage: '如果您想确认衣服、包装或物品颜色，可以直接拍照。我会给出主要颜色和更容易理解的描述。',
        initialPrompt: '这件衣服是什么颜色',
        quickPrompts: ['这件衣服是什么颜色', '帮我分辨这两个颜色', '这个物体的主色调是什么'],
      ),
      const _AssistantPreset(
        label: '紧急识别',
        subtitle: '检测危险并快速进入 SOS',
        icon: Icons.warning_amber_rounded,
        color: AppTheme.emergencyColor,
        title: '紧急求助识别',
        introMessage: '如果您处在危险、摔倒、迷路或身体不适等情况，可以直接描述。我会先判断风险，再建议发起 SOS。',
        initialPrompt: '我摔倒了，现在有点头晕',
        quickPrompts: ['我摔倒了，现在有点头晕', '我找不到路了', '救命，我现在很危险'],
      ),
    ];

    return DemoStageScaffold(
      title: 'AI助手',
      subtitle: '把高频能力收口成一个统一入口，再按场景进入对话',
      showBackButton: false,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          children: [
            DemoReveal(
              child: _HeroCard(
                onStartChat: () => _openDefaultChat(context),
                onConnectVolunteer: () =>
                    DemoMatchingFlow.startMatching(context),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXL),
            DemoReveal(
              delay: Duration(milliseconds: 90),
              child: DemoSectionTitle(
                title: '高频能力',
                subtitle: '优先覆盖 PRD 里的智能对话、OCR、场景描述、颜色识别与紧急检测。',
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: presets.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppTheme.spacingM,
                mainAxisSpacing: AppTheme.spacingM,
                childAspectRatio: 0.92,
              ),
              itemBuilder: (context, index) {
                final preset = presets[index];
                return _CapabilityCard(
                  preset: preset,
                  onTap: () => _openPresetChat(context, preset),
                );
              },
            ),
            const SizedBox(height: AppTheme.spacingXL),
            const DemoSectionTitle(title: '推荐场景'),
            const SizedBox(height: AppTheme.spacingM),
            Wrap(
              spacing: AppTheme.spacingS,
              runSpacing: AppTheme.spacingS,
              children: [
                for (final preset in presets)
                  ActionChip(
                    backgroundColor: AppTheme.stageSurfaceStrong,
                    side: BorderSide(
                      color: AppTheme.stageBorder.withValues(alpha: 0.82),
                    ),
                    avatar: Icon(preset.icon, size: 18, color: preset.color),
                    labelStyle: TextStyle(color: AppTheme.stageTextPrimary),
                    label: Text(preset.quickPrompts.first),
                    onPressed: () => _openPresetChat(context, preset),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingXL),
            DemoReveal(
              delay: Duration(milliseconds: 160),
              child: DemoSurfaceCard(
                semanticLabel: 'AI处理说明',
                hint: '双击查看 AI 与真人协作方式',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AccessibleText(
                      'AI 先处理，复杂问题再转真人',
                      style: TextStyle(
                        color: AppTheme.stageTextPrimary,
                        fontSize: AppTheme.fontSizeNormal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: AppTheme.spacingS),
                    _FlowRow(
                      icon: Icons.smart_toy_outlined,
                      color: AppTheme.primaryColor,
                      title: '标准化问题',
                      subtitle: 'AI 直接回复，适合读文字、颜色识别、环境描述等场景。',
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    _FlowRow(
                      icon: Icons.volunteer_activism_outlined,
                      color: AppTheme.secondaryColor,
                      title: '复杂或情绪化问题',
                      subtitle: '当回答不确定时，可一键转真人志愿者继续处理。',
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    _FlowRow(
                      icon: Icons.emergency_outlined,
                      color: AppTheme.emergencyColor,
                      title: '紧急情况',
                      subtitle: '识别到摔倒、迷路、危险等关键词时，会提示发起 SOS 广播。',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDefaultChat(BuildContext context) {
    pushDemoStageRoute(
      context,
      page: const DemoAIChatScreen(
        title: 'AI智能对话',
        introMessage: '您好，我是 AI 助手智动。您可以直接说需求，也可以通过下方按钮发语音或图片，我会优先尝试自己解决。',
        quickPrompts: ['帮我读一下这个说明书', '描述一下我周围的环境', '这件衣服是什么颜色', '我需要真人志愿者帮助'],
      ),
    );
  }

  void _openPresetChat(BuildContext context, _AssistantPreset preset) {
    pushDemoStageRoute(
      context,
      page: DemoAIChatScreen(
        title: preset.title,
        introMessage: preset.introMessage,
        initialPrompt: preset.initialPrompt,
        quickPrompts: preset.quickPrompts,
        autoSendInitialPrompt: true,
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.onStartChat,
    required this.onConnectVolunteer,
  });

  final VoidCallback onStartChat;
  final VoidCallback onConnectVolunteer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: AppTheme.stageCardDecoration(
        color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + 8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppTheme.stageAccentGradient,
              borderRadius: BorderRadius.circular(
                AppTheme.borderRadiusLarge + 4,
              ),
            ),
            child: Icon(
              Icons.multitrack_audio,
              color: AppTheme.stageBackground,
              size: 30,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          AccessibleText(
            '先由 AI 快速响应\n必要时再无缝转接志愿者',
            style: TextStyle(
              fontSize: AppTheme.fontSizeLarge,
              height: 1.35,
              fontWeight: FontWeight.bold,
              color: AppTheme.stageTextPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          AccessibleText(
            '支持语音、文字、图片三种输入，适合手机端快速求助演示。',
            style: TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              height: 1.6,
              color: AppTheme.stageTextSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          const Wrap(
            spacing: AppTheme.spacingS,
            runSpacing: AppTheme.spacingS,
            children: [
              _HeroStat(label: '响应目标', value: '3 秒内'),
              _HeroStat(label: '演示模式', value: '本地可用'),
              _HeroStat(label: '输入方式', value: '语音/文字/图片'),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          AccessibleButton(
            label: '开始智能对话',
            semanticLabel: '开始智能对话按钮',
            hint: '双击进入 AI 对话页',
            icon: Icons.chat_bubble_outline,
            backgroundColor: AppTheme.stageAccent,
            foregroundColor: AppTheme.stageBackground,
            height: 72,
            onPressed: onStartChat,
          ),
          const SizedBox(height: AppTheme.spacingM),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onConnectVolunteer,
              icon: Icon(Icons.volunteer_activism_outlined),
              label: const Text('复杂问题直接连接志愿者'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textOnPrimary,
                side: BorderSide(
                  color: AppTheme.stageTextPrimary.withValues(alpha: 0.22),
                  width: 1.5,
                ),
                backgroundColor: AppTheme.stageSurface,
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: AppTheme.stageSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.stageBorder.withValues(alpha: 0.82)),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: AppTheme.stageTextSecondary,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                fontWeight: FontWeight.bold,
                color: AppTheme.stageTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapabilityCard extends StatelessWidget {
  const _CapabilityCard({required this.preset, required this.onTap});

  final _AssistantPreset preset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DemoSurfaceCard(
      semanticLabel: '${preset.label}能力卡片',
      hint: '双击打开${preset.label}演示',
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: preset.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
            ),
            child: Icon(preset.icon, color: preset.color, size: 28),
          ),
          const Spacer(),
          AccessibleText(
            preset.label,
            style: TextStyle(
              color: AppTheme.stageTextPrimary,
              fontSize: AppTheme.fontSizeNormal,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          AccessibleText(
            preset.subtitle,
            style: TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              color: AppTheme.stageTextSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Row(
            children: [
              AccessibleText(
                '进入演示',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeSmall,
                  color: preset.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppTheme.spacingXS),
              Icon(Icons.arrow_forward, size: 18, color: preset.color),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlowRow extends StatelessWidget {
  const _FlowRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AccessibleText(
                title,
                style: TextStyle(
                  color: AppTheme.stageTextPrimary,
                  fontSize: AppTheme.fontSizeSmall,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXS),
              AccessibleText(
                subtitle,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeSmall,
                  color: AppTheme.stageTextSecondary,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AssistantPreset {
  const _AssistantPreset({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.title,
    required this.introMessage,
    required this.initialPrompt,
    required this.quickPrompts,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String title;
  final String introMessage;
  final String initialPrompt;
  final List<String> quickPrompts;
}
