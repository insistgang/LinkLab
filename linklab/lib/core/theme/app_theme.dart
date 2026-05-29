import 'package:flutter/material.dart';

enum DemoStageMode { night, day }

class _StagePalette {
  const _StagePalette({
    required this.background,
    required this.backgroundSoft,
    required this.surface,
    required this.surfaceStrong,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.accent,
    required this.accentLight,
    required this.success,
    required this.danger,
    required this.warning,
    required this.info,
    required this.heroGradient,
    required this.panelGradient,
    required this.accentGradient,
  });

  final Color background;
  final Color backgroundSoft;
  final Color surface;
  final Color surfaceStrong;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color accent;
  final Color accentLight;
  final Color success;
  final Color danger;
  final Color warning;
  final Color info;
  final LinearGradient heroGradient;
  final LinearGradient panelGradient;
  final LinearGradient accentGradient;
}

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

  static DemoStageMode _stageMode = DemoStageMode.day;

  static const _StagePalette _nightStagePalette = _StagePalette(
    background: Color(0xFF080510),      // 极深紫黑背景
    backgroundSoft: Color(0xFF0E0A1C),  // 暗紫背景
    surface: Color(0xFF2A1B54),         // 卡片背景 - 靠近按钮紫色调
    surfaceStrong: Color(0xFF352268),   // 导航栏/强表面 - 中紫
    border: Color(0xFF3D2A6E),          // 边框颜色（紫色边框）
    textPrimary: Color(0xFFF0F6FC),     // 主要文字 - 白色
    textSecondary: Color(0xFFB8A9D4),   // 次要文字 - 浅紫灰
    textHint: Color(0xFF8B7AAF),        // 提示文字
    accent: Color(0xFFB88CFF),          // 强调色 - 紫色
    accentLight: Color(0xFFD4BBFF),     // 浅强调色
    success: Color(0xFF56D364),         // 成功 - 绿色
    danger: Color(0xFFF85149),          // 危险 - 红色
    warning: Color(0xFFE3B341),         // 警告 - 黄色
    info: Color(0xFF79C0FF),            // 信息 - 蓝色
    heroGradient: LinearGradient(
      colors: [Color(0xFF1F6FEB), Color(0xFF9448FF), Color(0xFF58A6FF)],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    panelGradient: LinearGradient(
      colors: [Color(0xFF100B20), Color(0xFF0A0716), Color(0xFF060410)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    accentGradient: LinearGradient(
      colors: [Color(0xFFB88CFF), Color(0xFF9448FF), Color(0xFF6D28D9)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const _StagePalette _dayStagePalette = _StagePalette(
    background: Color(0xFFFFFFFF),
    backgroundSoft: Color(0xFFF3FFD9),
    surface: Color(0xEAF4FFE8),
    surfaceStrong: Color(0xF2EFFFF0),
    border: Color(0x99D4F5C8),
    textPrimary: Color(0xFF071006),
    textSecondary: Color(0xFF33422F),
    textHint: Color(0xFF5C6D55),
    accent: Color(0xFF5F1ACF),
    accentLight: Color(0xFF8D3DFF),
    success: Color(0xFF146F30),
    danger: Color(0xFFC82432),
    warning: Color(0xFF875900),
    info: Color(0xFF006E66),
    heroGradient: LinearGradient(
      colors: [Color(0xFFDFFF00), Color(0xFF6DFF58), Color(0xFF38E9D3)],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    panelGradient: LinearGradient(
      colors: [Color(0xF8F7FFE9), Color(0xEAF2FFE3), Color(0xDDF0FFF5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    accentGradient: LinearGradient(
      colors: [Color(0xFFB96BFF), Color(0xFF8D3DFF), Color(0xFF6D28D9)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static _StagePalette get _stagePalette =>
      _stageMode == DemoStageMode.day ? _dayStagePalette : _nightStagePalette;

  static DemoStageMode get stageMode => _stageMode;
  static bool get isDayStageMode => _stageMode == DemoStageMode.day;
  static bool get isNightStageMode => _stageMode == DemoStageMode.night;

  static void setStageMode(DemoStageMode mode) {
    _stageMode = mode;
  }

  // Demo 主线移动端舞台色板
  static Color get stageBackground => _stagePalette.background;
  static Color get stageBackgroundSoft => _stagePalette.backgroundSoft;
  static Color get stageSurface => _stagePalette.surface;
  static Color get stageSurfaceStrong => _stagePalette.surfaceStrong;
  static Color get stageBorder => _stagePalette.border;
  static Color get stageTextPrimary => _stagePalette.textPrimary;
  static Color get stageTextSecondary => _stagePalette.textSecondary;
  static Color get stageTextHint => _stagePalette.textHint;
  static Color get stageAccent => _stagePalette.accent;
  static Color get stageAccentLight => _stagePalette.accentLight;
  static Color get stageSuccess => _stagePalette.success;
  static Color get stageDanger => _stagePalette.danger;
  static Color get stageWarning => _stagePalette.warning;
  static Color get stageInfo => _stagePalette.info;

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

  // 深色模式颜色 - GitHub风格中性深色
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkCard = Color(0xFF21262D);
  static const Color darkComponentBg = Color(0xFF2D333B);
  static const Color darkComponentBorder = Color(0xFF373E47);
  static const Color darkTextPrimary = Color(0xFFF0F6FC);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkAccent = Color(0xFFB88CFF);

  // 高对比度模式颜色 - 基于深色模式但更高对比度
  static const Color highContrastBackground = Color(0xFF0D1117);
  static const Color highContrastSurface = Color(0xFF161B22);
  static const Color highContrastCard = Color(0xFF21262D);
  static const Color highContrastText = Color(0xFFFFFFFF);
  static const Color highContrastPrimary = Color(0xFF79C0FF);
  static const Color highContrastAccent = Color(0xFFB88CFF);

  // 字体大小 - 支持动态缩放
  static const double fontSizeXSmall = 12.0;
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

  static const List<BoxShadow> stageShadow = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 18.0,
      offset: Offset(0, 10),
    ),
  ];

  static LinearGradient get stageHeroGradient => _stagePalette.heroGradient;
  static LinearGradient get stagePanelGradient => _stagePalette.panelGradient;
  static LinearGradient get stageAccentGradient => _stagePalette.accentGradient;

  static BoxDecoration stageCardDecoration({
    Color? color,
    BorderRadius? borderRadius,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: color ?? stageSurface,
      borderRadius:
          borderRadius ?? BorderRadius.circular(AppTheme.borderRadiusLarge + 4),
      border: Border.all(
        color: borderColor ?? AppTheme.stageBorder.withValues(alpha: 0.72),
      ),
      boxShadow: stageShadow,
    );
  }

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
  /// 使用深色背景 + 高对比度文字，符合WCAG AAA标准
  static ThemeData get highContrastTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: highContrastPrimary,
        onPrimary: Colors.black,
        secondary: highContrastAccent,
        onSecondary: Colors.white,
        surface: highContrastSurface,
        onSurface: highContrastText,
        error: Color(0xFFFF6B6B),
        onError: Colors.white,
        surfaceContainerHighest: highContrastCard,
        surfaceContainerHigh: highContrastSurface,
      ),
      scaffoldBackgroundColor: highContrastBackground,
      cardTheme: CardThemeData(
        color: highContrastCard,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          side: const BorderSide(color: Color(0xFF4A5568), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: highContrastAccent,
          foregroundColor: Colors.white,
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
          foregroundColor: highContrastPrimary,
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
          foregroundColor: highContrastPrimary,
          side: const BorderSide(color: highContrastPrimary, width: 2),
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
        fillColor: highContrastSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: Color(0xFF4A5568), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: Color(0xFF4A5568), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: highContrastPrimary, width: 3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
        ),
        contentPadding: const EdgeInsets.all(spacingM),
        labelStyle: const TextStyle(
          fontSize: fontSizeNormal,
          color: highContrastText,
        ),
        hintStyle: const TextStyle(
          fontSize: fontSizeNormal,
          color: Color(0xFF8B949E),
        ),
        errorStyle: const TextStyle(
          fontSize: fontSizeNormal,
          color: Color(0xFFFF6B6B),
        ),
      ),
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
        displaySmall: TextStyle(
          fontSize: fontSizeLarge,
          fontWeight: FontWeight.bold,
          color: highContrastText,
        ),
        headlineLarge: TextStyle(
          fontSize: fontSizeXLarge,
          fontWeight: FontWeight.w600,
          color: highContrastText,
        ),
        headlineMedium: TextStyle(
          fontSize: fontSizeLarge,
          fontWeight: FontWeight.w600,
          color: highContrastText,
        ),
        headlineSmall: TextStyle(
          fontSize: fontSizeNormal,
          fontWeight: FontWeight.w600,
          color: highContrastText,
        ),
        bodyLarge: TextStyle(fontSize: fontSizeLarge, color: highContrastText),
        bodyMedium: TextStyle(
          fontSize: fontSizeNormal,
          color: highContrastText,
        ),
        bodySmall: TextStyle(
          fontSize: fontSizeSmall,
          color: Color(0xFF8B949E),
        ),
        labelLarge: TextStyle(
          fontSize: fontSizeLarge,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF161B22),
        foregroundColor: highContrastText,
        elevation: 4,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: fontSizeLarge,
          fontWeight: FontWeight.bold,
          color: highContrastText,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF352268),
        selectedItemColor: highContrastPrimary,
        unselectedItemColor: Color(0xFFB8A9D4),
        selectedLabelStyle: TextStyle(
          fontSize: fontSizeNormal,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TextStyle(fontSize: fontSizeSmall),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF3A2D5E),
        thickness: 1,
        space: spacingM,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF352268),
        contentTextStyle: const TextStyle(
          fontSize: fontSizeNormal,
          color: highContrastText,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: highContrastPrimary,
        linearTrackColor: Color(0xFF2D333B),
      ),
    );
  }
}
