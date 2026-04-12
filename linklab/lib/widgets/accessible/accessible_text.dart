import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// 无障碍文本组件
/// 支持动态字体缩放，确保屏幕阅读器可以正确读取
class AccessibleText extends StatelessWidget {
  const AccessibleText(
    this.data, {
    super.key,
    this.semanticLabel,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.isHeader = false,
    this.excludeFromSemantics = false,
  });

  final String data;
  final String? semanticLabel;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool isHeader;
  final bool excludeFromSemantics;

  @override
  Widget build(BuildContext context) {
    // 合并样式，确保字体大小不小于最小值
    final effectiveStyle = _mergeWithMinimumSize(context);

    return Semantics(
      label: semanticLabel ?? data,
      header: isHeader,
      excludeSemantics: excludeFromSemantics,
      child: Text(
        data,
        style: effectiveStyle,
        textAlign: textAlign,
        overflow: overflow,
        maxLines: maxLines,
      ),
    );
  }

  /// 合并样式，确保最小字体大小
  TextStyle _mergeWithMinimumSize(BuildContext context) {
    final baseStyle = style ?? Theme.of(context).textTheme.bodyMedium;
    final fontSize = baseStyle?.fontSize ?? AppTheme.fontSizeNormal;

    // 确保字体不小于14sp（无障碍要求）
    final effectiveFontSize = fontSize < AppTheme.fontSizeSmall
        ? AppTheme.fontSizeSmall
        : fontSize;

    return baseStyle?.copyWith(fontSize: effectiveFontSize) ??
        TextStyle(fontSize: effectiveFontSize);
  }
}

/// 无障碍标题组件
class AccessibleHeading extends StatelessWidget {
  const AccessibleHeading(
    this.data, {
    super.key,
    this.level = 1,
    this.semanticLabel,
    this.textAlign,
  });

  final String data;
  final int level; // 1-3, 对应不同大小
  final String? semanticLabel;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 根据级别选择样式
    TextStyle? style;
    switch (level) {
      case 1:
        style = theme.textTheme.displayMedium;
      case 2:
        style = theme.textTheme.headlineLarge;
      case 3:
        style = theme.textTheme.headlineMedium;
      default:
        style = theme.textTheme.headlineSmall;
    }

    return AccessibleText(
      data,
      semanticLabel: semanticLabel,
      style: style,
      textAlign: textAlign,
      isHeader: true,
    );
  }
}

/// 无障碍标签组件（用于表单标签）
class AccessibleLabel extends StatelessWidget {
  const AccessibleLabel(
    this.data, {
    super.key,
    this.required = false,
    this.semanticLabel,
  });

  final String data;
  final bool required;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = semanticLabel ??
        (required ? '$data，必填项' : data);

    return Semantics(
      label: effectiveLabel,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AccessibleText(
            data,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (required)
            const AccessibleText(
              ' *',
              style: TextStyle(
                color: AppTheme.emergencyColor,
                fontSize: AppTheme.fontSizeLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}

/// 无障碍错误文本组件
class AccessibleErrorText extends StatelessWidget {
  const AccessibleErrorText(
    this.data, {
    super.key,
    this.semanticLabel,
  });

  final String data;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? '错误：$data',
      liveRegion: true, // 自动通知屏幕阅读器
      child: Padding(
        padding: const EdgeInsets.only(top: AppTheme.spacingS),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: AppTheme.emergencyColor,
              size: AppTheme.fontSizeNormal,
            ),
            const SizedBox(width: AppTheme.spacingXS),
            AccessibleText(
              data,
              style: const TextStyle(
                color: AppTheme.emergencyColor,
                fontSize: AppTheme.fontSizeNormal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
