import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../widgets/common/widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final notifier = ref.read(authNotifierProvider.notifier);
      final ok = await notifier.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Account created! You can now log in.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      _showError(e.toString().replaceAll('AuthException: ', ''));
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textPrimary),
                  onPressed: () => context.go('/login'),
                ),
                const SizedBox(height: 16),
                Text('Create Account',
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(fontWeight: FontWeight.w800)
                ).animate().fadeIn().slideX(begin: -0.2),
                const SizedBox(height: 6),
                Text('Join ShieldX to report crimes safely',
                    style: Theme.of(context).textTheme.bodyMedium
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextField(
                        label: 'Full Name',
                        hint: 'John Doe',
                        controller: _nameCtrl,
                        prefixIcon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Name is required' : null,
                      ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'Email Address',
                        hint: 'you@example.com',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Email is required';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'Phone Number',
                        hint: '+880 1XXX-XXXXXX',
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                        textInputAction: TextInputAction.next,
                      ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'Password',
                        hint: '••••••••',
                        controller: _passwordCtrl,
                        obscureText: true,
                        prefixIcon: Icons.lock_outline,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password is required';
                          if (v.length < 6) return 'Min 6 characters';
                          return null;
                        },
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'Confirm Password',
                        hint: '••••••••',
                        controller: _confirmCtrl,
                        obscureText: true,
                        prefixIcon: Icons.lock_outline,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _register(),
                        validator: (v) {
                          if (v != _passwordCtrl.text)
                            return 'Passwords do not match';
                          return null;
                        },
                      ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2),
                      const SizedBox(height: 28),
                      GradientButton(
                        label: 'Create Account',
                        onTap: _isLoading ? null : _register,
                        isLoading: _isLoading,
                        icon: Icons.person_add_rounded,
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ',
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondary, fontSize: 14)),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text('Sign In',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 450.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
