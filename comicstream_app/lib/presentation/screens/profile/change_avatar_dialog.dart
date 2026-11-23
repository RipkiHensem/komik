import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user.dart';
import '../../../data/providers/providers.dart';
import '../../widgets/proxied_image.dart';
import '../../widgets/hover_builder.dart';

class ChangeAvatarDialog extends ConsumerStatefulWidget {
  final User? user;

  const ChangeAvatarDialog({super.key, required this.user});

  static Future<void> show(BuildContext context, User? user) {
    return showDialog<void>(
      context: context,
      builder: (context) => ChangeAvatarDialog(user: user),
    );
  }

  @override
  ConsumerState<ChangeAvatarDialog> createState() => _ChangeAvatarDialogState();
}

class _ChangeAvatarDialogState extends ConsumerState<ChangeAvatarDialog> {
  Uint8List? _pendingImageBytes;
  String _pendingImageExtension = 'jpg';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _recoverLostImage();
  }

  Future<void> _recoverLostImage() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final result = await ImagePicker().retrieveLostData();
      if (result.file != null) await _selectImage(result.file!);
      if (result.exception != null) throw result.exception!;
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _errorMessage =
            'Foto sebelumnya gagal dipulihkan. Silakan pilih lagi.',
      );
    }
  }

  Future<void> _selectImage(XFile image) async {
    final bytes = await image.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      throw const FormatException('Ukuran foto maksimal 5 MB.');
    }
    if (!mounted) return;
    setState(() {
      _pendingImageBytes = bytes;
      _pendingImageExtension = image.name.contains('.')
          ? image.name.split('.').last
          : 'jpg';
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handlePickImage(ImageSource source) async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        await _selectImage(image);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pemilihan foto dibatalkan.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e is PlatformException && e.code.contains('denied')
            ? 'Izin kamera atau foto ditolak. Izinkan Yomu melalui Pengaturan HP, lalu coba lagi.'
            : e is FormatException
            ? e.message
            : 'Gagal memilih gambar dari perangkat. Silakan coba lagi.';
      });
    }
  }

  Future<void> _saveAvatar() async {
    if (_pendingImageBytes == null || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ref
        .read(authProvider.notifier)
        .uploadAvatarImage(
          _pendingImageBytes!,
          extension: _pendingImageExtension,
        );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto profil berhasil diperbarui!'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      final error = ref.read(authProvider).errorMessage;
      setState(() {
        _errorMessage = error ?? 'Gagal menyimpan foto profil';
      });
    }
  }

  Future<void> _removeAvatar() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ref.read(authProvider.notifier).updateAvatar(null);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto profil dikembalikan ke inisial nama'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      final error = ref.read(authProvider).errorMessage;
      setState(() {
        _errorMessage = error ?? 'Gagal menghapus foto profil';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.user?.username ?? 'U';
    final initialLetter = username.isNotEmpty ? username[0].toUpperCase() : 'U';
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogMaxHeight = screenHeight * 0.88;

    return Dialog(
      backgroundColor: AppColors.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 500, maxHeight: dialogMaxHeight),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.account_circle_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ganti Foto Profil',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Pilih foto dari galeri atau ambil dengan kamera',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    HoverWidget(
                      scale: 1.15,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.textMuted,
                        ),
                        tooltip: 'Tutup',
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.divider),

              // ── Preview Section ──────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: AppColors.surface.withValues(alpha: 0.5),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2.5,
                              ),
                            ),
                            child: ClipOval(
                              child: _buildPreviewContent(initialLetter),
                            ),
                          ),
                          if (_isLoading)
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.5),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _pendingImageBytes != null
                            ? 'Foto siap diunggah'
                            : widget.user?.avatarUrl?.isNotEmpty == true
                            ? 'Foto profil saat ini'
                            : 'Avatar Default (Inisial)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              _buildImagePicker(),

              Divider(height: 1, color: AppColors.divider),

              // ── Footer Actions ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    if (widget.user?.avatarUrl != null)
                      HoverWidget(
                        scale: 1.05,
                        child: TextButton.icon(
                          onPressed: _isLoading ? null : _removeAvatar,
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: AppColors.error,
                          ),
                          label: Text(
                            'Hapus',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                    const Spacer(),
                    HoverWidget(
                      scale: 1.05,
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.divider),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                        child: Text(
                          'Batal',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    HoverWidget(
                      enableGlow: false,
                      glowColor: AppColors.primary,
                      scale: 1.05,
                      borderRadius: BorderRadius.circular(10),
                      child: ElevatedButton(
                        onPressed: _isLoading || _pendingImageBytes == null
                            ? null
                            : _saveAvatar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.background,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Simpan Foto',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.background,
                                  fontSize: 13,
                                ),
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
    );
  }

  Widget _buildPreviewContent(String initialLetter) {
    if (_pendingImageBytes != null) {
      return Image.memory(
        _pendingImageBytes!,
        width: 76,
        height: 76,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Center(
          child: Text(
            initialLetter,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    final currentAvatarUrl = widget.user?.avatarUrl;
    if (currentAvatarUrl != null && currentAvatarUrl.isNotEmpty) {
      return ProxiedImage(
        imageUrl: currentAvatarUrl,
        width: 76,
        height: 76,
        fit: BoxFit.cover,
        errorWidget: Center(
          child: Text(
            initialLetter,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return Center(
      child: Text(
        initialLetter,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pilih sumber foto',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ambil foto langsung atau pilih gambar yang sudah ada di galeri.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => _handlePickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Kamera'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => _handlePickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galeri'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_pendingImageBytes != null) ...[
            const SizedBox(height: 14),
            Center(
              child: Text(
                'Foto siap diunggah',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
