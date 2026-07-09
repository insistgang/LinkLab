import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../accessible/index.dart';
import '../brand/app_logo.dart';
import 'linkable_icon.dart';
import 'demo_stage.dart';

class DemoAuthBanner extends StatelessWidget {
  const DemoAuthBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.svgIcon,
    this.chips = const [],
    this.useLogo = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final LinkableIconName? svgIcon;
  final List<Widget> chips;
  final bool useLogo;

  @override
  Widget build(BuildContext context) {
    return DemoSurfaceCard(
      color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          useLogo
              ? const AppLogo(size: 62, borderRadius: 18)
              : DemoGlassIconBadge(
                  icon: icon,
                  svgIcon: svgIcon,
                  size: 62,
                  iconSize: 30,
                  shape: DemoGlassIconShape.circle,
                ),
          const SizedBox(height: AppTheme.spacingL),
          AccessibleText(
            title,
            style: TextStyle(
              color: AppTheme.stageTextPrimary,
              fontSize: AppTheme.fontSizeXLarge,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          AccessibleText(
            subtitle,
            style: TextStyle(
              color: AppTheme.stageTextSecondary,
              fontSize: AppTheme.fontSizeNormal,
              height: 1.6,
            ),
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingM),
            Wrap(
              spacing: AppTheme.spacingS,
              runSpacing: AppTheme.spacingS,
              children: chips,
            ),
          ],
        ],
      ),
    );
  }
}

class DemoAuthFormTheme extends StatelessWidget {
  const DemoAuthFormTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppTheme.stageSurface,
          hintStyle: TextStyle(color: AppTheme.stageTextHint),
          helperStyle: TextStyle(color: AppTheme.stageTextHint),
          errorStyle: TextStyle(color: AppTheme.stageDanger),
          labelStyle: TextStyle(color: AppTheme.stageTextSecondary),
          counterStyle: TextStyle(color: AppTheme.stageTextHint),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: AppTheme.stageBorder.withValues(alpha: 0.82),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: AppTheme.stageBorder.withValues(alpha: 0.82),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: AppTheme.stageAccent, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: AppTheme.stageDanger, width: 1.4),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: AppTheme.stageDanger, width: 1.6),
          ),
          contentPadding: const EdgeInsets.all(AppTheme.spacingM),
        ),
        textTheme: base.textTheme.apply(
          bodyColor: AppTheme.stageTextPrimary,
          displayColor: AppTheme.stageTextPrimary,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppTheme.stageAccent),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTheme.stageAccent;
            }
            return AppTheme.stageTextHint;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTheme.stageAccent.withValues(alpha: 0.28);
            }
            return AppTheme.stageBorder.withValues(alpha: 0.92);
          }),
        ),
        sliderTheme: base.sliderTheme.copyWith(
          activeTrackColor: AppTheme.stageAccent,
          inactiveTrackColor: AppTheme.stageBorder,
          thumbColor: AppTheme.stageAccent,
          overlayColor: AppTheme.stageAccent.withValues(alpha: 0.18),
          valueIndicatorColor: AppTheme.stageAccent,
          valueIndicatorTextStyle: TextStyle(color: AppTheme.stageBackground),
        ),
      ),
      child: child,
    );
  }
}

class DemoMetricStrip extends StatelessWidget {
  const DemoMetricStrip({super.key, required this.items});

  final List<DemoMetricItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(child: _DemoMetricCard(item: items[i])),
          if (i != items.length - 1) const SizedBox(width: AppTheme.spacingM),
        ],
      ],
    );
  }
}

class DemoMetricItem {
  const DemoMetricItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;
}

class _DemoMetricCard extends StatelessWidget {
  const _DemoMetricCard({required this.item});

  final DemoMetricItem item;

  @override
  Widget build(BuildContext context) {
    return DemoSurfaceCard(
      color: AppTheme.stageSurfaceStrong.withValues(alpha: 0.94),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AccessibleText(
            item.label,
            style: TextStyle(
              color: item.color,
              fontSize: AppTheme.fontSizeSmall,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          AccessibleText(
            item.value,
            style: TextStyle(
              color: AppTheme.stageTextPrimary,
              fontSize: AppTheme.fontSizeNormal,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class DemoSelectionCard extends StatelessWidget {
  const DemoSelectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.svgIcon,
    required this.isSelected,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final LinkableIconName? svgIcon;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: title,
      hint: subtitle,
      child: DemoSurfaceCard(
        onTap: onTap,
        color: isSelected
            ? AppTheme.stageAccent.withValues(alpha: 0.16)
            : AppTheme.stageSurfaceStrong.withValues(alpha: 0.96),
        borderColor: isSelected
            ? AppTheme.stageAccent.withValues(alpha: 0.42)
            : AppTheme.stageBorder.withValues(alpha: 0.82),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 112),
          child: Row(
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                scale: isSelected ? 1 : 0.96,
                child: DemoGlassIconBadge(icon: icon, svgIcon: svgIcon, size: 54, iconSize: 24),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AccessibleText(
                      title,
                      style: TextStyle(
                        color: AppTheme.stageTextPrimary,
                        fontSize: AppTheme.fontSizeNormal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    AccessibleText(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.stageTextSecondary,
                        fontSize: AppTheme.fontSizeSmall,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    _SelectionStatusBadge(isSelected: isSelected),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              trailing ??
                  LinkableMaterialIcon(
                    icon: isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: isSelected
                        ? AppTheme.stageAccent
                        : AppTheme.stageTextHint,
                    semanticLabel: isSelected ? '已选择' : '未选择',
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionStatusBadge extends StatelessWidget {
  const _SelectionStatusBadge({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return DemoPill(
      label: isSelected ? '已选择' : '双击选择',
      color: isSelected ? AppTheme.stageAccent : AppTheme.stageTextHint,
      backgroundColor: isSelected
          ? AppTheme.stageAccent.withValues(alpha: 0.14)
          : AppTheme.stageSurface,
    );
  }
}
