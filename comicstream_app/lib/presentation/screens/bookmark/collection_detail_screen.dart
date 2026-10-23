import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/providers/collection_repository_provider.dart';
import '../../widgets/proxied_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers/providers.dart';
import '../../../data/models/collection.dart';
import 'collections_screen.dart';
import 'edit_collection_dialog.dart';
import '../../widgets/collection_like_button.dart';

// ── Provider untuk detail satu koleksi ─────────────────────────
final collectionDetailProvider = FutureProvider.family<Collection?, String>((
  ref,
  id,
) async {
  return ref.watch(collectionRepositoryProvider).getById(id);
});

// ── Screen ─────────────────────────────────────────────────────
class CollectionDetailScreen extends ConsumerStatefulWidget {
  final String collectionId;
  const CollectionDetailScreen({super.key, required this.collectionId});

  @override
  ConsumerState<CollectionDetailScreen> createState() =>
      _CollectionDetailScreenState();
}

class _CollectionDetailScreenState
    extends ConsumerState<CollectionDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      collectionDetailProvider(widget.collectionId),
    );
    final myUser = ref.watch(authProvider).user;

    return detailAsync.when(
      data: (collection) {
        if (collection == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.textPrimary,
              title: const Text('Koleksi'),
            ),
            body: Center(
              child: Text(
                'Koleksi tidak ditemukan',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          );
        }

        final isOwner = myUser != null && myUser.id == collection.userId;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () => context.pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  collection.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${collection.itemCount} komik · oleh ${collection.username}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            actions: [
              CollectionLikeButton(collectionId: collection.id),
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit koleksi',
                  onPressed: () async {
                    final saved = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) =>
                          EditCollectionDialog(collection: collection),
                    );
                    if (saved == true && mounted) {
                      ref.invalidate(
                        collectionDetailProvider(widget.collectionId),
                      );
                      ref.invalidate(publicCollectionsProvider);
                      ref.invalidate(myCollectionsProvider);
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Koleksi berhasil diperbarui'),
                        ),
                      );
                    }
                  },
                ),
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.add_rounded),
                  tooltip: 'Tambah komik',
                  onPressed: () => _showAddComicSheet(context, collection),
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(color: AppColors.divider, height: 1),
            ),
          ),
          body: collection.items.isEmpty
              ? _buildEmpty(context, isOwner, collection)
              : RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  onRefresh: () => ref.refresh(
                    collectionDetailProvider(widget.collectionId).future,
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: collection.items.length,
                    itemBuilder: (context, index) {
                      final item = collection.items[index];
                      return _ComicItemCard(
                        item: item,
                        isOwner: isOwner,
                        onTap: () => context.push('/comic/${item.comicId}'),
                        onRemove: isOwner
                            ? () async {
                                try {
                                  await ref
                                      .read(myCollectionsProvider.notifier)
                                      .removeComic(
                                        widget.collectionId,
                                        item.comicId,
                                      );
                                  ref.invalidate(
                                    collectionDetailProvider(
                                      widget.collectionId,
                                    ),
                                  );
                                  ref.invalidate(publicCollectionsProvider);
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Gagal mengeluarkan komik. Coba lagi.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              }
                            : null,
                      );
                    },
                  ),
                ),
          floatingActionButton: isOwner
              ? FloatingActionButton.extended(
                  onPressed: () => _showAddComicSheet(context, collection),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    'Tambah Komik',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : null,
        );
      },
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                'Gagal membuka koleksi',
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(
                  collectionDetailProvider(widget.collectionId),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(
    BuildContext context,
    bool isOwner,
    Collection collection,
  ) {
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
              child: Icon(
                Icons.menu_book_outlined,
                size: 32,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Koleksi Masih Kosong',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isOwner
                  ? 'Tambahkan komik ke koleksi ini dengan menekan tombol di bawah.'
                  : 'Belum ada komik di koleksi ini.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (isOwner) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _showAddComicSheet(context, collection),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  'Tambah Komik',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showAddComicSheet(
    BuildContext context,
    Collection collection,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddComicSheet(
        collectionId: widget.collectionId,
        existingComicIds: collection.items.map((i) => i.comicId).toSet(),
        onAdded: () {
          ref.invalidate(collectionDetailProvider(widget.collectionId));
          ref.read(myCollectionsProvider.notifier).load();
        },
      ),
    );
  }
}

