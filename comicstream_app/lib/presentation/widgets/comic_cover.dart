import 'package:flutter/material.dart';
import '../../data/models/comic.dart';
import 'proxied_image.dart';

/// Shared cover presentation: preserve the full artwork at every size.
class ComicCover extends StatelessWidget {
  final String imageUrl;
  final String? posterUrl;
  final double? width;
  final double? height;

  const ComicCover({
    super.key,
    required this.imageUrl,
    this.posterUrl,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final urls = Comic.coverCandidates(
      posterUrl: posterUrl,
      thumbnailUrl: imageUrl,
    );
    return ProxiedImage(
      imageUrl: urls.firstOrNull ?? '',
      fallbackImageUrls: urls.skip(1).toList(),
      // Do not reuse previously cached, cropped thumbnails as original covers.
      // This stable namespace refreshes covers once, not on every rebuild.
      cacheNamespace: 'original-comic-cover-v2',
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }
}
