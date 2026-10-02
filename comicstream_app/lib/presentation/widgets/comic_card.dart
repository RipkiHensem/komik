import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/chapter.dart';
import '../../data/models/comic.dart';
import '../../data/providers/providers.dart';
import '../../data/services/api_service.dart';
import 'proxied_image.dart';

final MangaApiService _coverApi = MangaApiService();
final Map<String, Future<String?>> _posterUrlCache = {};

Future<String?> _posterUrlFor(String comicId) {
  return _posterUrlCache.putIfAbsent(
    comicId,
    () => _coverApi.getComicCover(comicId),
  );
}

/// Compact cover-first card shared by the home and search comic lists.
class ComicCard extends ConsumerStatefulWidget {
  final Comic comic;
  final VoidCallback? onTap;
  final bool showBadge;

  const ComicCard({
    super.key,
    required this.comic,
    this.onTap,
    this.showBadge = true,
  });

  @override
  ConsumerState<ComicCard> createState() => _ComicCardState();
}

class _ComicCardState extends ConsumerState<ComicCard> {
  bool _isPressed = false;
  bool _isHovered = false;
  late String _coverUrl;

  @override
  void initState() {
    super.initState();
    _coverUrl = widget.comic.coverUrl;
    _loadPosterUrl();
  }

  @override
  void didUpdateWidget(covariant ComicCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comic.id != widget.comic.id ||
        oldWidget.comic.coverUrl != widget.comic.coverUrl) {
      _coverUrl = widget.comic.coverUrl;
      _loadPosterUrl();
    }
  }

  Future<void> _loadPosterUrl() async {
    final comicId = widget.comic.id;
    final posterUrl = await _posterUrlFor(comicId);
    if (!mounted || widget.comic.id != comicId || posterUrl == null) return;
    if (posterUrl != _coverUrl) setState(() => _coverUrl = posterUrl);
  }

  bool get _isRecentlyUpdated {
    final updatedAt = widget.comic.updatedAt;
    return updatedAt != null && DateTime.now().difference(updatedAt).inHours < 24;
  }

  @override
  Widget build(BuildContext context) {
    final comic = widget.comic;
    final detailAsync = ref.watch(comicDetailProvider(comic.id));
    final detail = detailAsync.valueOrNull;
    final chapters = (detail?['chapters'] as List<Chapter>?) ?? const [];
    final detailComic = detail?['comic'] as Comic?;
    final chapterCount = detailComic != null && detailComic.chapterCount > 0
        ? detailComic.chapterCount
        : comic.chapterCount > 0
        ? comic.chapterCount
        : chapters.fold<int>(
            0,
            (total, chapter) => chapter.chapterNumber > total
                ? chapter.chapterNumber
                : total,
          );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _isHovered ? 0.92 : 1,
          duration: const Duration(milliseconds: 150),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 3 / 4,
                child: Semantics(
                  button: true,
                  label: 'Buka komik ${comic.title}',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onTap,
                    onTapDown: (_) => setState(() => _isPressed = true),
                    onTapUp: (_) => setState(() => _isPressed = false),
                    onTapCancel: () => setState(() => _isPressed = false),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ColoredBox(
                            color: AppColors.surfaceLight,
                            child: ProxiedImage(
                              imageUrl: _coverUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                comic.formatFlag,
                                style: const TextStyle(fontSize: 11, height: 1),
                              ),
                            ),
                          ),
                          if (widget.showBadge && _isRecentlyUpdated)
                            Positioned(
                              left: 8,
                              bottom: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.55),
                                  ),
                                ),
                                child: const Text(
                                  'BARU',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTap,
                child: SizedBox(
                  width: double.infinity,
                  height: 37,
                  child: Text(
                    comic.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    comic.formattedViews,
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.menu_book_outlined,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$chapterCount Ch',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
              if (chapters.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildRecentChapters(chapters.take(2).toList(), comic.updatedAt),
              ] else if (detailAsync.isLoading) ...[
                const SizedBox(height: 6),
                _buildRecentChaptersLoading(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentChapters(List<Chapter> chapters, DateTime? latestUpdate) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(2, (index) {
        if (index >= chapters.length) {
          return const SizedBox(height: 44);
        }
        final chapter = chapters[index];
        final relativeTime = chapter.relativeTimeAt(
          index == 0 ? latestUpdate : null,
        );
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: chapter.id.isEmpty
                ? null
                : () => context.push(
                    '/comic/${widget.comic.id}/chapter/${chapter.id}',
                  ),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
              decoration: index == 0
                  ? BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.border),
                      ),
                    )
                  : null,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      chapter.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (relativeTime != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      relativeTime,
                      maxLines: 1,
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRecentChaptersLoading() {
    return Column(
      children: List.generate(
        2,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

/// Featured comic card kept available for any existing screen that uses it.
class ComicCardHero extends StatelessWidget {
  final Comic comic;
  final VoidCallback? onTap;

  const ComicCardHero({super.key, required this.comic, this.onTap});

  @override
  Widget build(BuildContext context) {
    return CoverAccentGlow(
      imageUrl: comic.coverUrl,
      borderRadius: BorderRadius.circular(12),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ProxiedImage(imageUrl: comic.coverUrl, fit: BoxFit.cover),
              DecoratedBox(decoration: BoxDecoration(gradient: AppColors.cardOverlay)),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Text(
                  comic.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compatibility wrapper for featured covers; intentionally adds no glow.
class CoverAccentGlow extends StatelessWidget {
  final String imageUrl;
  final BorderRadius borderRadius;
  final Widget child;

  const CoverAccentGlow({
    super.key,
    required this.imageUrl,
    required this.borderRadius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(borderRadius: borderRadius, child: child);
  }
}
