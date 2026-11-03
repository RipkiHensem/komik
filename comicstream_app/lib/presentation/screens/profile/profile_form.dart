import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/validation/profile_validation.dart';
import '../../../data/providers/providers.dart';

/// Username input and its loading/success/error presentation.
class ProfileForm {
  static void show(BuildContext context, WidgetRef ref, dynamic user) {
    final initialUsername = user.username.toString();
    final controller = TextEditingController(text: initialUsername);
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
                  'Username ini tampil di profil dan koleksi kamu. Login menggunakan email.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
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
                  validator: ProfileValidation.username,
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
                            backgroundColor: success
                                ? AppColors.success
                                : AppColors.error,
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
}
