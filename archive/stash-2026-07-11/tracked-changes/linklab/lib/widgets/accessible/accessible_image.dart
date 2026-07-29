import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../demo/linkable_icon.dart';
import 'accessible_text.dart';

/// 可访问图片组件。
/// 统一处理 asset/network 加载失败时的可见回退和语义文本。
class AccessibleImage extends StatelessWidget {
  const AccessibleImage.asset({
    super.key,
    this.assetPath,
    required this.semanticLabel,
    this.hint,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = Icons.image_outlined,
    this.fallbackText,
  }) : imageUrl = null;

  const AccessibleImage.network({
    super.key,
    this.imageUrl,
    required this.semanticLabel,
    this.hint,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = Icons.image_outlined,
    this.fallbackText,
  }) : assetPath = null;

  final String? assetPath;
  final String? imageUrl;
  final String semanticLabel;
  final String? hint;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;
  final String? fallbackText;

  bool get _hasAsset => assetPath != null && assetPath!.trim().isNotEmpty;
  bool get _hasNetworkImage => imageUrl != null && imageUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final image = _buildImage();
    final clippedImage = borderRadius == null
        ? image
        : ClipRRect(borderRadius: borderRadius!, child: image);

    return Semantics(
      image: true,
      label: semanticLabel,
      hint: hint,
      child: clippedImage,
    );
  }

  Widget _buildImage() {
    if (_hasAsset) {
      return Image.asset(
        assetPath!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }

    if (_hasNetworkImage) {
      return Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      color: AppTheme.backgroundGrey,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LinkableMaterialIcon(
            icon: fallbackIcon,
            size: 48,
            color: AppTheme.textHint,
            semanticLabel: fallbackText ?? semanticLabel,
          ),
          if (fallbackText != null && fallbackText!.trim().isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingS),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingM,
              ),
              child: AccessibleText(
                fallbackText!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeSmall,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
