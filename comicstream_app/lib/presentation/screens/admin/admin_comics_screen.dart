import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/chapter.dart';
import '../../../data/models/comic.dart';
import '../../../data/providers/providers.dart';

class AdminComicsScreen extends ConsumerWidget {
  const AdminComicsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(isAdminProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelola Komik'),
        backgroundColor: AppColors.background,
      ),
      body: admin.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _MessageView(
          message: 'Gagal memeriksa akses admin: $error',
          onRetry: () => ref.invalidate(isAdminProvider),
        ),
        data: (isAdmin) {
          if (!isAdmin) {
            return const _MessageView(
              message: 'Akun ini belum diberi akses admin.',
            );
          }
          final comics = ref.watch(adminComicsProvider);
          return comics.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _MessageView(
              message: 'Gagal memuat katalog: $error',
              onRetry: () => ref.invalidate(adminComicsProvider),
            ),
            data: (items) => items.isEmpty
                ? const _MessageView(message: 'Belum ada komik di katalog.')
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => _ComicAdminTile(
                      comic: items[index],
                      onEdit: () => _editComic(context, ref, items[index]),
                      onDelete: () => _deleteComic(context, ref, items[index]),
                      onManageChapters: () =>
                          _manageChapters(context, ref, items[index]),
                    ),
                  ),
          );
        },
      ),
      floatingActionButton: admin.valueOrNull == true
          ? FloatingActionButton.extended(
              onPressed: () => _editComic(context, ref, null),
              icon: const Icon(Icons.add),
              label: const Text('Tambah komik'),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
            )
          : null,
    );
  }

  Future<void> _manageChapters(
    BuildContext context,
    WidgetRef ref,
    Comic comic,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => AdminChaptersDialog(comic: comic),
    );
    ref.invalidate(adminComicsProvider);
    ref.invalidate(homeComicsProvider);
  }

  Future<void> _editComic(
    BuildContext context,
    WidgetRef ref,
    Comic? comic,
  ) async {
    final values = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => ComicEditorDialog(comic: comic),
    );
    if (values == null) return;

    try {
      await ref.read(supabaseComicServiceProvider).saveAdminComic(values);
      ref.invalidate(adminComicsProvider);
      ref.invalidate(homeComicsProvider);
      ref.invalidate(popularComicsByFormatProvider);
      ref.invalidate(searchComicsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              comic == null ? 'Komik ditambahkan.' : 'Komik diperbarui.',
            ),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan komik: $error')),
        );
      }
    }
  }

  Future<void> _deleteComic(
    BuildContext context,
    WidgetRef ref,
    Comic comic,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus komik?'),
        content: Text(
          '"${comic.title}" akan disembunyikan dari katalog aplikasi. Data sumbernya tetap tersimpan.',
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
    if (confirmed != true) return;

    try {
      await ref.read(supabaseComicServiceProvider).hideAdminComic(comic.id);
      ref.invalidate(adminComicsProvider);
      ref.invalidate(homeComicsProvider);
      ref.invalidate(popularComicsByFormatProvider);
      ref.invalidate(searchComicsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Komik disembunyikan dari katalog.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyembunyikan komik: $error')),
        );
      }
    }
  }
}

class _ComicAdminTile extends StatelessWidget {
  const _ComicAdminTile({
    required this.comic,
    required this.onEdit,
    required this.onDelete,
    required this.onManageChapters,
  });

