import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/collection.dart';
import '../../../data/providers/collection_repository_provider.dart';
import '../../../data/providers/providers.dart';

class EditCollectionDialog extends ConsumerStatefulWidget {
  const EditCollectionDialog({super.key, this.collection});
  final Collection? collection;

  @override
  ConsumerState<EditCollectionDialog> createState() =>
      _EditCollectionDialogState();
}

class _EditCollectionDialogState extends ConsumerState<EditCollectionDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late bool _isPublic;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.collection?.name ?? '');
    _description = TextEditingController(
      text: widget.collection?.description ?? '',
    );
    _isPublic = widget.collection?.isPublic ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repository = ref.read(collectionRepositoryProvider);
      if (widget.collection == null) {
        final user = ref.read(authProvider).user;
        if (user == null) throw StateError('Silakan masuk');
        await repository.create(
          userId: user.id,
          name: _name.text,
          description: _description.text,
          isPublic: _isPublic,
        );
      } else {
        await repository.updateCollection(
          widget.collection!.id,
          name: _name.text,
          description: _description.text,
          isPublic: _isPublic,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Perubahan gagal disimpan. Silakan coba lagi.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: Text(widget.collection == null ? 'Buat Koleksi' : 'Edit Koleksi'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  enabled: !_saving,
                  maxLength: 80,
                  decoration: const InputDecoration(labelText: 'Nama koleksi'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nama koleksi wajib diisi'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  enabled: !_saving,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (opsional)',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Koleksi publik'),
                  subtitle: Text(
                    _isPublic
                        ? 'Bisa dilihat pengguna lain'
                        : 'Hanya kamu yang bisa melihat',
                  ),
                  value: _isPublic,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _isPublic = value),
                ),
                if (_error != null)
                  Semantics(liveRegion: true, child: Text(_error!)),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan Perubahan'),
        ),
      ],
    ),
  );
}
