import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers/providers.dart';
import '../../widgets/hover_builder.dart';

/// Login screen with premium dark theme
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (success && mounted) {
      context.go('/home');
    } else if (mounted) {
      final error = ref.read(authProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Login gagal'),
          backgroundColor: AppColors.error,
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.divider.withValues(alpha: 0.6),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 32,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
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

                            // Title
                            Text(
                              'Selamat Datang',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Masuk ke akun ComicStream kamu',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Email or Username field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.text,
                              style: TextStyle(color: AppColors.textPrimary),
                              decoration: const InputDecoration(
                                hintText: 'Email atau Username',
                                prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Email atau username tidak boleh kosong';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // Password field
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
                            const SizedBox(height: 24),

                            // Login button
                            HoverWidget(
                              scale: 1.025,
                              enableGlow: true,
                              glowColor: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _handleLogin,
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
                                          'Masuk',
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

                            // Register link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Belum punya akun? ',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                HoverWidget(
                                  scale: 1.08,
                                  onTap: () => context.pushReplacement('/register'),
                                  child: const Text(
                                    'Daftar',
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

                    // Top-right close button
                    Positioned(
                      top: 10,
                      right: 10,
                      child: HoverWidget(
                        scale: 1.15,
                        child: IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          tooltip: 'Tutup',
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/home');
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
