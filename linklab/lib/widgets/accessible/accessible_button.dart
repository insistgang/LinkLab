import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../demo/linkable_icon.dart';

/// 無障礙大按鈕組件
/// 適用於視障用戶，具有以下特點：
/// - 觸摸目標大於48x48dp
/// - 高對比度顏色
/// - 完整的語義標籤
/// - 觸覺反饋
class AccessibleButton extends StatelessWidget {
  const AccessibleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
    this.hint,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.height,
    this.borderRadius,
    this.elevation = 2,
    this.isLoading = false,
    this.isEmergency = false,
    this.hapticFeedback = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final String? hint;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? height;
  final double? borderRadius;
  final double elevation;
  final bool isLoading;
  final bool isEmergency;
  final bool hapticFeedback;

  @override
  Widget build(BuildContext context) {
    // 確定顏色
    final bgColor = isEmergency
        ? AppTheme.emergencyColor
        : (backgroundColor ?? AppTheme.primaryColor);
    final fgColor = foregroundColor ?? AppTheme.textOnPrimary;

    // 確定高度
    final btnHeight =
        height ??
        (isEmergency
            ? AppTheme.emergencyButtonHeight
            : AppTheme.largeButtonHeight);

    // 語義標籤
    final effectiveSemanticLabel = semanticLabel ?? label;
    final effectiveHint = hint ?? (isEmergency ? '雙擊觸發緊急求助' : '雙擊執行$label操作');

    return Semantics(
      button: true,
      label: effectiveSemanticLabel,
      hint: effectiveHint,
      enabled: onPressed != null && !isLoading,
      child: Material(
        elevation: elevation,
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppTheme.borderRadiusLarge,
        ),
        color: bgColor,
        child: InkWell(
          onTap: onPressed != null && !isLoading
              ? () {
                  if (hapticFeedback) {
                    HapticFeedback.mediumImpact();
                  }
                  onPressed!();
                }
              : null,
          borderRadius: BorderRadius.circular(
            borderRadius ?? AppTheme.borderRadiusLarge,
          ),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: btnHeight),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingL,
              vertical: AppTheme.spacingM,
            ),
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: fgColor,
                      strokeWidth: 3,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        LinkableMaterialIcon(
                          icon: icon!,
                          size: AppTheme.fontSizeXLarge,
                          color: fgColor,
                          semanticLabel: label,
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: fgColor,
                            fontSize: isEmergency
                                ? AppTheme.fontSizeXLarge
                                : AppTheme.fontSizeLarge,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// 無障礙圖標按鈕
class AccessibleIconButton extends StatelessWidget {
  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.hint,
    this.size = AppTheme.minTouchTarget,
    this.iconSize = AppTheme.fontSizeLarge,
    this.backgroundColor,
    this.iconColor,
    this.hapticFeedback = true,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final String? hint;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool hapticFeedback;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      hint: hint ?? '雙擊執行$semanticLabel',
      enabled: onPressed != null,
      child: Material(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        child: InkWell(
          onTap: onPressed != null
              ? () {
                  if (hapticFeedback) {
                    HapticFeedback.lightImpact();
                  }
                  onPressed!();
                }
              : null,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          child: SizedBox(
            width: size,
            height: size,
            child: LinkableMaterialIcon(
              icon: icon,
              size: iconSize,
              color: iconColor ?? AppTheme.primaryColor,
              semanticLabel: semanticLabel,
            ),
          ),
        ),
      ),
    );
  }
}

/// 無障礙浮動操作按鈕
class AccessibleFloatingButton extends StatelessWidget {
  const AccessibleFloatingButton({
    super.key,
    required this.onPressed,
    required this.semanticLabel,
    this.hint,
    this.icon = Icons.add,
    this.isEmergency = false,
    this.hapticFeedback = true,
  });

  final VoidCallback? onPressed;
  final String semanticLabel;
  final String? hint;
  final IconData icon;
  final bool isEmergency;
  final bool hapticFeedback;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      hint: hint ?? '雙擊$semanticLabel',
      enabled: onPressed != null,
      child: FloatingActionButton(
        onPressed: onPressed != null
            ? () {
                if (hapticFeedback) {
                  HapticFeedback.mediumImpact();
                }
                onPressed!();
              }
            : null,
        backgroundColor: isEmergency
            ? AppTheme.emergencyColor
            : AppTheme.primaryColor,
        foregroundColor: AppTheme.textOnPrimary,
        elevation: 6,
        child: LinkableMaterialIcon(
          icon: icon,
          size: AppTheme.fontSizeXLarge,
          color: AppTheme.textOnPrimary,
          semanticLabel: semanticLabel,
        ),
      ),
    );
  }
}
