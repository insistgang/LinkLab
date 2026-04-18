import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../accessible/index.dart';

class DemoDialog extends StatelessWidget {
  const DemoDialog({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.accentColor,
    this.content,
    this.actions = const [],
  });

  final String title;
  final String? description;
  final IconData? icon;
  final Color? accentColor;
  final Widget? content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final effectiveAccentColor = accentColor ?? AppTheme.stageAccent;
    return AlertDialog(
      backgroundColor: AppTheme.stageSurfaceStrong,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: effectiveAccentColor.withValues(alpha: 0.22)),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: effectiveAccentColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: effectiveAccentColor),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: AccessibleText(
                  title,
                  style: TextStyle(
                    color: AppTheme.stageTextPrimary,
                    fontSize: AppTheme.fontSizeXLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: 52,
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  effectiveAccentColor,
                  effectiveAccentColor.withValues(alpha: 0.42),
                ],
              ),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
      content:
          content ??
          AccessibleText(
            description ?? '',
            style: TextStyle(
              color: AppTheme.stageTextSecondary,
              fontSize: AppTheme.fontSizeNormal,
              height: 1.6,
            ),
          ),
      actions: actions,
    );
  }
}

Future<T?> showDemoStageDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withValues(alpha: 0.68),
    builder: builder,
  );
}

Future<T?> showDemoStageBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppTheme.stageSurfaceStrong,
    barrierColor: Colors.black.withValues(alpha: 0.68),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.stageBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 16),
                  builder(sheetContext),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

void showDemoStageSnackBar(
  BuildContext context, {
  required String message,
  IconData icon = Icons.info_outline,
  Color? accentColor,
}) {
  final effectiveAccentColor = accentColor ?? AppTheme.stageAccent;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: AppTheme.stageSurfaceStrong,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: effectiveAccentColor.withValues(alpha: 0.2)),
      ),
      content: Row(
        children: [
          Icon(icon, color: effectiveAccentColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppTheme.stageTextPrimary,
                fontSize: AppTheme.fontSizeSmall,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
