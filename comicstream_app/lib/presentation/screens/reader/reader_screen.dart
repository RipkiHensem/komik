import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/proxied_image.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers/providers.dart';
import '../../../data/models/comic.dart';
import '../../../data/models/comic_page.dart';
import '../../../data/models/chapter.dart';
import '../../widgets/error_view.dart';

/// Chapter reader screen with responsive desktop phone-width canvas,
/// continuous vertical slide (up/down) webtoon mode, and horizontal manga mode.
class ReaderScreen extends ConsumerStatefulWidget {
  final String comicId;
  final String chapterId;

  const ReaderScreen({
    super.key,
    required this.comicId,
    required this.chapterId,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  static const int _maxReaderImageDecodeHeight = 4096;
  bool _showOverlay = true;
  Timer? _hideOverlayTimer;
  Timer? _progressSaveTimer;
  final String _readingMode = AppConstants.readingModeScroll; // Default vertical scroll for webtoons
  int _currentPage = 0;
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  String? _comicTitle;
  String? _comicCoverUrl;
  bool _isLoadingComicMetadata = false;
  int? _lastPersistedPage;
  bool _metadataWasPersisted = false;
  bool _chapterMarkedAsRead = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    _startHideOverlayTimer();
    _loadComicMetadata();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleProgressSave(1);
    });
  }

  @override
  void dispose() {
    _hideOverlayTimer?.cancel();
    _progressSaveTimer?.cancel();
    _pageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _startHideOverlayTimer() {
    _hideOverlayTimer?.cancel();
    _hideOverlayTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _showOverlay) {
        setState(() => _showOverlay = false);
      }
    });
  }

  void _toggleOverlay() {
    setState(() => _showOverlay = !_showOverlay);
    if (_showOverlay) {
      _startHideOverlayTimer();
    } else {
      _hideOverlayTimer?.cancel();
    }
  }

  void _loadComicMetadata() {
    if (_isLoadingComicMetadata || _comicTitle != null) return;
    _isLoadingComicMetadata = true;

    ref.read(comicFromDetailProvider(widget.comicId).future).then((Comic comic) {
      if (!mounted) return;
      _comicTitle = comic.title;
      _comicCoverUrl = comic.coverUrl;
      _scheduleProgressSave(_currentPage + 1);
    }).catchError((_) {
      // Riwayat tetap dapat disimpan walau metadata komik sedang tidak tersedia.
    });
  }

  /// Menunda sinkronisasi hingga pembaca berhenti menggeser halaman.
  /// Ini mencegah request Supabase berulang saat scroll masih bergerak.
  void _scheduleProgressSave(int pageNumber) {
    _progressSaveTimer?.cancel();
    _progressSaveTimer = Timer(const Duration(milliseconds: 850), () {
      _persistProgress(pageNumber);
    });
  }

  void _flushProgress() {
    _progressSaveTimer?.cancel();
    _persistProgress(_currentPage + 1);
  }

  void _persistProgress(int pageNumber) {
    final hasMetadata = _comicTitle?.isNotEmpty == true;
    if (_lastPersistedPage == pageNumber &&
        (!hasMetadata || _metadataWasPersisted)) {
      return;
    }

    _lastPersistedPage = pageNumber;
    _metadataWasPersisted = hasMetadata;

    if (!_chapterMarkedAsRead) {
      _chapterMarkedAsRead = true;
      ref
          .read(readChaptersProvider(widget.comicId).notifier)
          .markAsRead(widget.chapterId);
    }

    ref.read(historyProvider.notifier).recordProgress(
          comicId: widget.comicId,
          chapterId: widget.chapterId,
          page: pageNumber,
          comicTitle: _comicTitle,
          comicCoverUrl: _comicCoverUrl,
        );
  }

  /// Slide Down smoothly (Scroll mode) or Next page (Page mode)
  void _slideDown() {
    if (_readingMode == AppConstants.readingModeScroll) {
      if (!_scrollController.hasClients) return;
      final step = MediaQuery.of(context).size.height * 0.65;
      final target = (_scrollController.offset + step)
          .clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      if (!_pageController.hasClients) return;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Slide Up smoothly (Scroll mode) or Previous page (Page mode)
  void _slideUp() {
    if (_readingMode == AppConstants.readingModeScroll) {
      if (!_scrollController.hasClients) return;
      final step = MediaQuery.of(context).size.height * 0.65;
      final target = (_scrollController.offset - step)
          .clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      if (!_pageController.hasClients) return;
      _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Robust exit handler that always returns the user to the comic detail screen
  void _handleExit() {
    _flushProgress();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (context.canPop()) {
      context.pop();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/comic/${widget.comicId}');
    }
  }

  void _goToChapter(String targetChapterId) {
    _flushProgress();
    _hideOverlayTimer?.cancel();
    context.pushReplacement('/comic/${widget.comicId}/chapter/$targetChapterId');
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.space ||
        event.logicalKey == LogicalKeyboardKey.pageDown ||
        event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _slideDown();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.pageUp ||
        event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _slideUp();
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      _handleExit();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hanya watch pages — chapters dibaca di _ChapterNavBar terpisah
    // agar rebuild chapters tidak mereset posisi scroll/page reader.
    final pagesAsync = ref.watch(chapterPagesProvider(widget.chapterId));

    // Responsive desktop calculations:
    // If screen width is wider than 680px, constrain the reader to a mobile phone width (560px)
    // so images are not stretched or upscaled.
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 680;
    final readerWidth = isDesktop ? 560.0 : screenSize.width;

    // Label chapter — baca sekali, tidak watch
    final chaptersSnapshot = ref.read(comicChaptersProvider(widget.comicId));
    Chapter? currentChapter;
    chaptersSnapshot.whenData((chapters) {
      final idx = chapters.indexWhere((ch) => ch.id == widget.chapterId);
      if (idx != -1) currentChapter = chapters[idx];
    });
    final chapterLabel = currentChapter == null
        ? 'Chapter'
        : 'Chapter ${currentChapter!.chapterNumber}';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleExit();
      },
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Scaffold(
          // Deep theater slate background on wide screens, pure black on mobile
          backgroundColor: isDesktop ? const Color(0xFF0C0E12) : Colors.black,
          body: pagesAsync.when(
            data: (pages) {
              if (pages.isEmpty) {
                return Scaffold(
                  backgroundColor: Colors.black,
                  appBar: AppBar(
                    backgroundColor: Colors.black,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: _handleExit,
                    ),
                    title: const Text(
                      'Chapter Kosong',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  body: const Center(
                    child: ErrorView(
                      message: 'Tidak ada halaman untuk chapter ini',
                      icon: Icons.image_not_supported_rounded,
                    ),
                  ),
                );
              }

              // Reader Canvas Widget
              Widget readerCanvas = Center(
                child: Container(
                  width: readerWidth,
                  constraints: BoxConstraints(maxWidth: readerWidth),
                  decoration: isDesktop
                      ? BoxDecoration(
                          color: Colors.black,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.8),
                              blurRadius: 32,
                              spreadRadius: 8,
                            ),
                          ],
                          border: Border.symmetric(
                            vertical: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                        )
                      : const BoxDecoration(color: Colors.black),
                  child: _readingMode == AppConstants.readingModePage
                      ? _buildPageMode(pages, readerWidth)
                      : _buildScrollMode(pages, readerWidth),
                ),
              );

              // Keep the reader scrollable without showing a scrollbar.
              Widget scrollableContent;
              if (_readingMode == AppConstants.readingModeScroll) {
                scrollableContent = ScrollConfiguration(
                  behavior: const MaterialScrollBehavior().copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                      PointerDeviceKind.stylus,
                    },
                    scrollbars: false,
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _toggleOverlay,
                    child: readerCanvas,
                  ),
                );
              } else {
                scrollableContent = GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _toggleOverlay,
                  child: readerCanvas,
                );
              }

              return Stack(
                children: [
                  // ── Full-screen reader content ──
                  Positioned.fill(
                    child: scrollableContent,
                  ),

                  // Minimal reader header: back and current chapter.
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      ignoring: !_showOverlay,
                      child: AnimatedOpacity(
                        opacity: _showOverlay ? 1 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.75),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: _handleExit,
                                    tooltip: 'Kembali',
                                    style: IconButton.styleFrom(
                                      minimumSize: const Size(44, 44),
                                      backgroundColor: Colors.black.withValues(alpha: 0.35),
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.arrow_back_rounded),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    chapterLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      shadows: [
                                        Shadow(color: Colors.black54, blurRadius: 8),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () {
                                      _hideOverlayTimer?.cancel();
                                      showModalBottomSheet<void>(
                                        context: context,
                                        isScrollControlled: true,
                                        useSafeArea: true,
                                        backgroundColor: AppColors.background,
                                        builder: (_) => ChapterCommentsSheet(
                                          chapterId: widget.chapterId,
                                        ),
                                      ).whenComplete(() {
                                        if (mounted && _showOverlay) {
                                          _startHideOverlayTimer();
                                        }
                                      });
                                    },
                                    tooltip: 'Komentar chapter',
                                    style: IconButton.styleFrom(
                                      minimumSize: const Size(44, 44),
                                      backgroundColor: Colors.black.withValues(alpha: 0.35),
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Only chapter-to-chapter navigation remains at the bottom.
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      ignoring: !_showOverlay,
                      child: AnimatedOpacity(
                        opacity: _showOverlay ? 1 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: _ChapterNavBar(
                          comicId: widget.comicId,
                          currentChapterId: widget.chapterId,
                          onNavigate: _goToChapter,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (err, stack) => Center(
              child: ErrorView(
                message: 'Gagal memuat halaman chapter.',
                onRetry: () =>
                    ref.invalidate(chapterPagesProvider(widget.chapterId)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Page-view mode (horizontal swipe) — for manga
  Widget _buildPageMode(List<ComicPage> pages, double readerWidth) {
    return PageView.builder(
      controller: _pageController,
      itemCount: pages.length,
      onPageChanged: (index) {
        _currentPage = index;
        _scheduleProgressSave(index + 1);
      },
      itemBuilder: (context, index) {
        return InteractiveViewer(
          minScale: 1.0,
          maxScale: 3.0,
          child: Center(
            child: SizedBox(
              width: readerWidth,
              child: ProxiedImage(
                imageUrl: pages[index].imageUrl,
                fit: BoxFit.contain,
                cacheWidth: (readerWidth * MediaQuery.devicePixelRatioOf(context))
                    .round(),
                cacheHeight: _maxReaderImageDecodeHeight,
                filterQuality: FilterQuality.low,
                gaplessPlayback: true,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Scroll mode (vertical continuous slide) — for manhwa/webtoon
  Widget _buildScrollMode(List<ComicPage> pages, double readerWidth) {
    // Hitung cacheExtent sekali di sini agar tidak menyebabkan rebuild
    // pada setiap frame saat MediaQuery berubah (mis. keyboard muncul).
    final cacheExtent = MediaQuery.sizeOf(context).height * 1.25;
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Menyimpan posisi saat scroll selesai saja. Menjadwalkan timer pada
        // setiap frame scroll dapat membuat reader terasa tersendat di HP.
        if (notification is ScrollEndNotification) {
          final maxExt = _scrollController.hasClients &&
                  _scrollController.position.maxScrollExtent > 0
              ? _scrollController.position.maxScrollExtent
              : 1.0;
          final scrollFraction = _scrollController.hasClients
              ? (_scrollController.offset / maxExt).clamp(0.0, 1.0)
              : 0.0;
          final estimatedPage = (scrollFraction * (pages.length - 1)).round();
          if (estimatedPage != _currentPage) {
            _currentPage = estimatedPage;
            _scheduleProgressSave(estimatedPage + 1);
          }
        }
        return false;
      },
      child: ScrollConfiguration(
        // Enable mouse, trackpad, and touch drag scrolling on desktop
        behavior: const MaterialScrollBehavior().copyWith(
          scrollbars: false,
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus,
          },
        ),
        child: ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          cacheExtent: cacheExtent,
          padding: EdgeInsets.zero,
          itemCount: pages.length,
          itemBuilder: (context, index) {
            return RepaintBoundary(
              child: ProxiedImage(
                imageUrl: pages[index].imageUrl,
                fit: BoxFit.fitWidth,
                width: readerWidth,
                cacheWidth: (readerWidth * MediaQuery.devicePixelRatioOf(context))
                    .round(),
                cacheHeight: _maxReaderImageDecodeHeight,
                filterQuality: FilterQuality.low,
                gaplessPlayback: true,
              ),
            );
          },
        ),
      ),
    );
  }

}

class ChapterCommentsSheet extends ConsumerStatefulWidget {
  final String chapterId;

  const ChapterCommentsSheet({super.key, required this.chapterId});

  @override
  ConsumerState<ChapterCommentsSheet> createState() => _ChapterCommentsSheetState();
}

class _ChapterCommentsSheetState extends ConsumerState<ChapterCommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();
  bool _isSending = false;
  bool _isSpoiler = false;
  // Menyimpan id komentar spoiler yang sudah di-reveal oleh user
  final Set<String> _revealedSpoilers = {};

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isLoggedIn = user != null;
    final commentsAsync = ref.watch(chapterCommentsProvider(widget.chapterId));
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75 + keyboardHeight,
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Komentar Chapter',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Comments List
          Expanded(
            child: commentsAsync.when(
              data: (comments) {
                if (comments.isEmpty) {
                  return Center(
                    child: Text('Belum ada komentar.', style: TextStyle(color: AppColors.textMuted)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final isOwn = isLoggedIn && comment.userId == user.id;
                    final isSpoilerRevealed = _revealedSpoilers.contains(comment.id);
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primarySurface,
                          backgroundImage: (comment.avatarUrl != null && comment.avatarUrl!.isNotEmpty)
                              ? NetworkImage(comment.avatarUrl!)
                              : null,
                          child: (comment.avatarUrl == null || comment.avatarUrl!.isEmpty)
                              ? Text(
                                  (comment.username.isNotEmpty ? comment.username[0] : '?').toUpperCase(),
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: comment.isSpoiler
                                    ? Colors.orange.withValues(alpha: 0.45)
                                    : AppColors.glassBorder,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      comment.username,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isOwn ? AppColors.primary : AppColors.textPrimary,
                                      ),
                                    ),
                                    if (comment.isSpoiler) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                                        ),
                                        child: const Text(
                                          '⚠ Spoiler',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.orange),
                                        ),
                                      ),
                                    ],
                                    const Spacer(),
                                    if (isOwn)
                                      GestureDetector(
                                        onTap: () {
                                          ref.read(chapterCommentsProvider(widget.chapterId).notifier).deleteComment(comment.id);
                                        },
                                        child: Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.textMuted),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // ── Spoiler blur overlay ──────────────────────
                                if (comment.isSpoiler && !isSpoilerRevealed)
                                  GestureDetector(
                                    onTap: () => setState(() => _revealedSpoilers.add(comment.id)),
                                    child: Stack(
                                      children: [
                                        // Teks asli tapi blur
                                        ImageFiltered(
                                          imageFilter: ColorFilter.matrix([
                                            0, 0, 0, 0, 30,
                                            0, 0, 0, 0, 30,
                                            0, 0, 0, 0, 30,
                                            0, 0, 0, 1, 0,
                                          ]),
                                          child: Text(
                                            comment.content,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textSecondary,
                                              height: 1.4,
                                              shadows: const [
                                                Shadow(blurRadius: 8, color: Colors.black),
                                                Shadow(blurRadius: 8, color: Colors.black),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Tombol reveal
                                        Positioned.fill(
                                          child: Container(
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.55),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.visibility_outlined, size: 14, color: Colors.orange),
                                                const SizedBox(width: 5),
                                                const Text(
                                                  'Ketuk untuk lihat spoiler',
                                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.orange),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Text(
                                    comment.content,
                                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, stack) => const Center(child: Text('Gagal memuat komentar', style: TextStyle(color: Colors.red))),
            ),
          ),

          // Input Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Column(
              children: [
                // Spoiler toggle row
                if (isLoggedIn)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _isSpoiler = !_isSpoiler),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _isSpoiler ? Colors.orange : AppColors.glassBorder,
                                width: 1.5,
                              ),
                              color: _isSpoiler
                                  ? Colors.orange.withValues(alpha: 0.2)
                                  : Colors.transparent,
                            ),
                            child: _isSpoiler
                                ? const Icon(Icons.check, size: 12, color: Colors.orange)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tandai sebagai spoiler',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _isSpoiler ? Colors.orange : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        focusNode: _commentFocus,
                        enabled: isLoggedIn,
                        maxLines: 3,
                        minLines: 1,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: isLoggedIn ? 'Tulis komentar...' : 'Masuk untuk komentar',
                          hintStyle: TextStyle(color: AppColors.textMuted),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.glassBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _isSpoiler
                                  ? Colors.orange.withValues(alpha: 0.5)
                                  : AppColors.glassBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _isSpoiler ? Colors.orange : AppColors.primary,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: (isLoggedIn && _commentController.text.trim().isNotEmpty && !_isSending)
                          ? () async {
                              setState(() => _isSending = true);
                              await ref.read(chapterCommentsProvider(widget.chapterId).notifier).postComment(
                                userId: user.id,
                                username: user.username,
                                avatarUrl: user.avatarUrl,
                                content: _commentController.text,
                                isSpoiler: _isSpoiler,
                              );
                              _commentController.clear();
                              setState(() {
                                _isSending = false;
                                _isSpoiler = false;
                              });
                            }
                          : null,
                      icon: _isSending
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(
                              Icons.send_rounded,
                              color: (isLoggedIn && _commentController.text.trim().isNotEmpty) ? AppColors.primary : AppColors.textMuted,
                            ),
                    ),
                    ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nav bar prev/next chapter — widget terpisah agar rebuild-nya
// tidak mempengaruhi scroll/page position di ReaderScreen ────────
class _ChapterNavBar extends ConsumerWidget {
  final String comicId;
  final String currentChapterId;
  final void Function(String chapterId) onNavigate;

  const _ChapterNavBar({
    required this.comicId,
    required this.currentChapterId,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chaptersAsync = ref.watch(comicChaptersProvider(comicId));

    Chapter? prevChapter;
    Chapter? nextChapter;
    chaptersAsync.whenData((chapters) {
      final idx = chapters.indexWhere((ch) => ch.id == currentChapterId);
      if (idx != -1) {
        if (idx > 0) nextChapter = chapters[idx - 1];
        if (idx < chapters.length - 1) prevChapter = chapters[idx + 1];
      }
    });

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.78),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: prevChapter == null
                      ? null
                      : () => onNavigate(prevChapter!.id),
                  icon: const Icon(Icons.chevron_left_rounded),
                  label: const Text('Sebelumnya'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white38,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                    backgroundColor: Colors.black.withValues(alpha: 0.28),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: nextChapter == null
                      ? null
                      : () => onNavigate(nextChapter!.id),
                  icon: const Icon(Icons.chevron_right_rounded),
                  label: const Text('Berikutnya'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white38,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                    backgroundColor: Colors.black.withValues(alpha: 0.28),
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
