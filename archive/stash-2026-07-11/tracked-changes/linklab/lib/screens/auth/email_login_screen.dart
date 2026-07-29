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
        _errorText = '请输入有效邮箱后再发送登录邮件。';
        _infoText = null;
      });
      return;
    }

    await _runAuthAction(() async {
      await ref.read(appSessionProvider.notifier).sendEmailLoginLink(email);
      if (!mounted) return;
      _setInfo('登录邮件已发送，请打开邮箱完成登录。');
      showDemoStageSnackBar(
        context,
        message: '登录邮件已发送',
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
        _errorText = '登录失败，请稍后再试。';
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
          title: '邮箱登录',
          subtitle: authReady
              ? 'RealMode 使用 Supabase Auth，不接短信服务商'
              : 'DemoMode 使用本地邮箱账号，不依赖外部认证',
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
                    title: '使用邮箱进入 LinkAble',
                    subtitle: authReady
                        ? '本阶段只接真实登录态。不会创建业务表，也不会触发匹配、AI、WebRTC 或 SOS。'
                        : '当前仍在竞赛 Demo 主线。输入任意有效邮箱和 6 位以上密码，即可使用本地账号进入应用。',
                    icon: Icons.alternate_email_rounded,
                    chips: [
                      DemoPill(
                        label: authReady ? 'Supabase Auth' : '本地登录',
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
                            label: '邮箱',
                            hint: 'name@example.com',
                            semanticLabel: '邮箱输入框，请输入你的邮箱地址',
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
                              if (email.isEmpty) return '请输入邮箱';
                              if (!_isValidEmail(email)) return '请输入有效邮箱';
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.spacingL),
                          AccessibleTextField(
                            controller: _passwordController,
                            label: '密码',
                            hint: '至少 6 位',
                            semanticLabel: '密码输入框，请输入至少 6 位密码',
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
                                return '请输入密码';
                              }
                              if (value.length < 6) {
                                return '密码至少 6 位';
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
                          ? '手机号验证码界面仍保留，但 Phase-2 不接真实短信。需要真实手机号登录时，要单独配置短信服务商。'
                          : '本地邮箱登录仅用于手机试装和竞赛演示。真实账号登录会在 RealMode 且 Supabase 配置完整时启用。',
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
                label: '邮箱登录',
                semanticLabel: '使用邮箱和密码登录',
                hint: authReady ? '双击使用 Supabase Auth 登录' : '双击使用本地演示邮箱账号登录',
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
            label: '注册',
            icon: Icons.person_add_alt_1_rounded,
            onPressed: isLoading ? null : onSignUp,
          ),
          _SecondaryActionButton(
            label: '发登录邮件',
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
