import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/app_session_service.dart';
import '../accessible/index.dart';

class DemoStageScaffold extends StatelessWidget {
  const DemoStageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions,
    this.bottomBar,
    this.showBackButton = true,
    this.onBackPressed,
    this.extendBody = false,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottomBar;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool extendBody;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.stageBackground,
      resizeToAvoidBottomInset: true,
      extendBody: extendBody,
      body: Stack(
        children: [
          const Positioned.fill(child: _DemoStageBackdrop()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingM,
                    AppTheme.spacingM,
                    AppTheme.spacingM,
                    0,
                  ),
                  child: Column(
                    children: [
                      const _DemoStageStatusStrip(),
                      const SizedBox(height: AppTheme.spacingM),
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                        decoration: AppTheme.stageCardDecoration(
                          color: AppTheme.stageSurfaceStrong.withValues(
                            alpha: 0.88,
                          ),
                          borderRadius: BorderRadius.circular(26),
                          borderColor: AppTheme.stageBorder.withValues(
                            alpha: 0.44,
                          ),
                        ),
                        child: _DemoStageHeader(
                          title: title,
                          subtitle: subtitle,
                          actions: actions,
                          showBackButton: showBackButton,
                          onBackPressed: onBackPressed,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth > 520
                          ? 520.0
                          : constraints.maxWidth;
                      return Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: width,
                          height: constraints.maxHeight,
                          child: const _DemoStageEntrance().wrap(body),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: bottomBar == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingL,
                  AppTheme.spacingS,
                  AppTheme.spacingL,
                  AppTheme.spacingL,
                ),
                child: bottomBar,
              ),
            ),
    );
  }
}

class DemoSurfaceCard extends StatelessWidget {
  const DemoSurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.semanticLabel,
    this.hint,
    this.color,
    this.borderColor,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? hint;
  final Color? color;
  final Color? borderColor;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: margin,
      decoration: AppTheme.stageCardDecoration(
        color: color,
        borderColor: borderColor,
        borderRadius: borderRadius,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius:
              borderRadius ??
              BorderRadius.circular(AppTheme.borderRadiusLarge + 4),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppTheme.spacingL),
            child: child,
          ),
        ),
      ),
    );

    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      hint: hint,
      child: content,
    );
  }
}

