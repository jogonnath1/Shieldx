import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/auth_service.dart';
import '../widgets/common/widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final service = AuthService();
      await service.resetPassword(_emailCtrl.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textPrimary),
                  onPressed: () => context.go('/login'),
                ),
                const SizedBox(height: 32),
                if (!_sent) ...[
                  Text('Forgot Password',
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(fontWeight: FontWeight.w800)
                  ).animate().fadeIn().slideX(begin: -0.2),
                  const SizedBox(height: 8),
                  Text(
                      "Enter your email and we'll send you a password reset link.",
                      style: Theme.of(context).textTheme.bodyMedium
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 36),
                  Form(
                    key: _formKey,
                    child: CustomTextField(
                      label: 'Email Address',
                      hint: 'you@example.com',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter valid email';
                        return null;
                      },
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                  ),
                  const SizedBox(height: 28),
                  GradientButton(
                    label: 'Send Reset Link',
                    onTap: _isLoading ? null : _send,
                    isLoading: _isLoading,
                    icon: Icons.send_rounded,
                  ).animate().fadeIn(delay: 300.ms),
                ] else ...[
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.mark_email_read_rounded,
                              color: AppColors.success, size: 40),
                        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                        const SizedBox(height: 24),
                        Text('Email Sent!',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w800)
                        ).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 12),
                        Text(
                            'Check your inbox and follow the link to reset your password.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                        ).animate().fadeIn(delay: 300.ms),
                        const SizedBox(height: 32),
                        GradientButton(
                          label: 'Back to Login',
                          onTap: () => context.go('/login'),
                          icon: Icons.arrow_back_rounded,
                        ).animate().fadeIn(delay: 400.ms),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
