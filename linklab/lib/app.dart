import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'config/app_config.dart';
import 'providers/app_session_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/home/main_screen.dart';

/// 应用根组件
/// 说明：
/// - 入口必须由 ProviderScope 包裹，满足全局 Riverpod 状态容器要求
/// - 竞赛版当前仍保留 Demo-first 主线，会话状态通过 Riverpod 包装旧会话服务
/// - 本类只负责组装 MaterialApp，不在此处重新创建状态容器
class LinkLabApp extends ConsumerWidget {
  const LinkLabApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(
      !AppConfig.isCompetitionDemoOnly || AppConfig.demoMode,
      'AGENTS.md §4.2：竞赛版默认启动必须锁定 Demo 主线',
    );

    final session = ref.watch(appSessionProvider);
    final preferences = session.preferences;
    AppTheme.setStageMode(session.stageMode);

    return MaterialApp(
      title: '共感LinkAble',
      debugShowCheckedModeBanner: false,
      theme: preferences.highContrastMode
          ? AppTheme.highContrastTheme
          : AppTheme.lightTheme,
      darkTheme: AppTheme.highContrastTheme,
      themeMode: ThemeMode.light,
      home: _buildInitialScreen(session),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final scaledText = preferences.fontScale.clamp(0.8, 2.0).toDouble();
        final childWidget = child ?? const SizedBox.shrink();

        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: TextScaler.linear(scaledText)),
          child: childWidget,
        );
      },
    );
  }

  Widget _buildInitialScreen(AppSessionState session) {
    // AGENTS.md §1 / §4.2：默认启动只允许进入登录、引导或 Demo 主线壳层，
    // 实验性真实页面与非 MVP 页面不得成为默认路由。
    if (!session.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (session.isLoggedIn) {
      return const MainScreen();
    }

    if (AppConfig.isRealMode) {
      return const LoginScreen();
    }

    if (session.isFirstLaunch) {
      return const OnboardingScreen();
    }

    return const LoginScreen();
  }
}
