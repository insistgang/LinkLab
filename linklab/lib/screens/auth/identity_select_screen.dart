import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_auth.dart';
import '../../widgets/demo/demo_motion.dart';
import '../../widgets/demo/demo_routes.dart';
import '../../widgets/demo/demo_stage.dart';
import '../../widgets/demo/linkable_icon.dart';
import 'disability_select_screen.dart';

/// 身份選擇頁面
/// 新用戶登錄時選擇「我要尋求幫助」或「我想成爲志願者」
class IdentitySelectScreen extends StatefulWidget {
  const IdentitySelectScreen({super.key, required this.phone});

  final String phone;

  @override
  State<IdentitySelectScreen> createState() => _IdentitySelectScreenState();
}

class _IdentitySelectScreenState extends State<IdentitySelectScreen> {
  String? _selectedRole;

  void _onContinue() {
    if (_selectedRole == null) return;
    HapticFeedback.mediumImpact();
    pushDemoStageRoute(
      context,
      page: DisabilitySelectScreen(phone: widget.phone, role: _selectedRole!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DemoStageLiveBuilder(
      builder: (context) {
        return DemoStageScaffold(
          title: '選擇身份',
          subtitle: '選擇您的主要使用角色，後續可隨時調整',
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingL,
              AppTheme.spacingL,
              AppTheme.spacingL,
              120,
            ),
            children: [
              DemoReveal(
                child: DemoAuthBanner(
                  title: '歡迎加入互助網絡',
                  subtitle: '您希望以什麼身份使用本應用？選擇後將爲您定製首頁體驗。',
                  icon: Icons.badge_outlined,
                  chips: [
                    DemoPill(label: '可隨時調整', color: AppTheme.stageInfo),
                    DemoPill(label: 'Demo-first', color: AppTheme.stageAccent),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              DemoReveal(
                delay: const Duration(milliseconds: 80),
                child: DemoMetricStrip(
                  items: [
                    DemoMetricItem(
                      label: '當前步驟',
                      value: '身份選擇',
                      color: AppTheme.stageAccent,
                    ),
                    DemoMetricItem(
                      label: '下一步',
                      value: '障礙與偏好',
                      color: AppTheme.stageInfo,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingXL),
              // 求助者身份卡片
              DemoReveal(
                delay: const Duration(milliseconds: 130),
                child: _IdentityCard(
                  title: '我需要幫助',
                  description: '獲取AI助手和志願者幫助',
                  icon: LinkableIconName.needHelp,
                  materialIcon: Icons.accessibility_new_rounded,
                  isSelected: _selectedRole == 'seeker',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedRole = 'seeker';
                    });
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              // 志願者身份卡片
              DemoReveal(
                delay: const Duration(milliseconds: 170),
                child: _IdentityCard(
                  title: '我想幫助他人',
                  description: '成爲志願者，幫助有需要的人',
                  icon: LinkableIconName.volunteerRole,
                  materialIcon: Icons.volunteer_activism_outlined,
                  isSelected: _selectedRole == 'volunteer',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedRole = 'volunteer';
                    });
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              // 兩者皆是卡片
              DemoReveal(
                delay: const Duration(milliseconds: 210),
                child: _IdentityCard(
                  title: '兩者皆是',
                  description: '我既需要幫助，也願意在合適時幫助他人',
                  icon: LinkableIconName.both,
                  materialIcon: Icons.people_outline_rounded,
                  isSelected: _selectedRole == 'both',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedRole = 'both';
                    });
                  },
                ),
              ),
              if (_selectedRole != null) ...[
                const SizedBox(height: AppTheme.spacingL),
                DemoReveal(
                  delay: const Duration(milliseconds: 260),
                  child: DemoSurfaceCard(
                    color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.96),
                    child: AccessibleText(
                      _buildSelectionHint(_selectedRole!),
                      style: TextStyle(
                        color: AppTheme.stageTextSecondary,
                        fontSize: AppTheme.fontSizeSmall,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          bottomBar: AccessibleButton(
            label: '繼續',
            semanticLabel: '繼續下一步',
            hint: '雙擊繼續設置',
            backgroundColor: _selectedRole != null
                ? AppTheme.stageAccent
                : AppTheme.stageSurfaceStrong,
            foregroundColor: _selectedRole != null
                ? AppTheme.stageBackground
                : AppTheme.stageTextHint,
            onPressed: _selectedRole != null ? _onContinue : null,
          ),
        );
      },
    );
  }

  String _buildSelectionHint(String role) {
    switch (role) {
      case 'seeker':
        return '你將以求助者身份進入應用，首頁會優先突出 AI 求助和 SOS 主入口，底部導航顯示「AI助手」。';
      case 'volunteer':
        return '你將以志願者身份進入應用，首頁會顯示「待幫助」列表，方便你快速響應求助請求。';
      case 'both':
        return '該身份最接近競賽版當前展示方式：既可求助，也可在設定中體現願意幫助他人的狀態。';
      default:
        return '';
    }
  }
}

/// 身份選擇卡片組件
/// 大按鈕設計，帶圖標和描述，觸摸目標 >= 48dp
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.materialIcon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String description;
  final LinkableIconName icon;
  final IconData materialIcon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title: $description',
      hint: isSelected ? '已選中' : '雙擊選擇此身份',
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: BoxDecoration(
            gradient: isSelected ? AppTheme.stageAccentGradient : null,
            color: isSelected
                ? null
                : AppTheme.stageSurfaceStrong.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge + 8),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : AppTheme.stageBorder.withValues(alpha: 0.72),
              width: isSelected ? 0 : 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.stageAccent.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // 圖標區域
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.18)
                      : AppTheme.stageAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: LinkableSvgIcon(
                    icon: icon,
                    size: 40,
                    semanticLabel: title,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingL),
              // 文字區域
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AccessibleText(
                      title,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppTheme.stageTextPrimary,
                        fontSize: AppTheme.fontSizeXLarge,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    AccessibleText(
                      description,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.85)
                            : AppTheme.stageTextSecondary,
                        fontSize: AppTheme.fontSizeNormal,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              // 選中狀態指示
              if (isSelected)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
