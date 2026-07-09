import 'package:flutter/material.dart';

/// BuildContext扩展
extension BuildContextExtension on BuildContext {
  /// 获取主题
  ThemeData get theme => Theme.of(this);

  /// 获取颜色方案
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// 获取文本主题
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// 获取屏幕尺寸
  Size get screenSize => MediaQuery.of(this).size;

  /// 获取屏幕宽度
  double get screenWidth => MediaQuery.of(this).size.width;

  /// 获取屏幕高度
  double get screenHeight => MediaQuery.of(this).size.height;

  /// 获取安全区域padding
  EdgeInsets get safePadding => MediaQuery.of(this).padding;

  /// 是否为暗色模式
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// 显示SnackBar
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 隐藏键盘
  void hideKeyboard() {
    FocusScope.of(this).unfocus();
  }
}

/// String扩展
extension StringExtension on String {
  /// 限制字符串长度
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$suffix';
  }

  /// 是否为手机号
  bool get isPhoneNumber {
    final regex = RegExp(r'^1[3-9]\d{9}$');
    return regex.hasMatch(this);
  }

  /// 是否为验证码
  bool get isVerificationCode {
    final regex = RegExp(r'^\d{6}$');
    return regex.hasMatch(this);
  }

  /// 隐藏手机号中间4位
  String get maskedPhone {
    if (length != 11) return this;
    return '${substring(0, 3)}****${substring(7)}';
  }

  /// 转换为语义化标签（用于屏幕阅读器）
  String get semanticLabel {
    // 为数字添加停顿
    return replaceAllMapped(
      RegExp(r'(\d)'),
      (match) => '${match.group(0)} ',
    );
  }
}

/// DateTime扩展
extension DateTimeExtension on DateTime {
  /// 格式化为友好时间
  String toFriendlyString() {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inDays > 365) {
      return '${diff.inDays ~/ 365}年前';
    } else if (diff.inDays > 30) {
      return '${diff.inDays ~/ 30}个月前';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}天前';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}小时前';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  /// 格式化为日期字符串
  String toDateString() {
    return '$year年$month月$day日';
  }

  /// 格式化为时间字符串
  String toTimeString() {
    final hourStr = hour.toString().padLeft(2, '0');
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr';
  }

  /// 格式化为相对时间（如：3天前）
  String formatRelative() {
    return toFriendlyString();
  }

  /// 格式化为完整日期时间
  String formatDateTime() {
    return '$year年$month月$day日 ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// 格式化为日期
  String formatDate() {
    return toDateString();
  }
}

/// Duration扩展
extension DurationExtension on Duration {
  /// 格式化为分钟:秒
  String toMinutesSeconds() {
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// 格式化为小时:分钟:秒
  String toHoursMinutesSeconds() {
    final hours = inHours.toString().padLeft(2, '0');
    final minutes = inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}

/// List扩展
extension ListExtension<T> on List<T> {
  /// 安全获取元素
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

/// Widget扩展
extension WidgetExtension on Widget {
  /// 添加语义标签
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

  /// 添加点击效果
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

  /// 展开
  Widget get expanded {
    return Expanded(child: this);
  }
}
