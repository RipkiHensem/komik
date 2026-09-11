import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers/providers.dart';
import '../../widgets/proxied_image.dart';
import 'change_avatar_dialog.dart';
import '../../widgets/hover_builder.dart';

/// Profile screen with user info, stats, and settings
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final bookmarksAsync = ref.watch(bookmarksProvider);
    final historyAsync = ref.watch(historyProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // ── Avatar ──────────────────────────────────────
                  Center(
                    child: user != null
                        ? Stack(
                            clipBehavior: Clip.none,
                            children: [
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => ChangeAvatarDialog.show(context, user),
                                  child: Container(
                                    width: 88,
                                    height: 88,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: AppColors.primaryGradient,
                                      border: Border.all(
                                        color: AppColors.primary,
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.35),
                                          blurRadius: 18,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                                          ? ProxiedImage(
                                              imageUrl: user.avatarUrl!,
                                              width: 88,
                                              height: 88,
                                              fit: BoxFit.cover,
                                              errorWidget: Center(
                                                child: Text(
                                                  user.username.isNotEmpty
                                                      ? user.username[0].toUpperCase()
                                                      : 'U',
                                                  style: const TextStyle(
                                                    fontSize: 34,
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Center(
                                              child: Text(
                                                user.username.isNotEmpty
                                                    ? user.username[0].toUpperCase()
                                                    : 'U',
                                                style: const TextStyle(
                                                  fontSize: 34,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () => ChangeAvatarDialog.show(context, user),
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.background,
                                          width: 2.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.25),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.2),
                                  AppColors.secondary.withValues(alpha: 0.2),
                                ],
                              ),
                              border: Border.all(
                                color: AppColors.glassBorder,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.person_outline_rounded,
                                size: 44,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                  ),
                  if (user != null) ...[
                    const SizedBox(height: 10),
                    HoverWidget(
                      scale: 1.06,
                      child: InkWell(
                        onTap: () => ChangeAvatarDialog.show(context, user),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_rounded, size: 14, color: AppColors.primary),
                              const SizedBox(width: 5),
                              Text(
                                'Ganti Foto Profil',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),

                  // ── Username ────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          user?.username ?? 'Tamu (Guest)',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user != null) ...[
                        const SizedBox(width: 8),
                        HoverWidget(
                          scale: 1.15,
                          child: InkWell(
                            onTap: () => _showEditUsernameDialog(context, ref, user),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'Masuk untuk sinkronisasi bookmark & riwayat',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Stats Cards ─────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.bookmark_rounded,
                          value: bookmarksAsync.whenOrNull(
                                data: (b) => '${b.length}',
                              ) ??
                              '0',
                          label: 'Bookmark',
                          color: AppColors.primary,
                          onTap: () {
                            ref.read(bookmarkTabProvider.notifier).state = 0;
                            context.go('/bookmarks');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.history_rounded,
                          value: historyAsync.whenOrNull(
                                data: (h) => '${h.length}',
                              ) ??
                              '0',
                          label: 'Riwayat Baca',
                          color: AppColors.secondary,
                          onTap: () {
                            ref.read(bookmarkTabProvider.notifier).state = 1;
                            context.go('/bookmarks');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Menu Items ──────────────────────────────────
                  _buildMenuItem(
                    icon: Icons.bookmark_rounded,
                    title: 'Rak Koleksi',
                    subtitle: 'Komik yang kamu simpan',
                    onTap: () {
                      ref.read(bookmarkTabProvider.notifier).state = 0;
                      context.go('/bookmarks');
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.history_rounded,
                    title: 'Riwayat Baca',
                    subtitle: 'Komik yang pernah kamu baca',
                    onTap: () {
                      ref.read(bookmarkTabProvider.notifier).state = 1;
                      context.go('/bookmarks');
                    },
                  ),
                  if (user != null)
                    _buildMenuItem(
                      icon: Icons.account_circle_rounded,
                      title: 'Ganti Foto Profil',
                      subtitle: 'Pilih karakter anime, unggah foto, atau link',
                      onTap: () => ChangeAvatarDialog.show(context, user),
                    ),
                  _buildMenuItem(
                    icon: isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    title: 'Dark Mode',
                    subtitle: isDarkMode ? 'Aktif (Mode Gelap)' : 'Nonaktif (Mode Terang)',
                    trailing: Switch(
                      value: isDarkMode,
                      onChanged: (val) {
                        ref.read(isDarkModeProvider.notifier).state = val;
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              val
                                  ? 'Mode Gelap diaktifkan'
                                  : 'Mode Terang (White Mode) diaktifkan',
                            ),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      activeThumbColor: AppColors.primary,
                    ),
                    onTap: () {
                      final next = !isDarkMode;
                      ref.read(isDarkModeProvider.notifier).state = next;
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            next
                                ? 'Mode Gelap diaktifkan'
                                : 'Mode Terang (White Mode) diaktifkan',
                          ),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.info_outline_rounded,
                    title: 'Tentang Aplikasi',
                    subtitle: 'ComicStream v1.0.0',
                    onTap: () => _showAboutAppDialog(context),
                  ),

                  const SizedBox(height: 20),

                  // ── Action Button (Masuk if guest, Keluar if logged in) ───
                  if (user == null)
                    HoverWidget(
                      scale: 1.03,
                      enableGlow: true,
                      glowColor: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/login'),
                          icon: const Icon(Icons.login_rounded, size: 20, color: Colors.white),
                          label: const Text(
                            'Masuk / Daftar Akun',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 4,
                            shadowColor: AppColors.primary.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    HoverWidget(
                      scale: 1.03,
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: AppColors.card,
                                title: const Text('Keluar'),
                                content: const Text('Yakin ingin keluar dari akun?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Batal'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.error,
                                    ),
                                    child: const Text('Keluar'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              await ref.read(authProvider.notifier).logout();
                              if (context.mounted) {
                                context.go('/home');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Berhasil keluar dari akun'),
                                    duration: Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: AppColors.error,
                            size: 20,
                          ),
                          label: const Text(
                            'Keluar',
                            style: TextStyle(color: AppColors.error),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditUsernameDialog(BuildContext context, WidgetRef ref, dynamic user) {
    final initialUsername = user.username.toString();
    final controller = TextEditingController(text: initialUsername);
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.badge_outlined, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Ubah Username',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Username ini digunakan untuk login dan tampil di profil kamu.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Username baru',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Username tidak boleh kosong';
                    }
                    if (val.trim().length < 3) {
                      return 'Username minimal 3 karakter';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      final newUsername = controller.text.trim();
                      setDialogState(() => isSaving = true);
                      final success = await ref
                          .read(authProvider.notifier)
                          .updateProfile(username: newUsername);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Username berhasil diubah ke "$newUsername"'
                                  : 'Gagal mengubah username',
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor:
                                success ? AppColors.success : AppColors.error,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo / App Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ComicStream',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'v1.0.0 (Release)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Aplikasi pembaca komik, manga, manhwa, dan manhua gratis dengan pengalaman membaca yang cepat, nyaman, dan modern.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Divider(color: AppColors.divider),
                const SizedBox(height: 12),
                _buildAboutFeatureRow(Icons.bolt_rounded, 'Chapter update berkala & cepat'),
                const SizedBox(height: 8),
                _buildAboutFeatureRow(Icons.bookmark_added_rounded, 'Bookmark & riwayat baca tersimpan rapi'),
                const SizedBox(height: 8),
                _buildAboutFeatureRow(Icons.dark_mode_rounded, 'Tema gelap nyaman untuk membaca'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAboutFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return HoverWidget(
      scale: 1.04,
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder, width: 1),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return HoverWidget(
      scale: 1.015,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder, width: 1),
          boxShadow: AppColors.cardShadow,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          trailing: trailing ??
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
          onTap: onTap,
        ),
      ),
    );
  }
}
