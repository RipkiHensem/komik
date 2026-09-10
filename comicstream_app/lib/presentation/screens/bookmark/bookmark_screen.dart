import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/proxied_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers/providers.dart';
import '../../../data/models/bookmark.dart';
import '../../widgets/error_view.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/hover_builder.dart';

/// Elevated modern Bookmark/Library screen with two tabs: Bookmarks & Reading History
class BookmarkScreen extends ConsumerStatefulWidget {
  const BookmarkScreen({super.key});

  @override
  ConsumerState<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends ConsumerState<BookmarkScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialTab = ref.read(bookmarkTabProvider).clamp(0, 1);
    _tabController = TabController(length: 2, vsync: this, initialIndex: initialTab);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(bookmarkTabProvider.notifier).state = _tabController.index;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(bookmarkTabProvider, (previous, next) {
      if (_tabController.index != next && next >= 0 && next < 2) {
        _tabController.animateTo(next);
      }
    });

    final bookmarksCount = ref.watch(bookmarksProvider).valueOrNull?.length ?? 0;
    final historyCount = ref.watch(historyProvider).valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Modern Elevated Header ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.collections_bookmark_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rak Koleksi',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        'Kelola komik favorit & progres riwayat bacamu',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── Refined Segmented Tab Bar ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 380),
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.glassBorder, width: 1),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                  padding: const EdgeInsets.all(3.5),
                  tabs: [
                    Tab(
                      height: 38,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bookmark_rounded, size: 15),
                          const SizedBox(width: 6),
                          const Text('Bookmark'),
                          if (bookmarksCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: _tabController.index == 0
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$bookmarksCount',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: _tabController.index == 0
                                      ? Colors.white
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      height: 38,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.history_rounded, size: 15),
                          const SizedBox(width: 6),
                          const Text('Riwayat Baca'),
                          if (historyCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: _tabController.index == 1
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$historyCount',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: _tabController.index == 1
                                      ? Colors.white
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Divider(color: AppColors.divider, height: 1),

            // ── Tab Content ───────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _BookmarkTab(),
                  _HistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bookmark Tab (manual bookmarks) ───────────────────────────
class _BookmarkTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authProvider).user;
    if (authUser == null) {
      return _buildEmptyState(
        context,
        title: 'Masuk untuk Simpan Bookmark',
        subtitle: 'Masuk atau buat akun agar komik favoritmu tersimpan rapi dan dapat diakses kapan saja.',
        icon: Icons.bookmark_add_outlined,
        buttonLabel: 'Masuk ke Akun',
        buttonIcon: Icons.login_rounded,
        onButtonPressed: () => context.push('/login'),
      );
    }

    final bookmarksAsync = ref.watch(bookmarksProvider);

    return bookmarksAsync.when(
      data: (bookmarks) {
        if (bookmarks.isEmpty) {
          return _buildEmptyState(
            context,
            title: 'Belum Ada Bookmark',
            subtitle: 'Simpan komik favoritmu dengan mengetuk ikon bookmark pada halaman komik agar tersusun rapi di sini.',
            icon: Icons.bookmark_add_outlined,
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            await ref.read(bookmarksProvider.notifier).loadBookmarks();
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: bookmarks.length,
            itemBuilder: (context, index) {
              final bookmark = bookmarks[index];
              return _BookmarkCard(
                bookmark: bookmark,
                onDelete: () => ref.read(bookmarksProvider.notifier).removeBookmark(bookmark.id),
                onTap: () => context.push('/comic/${bookmark.comicId}'),
                onContinue: bookmark.lastChapterId != null
                    ? () => context.push('/comic/${bookmark.comicId}/chapter/${bookmark.lastChapterId}')
                    : null,
                icon: Icons.bookmark_rounded,
                iconColor: AppColors.primary,
              );
            },
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(
            5,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ShimmerLoading(height: 96),
            ),
          ),
        ),
      ),
      error: (error, _) => ErrorView(
        message: 'Gagal memuat bookmark',
        onRetry: () => ref.read(bookmarksProvider.notifier).loadBookmarks(),
      ),
    );
  }
}

