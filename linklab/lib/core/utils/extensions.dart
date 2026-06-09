import 'package:flutter/material.dart';

/// BuildContext擴展
extension BuildContextExtension on BuildContext {
  /// 獲取主題
  ThemeData get theme => Theme.of(this);

  /// 獲取顏色方案
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// 獲取文本主題
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// 獲取屏幕尺寸
  Size get screenSize => MediaQuery.of(this).size;

  /// 獲取屏幕寬度
  double get screenWidth => MediaQuery.of(this).size.width;

  /// 獲取屏幕高度
  double get screenHeight => MediaQuery.of(this).size.height;

  /// 獲取安全區域padding
  EdgeInsets get safePadding => MediaQuery.of(this).padding;

  /// 是否爲暗色模式
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// 顯示SnackBar
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 隱藏鍵盤
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }
}

/// String擴展
extension StringExtension on String {
  /// 限制字符串長度
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$suffix';
  }

  /// 是否爲手機號
  bool get isPhoneNumber {
    final regex = RegExp(r'^1[3-9]\d{9}$');
    return regex.hasMatch(this);
  }

  /// 是否爲驗證碼
  bool get isVerificationCode {
    final regex = RegExp(r'^\d{6}$');
    return regex.hasMatch(this);
  }

  /// 隱藏手機號中間4位
  String get maskedPhone {
    if (length != 11) return this;
    return '${substring(0, 3)}****${substring(7)}';
  }

  /// 轉換爲語義化標籤（用於屏幕閱讀器）
  String get semanticLabel {
    // 爲數字添加停頓
    return replaceAllMapped(
      RegExp(r'(\d)'),
      (match) => '${match.group(0)} ',
    );
  }
}

/// DateTime擴展
extension DateTimeExtension on DateTime {
  /// 格式化爲友好時間
  String toFriendlyString() {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inDays > 365) {
      return '${diff.inDays ~/ 365}年前';
    } else if (diff.inDays > 30) {
      return '${diff.inDays ~/ 30}個月前';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}天前';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}小時前';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分鐘前';
    } else {
      return '剛剛';
    }
  }

  /// 格式化爲日期字符串
  String toDateString() {
    return '$year年$month月$day日';
  }

  /// 格式化爲時間字符串
  String toTimeString() {
    final hourStr = hour.toString().padLeft(2, '0');
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr';
  }

  /// 格式化爲相對時間（如：3天前）
  String formatRelative() {
    return toFriendlyString();
  }

  /// 格式化爲完整日期時間
  String formatDateTime() {
    return '$year年$month月$day日 ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// 格式化爲日期
  String formatDate() {
    return toDateString();
  }
}

/// Duration擴展
extension DurationExtension on Duration {
  /// 格式化爲分鐘:秒
  String toMinutesSeconds() {
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// 格式化爲小時:分鐘:秒
  String toHoursMinutesSeconds() {
    final hours = inHours.toString().padLeft(2, '0');
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}

/// List擴展
extension ListExtension<T> on List<T> {
  /// 安全獲取元素
  T? getOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// 分割列表
  List<List<T>> chunk(int size) {
    final result = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      result.add(sublist(i, i + size > length ? length : i + size));
    }
    return result;
  }
}

/// Widget擴展
extension WidgetExtension on Widget {
  /// 添加語義標籤
  Widget withSemantics({
    required String label,
    String? hint,
    bool button = false,
    bool header = false,
    bool link = false,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: button,
      header: header,
      link: link,
      onTap: onTap,
      child: this,
    );
  }

  /// 添加點擊效果
  Widget withTap(VoidCallback onTap, {String? semanticLabel}) {
    final gestureDetector = GestureDetector(
      onTap: onTap,
      child: this,
    );

    if (semanticLabel != null) {
      return Semantics(
        button: true,
        label: semanticLabel,
        child: gestureDetector,
      );
    }

    return gestureDetector;
  }

  /// 添加padding
  Widget withPadding(EdgeInsets padding) {
    return Padding(padding: padding, child: this);
  }

  /// 居中
  Widget get centered {
    return Center(child: this);
  }

  /// 展開
  Widget get expanded {
    return Expanded(child: this);
  }
}
