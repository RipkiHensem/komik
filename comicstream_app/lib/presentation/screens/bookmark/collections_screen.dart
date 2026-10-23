import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/repositories/collection_repository.dart';
import '../../../data/providers/collection_repository_provider.dart';
import '../../widgets/proxied_image.dart';
import '../../widgets/collection_like_button.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers/providers.dart';
import '../../../data/models/collection.dart';
import 'edit_collection_dialog.dart';

// ── Providers ─────────────────────────────────────────────────

/// State notifier untuk koleksi milik user
class MyCollectionsNotifier
    extends StateNotifier<AsyncValue<List<Collection>>> {
  final CollectionRepository _repository;
  final String _userId;

  MyCollectionsNotifier(this._repository, this._userId)
    : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getMyCollections(_userId);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Collection?> create({
    required String name,
    String? description,
    bool isPublic = true,
  }) async {
    try {
      final collection = await _repository.create(
        userId: _userId,
        name: name,
        description: description,
        isPublic: isPublic,
      );
      await load();
      return collection;
    } catch (_) {
      return null;
    }
  }

  Future<void> delete(String collectionId) async {
    try {
      await _repository.delete(collectionId);
      await load();
    } catch (error, stack) {
      if (mounted) state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  Future<void> addComic(
    String collectionId, {
    required String comicId,
    String? comicTitle,
    String? comicCoverUrl,
  }) async {
    try {
      await _repository.addComic(
        collectionId,
        comicId: comicId,
        comicTitle: comicTitle,
        comicCoverUrl: comicCoverUrl,
      );
      await load();
    } catch (error, stack) {
      if (mounted) state = AsyncValue.error(error, stack);
      rethrow;
    }
  }

  Future<void> removeComic(String collectionId, String comicId) async {
    try {
      await _repository.removeComic(collectionId, comicId);
      await load();
    } catch (error, stack) {
      if (mounted) state = AsyncValue.error(error, stack);
      rethrow;
    }
  }
}

final myCollectionsProvider =
    StateNotifierProvider<MyCollectionsNotifier, AsyncValue<List<Collection>>>((
      ref,
    ) {
      final user = ref.watch(authProvider).user;
      return MyCollectionsNotifier(
        ref.watch(collectionRepositoryProvider),
        user?.id ?? '',
      );
    });

/// Provider untuk koleksi publik semua user (explore)
final publicCollectionsProvider = FutureProvider<List<Collection>>((ref) async {
  return ref.watch(collectionRepositoryProvider).getPublicCollections();
});

// ── Screen ─────────────────────────────────────────────────────

class CollectionsScreen extends ConsumerStatefulWidget {
  const CollectionsScreen({super.key});

  @override
  ConsumerState<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends ConsumerState<CollectionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                    ),
                    child: const Icon(
                      Icons.folder_special_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Koleksi',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        'Kurasi dan bagikan daftar komik favoritmu',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (user != null)
                    IconButton(
                      onPressed: () => _showCreateDialog(context),
                      icon: const Icon(Icons.add_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: AppColors.glassBorder),
                      ),
                    ),
                ],
              ),
            ),

            // Tab bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 44,
                constraints: const BoxConstraints(maxWidth: 340),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                  padding: const EdgeInsets.all(3.5),
                  tabs: const [
                    Tab(height: 38, text: 'Milikku'),
                    Tab(height: 38, text: 'Jelajahi Publik'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: AppColors.divider, height: 1),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _MyCollectionsTab(
                    onCreateTap: () => _showCreateDialog(context),
                  ),
                  const _PublicCollectionsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const EditCollectionDialog(),
    );
    if (saved == true && mounted) {
      ref.invalidate(myCollectionsProvider);
      ref.invalidate(publicCollectionsProvider);
      ScaffoldMessenger.of(
        this.context,
      ).showSnackBar(const SnackBar(content: Text('Koleksi berhasil dibuat')));
    }
  }
}

// ── My Collections Tab ─────────────────────────────────────────

