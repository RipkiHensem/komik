import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/proxied_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers/providers.dart';
import '../../../data/models/comic.dart';
import '../../../data/models/chapter.dart';
import '../../../data/models/bookmark.dart';
import '../../widgets/chapter_tile.dart';
import '../../widgets/genre_chip.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/error_view.dart';
import '../../widgets/hover_builder.dart';

/// Comic detail screen with hero cover, metadata, chapter search, 3-column grid, and 1-10 pagination
class ComicDetailScreen extends ConsumerStatefulWidget {
  final String comicId;

  const ComicDetailScreen({super.key, required this.comicId});

  @override
  ConsumerState<ComicDetailScreen> createState() => _ComicDetailScreenState();
}

class _ComicDetailScreenState extends ConsumerState<ComicDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isAscending = false; // default false = Terbaru (newest first, Chapter 34, 33...) matching user screenshot
  bool _isExactMatch = false; // true when user submits/hits Enter, false during typing for partial matching

  void _submitSearch(String value) {
    setState(() {
      _searchQuery = value;
      _isExactMatch = value.trim().isNotEmpty;
    });
  }

  bool _matchesExact(Chapter ch, String rawQuery) {
    final cleanQuery = rawQuery.trim().toLowerCase();
    if (cleanQuery.isEmpty) return true;

    // Check if query is a chapter number or "chapter X" / "ch X" / "ep X"
    final regNum = RegExp(r'^(?:chapter\s*|ch\.?\s*|ep\.?\s*|episode\s*)?(\d+)$');
    final match = regNum.firstMatch(cleanQuery);
    if (match != null) {
      final targetNum = int.tryParse(match.group(1)!);
      if (targetNum != null) {
        return ch.chapterNumber == targetNum;
      }
    }

    // Exact title or display name match
    final numStr = ch.chapterNumber.toString();
    if (numStr == cleanQuery) return true;
    if (ch.displayName.toLowerCase() == cleanQuery) return true;
    if (ch.title != null && ch.title!.trim().toLowerCase() == cleanQuery) return true;

    return false;
  }

  bool _matchesPartial(Chapter ch, String rawQuery) {
    final cleanQuery = rawQuery.trim().toLowerCase();
    if (cleanQuery.isEmpty) return true;

    // Extract digits if user typed e.g. "chapter 1" or "1"
    final regNum = RegExp(r'^(?:chapter\s*|ch\.?\s*|ep\.?\s*|episode\s*)?(\d+)$');
    final match = regNum.firstMatch(cleanQuery);
    final targetDigits = match != null ? match.group(1)! : cleanQuery;

    final numStr = ch.chapterNumber.toString();
    return numStr.contains(targetDigits) ||
        ch.displayName.toLowerCase().contains(cleanQuery) ||
        (ch.title != null && ch.title!.toLowerCase().contains(cleanQuery));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(comicDetailProvider(widget.comicId));
      ref.invalidate(comicChaptersProvider(widget.comicId));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final comicAsync = ref.watch(comicFromDetailProvider(widget.comicId));
    final chaptersAsync = ref.watch(comicChaptersProvider(widget.comicId));
    final readChapters = ref.watch(readChaptersProvider(widget.comicId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: comicAsync.when(
        data: (comic) {
          return Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            trackVisibility: true,
            interactive: true,
            thickness: 8.0,
            radius: const Radius.circular(6.0),
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
              // ── Hero Header ───────────────────────────────────
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppColors.background,
                leading: HoverWidget(
                  scale: 1.1,
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, size: 20),
                    ),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Blurred background cover
                      ProxiedImage(
                        imageUrl: comic.coverUrl,
                        fit: BoxFit.cover,
                      ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.heroOverlay,
                        ),
                      ),
                      // Content over the hero
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Cover thumbnail
                              Container(
                                width: 110,
                                height: 160,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: ProxiedImage(
                                  imageUrl: comic.coverUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Title & metadata
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      comic.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                        height: 1.2,
                                      ),
                                    ),
                                    if (comic.alternativeTitle != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        comic.alternativeTitle!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    // Rating & View count chips
                                    Row(
                                      children: [
                                        _statChip(
                                          Icons.star_rounded,
                                          comic.rating.toStringAsFixed(1),
                                          AppColors.warning,
                                        ),
                                        const SizedBox(width: 12),
                                        _statChip(
                                          Icons.visibility_outlined,
                                          comic.formattedViews,
                                          AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 12),
                                        _statChip(
                                          Icons.bookmark_outline_rounded,
                                          comic.formattedBookmarks,
                                          AppColors.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Action Buttons (Modern World-Class Island Architecture) ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
                  child: Row(
                    children: [
                      // Primary "Mulai Baca" button with gradient and glow
                      HoverWidget(
                        scale: 1.05,
                        enableGlow: true,
                        glowColor: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          height: 44,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final chapters = ref.read(comicChaptersProvider(widget.comicId));
                                chapters.whenData((chapterList) {
                                  if (chapterList.isNotEmpty) {
                                    final firstChapter = chapterList.reduce(
                                      (a, b) => a.chapterNumber < b.chapterNumber ? a : b,
                                    );
                                    context.push(
                                      '/comic/${widget.comicId}/chapter/${firstChapter.id}',
                                    );
                                  }
                                });
                              },
                              icon: const Icon(Icons.play_arrow_rounded, size: 20, color: Colors.white),
                              label: const Text(
                                'Mulai Baca',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(horizontal: 22),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Frosted glass Bookmark button
                      HoverWidget(
                        scale: 1.05,
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final isAuth = ref.read(authProvider).user != null;
                              if (!isAuth) {
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Silakan masuk untuk menyimpan bookmark'),
                                    duration: const Duration(seconds: 4),
                                    behavior: SnackBarBehavior.floating,
                                    action: SnackBarAction(
                                      label: 'Masuk',
                                      textColor: AppColors.primary,
                                      onPressed: () => context.push('/login'),
                                    ),
                                  ),
                                );
                                return;
                              }

                              final isAlreadyBookmarked = ref
                                  .read(bookmarksProvider.notifier)
                                  .isBookmarked(widget.comicId);

                              if (isAlreadyBookmarked) {
                                final bookmarksList =
                                    ref.read(bookmarksProvider).valueOrNull ?? [];
                                final existing = bookmarksList.cast<Bookmark?>().firstWhere(
                                      (b) => b?.comicId == widget.comicId,
                                      orElse: () => null,
                                    );
                                if (existing != null) {
                                  ref
                                      .read(bookmarksProvider.notifier)
                                      .removeBookmarkByComicId(existing.comicId);
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Dihapus dari bookmark'),
                                      duration: Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } else {
                                ref.read(bookmarksProvider.notifier).addBookmark(widget.comicId);
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Ditambahkan ke bookmark'),
                                    duration: Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            icon: Icon(
                              ref.watch(bookmarksProvider.notifier).isBookmarked(widget.comicId)
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_outline_rounded,
                              size: 19,
                              color: ref.watch(bookmarksProvider.notifier).isBookmarked(widget.comicId)
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            label: Text(
                              ref.watch(bookmarksProvider.notifier).isBookmarked(widget.comicId)
                                  ? 'Tersimpan'
                                  : 'Bookmark',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColors.surface,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              side: BorderSide(color: AppColors.glassBorder, width: 0.8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Synopsis ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comic.synopsis,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Genre Chips (Clickable to Filter by Genre) ───────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: comic.genres.map((genre) {
                      return GenreChip(
                        label: genre,
                        onTap: () {
                          // Clear search query and select this genre exclusively
                          ref.read(searchStateProvider.notifier).state = SearchState(
                            query: '',
                            selectedGenres: {genre},
                            sortBy: 'latest',
                          );
                          // Route directly to Search Screen showing all comics with this genre
                          context.go('/search');
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),

              // ── Metadata ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _metaItem('Author', comic.author),
                      if (comic.artist != null)
                        _metaItem('Artist', comic.artist!),
                      _metaItem('Format', comic.format),
                      _metaItem('Status', comic.status),
                    ],
                  ),
                ),
              ),

              // ── Divider ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Divider(color: AppColors.divider, height: 1),
              ),

              // ── Chapters Section (Search, Responsive Grid, 1-10 Pagination) ─
              ...chaptersAsync.when<List<Widget>>(
                data: (chapters) =>
                    _buildChapterSlivers(context, comic, chapters, readChapters),
                loading: () => [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: List.generate(
                          6,
                          (index) => const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: ShimmerLoading(height: 56),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                error: (error, _) => [
                  SliverToBoxAdapter(
                    child: ErrorView(
                      message: 'Gagal memuat chapter',
                      onRetry: () =>
                          ref.invalidate(comicChaptersProvider(widget.comicId)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => ErrorView(
          message: 'Gagal memuat detail komik',
          onRetry: () => ref.invalidate(comicFromDetailProvider(widget.comicId)),
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.glassBorder,
          width: 0.6,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.glassBorder, width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isExactMatch
                ? AppColors.primary.withValues(alpha: 0.6)
                : AppColors.glassBorder,
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            HoverWidget(
              scale: 1.15,
              child: InkWell(
                onTap: () {
                  if (_searchController.text.trim().isNotEmpty) {
                    _submitSearch(_searchController.text);
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: _isExactMatch ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _isExactMatch = false; // Reset to partial mode when typing
                  });
                },
                onSubmitted: (value) {
                  _submitSearch(value); // Enter key triggers exact match
                },
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Cari Chapter, Contoh: 69 atau 76',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (_isExactMatch && _searchQuery.trim().isNotEmpty)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 11,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'Tepat',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            if (_searchQuery.isNotEmpty)
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                    _isExactMatch = false;
                  });
                },
                splashRadius: 16,
                tooltip: 'Hapus Pencarian',
              ),
            // Sort Toggle Button matching the ↕ icon in user's screenshot
            HoverWidget(
              scale: 1.1,
              child: Tooltip(
                message: _isAscending
                    ? 'Urutkan: Terlama (Klik untuk Terbaru)'
                    : 'Urutkan: Terbaru (Klik untuk Terlama)',
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isAscending = !_isAscending;
                    });
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      Icons.swap_vert_rounded,
                      size: 20,
                      color: _isAscending ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildChapterSlivers(
    BuildContext context,
    Comic comic,
    List<Chapter> chapters,
    Set<String> readChapters,
  ) {
    if (chapters.isEmpty) {
      return [
        const SliverToBoxAdapter(
          child: EmptyView(
            title: 'Belum ada chapter',
            subtitle: 'Chapter akan ditambahkan segera',
            icon: Icons.menu_book_rounded,
          ),
        ),
      ];
    }

    // 1. Sort chapters
    final sortedChapters = List<Chapter>.from(chapters);
    sortedChapters.sort((a, b) {
      return _isAscending
          ? a.chapterNumber.compareTo(b.chapterNumber)
          : b.chapterNumber.compareTo(a.chapterNumber);
    });

    // 2. Search filtering
    List<Chapter> filteredChapters = sortedChapters;
    if (_searchQuery.trim().isNotEmpty) {
      if (_isExactMatch) {
        // Enter pressed: strictly match exact chapter
        filteredChapters = sortedChapters
            .where((ch) => _matchesExact(ch, _searchQuery))
            .toList();
      } else {
        // Typing: partial match across chapter number, title, and display name
        filteredChapters = sortedChapters
            .where((ch) => _matchesPartial(ch, _searchQuery))
            .toList();
      }
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 900 ? 3 : (screenWidth > 550 ? 2 : 1);

    // Find the newest / highest chapter number among all chapters
    final maxChapterNumber = chapters.isNotEmpty
        ? chapters.map((c) => c.chapterNumber).fold<int>(0, math.max)
        : -1;

    return [
      // ── Chapters Header ─────────────────────────────────
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Row(
            children: [
              const Icon(
                Icons.list_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Chapters (${chapters.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              // Sort badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  _isAscending ? 'Terlama' : 'Terbaru',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Auto Update Button
              HoverWidget(
                scale: 1.06,
                child: InkWell(
                  onTap: () async {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Memeriksa update chapter terbaru...'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    ref.invalidate(comicChaptersProvider(widget.comicId));
                    ref.invalidate(comicDetailProvider(widget.comicId));
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 0.8,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sync_rounded,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Auto Update',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // ── Search Chapter Input Bar ────────────────────────
      SliverToBoxAdapter(
        child: _buildSearchBar(),
      ),

      // ── Chapter Grid or Search Empty State ──────────────
      if (filteredChapters.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: EmptyView(
              title: 'Chapter tidak ditemukan',
              subtitle: _isExactMatch
                  ? 'Tidak ada chapter yang cocok tepat dengan "$_searchQuery"'
                  : 'Coba cari dengan nomor chapter lain',
              icon: Icons.search_off_rounded,
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 62,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final chapter = filteredChapters[index];
                final isLatest = chapter.chapterNumber == maxChapterNumber;
                final isRead = readChapters.contains(chapter.id);
                final isNew = isLatest &&
                    !isRead &&
                    (comic.status.toLowerCase() == 'ongoing' ||
                        DateTime.now().difference(chapter.releasedAt).inDays <= 30);

                return ChapterTile(
                  chapter: chapter,
                  coverUrl: comic.coverUrl,
                  isRead: isRead,
                  isNew: isNew,
                  onTap: () {
                    context.push(
                      '/comic/${widget.comicId}/chapter/${chapter.id}',
                    );
                  },
                );
              },
              childCount: filteredChapters.length,
            ),
          ),
        ),

      // ── Bottom Info & Scroll to Top Button ───────────────
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 90),
          child: Center(
            child: filteredChapters.isNotEmpty
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'Ditemukan ${filteredChapters.length} dari ${chapters.length} chapter'
                            : 'Total ${chapters.length} chapter',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                      if (filteredChapters.length > 15) ...[
                        const SizedBox(width: 14),
                        HoverWidget(
                          scale: 1.08,
                          child: InkWell(
                            onTap: () {
                              if (_scrollController.hasClients) {
                                _scrollController.animateTo(
                                  0.0,
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeOutCubic,
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.glassBorder,
                                  width: 0.8,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_upward_rounded,
                                    size: 13,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Ke Atas',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    ];
  }
}
