import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';

/// 应用根组件
class LinkLabApp extends StatelessWidget {
  const LinkLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '共感LinkAble',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.highContrastTheme,
      themeMode: ThemeMode.light,
      home: const LoginScreen(),
      builder: (context, child) {
        // 确保所有页面都有正确的无障碍支持
        return MediaQuery(
          // 支持系统字体缩放
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 2.0),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
