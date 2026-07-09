import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
// ignore: deprecated_member_use_from_same_package
import '../../services/app_session_service.dart';
import '../accessible/index.dart';
import '../brand/app_logo.dart';
import 'linkable_icon.dart';

enum DemoGlassIconShape { rounded, circle }

bool _useCompactDemoLayout(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);
  return mediaQuery.size.width < 430 || mediaQuery.textScaler.scale(1) > 1.15;
}

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
    this.showStatusStrip = false,
    this.showThemeModeButton = true,
    this.headerTopPadding = AppTheme.spacingM,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottomBar;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool extendBody;
  final bool showStatusStrip;
  final bool showThemeModeButton;
  final double headerTopPadding;

  @override
  Widget build(BuildContext context) {
    final session = AppSessionService.instance;
    final mediaQuery = MediaQuery.of(context);
    final compactPhone =
        _useCompactDemoLayout(context) || mediaQuery.size.height < 700;
    final availableHeight =
        (mediaQuery.size.height - mediaQuery.viewInsets.bottom).clamp(
          0.0,
          double.infinity,
        );
    final maxBottomBarHeight = availableHeight * 0.6;
    final effectiveHeaderTopPadding = compactPhone
        ? headerTopPadding.clamp(0.0, AppTheme.spacingS)
        : headerTopPadding;
    final bottomHorizontalPadding = compactPhone
        ? AppTheme.spacingM
        : AppTheme.spacingL;
    final bottomVerticalPadding = compactPhone
        ? AppTheme.spacingS
        : AppTheme.spacingL;

    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        return KeyedSubtree(
          key: ValueKey(session.stageMode),
          child: Scaffold(
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
                          0,
                          AppTheme.spacingM,
                          0,
                        ).copyWith(top: effectiveHeaderTopPadding),
                        child: Column(
                          children: [
                            if (showStatusStrip) ...[
                              const _DemoStageStatusStrip(),
                              const SizedBox(height: AppTheme.spacingM),
                            ],
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingXS,
                              ),
                              child: _DemoStageHeader(
                                title: title,
                                subtitle: subtitle,
                                actions: actions,
                                showBackButton: showBackButton,
                                showThemeModeButton: showThemeModeButton,
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
                : AnimatedPadding(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.only(
                      bottom: mediaQuery.viewInsets.bottom,
                    ),
                    child: SafeArea(
                      top: false,
                      child: Center(
                        heightFactor: 1,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: 520,
                            maxHeight: maxBottomBarHeight,
                          ),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              bottomHorizontalPadding,
                              AppTheme.spacingS,
                              bottomHorizontalPadding,
                              bottomVerticalPadding,
                            ),
                            child: SingleChildScrollView(
                              primary: false,
                              physics: const ClampingScrollPhysics(),
                              child: bottomBar,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class DemoStageLiveBuilder extends StatelessWidget {
  const DemoStageLiveBuilder({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppSessionService.instance,
      builder: (context, _) => builder(context),
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
    final compactLayout = _useCompactDemoLayout(context);
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
            padding:
                padding ??
                EdgeInsets.all(
                  compactLayout ? AppTheme.spacingM : AppTheme.spacingL,
                ),
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
    this.svgIcon,
    this.color,
    this.backgroundColor,
  });

  final String label;
  final IconData? icon;
  final LinkableIconName? svgIcon;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final compactLayout = _useCompactDemoLayout(context);
    final effectiveColor = color ?? AppTheme.stageAccent;
    final filled = backgroundColor == null;
    final foregroundColor = filled
        ? effectiveColor.computeLuminance() > 0.55
              ? AppTheme.stageTextPrimary
              : Colors.white
        : effectiveColor;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compactLayout ? 12 : AppTheme.spacingM,
        vertical: compactLayout ? 6 : AppTheme.spacingS,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? effectiveColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: filled
              ? Colors.white.withValues(alpha: 0.44)
              : effectiveColor.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (svgIcon != null) ...[
            LinkableSvgIcon(
              icon: svgIcon!,
              size: compactLayout ? 16 : 18,
              semanticLabel: label,
            ),
            const SizedBox(width: AppTheme.spacingXS),
          ] else if (icon != null) ...[
            LinkableMaterialIcon(
              icon: icon!,
              size: compactLayout ? 16 : 18,
              color: foregroundColor,
              semanticLabel: label,
            ),
            const SizedBox(width: AppTheme.spacingXS),
          ],
          AccessibleText(
            label,
            style: TextStyle(
              fontSize: compactLayout
                  ? AppTheme.fontSizeXSmall
                  : AppTheme.fontSizeSmall,
              color: foregroundColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class DemoGlassIconBadge extends StatelessWidget {
  const DemoGlassIconBadge({
    super.key,
    required this.icon,
    this.svgIcon,
    this.size = 56,
    this.iconSize,
    this.iconColor = const Color(0xFFFDFBFF),
    this.shape = DemoGlassIconShape.rounded,
    this.semanticLabel,
  });

  final IconData icon;
  final LinkableIconName? svgIcon;
  final double size;
  final double? iconSize;
  final Color iconColor;
  final DemoGlassIconShape shape;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (svgIcon != null) {
      final badge = LinkableSvgIcon(
        icon: svgIcon!,
        size: size,
        semanticLabel: semanticLabel,
      );
      return semanticLabel == null ? ExcludeSemantics(child: badge) : badge;
    }

    final linkableIcon = linkableIconForMaterial(icon);
    if (linkableIcon != null) {
      final badge = LinkableSvgIcon(
        icon: linkableIcon,
        size: size,
        semanticLabel: semanticLabel,
      );
      return semanticLabel == null ? ExcludeSemantics(child: badge) : badge;
    }

    final radius = shape == DemoGlassIconShape.circle ? size / 2 : size * 0.34;

    final badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8F2FF), Color(0xFFD9C4FF), Color(0xFF6C2CFF)],
          stops: [0.0, 0.46, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.56)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x804822E2).withValues(alpha: 0.34),
            blurRadius: size * 0.34,
            offset: Offset(size * 0.12, size * 0.18),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.18),
            blurRadius: size * 0.18,
            offset: Offset(-size * 0.08, -size * 0.08),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.46),
                    Colors.white.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.12),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              left: size * 0.12,
              top: size * 0.12,
              child: IgnorePointer(
                child: Container(
                  width: size * 0.42,
                  height: size * 0.18,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(size),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.52),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: LinkableMaterialIcon(
                icon: icon,
                size: iconSize ?? size * 0.42,
                color: iconColor,
                semanticLabel: semanticLabel,
              ),
            ),
          ],
        ),
      ),
    );

    if (semanticLabel == null) {
      return badge;
    }

    return Semantics(image: true, label: semanticLabel, child: badge);
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
    final compactLayout = _useCompactDemoLayout(context);
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
                  fontSize: compactLayout
                      ? AppTheme.fontSizeNormal
                      : AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppTheme.spacingXS),
                AccessibleText(
                  subtitle!,
                  style: TextStyle(
                    color: AppTheme.stageTextSecondary,
                    fontSize: compactLayout
                        ? AppTheme.fontSizeXSmall
                        : AppTheme.fontSizeSmall,
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
    required this.showThemeModeButton,
    this.onBackPressed,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool showThemeModeButton;
  final VoidCallback? onBackPressed;

  @override
  Widget build(BuildContext context) {
    final compactLayout = _useCompactDemoLayout(context);
    final navButtonSize = compactLayout
        ? AppTheme.minTouchTarget
        : AppTheme.minTouchTarget + 8;
    final navIconSize = compactLayout ? 34.0 : 44.0;
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
                width: navButtonSize,
                height: navButtonSize,
                decoration: BoxDecoration(
                  gradient: AppTheme.stageAccentGradient,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.56),
                  ),
                ),
                child: LinkableSvgIcon(
                  icon: LinkableIconName.back,
                  size: navIconSize,
                  semanticLabel: '返回',
                ),
              ),
            ),
          )
        else if (showBackButton)
          SizedBox(width: navButtonSize),
        if (showBackButton && Navigator.of(context).canPop())
          const SizedBox(width: AppTheme.spacingM),
        if (!showBackButton) ...[
          AppLogo(
            size: compactLayout ? 40 : 48,
            borderRadius: compactLayout ? 10 : 12,
          ),
          SizedBox(
            width: compactLayout ? AppTheme.spacingS : AppTheme.spacingM,
          ),
        ],
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
                    fontSize: compactLayout
                        ? AppTheme.fontSizeNormal
                        : AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(
                  height: compactLayout
                      ? AppTheme.spacingXS
                      : AppTheme.spacingS,
                ),
                Container(
                  width: compactLayout ? 38 : 46,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.stageAccent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(
                    height: compactLayout
                        ? AppTheme.spacingXS
                        : AppTheme.spacingS,
                  ),
                  AccessibleText(
                    subtitle!,
                    maxLines: compactLayout ? 2 : null,
                    overflow: compactLayout ? TextOverflow.ellipsis : null,
                    style: TextStyle(
                      color: AppTheme.stageTextSecondary,
                      fontSize: compactLayout
                          ? AppTheme.fontSizeXSmall
                          : AppTheme.fontSizeSmall,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (showThemeModeButton) ...[
          const SizedBox(width: AppTheme.spacingS),
          _ThemeModeButton(),
        ],
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
    return const ExcludeSemantics(
      child: Row(
        children: [
          Spacer(),
          LinkableSvgIcon(
            icon: LinkableIconName.weakSignal,
            size: 18,
            semanticLabel: '网络信号',
          ),
          SizedBox(width: 4),
          LinkableSvgIcon(
            icon: LinkableIconName.weakSignal,
            size: 18,
            semanticLabel: '无线网络',
          ),
          SizedBox(width: 4),
          LinkableSvgIcon(
            icon: LinkableIconName.completed,
            size: 20,
            semanticLabel: '电量充足',
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
    final isDayMode = AppTheme.isDayStageMode;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppTheme.stageHeroGradient),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: isDayMode ? 0.08 : 0.0),
                    const Color(
                      0xFF04140D,
                    ).withValues(alpha: isDayMode ? 0.0 : 0.74),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _DemoStagePatternPainter()),
            ),
          ),
          Positioned(
            top: -120,
            left: -90,
            child: _BackdropGlow(
              width: 320,
              height: 320,
              angle: -0.42,
              color: const Color(
                0xFFFFFFE6,
              ).withValues(alpha: isDayMode ? 0.36 : 0.14),
            ),
          ),
          Positioned(
            top: 180,
            right: -70,
            child: _BackdropGlow(
              width: 250,
              height: 300,
              angle: 0.58,
              color: const Color(
                0xFFF5FF9B,
              ).withValues(alpha: isDayMode ? 0.24 : 0.12),
            ),
          ),
          Positioned(
            bottom: -140,
            right: -40,
            child: _BackdropGlow(
              width: 320,
              height: 360,
              angle: 0.3,
              color: const Color(
                0xFF5DE4E0,
              ).withValues(alpha: isDayMode ? 0.26 : 0.18),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -120,
            child: _BackdropGlow(
              width: 280,
              height: 240,
              angle: -0.2,
              color: const Color(
                0xFFB8FF69,
              ).withValues(alpha: isDayMode ? 0.18 : 0.1),
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
      ..color = Colors.white.withValues(
        alpha: AppTheme.isDayStageMode ? 0.08 : 0.04,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final mistPaint = Paint()
      ..color = Colors.white.withValues(
        alpha: AppTheme.isDayStageMode ? 0.18 : 0.08,
      )
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.shortestSide * 0.12
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 86);

    final cyanMistPaint = Paint()
      ..color = const Color(
        0xFFA8FFF7,
      ).withValues(alpha: AppTheme.isDayStageMode ? 0.16 : 0.08)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.shortestSide * 0.1
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 72);

    final upperFlow = Path()
      ..moveTo(size.width * 0.02, size.height * 0.08)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.02,
        size.width * 0.68,
        size.height * 0.22,
      );
    canvas.drawPath(upperFlow, mistPaint);

    final lowerFlow = Path()
      ..moveTo(size.width * 0.12, size.height * 0.76)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.66,
        size.width * 0.72,
        size.height * 0.82,
      );
    canvas.drawPath(lowerFlow, cyanMistPaint);

    final diagonalLine = Path()
      ..moveTo(size.width * 0.6, -20)
      ..quadraticBezierTo(
        size.width * 0.86,
        size.height * 0.22,
        size.width * 0.92,
        size.height * 0.58,
      );
    canvas.drawPath(diagonalLine, linePaint);

    final outlineArc = Path()
      ..moveTo(-12, size.height * 0.64)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.72,
        size.width * 0.5,
        size.height * 0.98,
      );
    canvas.drawPath(outlineArc, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _BackdropGlow extends StatelessWidget {
  const _BackdropGlow({
    required this.width,
    required this.height,
    required this.color,
    required this.angle,
  });

  final double width;
  final double height;
  final Color color;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(width),
            color: color,
            boxShadow: [
              BoxShadow(
                color: color,
                blurRadius: width * 0.44,
                spreadRadius: width * 0.1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeModeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final session = AppSessionService.instance;
    final compactLayout = _useCompactDemoLayout(context);
    final buttonSize = compactLayout
        ? AppTheme.minTouchTarget
        : AppTheme.minTouchTarget + 8;
    final iconSize = compactLayout ? 34.0 : 44.0;

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
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                gradient: AppTheme.stageAccentGradient,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.56)),
              ),
              child: ExcludeSemantics(
                child: LinkableMaterialIcon(
                  icon: icon,
                  size: iconSize,
                  color: Colors.white,
                  semanticLabel: label,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
