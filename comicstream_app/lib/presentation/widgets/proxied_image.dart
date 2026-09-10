import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

/// Reusable network image widget that automatically proxies URLs on web
/// to bypass CORS restrictions.
class ProxiedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const ProxiedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final proxiedUrl = AppConstants.resolveImageUrl(imageUrl);

    if (proxiedUrl.isEmpty) {
      return _buildPlaceholder();
    }

    Widget image = Image.network(
      proxiedUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ??
            Container(
              width: width,
              height: height,
              color: AppColors.surface,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: AppColors.primary,
                ),
              ),
            );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? _buildPlaceholder();
      },
    );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.card,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_stories_rounded,
              color: AppColors.primary.withValues(alpha: 0.4),
              size: (width != null && width! < 100) ? 24 : 36,
            ),
            if (width == null || width! >= 100) ...[
              const SizedBox(height: 6),
              Text(
                'ComicStream',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
