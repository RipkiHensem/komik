import 'dart:async';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/comic.dart';
import '../../data/providers/providers.dart';
import 'proxied_image.dart';

typedef ThumbnailLoader = Future<ui.Image> Function(String url);

class SessionThumbnail {
  ui.Image? image;
  late Future<void> ready;
}

/// Only tiny library covers are retained, never full-resolution reader pages.
class SessionThumbnailCache {
  final ThumbnailLoader _load;
  final _entries = <String, SessionThumbnail>{};
  bool _disposed = false;
  SessionThumbnailCache({ThumbnailLoader? loader}) : _load = loader ?? _decode;

  SessionThumbnail get(List<String> urls) {
    final key = urls.join('\n');
    return _entries.putIfAbsent(key, () {
      final entry = SessionThumbnail();
      entry.ready = _loadFirst(urls).then(
        (image) {
          if (_disposed) {
            image.dispose();
          } else {
            entry.image = image;
          }
        },
        onError: (Object error, StackTrace stack) {
          if (identical(_entries[key], entry)) _entries.remove(key);
          Error.throwWithStackTrace(error, stack);
        },
      );
      return entry;
    });
  }

  Future<ui.Image> _loadFirst(List<String> urls) async {
    for (final url in urls) {
      try {
        return await _load(url);
      } catch (_) {
        /* try next source */
      }
    }
    throw StateError('Cover tidak tersedia');
  }

  static Future<ui.Image> _decode(String url) {
    final resolved = ProxiedImage.resolveImageUrl(url);
    final provider = ResizeImage(
      CachedNetworkImageProvider(
        resolved,
        cacheKey: 'original-comic-cover-v2:$resolved',
      ),
      width: 204,
      height: 282,
      policy: ResizeImagePolicy.fit,
    );
    final stream = provider.resolve(ImageConfiguration.empty);
    final result = Completer<ui.Image>();
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (!result.isCompleted) result.complete(info.image.clone());
        info.dispose();
        stream.removeListener(listener);
      },
      onError: (Object error, StackTrace? stack) {
        if (!result.isCompleted) result.completeError(error, stack);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    return result.future;
  }

  void dispose() {
    _disposed = true;
    for (final entry in _entries.values) {
      entry.image?.dispose();
    }
    _entries.clear();
  }
}

final sessionThumbnailCacheProvider = Provider<SessionThumbnailCache>((ref) {
  ref.watch(authProvider.select((state) => state.user?.id));
  final cache = SessionThumbnailCache();
  ref.onDispose(cache.dispose);
  return cache;
});

class SavedComicCover extends ConsumerWidget {
  final String imageUrl;
  const SavedComicCover({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urls = Comic.coverCandidates(thumbnailUrl: imageUrl);
    Widget placeholder() => ColoredBox(
      color: AppColors.surface,
      child: Icon(
        Icons.auto_stories_outlined,
        color: AppColors.textMuted,
        size: 24,
      ),
    );
    if (urls.isEmpty) return placeholder();
    final entry = ref.watch(sessionThumbnailCacheProvider).get(urls);
    Widget loaded() => RawImage(
      image: entry.image,
      width: 68,
      height: 94,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.low,
    );
    // Completed covers render synchronously on remount: no spinner or fade.
    if (entry.image != null) return loaded();
    return FutureBuilder<void>(
      future: entry.ready,
      builder: (context, snapshot) =>
          entry.image != null ? loaded() : placeholder(),
    );
  }
}
