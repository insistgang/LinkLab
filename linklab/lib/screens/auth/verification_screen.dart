import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/app_session_provider.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_auth.dart';
import '../../widgets/demo/demo_motion.dart';
import '../../widgets/demo/demo_overlays.dart';
import '../../widgets/demo/demo_routes.dart';
import '../../widgets/demo/demo_stage.dart';
import '../home/main_screen.dart';
import 'identity_select_screen.dart';

/// 驗證碼頁面
class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key, required this.phone});

  final String phone;

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _onVerify() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorText = null;
      });

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });

        final session = ref.read(appSessionProvider);
        if (session.userProfile != null) {
          ref.read(appSessionProvider.notifier).loginExistingUser(widget.phone).then((_) {
            if (!mounted) return;
            pushAndRemoveUntilDemoStageRoute(
              context,
              page: const MainScreen(),
              predicate: (route) => false,
            );
          });
          return;
        }

        pushAndRemoveUntilDemoStageRoute(
          context,
          page: IdentitySelectScreen(phone: widget.phone),
          predicate: (route) => false,
        );
      });
    }
  }

  void _onResendCode() {
    showDemoStageSnackBar(
      context,
      message: '驗證碼已發送',
      icon: Icons.sms_outlined,
      accentColor: AppTheme.stageInfo,
    );
  }

  void _showVerificationHelp() {
    showDemoStageDialog<void>(
      context,
      builder: (dialogContext) => DemoDialog(
        title: '驗證碼說明',
        icon: Icons.help_outline_rounded,
        accentColor: AppTheme.stageInfo,
        description:
            '競賽演示版使用本地穩定驗證流程，不依賴真實短信服務。若現場未收到短信，可直接點擊"重新發送"，系統會繼續按演示路徑完成驗證。',
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.stageAccent,
              foregroundColor: AppTheme.stageBackground,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('我知道了'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maskedPhone =
        '${widget.phone.substring(0, 3)}****${widget.phone.substring(7)}';

    return DemoStageLiveBuilder(
      builder: (context) {
        return DemoStageScaffold(
          title: '輸入驗證碼',
          subtitle: '驗證碼驗證通過後，繼續完成身份與偏好設置',
          body: Form(
            key: _formKey,
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
                    title: '輸入並驗證驗證碼',
                    subtitle: '請輸入 6 位驗證碼。演示版保持流程穩定，驗證成功後會繼續完成首次資料設置。',
                    icon: Icons.mark_email_read_outlined,
                    chips: [
                      DemoPill(label: '6 位數字', color: AppTheme.stageAccent),
                      DemoPill(label: '可重新發送', color: AppTheme.stageInfo),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),
                DemoReveal(
                  delay: const Duration(milliseconds: 80),
                  child: DemoMetricStrip(
                    items: [
                      DemoMetricItem(
                        label: '手機號',
                        value: maskedPhone,
                        color: AppTheme.stageInfo,
                      ),
                      DemoMetricItem(
                        label: '下一步',
                        value: '身份與偏好',
                        color: AppTheme.stageAccent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),
                DemoReveal(
                  delay: const Duration(milliseconds: 140),
                  child: DemoSurfaceCard(
                    child: DemoAuthFormTheme(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AccessibleText(
                            '驗證碼已發送至 $maskedPhone',
                            style: TextStyle(
                              color: AppTheme.stageTextPrimary,
                              fontSize: AppTheme.fontSizeLarge,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingS),
                          AccessibleText(
                            '請輸入6位驗證碼',
                            style: TextStyle(
                              color: AppTheme.stageTextSecondary,
                              fontSize: AppTheme.fontSizeNormal,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingL),
                          AccessibleCodeField(
                            controller: _codeController,
                            autofocus: true,
                            onSubmitted: (_) => _onVerify(),
                            onSendCode: _onResendCode,
                          ),
                          if (_errorText != null) ...[
                            const SizedBox(height: AppTheme.spacingS),
                            AccessibleErrorText(_errorText!),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),
                DemoReveal(
                  delay: const Duration(milliseconds: 190),
                  child: Center(
                    child: TextButton(
                      onPressed: _showVerificationHelp,
                      child: Text(
                        '收不到驗證碼？',
                        style: TextStyle(color: AppTheme.stageAccent),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomBar: AccessibleButton(
            label: '驗證',
            semanticLabel: '驗證驗證碼',
            hint: '雙擊完成驗證並登錄',
            isLoading: _isLoading,
            backgroundColor: AppTheme.stageAccent,
            foregroundColor: AppTheme.stageBackground,
            onPressed: _onVerify,
          ),
        );
      },
    );
  }
}
