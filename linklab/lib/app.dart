import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'config/app_config.dart';
import 'providers/app_session_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/home/main_screen.dart';

/// 應用根組件
/// 說明：
/// - 入口必須由 ProviderScope 包裹，滿足全局 Riverpod 狀態容器要求
/// - 競賽版當前仍保留 Demo-first 主線，會話狀態通過 Riverpod 包裝舊會話服務
/// - 本類只負責組裝 MaterialApp，不在此處重新創建狀態容器
class LinkLabApp extends ConsumerWidget {
  const LinkLabApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(
      !AppConfig.isCompetitionDemoOnly || AppConfig.demoMode,
      'AGENTS.md §4.2：競賽版默認啓動必須鎖定 Demo 主線',
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
    // AGENTS.md §1 / §4.2：默認啓動只允許進入登錄、引導或 Demo 主線殼層，
    // 實驗性真實頁面與非 MVP 頁面不得成爲默認路由。
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
