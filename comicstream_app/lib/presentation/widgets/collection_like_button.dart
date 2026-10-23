import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/collection_repository_provider.dart';
import '../../data/providers/providers.dart';
import '../../core/theme/app_colors.dart';

final collectionLikesProvider = FutureProvider.autoDispose
    .family<({int count, bool liked}), String>((ref, id) {
      ref.watch(authProvider.select((state) => state.user?.id));
      return ref.watch(collectionRepositoryProvider).getLikes(id);
    });

class CollectionLikeButton extends ConsumerStatefulWidget {
  const CollectionLikeButton({super.key, required this.collectionId});
  final String collectionId;
  @override
  ConsumerState<CollectionLikeButton> createState() =>
      _CollectionLikeButtonState();
}

class _CollectionLikeButtonState extends ConsumerState<CollectionLikeButton> {
  bool _saving = false;

  Future<void> _toggle(bool liked) async {
    if (ref.read(authProvider).user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masuk terlebih dahulu untuk menyukai koleksi'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(collectionRepositoryProvider)
          .setLiked(widget.collectionId, !liked);
      ref.invalidate(collectionLikesProvider(widget.collectionId));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan suka. Silakan coba lagi.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final likes = ref.watch(collectionLikesProvider(widget.collectionId));
    return likes.when(
      loading: () => const SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => IconButton(
        tooltip: 'Muat ulang jumlah suka',
        onPressed: () =>
            ref.invalidate(collectionLikesProvider(widget.collectionId)),
        icon: const Icon(Icons.refresh, size: 20),
      ),
      data: (value) => TextButton.icon(
        onPressed: _saving ? null : () => _toggle(value.liked),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(44, 44),
        ),
        icon: _saving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                value.liked ? Icons.favorite : Icons.favorite_border,
                size: 20,
                semanticLabel: value.liked ? 'Batal suka' : 'Suka',
              ),
        label: Text('${value.count}'),
      ),
    );
  }
}
