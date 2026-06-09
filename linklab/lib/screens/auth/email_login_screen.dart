import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_session_provider.dart';
import '../../widgets/accessible/index.dart';
import '../../widgets/demo/demo_auth.dart';
import '../../widgets/demo/demo_motion.dart';
import '../../widgets/demo/demo_overlays.dart';
import '../../widgets/demo/demo_routes.dart';
import '../../widgets/demo/demo_stage.dart';
import '../home/main_screen.dart';

class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;
  String? _infoText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_validateForm()) return;
    await _runAuthAction(() async {
      final outcome = await ref
          .read(appSessionProvider.notifier)
          .loginWithEmailPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (!mounted) return;
      if (outcome.signedIn) {
        _goHome();
      } else {
        _setInfo(outcome.message);
      }
    });
  }

  Future<void> _signUp() async {
    if (!_validateForm()) return;
    await _runAuthAction(() async {
      final outcome = await ref
          .read(appSessionProvider.notifier)
          .signUpWithEmailPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (!mounted) return;
      if (outcome.signedIn) {
        _goHome();
      } else {
        _setInfo(outcome.message);
      }
    });
  }

  Future<void> _sendLoginLink() async {
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      setState(() {
        _errorText = '請輸入有效郵箱後再發送登錄郵件。';
        _infoText = null;
      });
      return;
    }

    await _runAuthAction(() async {
      await ref.read(appSessionProvider.notifier).sendEmailLoginLink(email);
      if (!mounted) return;
      _setInfo('登錄郵件已發送，請打開郵箱完成登錄。');
      showDemoStageSnackBar(
        context,
        message: '登錄郵件已發送',
        icon: Icons.mark_email_read_outlined,
        accentColor: AppTheme.stageInfo,
      );
    });
  }

  bool _validateForm() {
    return _formKey.currentState?.validate() ?? false;
  }

  Future<void> _runAuthAction(Future<void> Function() action) async {
    setState(() {
      _isLoading = true;
      _errorText = null;
      _infoText = null;
    });

    try {
      await action();
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorText = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorText = '登錄失敗，請稍後再試。';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _setInfo(String message) {
    setState(() {
      _infoText = message;
      _errorText = null;
    });
  }

  void _goHome() {
    pushAndRemoveUntilDemoStageRoute(
      context,
      page: const MainScreen(),
      predicate: (route) => false,
    );
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    final authReady = FeatureFlags.enableSupabaseAuth;

    return DemoStageLiveBuilder(
      builder: (context) {
        return DemoStageScaffold(
          title: '郵箱登錄',
          subtitle: authReady
              ? 'RealMode 使用 Supabase Auth，不接短信服務商'
              : 'DemoMode 使用本地郵箱賬號，不依賴外部認證',
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingL,
                AppTheme.spacingL,
                AppTheme.spacingL,
                140,
              ),
              children: [
                DemoReveal(
                  child: DemoAuthBanner(
                    title: '使用郵箱進入 LinkAble',
                    subtitle: authReady
                        ? '本階段只接真實登錄態。不會創建業務表，也不會觸發匹配、AI、WebRTC 或 SOS。'
                        : '當前仍在競賽 Demo 主線。輸入任意有效郵箱和 6 位以上密碼，即可使用本地賬號進入應用。',
                    icon: Icons.alternate_email_rounded,
                    chips: [
                      DemoPill(
                        label: authReady ? 'Supabase Auth' : '本地登錄',
                        color: AppTheme.stageAccent,
                      ),
                      DemoPill(
                        label: authReady ? 'Anon key only' : 'DemoMode',
                        color: AppTheme.stageSuccess,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),
                DemoReveal(
                  delay: const Duration(milliseconds: 90),
                  child: DemoSurfaceCard(
                    child: DemoAuthFormTheme(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AccessibleTextField(
                            controller: _emailController,
                            label: '郵箱',
                            hint: 'name@example.com',
                            semanticLabel: '郵箱輸入框，請輸入你的郵箱地址',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            prefixIcon: Icon(
                              Icons.mail_outline_rounded,
                              color: AppTheme.stageAccent,
                            ),
                            enabled: !_isLoading,
                            autofocus: true,
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty) return '請輸入郵箱';
                              if (!_isValidEmail(email)) return '請輸入有效郵箱';
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.spacingL),
                          AccessibleTextField(
                            controller: _passwordController,
                            label: '密碼',
                            hint: '至少 6 位',
                            semanticLabel: '密碼輸入框，請輸入至少 6 位密碼',
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            prefixIcon: Icon(
                              Icons.lock_outline_rounded,
                              color: AppTheme.stageAccent,
                            ),
                            enabled: !_isLoading,
                            onSubmitted: (_) => _signIn(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '請輸入密碼';
                              }
                              if (value.length < 6) {
                                return '密碼至少 6 位';
                              }
                              return null;
                            },
                          ),
                          if (_errorText != null) ...[
                            const SizedBox(height: AppTheme.spacingM),
                            AccessibleErrorText(_errorText!),
                          ],
                          if (_infoText != null) ...[
                            const SizedBox(height: AppTheme.spacingM),
                            _InfoMessage(message: _infoText!),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),
                DemoReveal(
                  delay: const Duration(milliseconds: 150),
                  child: DemoSurfaceCard(
                    color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.96),
                    child: AccessibleText(
                      authReady
                          ? '手機號驗證碼界面仍保留，但 Phase-2 不接真實短信。需要真實手機號登錄時，要單獨配置短信服務商。'
                          : '本地郵箱登錄僅用於手機試裝和競賽演示。真實賬號登錄會在 RealMode 且 Supabase 配置完整時啓用。',
                      style: TextStyle(
                        color: AppTheme.stageTextSecondary,
                        fontSize: AppTheme.fontSizeSmall,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AccessibleButton(
                label: '郵箱登錄',
                semanticLabel: '使用郵箱和密碼登錄',
                hint: authReady ? '雙擊使用 Supabase Auth 登錄' : '雙擊使用本地演示郵箱賬號登錄',
                icon: Icons.login_rounded,
                isLoading: _isLoading,
                backgroundColor: AppTheme.stageAccent,
                foregroundColor: AppTheme.stageBackground,
                onPressed: _isLoading ? null : _signIn,
              ),
              const SizedBox(height: AppTheme.spacingM),
              _EmailAuthSecondaryActions(
                isLoading: _isLoading,
                onSignUp: _signUp,
                onSendLoginLink: _sendLoginLink,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmailAuthSecondaryActions extends StatelessWidget {
  const _EmailAuthSecondaryActions({
    required this.isLoading,
    required this.onSignUp,
    required this.onSendLoginLink,
  });

  final bool isLoading;
  final VoidCallback onSignUp;
  final VoidCallback onSendLoginLink;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useVerticalLayout =
            constraints.maxWidth < 360 || textScale > 1.35;
        final children = [
          _SecondaryActionButton(
            label: '註冊',
            icon: Icons.person_add_alt_1_rounded,
            onPressed: isLoading ? null : onSignUp,
          ),
          _SecondaryActionButton(
            label: '發登錄郵件',
            icon: Icons.mark_email_read_outlined,
            onPressed: isLoading ? null : onSendLoginLink,
          ),
        ];

        if (useVerticalLayout) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              children[0],
              const SizedBox(height: AppTheme.spacingS),
              children[1],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: children[0]),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(child: children[1]),
          ],
        );
      },
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _InfoMessage extends StatelessWidget {
  const _InfoMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppTheme.stageInfo),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: AccessibleText(
              message,
              style: TextStyle(
                color: AppTheme.stageTextPrimary,
                fontSize: AppTheme.fontSizeSmall,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
