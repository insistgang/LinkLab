import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'services/app_session_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/home/main_screen.dart';

/// 应用根组件
class LinkLabApp extends StatelessWidget {
  const LinkLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AppSessionService.instance;

    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final preferences = session.preferences;

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
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(scaledText),
              ),
              child: childWidget,
            );
          },
        );
      },
    );
  }

  Widget _buildInitialScreen(AppSessionService session) {
    if (session.isLoggedIn) {
      return const MainScreen();
    }

    if (session.isFirstLaunch) {
      return const OnboardingScreen();
    }

    return const LoginScreen();
  }
}
