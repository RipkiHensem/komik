import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/proxied_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers/providers.dart';
import '../../../data/models/comic.dart';
import '../../../data/models/chapter.dart';
import '../../../data/models/comment.dart';
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
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  bool _isSendingComment = false;
  String _searchQuery = '';
  bool _isAscending = false;
  bool _isExactMatch = false;
  int _chapterPage = 0;
  static const int _chaptersPerPage = 10;

  Future<void> _hideComic(Comic comic) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus komik dari aplikasi?'),
        content: Text(
          '"${comic.title}" akan disembunyikan dari katalog. Data sumbernya tetap tersimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(supabaseComicServiceProvider).hideAdminComic(comic.id);
      ref.invalidate(adminComicsProvider);
      ref.invalidate(homeComicsProvider);
      ref.invalidate(popularComicsByFormatProvider);
      ref.invalidate(searchComicsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Komik dihapus dari katalog aplikasi.')),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus komik: $error')),
      );
    }
  }

  Future<void> _hideChapter(Chapter chapter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus chapter dari aplikasi?'),
        content: Text(
          '${chapter.displayName} akan disembunyikan. Data sumbernya tetap tersimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(supabaseComicServiceProvider).hideAdminChapter(
            comicId: widget.comicId,
            chapterId: chapter.id,
          );
      ref.invalidate(comicDetailProvider(widget.comicId));
      ref.invalidate(comicChaptersProvider(widget.comicId));
      ref.invalidate(homeComicsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${chapter.displayName} dihapus dari aplikasi.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus chapter: $error')),
      );
    }
  }

  void _submitSearch(String value) {
    setState(() {
      _searchQuery = value;
      _isExactMatch = value.trim().isNotEmpty;
      _chapterPage = 0;
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
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final comicAsync = ref.watch(comicFromDetailProvider(widget.comicId));
    final chaptersAsync = ref.watch(comicChaptersProvider(widget.comicId));
    final readChapters = ref.watch(readChaptersProvider(widget.comicId));
    final isAdmin = ref.watch(isAdminProvider).valueOrNull == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: comicAsync.when(
        data: (comic) {
          return ScrollConfiguration(
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
                      Expanded(
                        child: HoverWidget(
                          scale: 1.02,
                          enableGlow: true,
                          glowColor: AppColors.primary,
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                          height: 44,
                          width: double.infinity,
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      ),
                      const SizedBox(width: 8),
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
                      if (isAdmin) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'Hapus komik dari aplikasi',
                          onPressed: () => _hideComic(comic),
                          style: IconButton.styleFrom(
                            minimumSize: const Size(44, 44),
                            backgroundColor: AppColors.surface,
                            side: BorderSide(color: AppColors.glassBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
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
                    ],
                  ),
                ),
              ),

              // ── Comment Section ──────────────────────────────────
              SliverToBoxAdapter(
                child: _buildCommentSection(context),
              ),

              // ── Divider ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Divider(color: AppColors.divider, height: 1),
              ),

              // ── Chapters Section (Search, Responsive Grid, 1-10 Pagination) ─
              ...chaptersAsync.when<List<Widget>>(
                data: (chapters) =>
                    _buildChapterSlivers(
                      context,
                      comic,
                      chapters,
                      readChapters,
                      isAdmin,
                    ),
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
          );
    },
        loading: () => Center(
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

  Widget _buildCommentSection(BuildContext context) {
    final authState = ref.watch(authProvider);
    final commentsAsync = ref.watch(commentsProvider(widget.comicId));
    final user = authState.user;
    final isLoggedIn = user != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Komentar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                commentsAsync.when(
                  data: (list) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.glassBorder, width: 0.6),
                    ),
                    child: Text(
                      '${list.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (err, stack) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Input Box
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _commentFocus.hasFocus
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : AppColors.glassBorder,
                width: 0.8,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primarySurface,
                  backgroundImage: (isLoggedIn && user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: (isLoggedIn && (user.avatarUrl == null || user.avatarUrl!.isEmpty))
                      ? Text(
                          (user.username.isNotEmpty ? user.username[0] : '?').toUpperCase(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        )
                      : (!isLoggedIn
                          ? Icon(Icons.person, size: 16, color: AppColors.primary)
                          : null),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _commentFocus,
                    maxLines: 4,
                    minLines: 1,
                    enabled: isLoggedIn,
                    textInputAction: TextInputAction.newline,
                    onTap: () => setState(() {}),
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.45,
                    ),
                    decoration: InputDecoration(
                      hintText: isLoggedIn
                          ? 'Tulis komentar kamu...'
                          : 'Masuk untuk menulis komentar',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Send button
                AnimatedOpacity(
                  opacity: isLoggedIn && _commentController.text.trim().isNotEmpty ? 1.0 : 0.35,
                  duration: const Duration(milliseconds: 200),
                  child: GestureDetector(
                    onTap: (isLoggedIn && !_isSendingComment)
                        ? () async {
                            final text = _commentController.text.trim();
                            if (text.isEmpty) return;
                            setState(() => _isSendingComment = true);
                            await ref
                                .read(commentsProvider(widget.comicId).notifier)
                                .postComment(
                                  userId: user.id,
                                  username: user.username,
                                  avatarUrl: user.avatarUrl,
                                  content: text,
                                );
                            _commentController.clear();
                            setState(() => _isSendingComment = false);
                          }
                        : null,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _isSendingComment
                          ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              size: 17,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (!isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: () => context.push('/login'),
                child: Text(
                  'Masuk untuk ikut berkomentar →',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 14),

          // Comment list
          commentsAsync.when(
            data: (comments) {
              if (comments.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 36,
                          color: AppColors.textMuted.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Belum ada komentar. Jadilah yang pertama!',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  final isOwn = user != null && comment.userId == user.id;
                  return _buildCommentTile(comment, isOwn);
                },
              );
            },
            loading: () => Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            ),
            error: (err, stack) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentTile(Comment comment, bool isOwn) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOwn
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.glassBorder,
          width: 0.7,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primarySurface,
            backgroundImage: (comment.avatarUrl != null && comment.avatarUrl!.isNotEmpty)
                ? NetworkImage(comment.avatarUrl!)
                : null,
            child: (comment.avatarUrl == null || comment.avatarUrl!.isEmpty)
                ? Text(
                    (comment.username.isNotEmpty ? comment.username[0] : '?').toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.username,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isOwn ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    if (isOwn) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Kamu',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      comment.timeAgo,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    if (isOwn)
                      GestureDetector(
                        onTap: () {
                          ref
                              .read(commentsProvider(widget.comicId).notifier)
                              .deleteComment(comment.id);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 15,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
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
                    _chapterPage = 0;
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
                    _chapterPage = 0;
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
                      _chapterPage = 0;
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
    bool isAdmin,
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
    final pageCount = (filteredChapters.length / _chaptersPerPage).ceil();
    final currentPage = pageCount == 0
        ? 0
        : _chapterPage.clamp(0, pageCount - 1).toInt();
    final pageChapters = filteredChapters
        .skip(currentPage * _chaptersPerPage)
        .take(_chaptersPerPage)
        .toList();

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
              Icon(
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
                    child: Row(
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
                final chapter = pageChapters[index];
                final isLatest = chapter.chapterNumber == maxChapterNumber;
                final isRead = readChapters.contains(chapter.id);
                final isNew = isLatest &&
                    !isRead &&
                    (comic.status.toLowerCase() == 'ongoing' ||
                        (chapter.releasedAt != null &&
                            DateTime.now()
                                    .difference(chapter.releasedAt!)
                                    .inDays <=
                                30));

                return ChapterTile(
                  chapter: chapter,
                  coverUrl: comic.coverUrl,
                  isRead: isRead,
                  isNew: isNew,
                  showDelete: isAdmin,
                  onDelete: isAdmin ? () => _hideChapter(chapter) : null,
                  onTap: () {
                    context.push(
                      '/comic/${widget.comicId}/chapter/${chapter.id}',
                    );
                  },
                );
              },
              childCount: pageChapters.length,
            ),
          ),
        ),

      if (pageCount > 1)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Halaman sebelumnya',
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  onPressed: currentPage > 0
                      ? () => setState(() => _chapterPage = currentPage - 1)
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                const SizedBox(width: 12),
                Text(
                  '${currentPage + 1}',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Halaman berikutnya',
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  onPressed: currentPage < pageCount - 1
                      ? () => setState(() => _chapterPage = currentPage + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
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
                              child: Row(
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
