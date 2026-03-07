import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../shared/core/app_theme.dart';
import '../../../shared/data/auth_provider.dart';
import '../../../shared/ui/glass_card.dart';

/// Glass-card registration screen.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).signUp(email, password, fullName: _nameController.text.trim());
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created! Please sign in.'),
          backgroundColor: AppTheme.accentGreen,
        ),
      );
      context.go('/login');
    } else if (mounted) {
      final error = ref.read(authProvider).error ?? 'Registration failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D3B2E),
              Color(0xFF0A2F25),
              Color(0xFF0F1420),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Logo
                SvgPicture.asset(
                  'assets/images/bioClockLeafLogo.svg',
                  width: 120,
                ).animate().fadeIn(duration: 600.ms).scale(
                      begin: const Offset(0.8, 0.8),
                      curve: Curves.easeOutBack,
                    ),

                const SizedBox(height: 20),

                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

                const SizedBox(height: 6),

                Text(
                  'Join Bio Clock to reduce food waste',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 600.ms),

                const SizedBox(height: 32),

                // Register card
                GlassCard(
                  backgroundColor: Colors.white.withValues(alpha: 0.07),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('Full Name'),
                        const SizedBox(height: 8),
                        _textField(
                          controller: _nameController,
                          hint: 'Enter your full name',
                          icon: LucideIcons.user,
                        ),

                        const SizedBox(height: 18),
                        _fieldLabel('Email'),
                        const SizedBox(height: 8),
                        _textField(
                          controller: _emailController,
                          hint: 'Enter your email',
                          icon: LucideIcons.mail,
                        ),

                        const SizedBox(height: 18),
                        _fieldLabel('Password'),
                        const SizedBox(height: 8),
                        _textField(
                          controller: _passwordController,
                          hint: 'Create a password',
                          icon: LucideIcons.lock,
                          obscure: _obscure,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white.withValues(alpha: 0.4),
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),

                        const SizedBox(height: 18),
                        _fieldLabel('Confirm Password'),
                        const SizedBox(height: 8),
                        _textField(
                          controller: _confirmController,
                          hint: 'Confirm your password',
                          icon: LucideIcons.lock,
                          obscure: _obscureConfirm,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white.withValues(alpha: 0.4),
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Register button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: AppTheme.gradientPrimary,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: AppTheme.neonGlow(AppTheme.accentGreen,
                                  intensity: 0.3),
                            ),
                            child: ElevatedButton(
                              onPressed: ref.watch(authProvider).isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: ref.watch(authProvider).isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 700.ms)
                    .slideY(begin: 0.1),

                const SizedBox(height: 24),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accentGreen,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 600.ms, duration: 600.ms),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        prefixIcon:
            Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 20),
        suffixIcon: suffixIcon,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.accentGreen, width: 1.5),
        ),
      ),
    );
  }
}
