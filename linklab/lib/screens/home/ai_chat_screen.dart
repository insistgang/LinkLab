import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../demo_flow/demo_matching_flow.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_motion.dart';
import '../../widgets/demo/demo_routes.dart';
import '../../widgets/demo/demo_stage.dart';
import '../../widgets/demo/linkable_icon.dart';
import '../ai_chat/demo_ai_chat_screen.dart';

/// AI助手主入口
/// 對齊 PRD 的 F1/F2/F3/F4 主要能力，並作爲手機端演示的統一入口。
class AIChatScreen extends StatelessWidget {
  const AIChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final presets = [
      const _AssistantPreset(
        label: '文字識別',
        subtitle: '讀說明書、菜單、站牌',
        icon: Icons.document_scanner_outlined,
        color: AppTheme.primaryColor,
        title: 'AI文字識別',
        introMessage: '請告訴我需要讀什麼，或者直接上傳一張圖片。我會先嚐試識別文字，再用更容易理解的方式讀給您聽。',
        initialPrompt: '幫我讀一下這個說明書',
        quickPrompts: ['幫我讀一下這個說明書', '幫我看一下菜單寫了什麼', '讀一下公交站牌內容'],
      ),
      const _AssistantPreset(
        label: '場景描述',
        subtitle: '理解周圍環境與障礙物',
        icon: Icons.camera_alt_outlined,
        color: AppTheme.secondaryColor,
        title: 'AI場景描述',
        introMessage: '您可以發一張現場照片，或者直接描述現在的困惑。我會按方位、距離和風險點來說明當前環境。',
        initialPrompt: '描述一下我周圍的環境',
        quickPrompts: ['描述一下我周圍的環境', '告訴我前面有沒有障礙物', '我面前現在是什麼樣子'],
      ),
      const _AssistantPreset(
        label: '顏色識別',
        subtitle: '識別衣物和物品主色',
        icon: Icons.color_lens_outlined,
        color: AppTheme.accentColor,
        title: 'AI顏色識別',
        introMessage: '如果您想確認衣服、包裝或物品顏色，可以直接拍照。我會給出主要顏色和更容易理解的描述。',
        initialPrompt: '這件衣服是什麼顏色',
        quickPrompts: ['這件衣服是什麼顏色', '幫我分辨這兩個顏色', '這個物體的主色調是什麼'],
      ),
      const _AssistantPreset(
        label: '緊急識別',
        subtitle: '檢測危險並快速進入 SOS',
        icon: Icons.warning_amber_rounded,
        color: AppTheme.emergencyColor,
        title: '緊急求助識別',
        introMessage: '如果您處在危險、摔倒、迷路或身體不適等情況，可以直接描述。我會先判斷風險，再建議發起 SOS。',
        initialPrompt: '我摔倒了，現在有點頭暈',
        quickPrompts: ['我摔倒了，現在有點頭暈', '我找不到路了', '救命，我現在很危險'],
      ),
    ];

    return DemoStageLiveBuilder(
      builder: (context) {
        return DemoStageScaffold(
          title: 'AI助手',
          subtitle: '把高頻能力收口成一個統一入口，再按場景進入對話',
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
                const DemoReveal(
                  delay: Duration(milliseconds: 90),
                  child: DemoSectionTitle(
                    title: '高頻能力',
                    subtitle: '優先覆蓋 PRD 裏的智能對話、OCR、場景描述、顏色識別與緊急檢測。',
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
                const DemoSectionTitle(title: '推薦場景'),
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
                        avatar: LinkableMaterialIcon(
                          icon: preset.icon,
                          size: 18,
                          color: preset.color,
                          semanticLabel: preset.label,
                        ),
                        labelStyle: TextStyle(color: AppTheme.stageTextPrimary),
                        label: Text(preset.quickPrompts.first),
                        onPressed: () => _openPresetChat(context, preset),
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXL),
                DemoReveal(
                  delay: const Duration(milliseconds: 160),
                  child: DemoSurfaceCard(
                    semanticLabel: 'AI處理說明',
                    hint: '雙擊查看 AI 與真人協作方式',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AccessibleText(
                          'AI 先處理，複雜問題再轉真人',
                          style: TextStyle(
                            color: AppTheme.stageTextPrimary,
                            fontSize: AppTheme.fontSizeNormal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        const _FlowRow(
                          icon: Icons.smart_toy_outlined,
                          title: '標準化問題',
                          subtitle: 'AI 直接回復，適合讀文字、顏色識別、環境描述等場景。',
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        const _FlowRow(
                          icon: Icons.volunteer_activism_outlined,
                          title: '複雜或情緒化問題',
                          subtitle: '當回答不確定時，可一鍵轉真人志願者繼續處理。',
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        const _FlowRow(
                          icon: Icons.emergency_outlined,
                          title: '緊急情況',
                          subtitle: '識別到摔倒、迷路、危險等關鍵詞時，會提示發起 SOS 廣播。',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openDefaultChat(BuildContext context) {
    pushDemoStageRoute(
      context,
      page: const DemoAIChatScreen(
        title: 'AI智能對話',
        introMessage: '您好，我是 AI 助手智動。您可以直接說需求，也可以通過下方按鈕發語音或圖片，我會優先嚐試自己解決。',
        quickPrompts: ['幫我讀一下這個說明書', '描述一下我周圍的環境', '這件衣服是什麼顏色', '我需要真人志願者幫助'],
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
          const DemoGlassIconBadge(
            icon: Icons.multitrack_audio,
            size: 58,
            iconSize: 28,
            shape: DemoGlassIconShape.circle,
          ),
          const SizedBox(height: AppTheme.spacingL),
          AccessibleText(
            '先由 AI 快速響應\n必要時再無縫轉接志願者',
            style: TextStyle(
              fontSize: AppTheme.fontSizeLarge,
              height: 1.35,
              fontWeight: FontWeight.bold,
              color: AppTheme.stageTextPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          AccessibleText(
            '支持語音、文字、圖片三種輸入，適合手機端快速求助演示。',
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
              _HeroStat(label: '響應目標', value: '3 秒內'),
              _HeroStat(label: '演示模式', value: '本地可用'),
              _HeroStat(label: '輸入方式', value: '語音/文字/圖片'),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          AccessibleButton(
            label: '開始智能對話',
            semanticLabel: '開始智能對話按鈕',
            hint: '雙擊進入 AI 對話頁',
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
              icon: const LinkableSvgIcon(
                icon: LinkableIconName.volunteerMatch,
                size: 24,
                semanticLabel: '志願者匹配',
              ),
              label: const Text('複雜問題直接連接志願者'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.stageTextPrimary,
                side: BorderSide(
                  color: AppTheme.stageBorder.withValues(alpha: 0.82),
                  width: 1.5,
                ),
                backgroundColor: AppTheme.stageSurfaceStrong,
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
      hint: '雙擊打開${preset.label}演示',
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DemoGlassIconBadge(icon: preset.icon, size: 54, iconSize: 26),
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
                '進入演示',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeSmall,
                  color: preset.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppTheme.spacingXS),
              LinkableMaterialIcon(
                icon: Icons.arrow_forward,
                size: 18,
                color: preset.color,
                semanticLabel: '進入演示',
              ),
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
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DemoGlassIconBadge(
          icon: icon,
          size: 46,
          iconSize: 22,
          shape: DemoGlassIconShape.circle,
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
