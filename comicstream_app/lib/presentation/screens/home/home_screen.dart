import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers/providers.dart';
import '../../../data/models/comic.dart';
import '../../widgets/comic_card.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/error_view.dart';
import '../../widgets/hover_builder.dart';

/// World-class modern Home screen with hero showcase and refined sections
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _heroPageController = PageController(
    viewportFraction: 0.92,
  );
  final ScrollController _homeScrollController = ScrollController();
  int _currentHeroPage = 0;
  String? _selectedFormat;

  Timer? _heroAutoSlideTimer;
  int _featuredHeroCount = 0;
  bool _isHeroHovered = false;
  static const Duration _autoSlideInterval = Duration(seconds: 5);

  void _startHeroAutoPlay(int count) {
    _featuredHeroCount = count;
    if (count <= 1) return;
    _heroAutoSlideTimer?.cancel();
    _heroAutoSlideTimer = Timer.periodic(_autoSlideInterval, (timer) {
      if (!mounted || !_heroPageController.hasClients || _featuredHeroCount <= 1 || _isHeroHovered) {
        return;
      }
      final nextPage = (_currentHeroPage + 1) % _featuredHeroCount;
      _heroPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _stopHeroAutoPlay() {
    _heroAutoSlideTimer?.cancel();
    _heroAutoSlideTimer = null;
  }

  void _resetHeroAutoPlay() {
    if (_featuredHeroCount > 1 && !_isHeroHovered) {
      _startHeroAutoPlay(_featuredHeroCount);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(popularComicsByFormatProvider(null));
      ref.invalidate(latestComicsByFormatProvider(null));
    });
  }

  @override
  void dispose() {
    _heroAutoSlideTimer?.cancel();
    _heroPageController.dispose();
    _homeScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final popularComics = ref.watch(popularComicsByFormatProvider(_selectedFormat));
    final latestComics = ref.watch(latestComicsByFormatProvider(_selectedFormat));
    final authUser = ref.watch(authProvider).user;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Scrollbar(
        controller: _homeScrollController,
        thumbVisibility: true,
        trackVisibility: true,
        interactive: true,
        thickness: 8.0,
        radius: const Radius.circular(6.0),
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            _stopHeroAutoPlay();
            ref.invalidate(popularComicsByFormatProvider(_selectedFormat));
            ref.invalidate(latestComicsByFormatProvider(_selectedFormat));
          },
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: CustomScrollView(
              controller: _homeScrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // ── Modern Floating App Bar ──────────────────────────────
              SliverAppBar(
                floating: true,
                pinned: false,
                backgroundColor: AppColors.background.withValues(alpha: 0.95),
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                titleSpacing: isDesktop ? 20 : 16,
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand Icon with glowing gradient
                    Container(
                      width: isDesktop ? 36 : 32,
                      height: isDesktop ? 36 : 32,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(isDesktop ? 10 : 8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.auto_stories_rounded,
                        size: isDesktop ? 20 : 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'ComicStream',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: isDesktop ? 21 : 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  // Modern search capsule (desktop) or circular icon button (mobile)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: HoverWidget(
                      scale: 1.05,
                      enableGlow: true,
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        ref.read(searchStateProvider.notifier).state =
                            const SearchState();
                        context.go('/search');
                      },
                      child: Container(
                        height: 36,
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 14 : 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.glassBorder,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            if (isDesktop) ...[
                              const SizedBox(width: 8),
                              Text(
                                'Cari komik...',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  // In-App Login or User Avatar
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: authUser == null
                        ? HoverWidget(
                            scale: 1.05,
                            enableGlow: true,
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => context.push('/login'),
                            child: Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.login_rounded,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Masuk',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : HoverWidget(
                            scale: 1.08,
                            borderRadius: BorderRadius.circular(17),
                            onTap: () => context.go('/profile'),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                                color: AppColors.surface,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: (authUser.avatarUrl != null &&
                                      authUser.avatarUrl!.isNotEmpty)
                                  ? Image.network(
                                      authUser.avatarUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Center(
                                        child: Text(
                                          authUser.username.isNotEmpty
                                              ? authUser.username[0].toUpperCase()
                                              : 'U',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        authUser.username.isNotEmpty
                                              ? authUser.username[0].toUpperCase()
                                              : 'U',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                  ),
                ],
              ),

              // ── Hero Showcase Carousel ────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: popularComics.when(
                    data: (comics) => _buildHeroCarousel(comics),
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ShimmerLoading(height: 220, borderRadius: 20),
                    ),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ),
              ),

              // ── Quick Category Pills ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildQuickFilterPill('⚡ Semua', null),
                        const SizedBox(width: 8),
                        _buildQuickFilterPill('🇰🇷 Manhwa', 'Manhwa'),
                        const SizedBox(width: 8),
                        _buildQuickFilterPill('🇯🇵 Manga', 'Manga'),
                        const SizedBox(width: 8),
                        _buildQuickFilterPill('🇨🇳 Manhua', 'Manhua'),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Section: Populer ──────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  title: _selectedFormat != null ? 'Populer $_selectedFormat' : 'Populer Minggu Ini',
                  tag: _selectedFormat != null ? _selectedFormat!.toUpperCase() : 'HOT',
                  onSeeAll: () {
                    ref.read(searchStateProvider.notifier).state = SearchState(
                      sortBy: 'popular',
                      selectedFormat: _selectedFormat,
                    );
                    context.go('/search');
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: popularComics.when(
                  data: (comics) => _buildHorizontalList(comics.take(7).toList()),
                  loading: () => _buildHorizontalShimmer(),
                  error: (error, _) => ErrorView(
                    message: 'Gagal memuat komik populer',
                    onRetry: () => ref.invalidate(popularComicsByFormatProvider(_selectedFormat)),
                  ),
                ),
              ),

              // ── Section: Update Terbaru ───────────────────────────────
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  title: _selectedFormat != null ? 'Update $_selectedFormat Terbaru' : 'Update Terbaru',
                  tag: 'LIVE',
                  onSeeAll: () {
                    ref.read(searchStateProvider.notifier).state = SearchState(
                      sortBy: 'latest',
                      selectedFormat: _selectedFormat,
                    );
                    context.go('/search');
                  },
                ),
              ),
              latestComics.when(
                data: (comics) => _buildComicGrid(comics),
                loading: () => const SliverToBoxAdapter(
                  child: ComicGridShimmer(),
                ),
                error: (error, _) => SliverToBoxAdapter(
                  child: ErrorView(
                    message: 'Gagal memuat update terbaru',
                    onRetry: () => ref.invalidate(latestComicsByFormatProvider(_selectedFormat)),
                  ),
                ),
              ),

              // Bottom padding to avoid floating dock collision
              const SliverToBoxAdapter(
                child: SizedBox(height: 110),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildQuickFilterPill(String label, String? format) {
    final isSelected = _selectedFormat == format;

    return HoverWidget(
      scale: 1.06,
      enableGlow: isSelected,
      glowColor: AppColors.primary,
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        if (_selectedFormat != format) {
          setState(() {
            _selectedFormat = format;
            _currentHeroPage = 0;
          });
          if (_heroPageController.hasClients) {
            _heroPageController.jumpToPage(0);
          }
          _resetHeroAutoPlay();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.glassBorder,
            width: 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  /// Hero carousel with featured comics
  Widget _buildHeroCarousel(List<Comic> comics) {
    if (comics.isEmpty) return const SizedBox.shrink();
    final featured = comics.take(5).toList();

    // Start auto-play timer when comics are available or count changes
    if (_featuredHeroCount != featured.length || _heroAutoSlideTimer == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startHeroAutoPlay(featured.length);
        }
      });
    }

    return MouseRegion(
      onEnter: (_) {
        _isHeroHovered = true;
      },
      onExit: (_) {
        _isHeroHovered = false;
        _resetHeroAutoPlay();
      },
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: PageView.builder(
              controller: _heroPageController,
              itemCount: featured.length,
              onPageChanged: (index) {
                setState(() => _currentHeroPage = index);
                _resetHeroAutoPlay();
              },
              itemBuilder: (context, index) {
                return ComicCardHero(
                  comic: featured[index],
                  onTap: () => context.go('/comic/${featured[index].id}'),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Page indicators with animated capsules & interactive click support
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(featured.length, (index) {
              final isCurrent = index == _currentHeroPage;
              return GestureDetector(
                onTap: () {
                  _heroPageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOutCubic,
                  );
                  _resetHeroAutoPlay();
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    color: Colors.transparent,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      width: isCurrent ? 26 : 7,
                      height: 5,
                      decoration: BoxDecoration(
                        gradient: isCurrent ? AppColors.primaryGradient : null,
                        color: isCurrent ? null : AppColors.textMuted.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.45),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Horizontal scrollable comic list (limited to max 7 comics)
  Widget _buildHorizontalList(List<Comic> comics) {
    final displayComics = comics.take(7).toList();
    if (displayComics.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            _selectedFormat != null
                ? 'Belum ada komik populer untuk $_selectedFormat'
                : 'Belum ada komik',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    return SizedBox(
      height: 255,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: displayComics.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 135,
              child: ComicCard(
                comic: displayComics[index],
                onTap: () => context.go('/comic/${displayComics[index].id}'),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Grid of comic cards
  SliverPadding _buildComicGrid(List<Comic> comics) {
    if (comics.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.all(32),
        sliver: SliverToBoxAdapter(
          child: Center(
            child: Text(
              _selectedFormat != null
                  ? 'Belum ada update untuk $_selectedFormat'
                  : 'Belum ada update',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          childAspectRatio: 0.60,
          crossAxisSpacing: 12,
          mainAxisSpacing: 14,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return ComicCard(
              comic: comics[index],
              onTap: () => context.go('/comic/${comics[index].id}'),
            );
          },
          childCount: comics.length,
        ),
      ),
    );
  }

  /// Refined section header with title, badge tag, and circular arrow CTA
  Widget _buildSectionHeader({
    required String title,
    String? tag,
    VoidCallback? onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
      child: Row(
        children: [
          // Subtle vertical accent bar
          Container(
            width: 3.5,
            height: 18,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (tag != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tag,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (onSeeAll != null)
            HoverWidget(
              scale: 1.06,
              borderRadius: BorderRadius.circular(14),
              onTap: onSeeAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.glassBorder,
                    width: 0.6,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Semua',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHorizontalShimmer() {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return const Padding(
            padding: EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 135,
              child: ComicCardShimmer(),
            ),
          );
        },
      ),
    );
  }
}
