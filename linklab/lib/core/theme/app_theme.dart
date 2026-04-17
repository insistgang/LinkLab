import 'package:flutter/material.dart';

/// 共感LinkAble应用主题配置
/// 遵循WCAG 2.1 AAA无障碍标准
class AppTheme {
  // 私有构造函数，防止实例化
  AppTheme._();

  // 品牌色 - 高对比度设计
  static const Color primaryColor = Color(0xFF1565C0); // 深蓝色
  static const Color primaryLight = Color(0xFF5E92F3);
  static const Color primaryDark = Color(0xFF003C8F);

  // 辅助色
  static const Color secondaryColor = Color(0xFF2E7D32); // 绿色
  static const Color secondaryLight = Color(0xFF60AD5E);
  static const Color secondaryDark = Color(0xFF005005);

  // 强调色
  static const Color accentColor = Color(0xFFFF6F00); // 橙色
  static const Color accentLight = Color(0xFFFFA040);
  static const Color accentDark = Color(0xFFC43E00);

  // 紧急/警告色
  static const Color emergencyColor = Color(0xFFD32F2F); // 红色
  static const Color warningColor = Color(0xFFF57C00); // 橙色
  static const Color successColor = Color(0xFF388E3C); // 绿色

  // 中性色 - 高对比度
  static const Color backgroundColor = Color(0xFFFFFFFF); // 纯白背景
  static const Color surfaceColor = Color(0xFFF5F5F5); // 浅灰表面
  static const Color cardColor = Color(0xFFFFFFFF);

  // 文字颜色 - 确保对比度 >= 7:1
  static const Color textPrimary = Color(0xFF000000); // 黑色
  static const Color textSecondary = Color(0xFF424242); // 深灰
  static const Color textHint = Color(0xFF616161); // 中灰
  static const Color textOnPrimary = Color(0xFFFFFFFF); // 白字
  static const Color backgroundGrey = Color(0xFFF5F5F5); // 浅灰背景
  static const Color successLight = Color(0xFF81C784); // 浅绿色
  static const Color errorColor = Color(0xFFD32F2F); // 错误红色

  // 边框和分割线
  static const Color borderColor = Color(0xFF424242);
  static const Color dividerColor = Color(0xFFBDBDBD);

  // 高对比度模式颜色
  static const Color highContrastBackground = Colors.black;
  static const Color highContrastText = Colors.yellow;
  static const Color highContrastPrimary = Colors.cyan;

  // 字体大小 - 支持动态缩放
  static const double fontSizeSmall = 14.0;
  static const double fontSizeNormal = 18.0;
  static const double fontSizeLarge = 24.0;
  static const double fontSizeXLarge = 32.0;
  static const double fontSizeXXLarge = 48.0;

  // 触摸目标大小 - 最小48dp
  static const double minTouchTarget = 48.0;
  static const double buttonHeight = 56.0;
  static const double largeButtonHeight = 72.0;
  static const double emergencyButtonHeight = 120.0;

  // 间距
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // 圆角
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 16.0;

  // 阴影
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x40000000), blurRadius: 4.0, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(color: Color(0x60000000), blurRadius: 8.0, offset: Offset(0, 4)),
  ];

  /// 获取亮色主题
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        onPrimary: textOnPrimary,
        primaryContainer: primaryLight,
        onPrimaryContainer: textOnPrimary,
        secondary: secondaryColor,
        onSecondary: textOnPrimary,
        secondaryContainer: secondaryLight,
        onSecondaryContainer: textOnPrimary,
        surface: surfaceColor,
        onSurface: textPrimary,
        error: emergencyColor,
        onError: textOnPrimary,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textOnPrimary,
          minimumSize: const Size(double.infinity, buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingL,
            vertical: spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingM,
            vertical: spacingS,
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeNormal,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 2),
          minimumSize: const Size(double.infinity, buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: spacingL,
            vertical: spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: borderColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: borderColor, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: primaryColor, width: 3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: emergencyColor, width: 2),
        ),
        contentPadding: const EdgeInsets.all(spacingM),
        labelStyle: const TextStyle(fontSize: fontSizeNormal),
        hintStyle: const TextStyle(fontSize: fontSizeNormal, color: textHint),
        errorStyle: const TextStyle(
          fontSize: fontSizeNormal,
          color: emergencyColor,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: fontSizeXXLarge,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: fontSizeXLarge,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: fontSizeLarge,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineLarge: TextStyle(
          fontSize: fontSizeXLarge,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: fontSizeLarge,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: fontSizeNormal,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(fontSize: fontSizeLarge, color: textPrimary),
        bodyMedium: TextStyle(fontSize: fontSizeNormal, color: textPrimary),
        bodySmall: TextStyle(fontSize: fontSizeSmall, color: textSecondary),
        labelLarge: TextStyle(
          fontSize: fontSizeLarge,
          fontWeight: FontWeight.bold,
          color: textOnPrimary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: textOnPrimary,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: fontSizeLarge,
          fontWeight: FontWeight.bold,
          color: textOnPrimary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: TextStyle(
          fontSize: fontSizeNormal,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TextStyle(fontSize: fontSizeSmall),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: spacingM,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textSecondary,
        contentTextStyle: const TextStyle(
          fontSize: fontSizeNormal,
          color: textOnPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: surfaceColor,
      ),
    );
  }

  /// 获取高对比度主题（用于视障用户）
  static ThemeData get highContrastTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: highContrastPrimary,
        onPrimary: Colors.black,
        secondary: Colors.yellow,
        onSecondary: Colors.black,
        surface: highContrastBackground,
        onSurface: highContrastText,
        error: Colors.red,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: highContrastBackground,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: fontSizeXXLarge,
          fontWeight: FontWeight.bold,
          color: highContrastText,
        ),
        displayMedium: TextStyle(
          fontSize: fontSizeXLarge,
          fontWeight: FontWeight.bold,
          color: highContrastText,
        ),
        bodyLarge: TextStyle(fontSize: fontSizeLarge, color: highContrastText),
        bodyMedium: TextStyle(
          fontSize: fontSizeNormal,
          color: highContrastText,
        ),
      ),
    );
  }
}
