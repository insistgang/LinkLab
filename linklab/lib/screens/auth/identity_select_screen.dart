import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_auth.dart';
import '../../widgets/demo/demo_motion.dart';
import '../../widgets/demo/demo_routes.dart';
import '../../widgets/demo/demo_stage.dart';
import 'disability_select_screen.dart';

/// 身份选择页面
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
          title: '选择身份',
          subtitle: '默认只做一档简化身份收集，不增加复杂认证分支',
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
                  title: '欢迎加入互助网络',
                  subtitle: '您希望以什么身份使用本应用？当前竞赛版保持流程简洁，先完成主角色选择。',
                  icon: Icons.badge_outlined,
                  chips: [
                    DemoPill(label: '可随时调整', color: AppTheme.stageInfo),
                    DemoPill(label: 'Demo-first', color: AppTheme.stageAccent),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              DemoReveal(
                delay: Duration(milliseconds: 80),
                child: DemoMetricStrip(
                  items: [
                    DemoMetricItem(
                      label: '当前步骤',
                      value: '身份选择',
                      color: AppTheme.stageAccent,
                    ),
                    DemoMetricItem(
                      label: '下一步',
                      value: '障碍与偏好',
                      color: AppTheme.stageInfo,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              DemoReveal(
                delay: const Duration(milliseconds: 130),
                child: DemoSelectionCard(
                  title: '我需要帮助',
                  subtitle: '我是视障人士或当前需要帮助的人',
                  icon: Icons.accessibility_new_rounded,
                  isSelected: _selectedRole == 'seeker',
                  onTap: () {
                    setState(() {
                      _selectedRole = 'seeker';
                    });
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              DemoReveal(
                delay: const Duration(milliseconds: 170),
                child: DemoSelectionCard(
                  title: '我想帮助他人',
                  subtitle: '我是志愿者，愿意在需要时提供帮助',
                  icon: Icons.volunteer_activism_outlined,
                  isSelected: _selectedRole == 'volunteer',
                  onTap: () {
                    setState(() {
                      _selectedRole = 'volunteer';
                    });
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              DemoReveal(
                delay: const Duration(milliseconds: 210),
                child: DemoSelectionCard(
                  title: '两者皆是',
                  subtitle: '我既需要帮助，也愿意在合适时帮助他人',
                  icon: Icons.people_outline_rounded,
                  isSelected: _selectedRole == 'both',
                  onTap: () {
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
            label: '继续',
            semanticLabel: '继续下一步',
            hint: '双击继续设置',
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
        return '你将以求助者主视角进入后续设置，首页会优先突出 AI 求助和 SOS 主入口。';
      case 'volunteer':
        return '你仍会进入同一套 Demo 主线，但后续资料会记录为志愿者身份，便于展示互助双向价值。';
      case 'both':
        return '该身份最接近竞赛版当前展示方式：既可求助，也可在设定中体现愿意帮助他人的状态。';
      default:
        return '';
    }
  }
}
