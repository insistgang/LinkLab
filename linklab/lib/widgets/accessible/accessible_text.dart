import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../demo/linkable_icon.dart';

/// 無障礙文本組件
/// 支持動態字體縮放，確保屏幕閱讀器可以正確讀取
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
    // 合併樣式，確保字體大小不小於最小值
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

  /// 合併樣式，確保最小字體大小
  TextStyle _mergeWithMinimumSize(BuildContext context) {
    final baseStyle = style ?? Theme.of(context).textTheme.bodyMedium;
    final fontSize = baseStyle?.fontSize ?? AppTheme.fontSizeNormal;

    // 確保字體不小於14sp（無障礙要求）
    final effectiveFontSize = fontSize < AppTheme.fontSizeSmall
        ? AppTheme.fontSizeSmall
        : fontSize;

    return baseStyle?.copyWith(fontSize: effectiveFontSize) ??
        TextStyle(fontSize: effectiveFontSize);
  }
}

/// 無障礙標題組件
class AccessibleHeading extends StatelessWidget {
  const AccessibleHeading(
    this.data, {
    super.key,
    this.level = 1,
    this.semanticLabel,
    this.textAlign,
  });

  final String data;
  final int level; // 1-3, 對應不同大小
  final String? semanticLabel;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 根據級別選擇樣式
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

/// 無障礙標籤組件（用於表單標籤）
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
    final effectiveLabel = semanticLabel ?? (required ? '$data，必填項' : data);

    return Semantics(
      label: effectiveLabel,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AccessibleText(
            data,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
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

/// 無障礙錯誤文本組件
class AccessibleErrorText extends StatelessWidget {
  const AccessibleErrorText(this.data, {super.key, this.semanticLabel});

  final String data;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? '錯誤：$data',
      liveRegion: true, // 自動通知屏幕閱讀器
      child: Padding(
        padding: const EdgeInsets.only(top: AppTheme.spacingS),
        child: Row(
          children: [
            const LinkableSvgIcon(
              icon: LinkableIconName.emergency,
              size: AppTheme.fontSizeNormal,
              semanticLabel: '錯誤',
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
