import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

/// 无障碍大按钮组件
/// 适用于视障用户，具有以下特点：
/// - 触摸目标大于48x48dp
/// - 高对比度颜色
/// - 完整的语义标签
/// - 触觉反馈
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
    // 确定颜色
    final bgColor = isEmergency
        ? AppTheme.emergencyColor
        : (backgroundColor ?? AppTheme.primaryColor);
    final fgColor = foregroundColor ?? AppTheme.textOnPrimary;

    // 确定高度
    final btnHeight =
        height ??
        (isEmergency
            ? AppTheme.emergencyButtonHeight
            : AppTheme.largeButtonHeight);

    // 语义标签
    final effectiveSemanticLabel = semanticLabel ?? label;
    final effectiveHint = hint ?? (isEmergency ? '双击触发紧急求助' : '双击执行$label操作');

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
            height: btnHeight,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
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
                        Icon(
                          icon,
                          color: fgColor,
                          size: AppTheme.fontSizeXLarge,
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                          color: fgColor,
                          fontSize: isEmergency
                              ? AppTheme.fontSizeXLarge
                              : AppTheme.fontSizeLarge,
                          fontWeight: FontWeight.bold,
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

/// 无障碍图标按钮
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
      hint: hint ?? '双击执行$semanticLabel',
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
            child: Icon(
              icon,
              size: iconSize,
              color: iconColor ?? AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// 无障碍浮动操作按钮
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
      hint: hint ?? '双击$semanticLabel',
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
        child: Icon(icon, size: AppTheme.fontSizeXLarge),
      ),
    );
  }
}
