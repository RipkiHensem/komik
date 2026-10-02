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

/// Home screen for popular comics and paged latest updates.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _homeScrollController = ScrollController();
  static const int _latestPageSize = 8;
  static const double _latestGridMaxWidth = 440;
  static const double _mobileAppMaxWidth = 480;
  int _latestPage = 0;
  String? _selectedFormat;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _homeScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final popularComics = ref.watch(
      popularComicsByFormatProvider(_selectedFormat),
    );
    final homeComicsState = ref.watch(homeComicsProvider(_selectedFormat));
    final authUser = ref.watch(authProvider).user;
    final screenWidth = MediaQuery.of(context).size.width;
    final appWidth = screenWidth.clamp(0.0, _mobileAppMaxWidth);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SizedBox(
          width: appWidth,
          child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: () async {
                setState(() => _latestPage = 0);
                ref.invalidate(popularComicsByFormatProvider(_selectedFormat));
                await ref
                    .read(homeComicsProvider(_selectedFormat).notifier)
                    .loadInitial();
              },
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
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
                      backgroundColor: AppColors.background.withValues(
                        alpha: 0.95,
                      ),
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      scrolledUnderElevation: 0,
                      titleSpacing: 16,
                      title: Row(
                        children: [
                          Icon(Icons.auto_stories_outlined, size: 28, color: AppColors.textPrimary),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'ComicStream',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
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
                            scale: 0.98,
                            duration: const Duration(milliseconds: 150),
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              ref.read(searchStateProvider.notifier).state =
                                  const SearchState();
                              context.go('/search');
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              child: Icon(Icons.search, size: 22, color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                        // In-App Login or User Avatar
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: authUser == null
                              ? HoverWidget(
                                  scale: 0.98,
                                  duration: const Duration(milliseconds: 150),
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: () => context.push('/login'),
                                  child: Container(
                                    height: 44,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.login_rounded,
                                          size: 15,
                                          color: AppColors.background,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          'Masuk',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.background,
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
                                        color: AppColors.border,
                                        width: 1,
                                      ),
                                      color: AppColors.surface,
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child:
                                        (authUser.avatarUrl != null &&
                                            authUser.avatarUrl!.isNotEmpty)
                                        ? Image.network(
                                            authUser.avatarUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) => Center(
                                                  child: Text(
                                                    authUser.username.isNotEmpty
                                                        ? authUser.username[0]
                                                              .toUpperCase()
                                                        : 'U',
                                                    style:
                                                        GoogleFonts.plusJakartaSans(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color:
                                                              AppColors.primary,
                                                        ),
                                                  ),
                                                ),
                                          )
                                        : Center(
                                            child: Text(
                                              authUser.username.isNotEmpty
                                                  ? authUser.username[0]
                                                        .toUpperCase()
                                                  : 'U',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
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

                    // ── Section: Populer ──────────────────────────────────────
                    SliverToBoxAdapter(
                      child: _buildSectionHeader(
                        title: _selectedFormat != null
                            ? 'Populer $_selectedFormat'
                            : 'Populer Minggu Ini',
                        tag: _selectedFormat != null
                            ? _selectedFormat!.toUpperCase()
                            : 'HOT',
                        onSeeAll: () {
                          ref
                              .read(searchStateProvider.notifier)
                              .state = SearchState(
                            sortBy: 'popular',
                            selectedFormat: _selectedFormat,
                          );
                          context.go('/search');
                        },
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
                              _buildQuickFilterPill('Semua', null),
                              const SizedBox(width: 8),
                              _buildQuickFilterPill('Manhwa', 'Manhwa'),
                              const SizedBox(width: 8),
                              _buildQuickFilterPill('Manga', 'Manga'),
                              const SizedBox(width: 8),
                              _buildQuickFilterPill('Manhua', 'Manhua'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: popularComics.when(
                        data: (comics) =>
                            _buildHorizontalList(comics.take(7).toList()),
                        loading: () => _buildHorizontalShimmer(),
                        error: (error, _) => ErrorView(
                          message: 'Gagal memuat komik populer',
                          onRetry: () => ref.invalidate(
                            popularComicsByFormatProvider(_selectedFormat),
                          ),
                        ),
                      ),
                    ),

                    // ── Section: Update Terbaru ───────────────────────────────
                    SliverToBoxAdapter(
                      child: _buildSectionHeader(
                        title: _selectedFormat != null
                            ? 'Update $_selectedFormat Terbaru'
                            : 'Update Terbaru',
                        tag: _selectedFormat == null ? 'LIVE' : null,
                        onSeeAll: () {
                          ref
                              .read(searchStateProvider.notifier)
                              .state = SearchState(
                            sortBy: 'latest',
                            selectedFormat: _selectedFormat,
                          );
                          context.go('/search');
                        },
                      ),
                    ),
                    if (homeComicsState.isLoading &&
                        homeComicsState.comics.isEmpty)
                      const SliverToBoxAdapter(child: ComicGridShimmer())
                    else if (homeComicsState.error != null &&
                        homeComicsState.comics.isEmpty)
                      SliverToBoxAdapter(
                        child: ErrorView(
                          message: 'Gagal memuat update terbaru',
                          onRetry: () => ref
                              .read(
                                homeComicsProvider(_selectedFormat).notifier,
                              )
                              .loadInitial(),
                        ),
                      )
                    else ...[
                      _buildComicGrid(
                        homeComicsState.comics
                            .skip(_latestPage * _latestPageSize)
                            .take(_latestPageSize)
                            .toList(),
                      ),
                      SliverToBoxAdapter(
                        child: _buildLatestPagination(homeComicsState),
                      ),
                    ],

                    // Bottom padding to avoid floating dock collision
                    const SliverToBoxAdapter(child: SizedBox(height: 88)),
                  ],
                ),
              ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFilterPill(String label, String? format) {
    final isSelected = _selectedFormat == format;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: HoverWidget(
        scale: 0.98,
        duration: const Duration(milliseconds: 150),
        borderRadius: BorderRadius.circular(999),
        onTap: () {
          if (_selectedFormat == format) return;
          setState(() {
            _selectedFormat = format;
            _latestPage = 0;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppColors.background : AppColors.textSecondary,
            ),
          ),
        ),
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
      height: 372,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: displayComics.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 150,
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

  /// Two-card grid with a capped width so the right side stays open.
  Widget _buildComicGrid(List<Comic> comics) {
    if (comics.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Belum ada update',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    final availableWidth = MediaQuery.sizeOf(context).width - 32;
    final gridWidth = availableWidth.clamp(0.0, _latestGridMaxWidth);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: gridWidth,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.42,
                crossAxisSpacing: 16,
                mainAxisSpacing: 24,
              ),
              itemCount: comics.length,
              itemBuilder: (context, index) => ComicCard(
                comic: comics[index],
                onTap: () => context.go('/comic/${comics[index].id}'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLatestPagination(HomeComicsState state) {
    final nextPageStart = (_latestPage + 1) * _latestPageSize;
    final canGoNext = nextPageStart < state.comics.length || state.hasMore;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    textStyle: const TextStyle(fontSize: 11),
                    minimumSize: const Size(44, 44),
                  ),
                  onPressed: _latestPage > 0 && !state.isLoadingMore
                      ? () => setState(() => _latestPage--)
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Sebelumnya'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 48,
                child: Center(
                  child: Text(
                    '${_latestPage + 1}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    textStyle: const TextStyle(fontSize: 11),
                    minimumSize: const Size(44, 44),
                  ),
                  onPressed: canGoNext && !state.isLoadingMore
                      ? () => _goToNextLatestPage(state)
                      : null,
                  icon: state.isLoadingMore
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Berikutnya'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _goToNextLatestPage(HomeComicsState state) async {
    final nextPage = _latestPage + 1;
    final requiredCount = (nextPage + 1) * _latestPageSize;
    if (state.comics.length < requiredCount && state.hasMore) {
      await ref.read(homeComicsProvider(_selectedFormat).notifier).loadMore();
    }
    if (!mounted) return;
    final updated = ref.read(homeComicsProvider(_selectedFormat));
    if (updated.comics.length > nextPage * _latestPageSize) {
      setState(() => _latestPage = nextPage);
    }
  }

  /// Refined section header with title, badge tag, and circular arrow CTA
  Widget _buildSectionHeader({
    required String title,
    String? tag,
    VoidCallback? onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.visible,
            ),
          ),
          if (tag != null) ...[
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 6, color: AppColors.textMuted),
                const SizedBox(width: 5),
                Text(
                  tag,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
          if (onSeeAll != null)
            HoverWidget(
              scale: 0.98,
              duration: const Duration(milliseconds: 150),
              borderRadius: BorderRadius.circular(999),
              onTap: onSeeAll,
              child: SizedBox(
                height: 44,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    Text(
                      'Semua',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHorizontalShimmer() {
    return SizedBox(
      height: 372,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return const Padding(
            padding: EdgeInsets.only(right: 12),
            child: SizedBox(width: 135, child: ComicCardShimmer()),
          );
        },
      ),
    );
  }
}
