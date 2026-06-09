import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../demo/linkable_icon.dart';

/// 無障礙Scaffold組件
/// 提供統一的頁面結構和焦點管理
class AccessibleScaffold extends StatelessWidget {
  const AccessibleScaffold({
    super.key,
    this.title,
    this.body,
    this.leading,
    this.actions,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.extendBodyBehindAppBar = false,
    this.extendBody = false,
    this.drawer,
    this.onBackPressed,
  });

  final String? title;
  final Widget? body;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool extendBodyBehindAppBar;
  final bool extendBody;
  final Widget? drawer;
  final VoidCallback? onBackPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppTheme.backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      extendBody: extendBody,
      drawer: drawer,
      appBar: title != null
          ? AppBar(
              title: Semantics(
                header: true,
                child: Text(
                  title!,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              leading:
                  leading ??
                  (Navigator.canPop(context)
                      ? Semantics(
                          button: true,
                          label: '返回',
                          hint: '雙擊返回上一頁',
                          child: IconButton(
                            icon: const LinkableMaterialIcon(
                              icon: Icons.arrow_back,
                              semanticLabel: '返回',
                            ),
                            onPressed:
                                onBackPressed ??
                                () {
                                  Navigator.of(context).pop();
                                },
                          ),
                        )
                      : null),
              actions: actions,
            )
          : null,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}

/// 無障礙頁面包裝器
/// 自動處理頁面焦點和語義化
class AccessiblePage extends StatelessWidget {
  const AccessiblePage({
    super.key,
    required this.child,
    this.semanticLabel,
    this.autofocus = true,
  });

  final Widget child;
  final String? semanticLabel;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: Focus(autofocus: autofocus, child: child),
    );
  }
}

/// 無障礙列表項
/// 確保列表項具有正確的觸摸目標和語義
class AccessibleListTile extends StatelessWidget {
  const AccessibleListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.semanticLabel,
    this.hint,
    this.selected = false,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? hint;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: semanticLabel,
      hint: hint,
      child: ListTile(
        title: title,
        subtitle: subtitle,
        leading: leading != null
            ? SizedBox(
                width: AppTheme.minTouchTarget,
                height: AppTheme.minTouchTarget,
                child: Center(child: leading),
              )
            : null,
        trailing: trailing != null
            ? SizedBox(
                width: AppTheme.minTouchTarget,
                height: AppTheme.minTouchTarget,
                child: Center(child: trailing),
              )
            : null,
        onTap: onTap,
        selected: selected,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
        minLeadingWidth: AppTheme.minTouchTarget,
        minVerticalPadding: AppTheme.spacingM,
      ),
    );
  }
}

/// 無障礙卡片
class AccessibleCard extends StatelessWidget {
  const AccessibleCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.hint,
    this.elevation = 2,
    this.margin,
    this.padding,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? hint;
  final double elevation;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    Widget card = Card(
      elevation: elevation,
      margin: margin ?? const EdgeInsets.all(AppTheme.spacingS),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppTheme.spacingM),
        child: child,
      ),
    );

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        child: card,
      );
    }

    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      hint: hint,
      child: card,
    );
  }
}
