import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_picker_helper.dart';
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

class _ChangeAvatarDialogState extends ConsumerState<ChangeAvatarDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _urlController;

  String? _selectedAvatarUrl;
  String? _pendingBase64Image;
  bool _isLoading = false;
  String? _errorMessage;

  static const List<Map<String, String>> _presets = [
    {
      'name': 'Jinwoo',
      'role': 'Solo Hunter',
      'url': 'https://api.dicebear.com/7.x/adventurer/png?seed=Jinwoo',
    },
    {
      'name': 'Zoro',
      'role': 'Swordsman',
      'url': 'https://api.dicebear.com/7.x/adventurer/png?seed=Zoro',
    },
    {
      'name': 'Anya',
      'role': 'Telepath',
      'url': 'https://api.dicebear.com/7.x/lorelei/png?seed=Anya',
    },
    {
      'name': 'Shadow',
      'role': 'Monarch',
      'url': 'https://api.dicebear.com/7.x/adventurer/png?seed=Shadow',
    },
    {
      'name': 'Manga',
      'role': 'Hero',
      'url': 'https://api.dicebear.com/7.x/lorelei/png?seed=Manga',
    },
    {
      'name': 'Cyber',
      'role': 'Mecha',
      'url': 'https://api.dicebear.com/7.x/bottts/png?seed=Cyber',
    },
    {
      'name': 'Felix',
      'role': 'Shinobi',
      'url': 'https://api.dicebear.com/7.x/adventurer/png?seed=Felix',
    },
    {
      'name': 'Aneka',
      'role': 'Sorceress',
      'url': 'https://api.dicebear.com/7.x/adventurer/png?seed=Aneka',
    },
    {
      'name': 'Milo',
      'role': 'Alchemist',
      'url': 'https://api.dicebear.com/7.x/adventurer/png?seed=Milo',
    },
    {
      'name': 'Ronin',
      'role': 'Samurai',
      'url': 'https://api.dicebear.com/7.x/adventurer/png?seed=Ronin',
    },
    {
      'name': 'Shonen',
      'role': 'Protagonist',
      'url': 'https://api.dicebear.com/7.x/lorelei/png?seed=Shonen',
    },
    {
      'name': 'Kitsune',
      'role': 'Mystic',
      'url': 'https://api.dicebear.com/7.x/adventurer/png?seed=Kitsune',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _urlController = TextEditingController();
    _selectedAvatarUrl = widget.user?.avatarUrl;
    if (_selectedAvatarUrl != null &&
        !_presets.any((p) => p['url'] == _selectedAvatarUrl)) {
      _urlController.text = _selectedAvatarUrl!;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handlePickFile() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final base64 = await pickImageBase64();
      if (base64 != null && base64.isNotEmpty) {
        setState(() {
          _pendingBase64Image = base64;
          _selectedAvatarUrl = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memilih gambar dari perangkat';
      });
    }
  }

  Future<void> _saveAvatar() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    bool success = false;
    if (_pendingBase64Image != null) {
      success = await ref
          .read(authProvider.notifier)
          .uploadAvatarBase64(_pendingBase64Image!);
    } else {
      final finalUrl = _selectedAvatarUrl?.trim();
      success = await ref
          .read(authProvider.notifier)
          .updateAvatar(finalUrl?.isNotEmpty == true ? finalUrl : null);
    }

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
    final dialogMaxHeight = (screenHeight * 0.88).clamp(480.0, 660.0);

    return Dialog(
      backgroundColor: AppColors.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: dialogMaxHeight,
        ),
        child: Column(
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
                    child: const Icon(
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
                          'Pilih karakter, unggah foto, atau link gambar',
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
                      icon: Icon(Icons.close_rounded, color: AppColors.textMuted),
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
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                blurRadius: 14,
                                offset: const Offset(0, 3),
                              ),
                            ],
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
                      _pendingBase64Image != null
                          ? 'Foto siap diunggah'
                          : (_selectedAvatarUrl != null
                              ? 'Preview Avatar Terpilih'
                              : 'Avatar Default (Inisial)'),
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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Tabs ─────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider, width: 0.5),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.primary,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(
                    iconMargin: EdgeInsets.zero,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.face_rounded, size: 15),
                          SizedBox(width: 5),
                          Text('Pilihan Karakter'),
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    iconMargin: EdgeInsets.zero,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.upload_rounded, size: 15),
                          SizedBox(width: 5),
                          Text('Unggah / URL'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Tab Views ────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Presets
                  _buildPresetsGrid(),

                  // Tab 2: Upload & Custom URL
                  _buildUploadAndUrlTab(),
                ],
              ),
            ),

            Divider(height: 1, color: AppColors.divider),

            // ── Footer Actions ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  if (widget.user?.avatarUrl != null)
                    HoverWidget(
                      scale: 1.05,
                      child: TextButton.icon(
                        onPressed: _isLoading ? null : _removeAvatar,
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 16, color: AppColors.error),
                        label: const Text(
                          'Hapus',
                          style: TextStyle(color: AppColors.error, fontSize: 12),
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
                            horizontal: 14, vertical: 10),
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
                    enableGlow: true,
                    glowColor: AppColors.primary,
                    scale: 1.05,
                    borderRadius: BorderRadius.circular(10),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveAvatar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
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
                          : const Text(
                              'Simpan Foto',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
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
    );
  }

  Widget _buildPreviewContent(String initialLetter) {
    if (_pendingBase64Image != null) {
      return Image.network(
        _pendingBase64Image!,
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

    if (_selectedAvatarUrl != null && _selectedAvatarUrl!.isNotEmpty) {
      return ProxiedImage(
        imageUrl: _selectedAvatarUrl!,
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

  Widget _buildPresetsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 440;
        final crossAxisCount = isMobile ? 3 : 4;
        final avatarSize = isMobile ? 44.0 : 48.0;

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _presets.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: isMobile ? 0.72 : 0.74,
          ),
          itemBuilder: (context, index) {
            final preset = _presets[index];
            final isSelected = _pendingBase64Image == null &&
                _selectedAvatarUrl == preset['url'];

            return HoverWidget(
              scale: 1.06,
              borderRadius: BorderRadius.circular(12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _pendingBase64Image = null;
                      _selectedAvatarUrl = preset['url'];
                      _urlController.clear();
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                      width: isSelected ? 2 : 0.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: avatarSize,
                            height: avatarSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.card,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.divider,
                                width: 1.5,
                              ),
                            ),
                            child: ClipOval(
                              child: ProxiedImage(
                                imageUrl: preset['url']!,
                                width: avatarSize,
                                height: avatarSize,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 11,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Flexible(
                        child: Text(
                          preset['name']!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          preset['role']!,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        );
      },
    );
  }

  Widget _buildUploadAndUrlTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Upload from Device ──────────────────────────────
          Text(
            'Unggah Foto dari Perangkat',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih foto atau gambar dari komputer / galeri HP kamu (JPG, PNG, WebP)',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          HoverWidget(
            scale: 1.02,
            borderRadius: BorderRadius.circular(10),
            child: OutlinedButton.icon(
              onPressed: _handlePickFile,
              icon: const Icon(Icons.add_photo_alternate_rounded,
                  color: AppColors.primary, size: 18),
              label: Text(
                _pendingBase64Image != null
                    ? 'Ganti Foto Terpilih'
                    : 'Pilih File Gambar',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Divider(color: AppColors.divider)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'ATAU TEMPEL URL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              Expanded(child: Divider(color: AppColors.divider)),
            ],
          ),
          const SizedBox(height: 16),

          // ── Direct URL ──────────────────────────────────────
          Text(
            'Gunakan Link / URL Gambar',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tempel tautan gambar dari internet (Pinterest, Discord, Imgur, dll)',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _urlController,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'https://example.com/foto.jpg',
              hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.link_rounded, size: 18),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              suffixIcon: HoverWidget(
                scale: 1.15,
                child: IconButton(
                  icon: const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary, size: 20),
                  tooltip: 'Terapkan Link',
                  onPressed: () {
                    final url = _urlController.text.trim();
                    if (url.isNotEmpty) {
                      setState(() {
                        _pendingBase64Image = null;
                        _selectedAvatarUrl = url;
                      });
                    }
                  },
                ),
              ),
            ),
            onChanged: (val) {
              if (val.trim().isNotEmpty) {
                setState(() {
                  _pendingBase64Image = null;
                  _selectedAvatarUrl = val.trim();
                });
              }
            },
          ),
        ],
      ),
    );
  }
}
