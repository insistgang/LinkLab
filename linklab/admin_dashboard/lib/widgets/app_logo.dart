import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 48,
    this.semanticLabel = '共感 LinkAble 應用標誌',
    this.borderRadius = 12,
  });

  static const assetPath = 'assets/brand/logo.svg';

  final double size;
  final String? semanticLabel;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final logo = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SvgPicture.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      ),
    );

    if (semanticLabel == null) {
      return ExcludeSemantics(child: logo);
    }

    return Semantics(image: true, label: semanticLabel, child: logo);
  }
}