class DemoPill extends StatelessWidget {
  const DemoPill({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.backgroundColor,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.stageAccent;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? effectiveColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: effectiveColor.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: effectiveColor),
            const SizedBox(width: AppTheme.spacingXS),
          ],
          AccessibleText(
            label,
            style: TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              color: effectiveColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class DemoSectionTitle extends StatelessWidget {
  const DemoSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AccessibleText(
                title,
                style: TextStyle(
                  color: AppTheme.stageTextPrimary,
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppTheme.spacingXS),
                AccessibleText(
                  subtitle!,
                  style: TextStyle(
                    color: AppTheme.stageTextSecondary,
                    fontSize: AppTheme.fontSizeSmall,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _DemoStageEntrance {
  const _DemoStageEntrance();

  Widget wrap(Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 12, end: 0),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, offsetY, _) {
        final progress = 1 - (offsetY / 12).clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, offsetY),
          child: Opacity(opacity: 0.92 + (progress * 0.08), child: child),
        );
      },
    );
  }
}

class _DemoStageHeader extends StatelessWidget {
  const _DemoStageHeader({
    required this.title,
    this.subtitle,
    this.actions,
    required this.showBackButton,
    this.onBackPressed,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBackButton && Navigator.of(context).canPop())
          Semantics(
            button: true,
            label: '返回',
            hint: '双击返回上一页',
            child: InkWell(
              onTap: onBackPressed ?? () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
              child: Ink(
                width: AppTheme.minTouchTarget + 8,
                height: AppTheme.minTouchTarget + 8,
                decoration: BoxDecoration(
                  color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusLarge,
                  ),
                  border: Border.all(
                    color: AppTheme.stageBorder.withValues(alpha: 0.78),
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: AppTheme.stageTextPrimary,
                ),
              ),
            ),
          )
        else
          const SizedBox(width: AppTheme.minTouchTarget + 8),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacingXS),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccessibleText(
                  title,
                  isHeader: true,
                  style: TextStyle(
                    color: AppTheme.stageTextPrimary,
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Container(
                  width: 46,
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: AppTheme.stageAccentGradient,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppTheme.spacingS),
                  AccessibleText(
                    subtitle!,
                    style: TextStyle(
                      color: AppTheme.stageTextSecondary,
                      fontSize: AppTheme.fontSizeSmall,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingS),
        _ThemeModeButton(),
        if (actions != null) ...[
          const SizedBox(width: AppTheme.spacingS),
          ...actions!,
        ],
      ],
    );
  }
}

class _DemoStageStatusStrip extends StatelessWidget {
  const _DemoStageStatusStrip();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        children: [
          AccessibleText(
            '09:41',
            style: TextStyle(
              color: AppTheme.stageTextPrimary,
              fontSize: AppTheme.fontSizeSmall,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const Spacer(),
          _StatusChip(label: 'Demo 主线', dotColor: AppTheme.stageAccent),
          const SizedBox(width: AppTheme.spacingS),
          _StatusChip(label: '无障碍已就绪', dotColor: AppTheme.stageSuccess),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.dotColor});

  final String label;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingS,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.stageBorder.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppTheme.spacingXS),
          AccessibleText(
            label,
            style: TextStyle(
              color: AppTheme.stageTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoStageBackdrop extends StatelessWidget {
  const _DemoStageBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppTheme.stageHeroGradient),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _DemoStagePatternPainter()),
            ),
          ),
          Positioned(
            top: -90,
            right: -40,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.stageAccent.withValues(alpha: 0.18),
                ),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -120,
            child: IgnorePointer(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.stageInfo.withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -70,
            child: IgnorePointer(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.stageSuccess.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoStagePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppTheme.stageBorder.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final accentPaint = Paint()
      ..color = AppTheme.stageAccent.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (var i = 0; i < 7; i++) {
      final dy = size.height * 0.14 + (i * size.height * 0.12);
      canvas.drawLine(
        Offset(size.width * 0.08, dy),
        Offset(size.width * 0.92, dy),
        linePaint,
      );
    }

    final topArc = Path()
      ..moveTo(size.width * 0.58, 0)
      ..quadraticBezierTo(
        size.width * 0.96,
        size.height * 0.12,
        size.width * 0.82,
        size.height * 0.36,
      );
    canvas.drawPath(topArc, accentPaint);

    final bottomArc = Path()
      ..moveTo(0, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.26,
        size.height * 0.74,
        size.width * 0.42,
        size.height,
      );
    canvas.drawPath(bottomArc, linePaint);

    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    for (final point in [
      Offset(size.width * 0.18, size.height * 0.2),
      Offset(size.width * 0.76, size.height * 0.28),
      Offset(size.width * 0.34, size.height * 0.66),
      Offset(size.width * 0.82, size.height * 0.78),
    ]) {
      canvas.drawCircle(point, 2.2, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ThemeModeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final session = AppSessionService.instance;

    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final isDayMode = session.isDayStageMode;
        final icon = isDayMode ? Icons.dark_mode_outlined : Icons.light_mode;
        final label = isDayMode ? '切换到深夜模式' : '切换到日间模式';

        return Semantics(
          button: true,
          label: label,
          hint: '双击切换当前界面配色模式',
          child: InkWell(
            onTap: () {
              session.toggleStageMode();
            },
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
            child: Ink(
              width: AppTheme.minTouchTarget + 8,
              height: AppTheme.minTouchTarget + 8,
              decoration: BoxDecoration(
                color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                border: Border.all(
                  color: AppTheme.stageBorder.withValues(alpha: 0.78),
                ),
              ),
              child: Icon(icon, color: AppTheme.stageAccent),
            ),
          ),
        );
      },
    );
  }
}
