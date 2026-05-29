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
              : '入口已保留，当前 DemoMode 不启动真实认证',
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
                        : '当前仍在竞赛 Demo 主线。邮箱页面保留在这里，真实登录需要切换到 RealMode。',
                    icon: Icons.alternate_email_rounded,
                    chips: [
                      DemoPill(
                        label: authReady ? 'Supabase Auth' : '入口保留',
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
                      '手机号验证码界面仍保留，但 Phase-2 不接真实短信。需要真实手机号登录时，要单独配置短信服务商。',
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
                hint: '双击使用 Supabase Auth 登录',
                icon: Icons.login_rounded,
                isLoading: _isLoading,
                backgroundColor: AppTheme.stageAccent,
                foregroundColor: AppTheme.stageBackground,
                onPressed: _isLoading ? null : _signIn,
              ),
              const SizedBox(height: AppTheme.spacingM),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _signUp,
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('注册'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _sendLoginLink,
                      icon: const Icon(Icons.mark_email_read_outlined),
                      label: const Text('发登录邮件'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
