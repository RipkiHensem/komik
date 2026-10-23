import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

/// Reusable network image widget that automatically proxies URLs on web
/// to bypass CORS restrictions from thumbnail.komiku.org.
/// Gambar di-cache ke disk via [CachedNetworkImage] sehingga tidak di-download
/// ulang saat chapter dibuka kembali.
class ProxiedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int? cacheWidth;
  final int? cacheHeight;
  final FilterQuality filterQuality;
  final bool gaplessPlayback;

  const ProxiedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.cacheWidth,
    this.cacheHeight,
    this.filterQuality = FilterQuality.medium,
    this.gaplessPlayback = false,
  });

  /// Converts a thumbnail URL to go through our Supabase Edge Function proxy
  /// on web to bypass CORS. On mobile/desktop, returns the original URL.
  static String resolveImageUrl(String imageUrl) {
    if (imageUrl.isEmpty) return '';
    // Only proxy on web — mobile & desktop can load directly
    if (!kIsWeb) return imageUrl;
    // If already a proxied URL, don't double-proxy
    if (imageUrl.contains('/img-proxy')) return imageUrl;
    // On web, external images suffer from CORS restrictions.
    // Proxy any external http/https image that is not from Supabase.
    final isExternal =
        imageUrl.contains('thumbnail.komiku.org') ||
        imageUrl.contains('komiku.org') ||
        ((imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) &&
            !imageUrl.contains('supabase.co'));
    if (isExternal) {
      final encoded = Uri.encodeComponent(imageUrl);
      return '${AppConstants.mangaApiBaseUrl}/img-proxy?url=$encoded';
    }
    return imageUrl;
  }

  @override
  Widget build(BuildContext context) {
    final proxiedUrl = resolveImageUrl(imageUrl);

    if (proxiedUrl.isEmpty) {
      return _buildPlaceholder();
    }

    // CachedNetworkImage menyimpan gambar ke disk cache sehingga saat chapter
    // dibuka kembali gambar tidak perlu di-download ulang dari internet.
    Widget image = CachedNetworkImage(
      imageUrl: proxiedUrl,
      width: width,
      height: height,
      fit: fit,
      filterQuality: filterQuality,
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 100),
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
      placeholder: (context, url) =>
          placeholder ??
          Container(
            width: width,
            height: height,
            color: AppColors.surface,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ),
      errorWidget: (context, url, error) =>
          errorWidget ?? _buildPlaceholder(),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
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
          colors: [AppColors.surface, AppColors.card],
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
                'Yomu',
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