  final Comic comic;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onManageChapters;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.card,
      child: ListTile(
        title: Text(comic.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${comic.format} · ${comic.status} · ${comic.chapterCount} chapter',
        ),
        leading: const Icon(Icons.menu_book_outlined),
        trailing: Wrap(
          spacing: 0,
          children: [
            IconButton(
              tooltip: 'Kelola chapter',
              onPressed: onManageChapters,
              icon: const Icon(Icons.list_alt_outlined),
            ),
            IconButton(
              tooltip: 'Edit',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Hapus',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminChaptersDialog extends ConsumerStatefulWidget {
  const AdminChaptersDialog({super.key, required this.comic});

  final Comic comic;

  @override
  ConsumerState<AdminChaptersDialog> createState() =>
      _AdminChaptersDialogState();
}

class _AdminChaptersDialogState extends ConsumerState<AdminChaptersDialog> {
  late Future<List<Chapter>> _chapters;

  @override
  void initState() {
    super.initState();
    _chapters = _loadChapters();
  }

  Future<List<Chapter>> _loadChapters() async {
    final db = ref.read(supabaseComicServiceProvider);
    final api = ref.read(mangaApiServiceProvider);
    List<Chapter> saved = [];
    try {
      saved = await db.getAdminComicChapters(widget.comic.id);
    } catch (error) {
      debugPrint('[Admin] saved chapters unavailable: $error');
    }
    List<Chapter> chapters = saved;
    try {
      final detail = await api.getComicDetail(widget.comic.id);
      final apiChapters = detail['chapters'] as List<Chapter>? ?? const [];
      final byId = {for (final chapter in apiChapters) chapter.id: chapter};
      for (final chapter in saved) {
        byId[chapter.id] = chapter;
      }
      chapters = byId.values.toList()
        ..sort((a, b) => b.chapterNumber.compareTo(a.chapterNumber));
    } catch (error) {
      debugPrint('[Admin] chapter API unavailable: $error');
    }
    final hiddenIds = await db.getHiddenChapterIds();
    return chapters
        .where((chapter) => !hiddenIds.contains(chapter.id))
        .toList();
  }

  Future<void> _deleteChapter(Chapter chapter) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus chapter?'),
        content: Text(
          '${chapter.displayName} akan disembunyikan dari daftar chapter aplikasi. Data sumbernya tetap tersimpan.',
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
            comicId: widget.comic.id,
            chapterId: chapter.id,
          );
      if (!mounted) return;
      setState(() => _chapters = _loadChapters());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${chapter.displayName} disembunyikan.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyembunyikan chapter: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Chapter · ${widget.comic.title}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      content: SizedBox(
        width: 440,
        height: 360,
        child: FutureBuilder<List<Chapter>>(
          future: _chapters,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Gagal memuat chapter: ${snapshot.error}'));
            }
            final chapters = snapshot.data ?? const <Chapter>[];
            if (chapters.isEmpty) {
              return const Center(
                child: Text('Belum ada chapter tersimpan untuk komik ini.'),
              );
            }
            return ListView.separated(
              itemCount: chapters.length,
              separatorBuilder: (_, _) => Divider(color: AppColors.divider),
              itemBuilder: (context, index) {
                final chapter = chapters[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(chapter.displayName),
                  subtitle: Text('Chapter ${chapter.chapterNumber}'),
                  trailing: IconButton(
                    tooltip: 'Hapus chapter',
                    onPressed: () => _deleteChapter(chapter),
                    icon: const Icon(Icons.delete_outline),
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ],
      ),
    ),
  );
}

class ComicEditorDialog extends StatefulWidget {
  const ComicEditorDialog({super.key, this.comic});
  final Comic? comic;

  @override
  State<ComicEditorDialog> createState() => _ComicEditorDialogState();
}

class _ComicEditorDialogState extends State<ComicEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _id;
  late final TextEditingController _title;
  late final TextEditingController _cover;
  late final TextEditingController _synopsis;
  late final TextEditingController _author;
  late final TextEditingController _artist;
  late final TextEditingController _genres;
  late final TextEditingController _chapters;
  late String _format;
  late String _status;
  bool _popular = false;
  bool _recommended = false;

  @override
  void initState() {
    super.initState();
    final comic = widget.comic;
    _id = TextEditingController(text: comic?.id ?? '');
    _title = TextEditingController(text: comic?.title ?? '');
    _cover = TextEditingController(text: comic?.coverUrl ?? '');
    _synopsis = TextEditingController(text: comic?.synopsis ?? '');
    _author = TextEditingController(text: comic?.author ?? '');
    _artist = TextEditingController(text: comic?.artist ?? '');
    _genres = TextEditingController(text: comic?.genres.join(', ') ?? '');
    _chapters = TextEditingController(text: '${comic?.chapterCount ?? 0}');
    _format = comic?.format ?? 'Manhwa';
    _status = comic?.status ?? 'Ongoing';
    _popular = comic?.isPopular ?? false;
    _recommended = comic?.isRecommended ?? false;
  }

  @override
  void dispose() {
    for (final controller in [
      _id,
      _title,
      _cover,
      _synopsis,
      _author,
      _artist,
      _genres,
      _chapters,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.comic == null ? 'Tambah komik' : 'Edit komik'),
    content: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 480,
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      child: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(_title, 'Judul', required: true),
                _field(
                  _id,
                  'ID / slug',
                  required: widget.comic != null,
                  enabled: widget.comic == null,
                ),
                _field(
                  _cover,
                  'URL cover',
                  required: true,
                  keyboardType: TextInputType.url,
                  validator: _validateUrl,
                ),
                _field(_synopsis, 'Sinopsis', maxLines: 3),
                _field(_author, 'Author'),
                _field(_artist, 'Artist'),
                _field(_genres, 'Genre, pisahkan dengan koma'),
                _field(
                  _chapters,
                  'Jumlah chapter',
                  keyboardType: TextInputType.number,
                  validator: _validateCount,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _format,
                  decoration: const InputDecoration(labelText: 'Format'),
                  items: const ['Manhwa', 'Manga', 'Manhua']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _format = value ?? _format),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const ['Ongoing', 'Completed', 'Hiatus']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _status = value ?? _status),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tampilkan di Populer'),
                  value: _popular,
                  onChanged: (value) =>
                      setState(() => _popular = value ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tampilkan di Rekomendasi'),
                  value: _recommended,
                  onChanged: (value) =>
                      setState(() => _recommended = value ?? false),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Batal'),
      ),
      FilledButton(onPressed: _save, child: const Text('Simpan')),
    ],
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      validator:
          validator ??
          (required
              ? (value) => value == null || value.trim().isEmpty
                    ? '$label wajib diisi'
                    : null
              : null),
    ),
  );

  String? _validateCount(String? value) {
    if (int.tryParse(value ?? '') == null || int.parse(value!) < 0) {
      return 'Masukkan angka 0 atau lebih';
    }
    return null;
  }

  String? _validateUrl(String? value) {
    final uri = Uri.tryParse(value?.trim() ?? '');
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return 'Masukkan URL cover yang valid';
    }
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final title = _title.text.trim();
    var generatedId = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    if (generatedId.isEmpty) {
      generatedId = 'comic-${DateTime.now().millisecondsSinceEpoch}';
    }
    final id = _id.text.trim().isEmpty ? generatedId : _id.text.trim();
    Navigator.pop(context, <String, dynamic>{
      'id': id,
      'title': title,
      'cover_url': _cover.text.trim(),
      'synopsis': _synopsis.text.trim(),
      'author': _author.text.trim().isEmpty ? 'Unknown' : _author.text.trim(),
      'artist': _artist.text.trim().isEmpty ? null : _artist.text.trim(),
      'genres': _genres.text
          .split(',')
          .map((genre) => genre.trim())
          .where((genre) => genre.isNotEmpty)
          .toList(),
      'chapter_count': int.parse(_chapters.text.trim()),
      'format': _format,
      'status': _status,
      'is_popular': _popular,
      'is_recommended': _recommended,
    });
  }
}
