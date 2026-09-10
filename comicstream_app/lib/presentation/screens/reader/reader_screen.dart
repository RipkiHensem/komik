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
import '../../../data/models/comic_page.dart';
import '../../../data/models/chapter.dart';
import '../../widgets/error_view.dart';
import '../../widgets/hover_builder.dart';

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
  bool _showOverlay = true;
  Timer? _hideOverlayTimer;
  String _readingMode = AppConstants.readingModeScroll; // Default vertical scroll for webtoons
  int _currentPage = 0;
  late final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(0);
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveProgress(1);
    });
  }

  @override
  void dispose() {
    _hideOverlayTimer?.cancel();
    _currentPageNotifier.dispose();
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

  void _setReadingMode(String mode) {
    if (_readingMode == mode) return;
    _startHideOverlayTimer();
    setState(() => _readingMode = mode);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mode == AppConstants.readingModeScroll
              ? 'Mode Baca: Slide Bawah - Atas (Webtoon)'
              : 'Mode Baca: Geser Samping (Manga)',
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surface,
      ),
    );
  }

  void _saveProgress(int pageNumber) {
    // 1. Mark chapter as read locally and sync to backend
    ref
        .read(readChaptersProvider(widget.comicId).notifier)
        .markAsRead(widget.chapterId);

    // 2. Record reading history immediately
    ref.read(historyProvider.notifier).recordProgress(
          comicId: widget.comicId,
          chapterId: widget.chapterId,
          page: pageNumber,
        );

    // 3. Update bookmark progress if bookmarked
    ref.read(bookmarksProvider.notifier).updateProgress(
          widget.comicId,
          widget.chapterId,
          pageNumber,
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
    _saveProgress(_currentPage + 1);
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
    _saveProgress(_currentPage + 1);
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
    final pagesAsync = ref.watch(chapterPagesProvider(widget.chapterId));
    final chaptersAsync = ref.watch(comicChaptersProvider(widget.comicId));

    // Responsive desktop calculations:
    // If screen width is wider than 680px, constrain the reader to a mobile phone width (560px)
    // so images are not stretched or upscaled.
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 680;
    final readerWidth = isDesktop ? 560.0 : screenSize.width;

    // Calculate next & previous chapters
    Chapter? prevChapter;
    Chapter? nextChapter;
    chaptersAsync.whenData((chapters) {
      final currentIndex = chapters.indexWhere((ch) => ch.id == widget.chapterId);
      if (currentIndex != -1) {
        if (currentIndex > 0) {
          nextChapter = chapters[currentIndex - 1];
        }
        if (currentIndex < chapters.length - 1) {
          prevChapter = chapters[currentIndex + 1];
        }
      }
    });

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

              // Position scrollbar at the far right of the desktop
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
                  // ── Reader Content (Full screen with far-right scrollbar on desktop) ──
                  Positioned.fill(
                    child: scrollableContent,
                  ),

                  // ── Custom Non-Blinking Scrollbar (Draggable & Proportional) ──
                  if (_readingMode == AppConstants.readingModeScroll && pages.length > 1)
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: 2,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragUpdate: (details) {
                          if (!_scrollController.hasClients ||
                              _scrollController.position.maxScrollExtent <= 0) {
                            return;
                          }
                          final screenHeight = MediaQuery.of(context).size.height;
                          final fraction = (details.globalPosition.dy / screenHeight).clamp(0.0, 1.0);
                          final targetOffset = fraction * _scrollController.position.maxScrollExtent;
                          _scrollController.jumpTo(targetOffset);
                        },
                        child: SizedBox(
                          width: 14,
                          child: ValueListenableBuilder<int>(
                            valueListenable: _currentPageNotifier,
                            builder: (context, currentPage, _) {
                              final screenHeight = MediaQuery.of(context).size.height;
                              final thumbHeight = (screenHeight / pages.length).clamp(30.0, screenHeight);
                              final maxTop = screenHeight - thumbHeight;
                              final topOffset = (currentPage / (pages.length - 1)) * maxTop;

                              return Stack(
                                alignment: Alignment.centerRight,
                                children: [
                                  // Track
                                  Container(
                                    width: 5,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  // Thumb
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 150),
                                    curve: Curves.easeOut,
                                    top: topOffset,
                                    right: 0,
                                    child: Container(
                                      width: 5,
                                      height: thumbHeight,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.7),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                  // ── Top Overlay (Auto-hides in 5 seconds) ──────────────────
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      ignoring: !_showOverlay,
                      child: AnimatedOpacity(
                        opacity: _showOverlay ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.95),
                                Colors.black.withValues(alpha: 0.5),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  // Back button
                                  HoverWidget(
                                    scale: 1.08,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _handleExit,
                                        borderRadius: BorderRadius.circular(24),
                                        child: Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: AppColors.surface.withValues(alpha: 0.9),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.2),
                                              width: 1,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.arrow_back_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'ComicStream Reader',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        ValueListenableBuilder<int>(
                                          valueListenable: _currentPageNotifier,
                                          builder: (context, currentPage, _) {
                                            return Text(
                                              'Halaman ${currentPage + 1} / ${pages.length}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white.withValues(alpha: 0.7),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Reading mode toggle
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.surface.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Tooltip(
                                          message: 'Mode Slide Bawah-Atas (Webtoon)',
                                          child: _modeButton(
                                            icon: Icons.swap_vert_rounded,
                                            label: isDesktop ? 'Slide Bawah-Atas' : null,
                                            isActive: _readingMode ==
                                                AppConstants.readingModeScroll,
                                            onTap: () => _setReadingMode(
                                                AppConstants.readingModeScroll),
                                          ),
                                        ),
                                        Tooltip(
                                          message: 'Mode Geser Samping (Manga)',
                                          child: _modeButton(
                                            icon: Icons.swap_horiz_rounded,
                                            label: isDesktop ? 'Geser Samping' : null,
                                            isActive: _readingMode ==
                                                AppConstants.readingModePage,
                                            onTap: () => _setReadingMode(
                                                AppConstants.readingModePage),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  HoverWidget(
                                    scale: 1.1,
                                    child: IconButton(
                                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                                      tooltip: 'Tutup Reader',
                                      onPressed: _handleExit,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Bottom Overlay (Auto-hides in 5 seconds: Prev, Keluar, Next) ──
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      ignoring: !_showOverlay,
                      child: AnimatedOpacity(
                        opacity: _showOverlay ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.95),
                                Colors.black.withValues(alpha: 0.5),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: SafeArea(
                            top: false,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Page jump slider
                                  if (pages.length > 1)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: SliderTheme(
                                        data: SliderThemeData(
                                          activeTrackColor: AppColors.primary,
                                          inactiveTrackColor:
                                              Colors.white.withValues(alpha: 0.2),
                                          thumbColor: AppColors.primary,
                                          thumbShape: const RoundSliderThumbShape(
                                            enabledThumbRadius: 6,
                                          ),
                                          trackHeight: 3,
                                        ),
                                        child: ValueListenableBuilder<int>(
                                          valueListenable: _currentPageNotifier,
                                          builder: (context, currentPage, _) {
                                            return Slider(
                                              value: currentPage
                                                  .clamp(0, pages.length - 1)
                                                  .toDouble(),
                                              min: 0,
                                              max: (pages.length - 1).toDouble(),
                                              onChanged: (value) {
                                                _startHideOverlayTimer();
                                                final targetPage = value.toInt();
                                                _currentPage = targetPage;
                                                _currentPageNotifier.value = targetPage;
                                                if (_readingMode ==
                                                    AppConstants.readingModePage) {
                                                  _pageController.jumpToPage(targetPage);
                                                } else if (_scrollController.hasClients &&
                                                    _scrollController
                                                            .position.maxScrollExtent >
                                                        0) {
                                                  final targetOffset = (targetPage /
                                                          (pages.length - 1)) *
                                                      _scrollController
                                                          .position.maxScrollExtent;
                                                  _scrollController.jumpTo(targetOffset);
                                                }
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ),

                                  // Chapter navigation: Prev, Keluar, Next
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        HoverWidget(
                                          scale: 1.08,
                                          child: TextButton.icon(
                                            onPressed: prevChapter != null
                                                ? () => _goToChapter(prevChapter!.id)
                                                : null,
                                            icon: Icon(
                                              Icons.skip_previous_rounded,
                                              size: 20,
                                              color: prevChapter != null
                                                  ? Colors.white
                                                  : Colors.white24,
                                            ),
                                            label: Text(
                                              'Prev',
                                              style: TextStyle(
                                                color: prevChapter != null
                                                    ? Colors.white
                                                    : Colors.white24,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Middle: Keluar button
                                        HoverWidget(
                                          scale: 1.06,
                                          child: ElevatedButton.icon(
                                            onPressed: _handleExit,
                                            icon: const Icon(Icons.arrow_back_rounded, size: 16),
                                            label: const Text('Keluar'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.surface,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                              side: BorderSide(
                                                color: Colors.white.withValues(alpha: 0.2),
                                                width: 0.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                        HoverWidget(
                                          scale: 1.08,
                                          child: TextButton.icon(
                                            onPressed: nextChapter != null
                                                ? () => _goToChapter(nextChapter!.id)
                                                : null,
                                            icon: Text(
                                              'Next',
                                              style: TextStyle(
                                                color: nextChapter != null
                                                    ? Colors.white
                                                    : Colors.white24,
                                              ),
                                            ),
                                            label: Icon(
                                              Icons.skip_next_rounded,
                                              size: 20,
                                              color: nextChapter != null
                                                  ? Colors.white
                                                  : Colors.white24,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(
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
        _currentPageNotifier.value = index;
        _saveProgress(index + 1);
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
              ),
            ),
          ),
        );
      },
    );
  }

  /// Scroll mode (vertical continuous slide) — for manhwa/webtoon
  Widget _buildScrollMode(List<ComicPage> pages, double readerWidth) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          final maxExt = _scrollController.hasClients &&
                  _scrollController.position.maxScrollExtent > 0
              ? _scrollController.position.maxScrollExtent
              : 1.0;
          final scrollFraction = _scrollController.hasClients
              ? (_scrollController.offset / maxExt).clamp(0.0, 1.0)
              : 0.0;
          final estimatedPage = (scrollFraction * (pages.length - 1)).round();
          if (estimatedPage != _currentPageNotifier.value) {
            _currentPage = estimatedPage;
            _currentPageNotifier.value = estimatedPage;
            _saveProgress(estimatedPage + 1);
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
          cacheExtent: 3000,
          padding: EdgeInsets.zero,
          itemCount: pages.length,
          itemBuilder: (context, index) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: readerWidth,
                maxWidth: readerWidth,
                minHeight: readerWidth * 1.3,
              ),
              child: ProxiedImage(
                imageUrl: pages[index].imageUrl,
                fit: BoxFit.fitWidth,
                width: readerWidth,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _modeButton({
    required IconData icon,
    String? label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return HoverWidget(
      scale: 1.06,
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : AppColors.textMuted,
            ),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