// ── History Tab (auto reading progress) ───────────────────────
class _HistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authProvider).user;
    if (authUser == null) {
      return _buildEmptyState(
        context,
        title: 'Masuk untuk Catat Riwayat',
        subtitle: 'Masuk agar chapter dan posisi komik yang kamu baca tersimpan otomatis di akunmu.',
        icon: Icons.history_toggle_off_rounded,
        buttonLabel: 'Masuk ke Akun',
        buttonIcon: Icons.login_rounded,
        onButtonPressed: () => context.push('/login'),
      );
    }

    final historyAsync = ref.watch(historyProvider);

    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) {
          return _buildEmptyState(
            context,
            title: 'Riwayat Baca Kosong',
            subtitle: 'Komik dan chapter yang kamu baca akan otomatis tersimpan di sini agar kamu bisa lanjut kapan saja.',
            icon: Icons.history_toggle_off_rounded,
          );
        }

        return Column(
          children: [
            // Info banner & Clear All button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${history.length} komik telah kamu baca',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppColors.card,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: AppColors.glassBorder),
                          ),
                          title: Text(
                            'Hapus Semua Riwayat?',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          content: Text(
                            'Semua catatan progres membaca komikmu akan dibersihkan.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(
                                'Batal',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Hapus'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await ref.read(historyProvider.notifier).clearAll();
                      }
                    },
                    child: HoverWidget(
                      scale: 1.08,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete_sweep_rounded,
                              size: 15,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Hapus Semua',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
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
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                onRefresh: () async {
                  await ref.read(historyProvider.notifier).loadHistory();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return _BookmarkCard(
                      bookmark: item,
                      onDelete: () => ref.read(historyProvider.notifier).deleteEntry(item.id),
                      onTap: () => context.push('/comic/${item.comicId}'),
                      onContinue: item.lastChapterId != null
                          ? () => context.push('/comic/${item.comicId}/chapter/${item.lastChapterId}')
                          : null,
                      icon: Icons.history_rounded,
                      iconColor: AppColors.secondary,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(
            5,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ShimmerLoading(height: 96),
            ),
          ),
        ),
      ),
      error: (error, _) => ErrorView(
        message: 'Gagal memuat riwayat',
        onRetry: () => ref.read(historyProvider.notifier).loadHistory(),
      ),
    );
  }
}

// ── Shared modern bookmark/history card widget ───────────────────────
class _BookmarkCard extends StatefulWidget {
  final Bookmark bookmark;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final VoidCallback? onContinue;
  final IconData icon;
  final Color iconColor;

  const _BookmarkCard({
    required this.bookmark,
    required this.onDelete,
    required this.onTap,
    this.onContinue,
    required this.icon,
    required this.iconColor,
  });

  @override
  State<_BookmarkCard> createState() => _BookmarkCardState();
}

class _BookmarkCardState extends State<_BookmarkCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bookmark = widget.bookmark;
    return Dismissible(
      key: Key(bookmark.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Hapus',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_rounded, color: AppColors.error),
          ],
        ),
      ),
      onDismissed: (_) => widget.onDelete(),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedScale(
          scale: _isHovered ? 1.015 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: _isHovered ? AppColors.cardHover : AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isHovered
                    ? AppColors.primary.withValues(alpha: 0.45)
                    : AppColors.glassBorder,
                width: 0.9,
              ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: _isHovered ? 0.32 : (AppColors.isDark ? 0.2 : 0.05),
                ),
                blurRadius: _isHovered ? 14 : 8,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Cover Image with smooth rounded corners & subtle shadow
                  Container(
                    width: 68,
                    height: 94,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.glassBorder, width: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ProxiedImage(
                      imageUrl: bookmark.comicCoverUrl ?? '',
                      width: 68,
                      height: 94,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Metadata & Actions
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          bookmark.comicTitle ?? 'Untitled',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 7),

                        // Progress Tag Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.18),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(widget.icon, size: 12, color: widget.iconColor),
                              const SizedBox(width: 4.5),
                              Flexible(
                                child: Text(
                                  bookmark.progressText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Continue reading button
                        if (widget.onContinue != null)
                          HoverWidget(
                            scale: 1.06,
                            onTap: widget.onContinue,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.play_arrow_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Lanjut Baca',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Actions: 1-Tap Delete Button
                  HoverWidget(
                    scale: 1.15,
                    child: IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.textMuted.withValues(alpha: 0.7),
                        size: 20,
                      ),
                      splashRadius: 20,
                      tooltip: 'Hapus',
                      onPressed: widget.onDelete,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}

// ── Custom Art-Directed Empty State Widget ─────────────────────────────
Widget _buildEmptyState(
  BuildContext context, {
  required String title,
  required String subtitle,
  required IconData icon,
  String buttonLabel = 'Jelajahi Komik',
  IconData buttonIcon = Icons.explore_rounded,
  VoidCallback? onButtonPressed,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.08),
                ),
              ),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.22),
                      AppColors.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 34,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          HoverWidget(
            scale: 1.05,
            enableGlow: true,
            glowColor: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
            child: ElevatedButton.icon(
              onPressed: onButtonPressed ?? () => context.go('/home'),
              icon: Icon(buttonIcon, size: 16),
              label: Text(buttonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