// ── Kartu komik dalam koleksi ──────────────────────────────────
class _ComicItemCard extends StatefulWidget {
  final CollectionItem item;
  final bool isOwner;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _ComicItemCard({
    required this.item,
    required this.isOwner,
    required this.onTap,
    this.onRemove,
  });

  @override
  State<_ComicItemCard> createState() => _ComicItemCardState();
}

class _ComicItemCardState extends State<_ComicItemCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.cardHover : AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : AppColors.glassBorder,
            ),
          ),
          child: Row(
            children: [
              // Cover
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 68,
                  child:
                      item.comicCoverUrl != null &&
                          item.comicCoverUrl!.isNotEmpty
                      ? ProxiedImage(
                          imageUrl: item.comicCoverUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppColors.surfaceLight,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.comicTitle ?? item.comicId,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ditambah ${_timeAgo(item.addedAt)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isOwner && widget.onRemove != null)
                IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline_rounded,
                    color: AppColors.textMuted.withValues(alpha: 0.7),
                    size: 20,
                  ),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.card,
                        title: Text(
                          'Hapus dari Koleksi?',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                        content: Text(
                          'Komik ini akan dihapus dari koleksi.',
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
                    if (ok == true) widget.onRemove!();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 30) return '${diff.inDays} hari lalu';
    return '${(diff.inDays / 30).floor()} bulan lalu';
  }
}

// ── Bottom sheet: tambah komik via search ─────────────────────
class _AddComicSheet extends ConsumerStatefulWidget {
  final String collectionId;
  final Set<String> existingComicIds;
  final VoidCallback onAdded;

  const _AddComicSheet({
    required this.collectionId,
    required this.existingComicIds,
    required this.onAdded,
  });

  @override
  ConsumerState<_AddComicSheet> createState() => _AddComicSheetState();
}

class _AddComicSheetState extends ConsumerState<_AddComicSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  final Set<String> _adding = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = _query.trim().length >= 2
        ? ref.watch(searchComicsByQueryProvider(_query.trim()))
        : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) => Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.glassBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  Text(
                    'Tambah Komik',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: TextStyle(color: AppColors.textPrimary),
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Cari judul komik...',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.textMuted,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.glassBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.glassBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            Divider(color: AppColors.divider, height: 1),

            // Results
            Expanded(
              child: searchAsync == null
                  ? _buildHint()
                  : searchAsync.when(
                      data: (comics) {
                        if (comics.isEmpty) {
                          return Center(
                            child: Text(
                              'Tidak ada hasil untuk "$_query"',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          );
                        }
                        return ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          itemCount: comics.length,
                          itemBuilder: (context, index) {
                            final comic = comics[index];
                            final alreadyIn = widget.existingComicIds.contains(
                              comic.id,
                            );
                            final isAdding = _adding.contains(comic.id);

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 4,
                              ),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 40,
                                  height: 56,
                                  child: comic.coverUrl.isNotEmpty
                                      ? ProxiedImage(
                                          imageUrl: comic.coverUrl,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          color: AppColors.surfaceLight,
                                        ),
                                ),
                              ),
                              title: Text(
                                comic.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                comic.id,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              trailing: alreadyIn
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Sudah ada',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: AppColors.textMuted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  : isAdding
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : ElevatedButton(
                                      onPressed: () async {
                                        setState(() => _adding.add(comic.id));
                                        try {
                                          await ref
                                              .read(
                                                myCollectionsProvider.notifier,
                                              )
                                              .addComic(
                                                widget.collectionId,
                                                comicId: comic.id,
                                                comicTitle: comic.title,
                                                comicCoverUrl: comic.coverUrl,
                                              );
                                          if (!mounted || !context.mounted) {
                                            return;
                                          }
                                          widget.onAdded();
                                          ref.invalidate(
                                            publicCollectionsProvider,
                                          );
                                          setState(() {
                                            _adding.remove(comic.id);
                                            widget.existingComicIds.add(
                                              comic.id,
                                            );
                                          });
                                        } catch (_) {
                                          if (!mounted) return;
                                          setState(
                                            () => _adding.remove(comic.id),
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Gagal menambah komik. Silakan coba lagi.',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: AppColors.background,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        '+ Tambah',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(
                        child: Text(
                          'Gagal mencari komik',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHint() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_rounded,
            size: 40,
            color: AppColors.textMuted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Ketik minimal 2 karakter\nuntuk mencari komik',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