class _MyCollectionsTab extends ConsumerWidget {
  final VoidCallback onCreateTap;
  const _MyCollectionsTab({required this.onCreateTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    if (user == null) {
      return _buildEmptyState(
        context,
        icon: Icons.folder_off_rounded,
        title: 'Masuk untuk Buat Koleksi',
        subtitle: 'Kamu perlu login untuk membuat dan mengelola koleksi komik.',
        buttonLabel: 'Masuk',
        onButton: () => context.push('/login'),
      );
    }

    final collectionsAsync = ref.watch(myCollectionsProvider);

    return collectionsAsync.when(
      data: (collections) {
        if (collections.isEmpty) {
          return _buildEmptyState(
            context,
            icon: Icons.folder_open_rounded,
            title: 'Belum Ada Koleksi',
            subtitle:
                'Buat koleksi pertamamu dan mulai kurasi komik favoritmu!',
            buttonLabel: 'Buat Koleksi',
            onButton: onCreateTap,
          );
        }
        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () => ref.read(myCollectionsProvider.notifier).load(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: collections.length,
            itemBuilder: (context, index) => _CollectionCard(
              collection: collections[index],
              isOwner: true,
              onTap: () =>
                  context.push('/collections/${collections[index].id}'),
              onDelete: () async {
                try {
                  await ref
                      .read(myCollectionsProvider.notifier)
                      .delete(collections[index].id);
                  ref.invalidate(publicCollectionsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Koleksi berhasil dihapus')),
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gagal menghapus koleksi. Coba lagi.'),
                      ),
                    );
                  }
                }
              },
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Gagal memuat koleksi',
              style: TextStyle(color: AppColors.textMuted),
            ),
            TextButton(
              onPressed: () => ref.read(myCollectionsProvider.notifier).load(),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Public Collections Tab ─────────────────────────────────────

class _PublicCollectionsTab extends ConsumerWidget {
  const _PublicCollectionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final publicAsync = ref.watch(publicCollectionsProvider);

    return publicAsync.when(
      data: (collections) {
        if (collections.isEmpty) {
          return _buildEmptyState(
            context,
            icon: Icons.public_rounded,
            title: 'Belum Ada Koleksi Publik',
            subtitle: 'Jadilah yang pertama membagikan koleksi komikmu!',
          );
        }
        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () => ref.refresh(publicCollectionsProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: collections.length,
            itemBuilder: (context, index) => _CollectionCard(
              collection: collections[index],
              isOwner: false,
              onTap: () =>
                  context.push('/collections/${collections[index].id}'),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 36,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                'Gagal memuat koleksi publik',
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(publicCollectionsProvider),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Collection Card ────────────────────────────────────────────

class _CollectionCard extends StatefulWidget {
  final Collection collection;
  final bool isOwner;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _CollectionCard({
    required this.collection,
    required this.isOwner,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<_CollectionCard> createState() => _CollectionCardState();
}

class _CollectionCardState extends State<_CollectionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.collection;
    final covers = c.previewCovers;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.cardHover : AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : AppColors.glassBorder,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Cover grid 2×2
                SizedBox(
                  width: 72,
                  height: 72,
                  child: covers.isEmpty
                      ? Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.folder_rounded,
                            color: AppColors.textMuted,
                            size: 28,
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: GridView.count(
                            crossAxisCount: 2,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            crossAxisSpacing: 2,
                            mainAxisSpacing: 2,
                            children: [
                              ...List.generate(4, (i) {
                                final url = i < covers.length ? covers[i] : '';
                                return url.isNotEmpty
                                    ? ProxiedImage(
                                        imageUrl: url,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(color: AppColors.surfaceLight);
                              }),
                            ],
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: c.isPublic
                                  ? Colors.green.withValues(alpha: 0.12)
                                  : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: c.isPublic
                                    ? Colors.green.withValues(alpha: 0.3)
                                    : AppColors.glassBorder,
                              ),
                            ),
                            child: Text(
                              c.isPublic ? '🌐 Publik' : '🔒 Privat',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: c.isPublic
                                    ? Colors.green
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (c.description != null && c.description!.isNotEmpty)
                        Text(
                          c.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      CollectionLikeButton(collectionId: c.id),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${c.itemCount} komik',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!widget.isOwner) ...[
                            const SizedBox(width: 10),
                            CircleAvatar(
                              radius: 9,
                              backgroundColor: AppColors.primarySurface,
                              backgroundImage:
                                  (c.userAvatarUrl != null &&
                                      c.userAvatarUrl!.isNotEmpty)
                                  ? NetworkImage(c.userAvatarUrl!)
                                  : null,
                              child:
                                  (c.userAvatarUrl == null ||
                                      c.userAvatarUrl!.isEmpty)
                                  ? Text(
                                      c.username[0].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              c.username,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (widget.isOwner && widget.onDelete != null)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.textMuted.withValues(alpha: 0.7),
                      size: 18,
                    ),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppColors.card,
                          title: Text(
                            'Hapus Koleksi?',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                          content: Text(
                            'Koleksi "${c.name}" akan dihapus permanen.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(
                                'Batal',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade800,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Hapus'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) widget.onDelete!();
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helper empty state ─────────────────────────────────────────

Widget _buildEmptyState(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  String? buttonLabel,
  VoidCallback? onButton,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Icon(icon, size: 32, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (buttonLabel != null && onButton != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onButton,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                buttonLabel,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
