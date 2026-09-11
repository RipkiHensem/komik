import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers/providers.dart';
import '../../widgets/hover_builder.dart';

/// Register screen
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() => _errorMessage = null);
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).register(
          _usernameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (success && mounted) {
      context.go('/home');
    } else if (mounted) {
      final error = ref.read(authProvider).errorMessage;
      setState(() {
        _errorMessage = error ?? 'Registrasi gagal. Silakan coba lagi.';
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight > 64 ? constraints.maxHeight - 64 : 0,
                  minWidth: constraints.maxWidth,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        // Ambient glow decorations
                        Positioned(
                          top: -30,
                          child: Container(
                            width: 280,
                            height: 280,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.18),
                                  blurRadius: 120,
                                  spreadRadius: 30,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -20,
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondary.withValues(alpha: 0.10),
                                  blurRadius: 100,
                                  spreadRadius: 20,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Card container
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppColors.isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.08),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: AppColors.isDark ? 0.45 : 0.08),
                                blurRadius: 40,
                                offset: const Offset(0, 16),
                                spreadRadius: -4,
                              ),
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.06),
                                blurRadius: 24,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                            // Logo
                            Center(
                              child: Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.35),
                                      blurRadius: 20,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.auto_stories_rounded,
                                  size: 34,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            Text(
                              'Buat Akun Baru',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Daftar dan mulai baca komik favoritmu',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 28),

                            // In-form Error Notification Banner
                            if (_errorMessage != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.error.withValues(alpha: 0.45),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Icon(
                                        Icons.error_outline_rounded,
                                        color: AppColors.error,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Pendaftaran Gagal',
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.error,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            _errorMessage!,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: AppColors.textPrimary.withValues(alpha: 0.9),
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => setState(() => _errorMessage = null),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(2),
                                        child: Icon(
                                          Icons.close_rounded,
                                          size: 18,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                            ],

                            // Username
                            TextFormField(
                              controller: _usernameController,
                              style: TextStyle(color: AppColors.textPrimary),
                              decoration: const InputDecoration(
                                hintText: 'Username',
                                prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                              ),
                              onChanged: (_) {
                                if (_errorMessage != null) {
                                  setState(() => _errorMessage = null);
                                }
                              },
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Username tidak boleh kosong';
                                }
                                if (value.trim().length < 3) {
                                  return 'Username minimal 3 karakter';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Email
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(color: AppColors.textPrimary),
                              decoration: const InputDecoration(
                                hintText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined, size: 20),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Email tidak boleh kosong';
                                }
                                if (!value.contains('@') || !value.contains('.')) {
                                  return 'Format email tidak valid';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Password
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: TextStyle(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() => _obscurePassword = !_obscurePassword);
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password tidak boleh kosong';
                                }
                                if (value.length < 6) {
                                  return 'Password minimal 6 karakter';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Confirm Password
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirm,
                              style: TextStyle(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Konfirmasi Password',
                                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirm
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() => _obscureConfirm = !_obscureConfirm);
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return 'Password tidak cocok';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Register button
                            HoverWidget(
                              scale: 1.025,
                              enableGlow: true,
                              glowColor: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _handleRegister,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Daftar',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Login link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Sudah punya akun? ',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                HoverWidget(
                                  scale: 1.08,
                                  onTap: () => context.pushReplacement('/login'),
                                  child: const Text(
                                    'Masuk',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(child: Divider(color: AppColors.divider, height: 1)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    'atau',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: AppColors.divider, height: 1)),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Continue as guest button
                            HoverWidget(
                              scale: 1.04,
                              child: TextButton.icon(
                                onPressed: () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go('/home');
                                  }
                                },
                                icon: const Icon(Icons.explore_outlined, size: 16),
                                label: const Text('Lanjut Baca sebagai Tamu'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                  textStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                    // Top-right close button
                    Positioned(
                      top: 14,
                      right: 14,
                      child: HoverWidget(
                        scale: 1.08,
                        child: InkWell(
                          onTap: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/home');
                            }
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surface.withValues(alpha: 0.6),
                              border: Border.all(
                                color: AppColors.isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
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
      },
    ),
  ),
);
  }
}
