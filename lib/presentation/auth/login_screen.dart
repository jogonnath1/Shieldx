import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../widgets/common/widgets.dart';
import '../../core/services/preferences_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Require active internet connection to login
    final isOnline = await ref.read(connectivityProvider.notifier).checkConnection();
    if (!isOnline) {
      _showError('Active internet connection is required to sign in.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final notifier = ref.read(authNotifierProvider.notifier);
      await notifier.signIn(
        _emailCtrl.text.trim(),
        _passwordCtrl.text.trim(),
      );
      if (!mounted) return;

      // Save credentials for persistent background auto-login
      final prefsService = ref.read(preferencesServiceProvider);
      await prefsService.saveCredentials(
        _emailCtrl.text.trim(),
        _passwordCtrl.text.trim(),
      );

      final profile = ref.read(authNotifierProvider).valueOrNull;
      // If profile is incomplete, GoRouter will redirect to /register automatically.
      // We just navigate to /home and let GoRouter handle the guard.
      final phone = profile?.phone;
      final nid = profile?.nid;
      final isIncomplete = phone == null || phone.trim().isEmpty ||
          nid == null || nid.trim().isEmpty;

      if (isIncomplete) {
        if (context.mounted) context.go('/register');
      } else {
        if (context.mounted) {
          context.go(profile?.isAdmin == true ? '/admin/dashboard' : '/home');
        }
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      if (msg.contains('email not confirmed') || msg.contains('not confirmed')) {
        _showError('Email not verified. Please check your inbox or contact support.');
      } else if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
        _showError('Wrong email or password. Please try again.');
      } else {
        _showError(e.toString().replaceAll('AuthException: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Logo
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: const Icon(Icons.shield_rounded,
                            color: Colors.white, size: 44),
                      ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                      const SizedBox(height: 16),
                      Text('ShieldX',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          )).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 4),
                      Text('Crime Reporting Portal',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            letterSpacing: 1,
                          )).animate().fadeIn(delay: 300.ms),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Text('Welcome Back',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800)
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
                const SizedBox(height: 6),
                Text('Sign in to your account',
                    style: Theme.of(context).textTheme.bodyMedium
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextField(
                        label: 'Email Address',
                        hint: 'you@example.com',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Email is required';
                          if (!v.contains('@')) return 'Enter valid email';
                          return null;
                        },
                      ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Password',
                        hint: '••••••••',
                        controller: _passwordCtrl,
                        obscureText: true,
                        prefixIcon: Icons.lock_outline,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _login(),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password is required';
                          if (v.length < 6) return 'Min 6 characters';
                          return null;
                        },
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.push('/forgot-password'),
                          child: const Text('Forgot Password?'),
                        ),
                      ).animate().fadeIn(delay: 450.ms),
                      const SizedBox(height: 24),
                      GradientButton(
                        label: 'Sign In',
                        onTap: _isLoading ? null : _login,
                        isLoading: _isLoading,
                        icon: Icons.login_rounded,
                      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.cardBorder)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR',
                          style: GoogleFonts.inter(
                            color: AppColors.textHint, fontSize: 12)),
                    ),
                    const Expanded(child: Divider(color: AppColors.cardBorder)),
                  ],
                ).animate().fadeIn(delay: 550.ms),
                const SizedBox(height: 24),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ",
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondary, fontSize: 14)),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: Text('Register',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 600.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
