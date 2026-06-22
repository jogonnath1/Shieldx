import 'package:flutter/material.dart';
import 'package:shieldx/common/core/utils/app_snackbar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shieldx/common/core/constants/app_colors.dart';
import 'package:shieldx/common/data/services/auth_service.dart';
import 'package:shieldx/common/providers/auth_provider.dart';
import 'package:shieldx/common/presentation/widgets/common/widgets.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;
  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _change() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final currentPassword = _currentCtrl.text.trim();
      final newPassword = _newCtrl.text.trim();
      final profile = ref.read(authNotifierProvider).valueOrNull;
      final currentEmail = profile?.email ?? AuthService().currentUser?.email;
      if (currentEmail == null) {
        throw Exception('User session or email not found');
      }
      try {
        await AuthService().signIn(
          email: currentEmail,
          password: currentPassword,
        );
      } catch (e) {
        throw Exception('Current password is incorrect');
      }
      await AuthService().updatePassword(newPassword);
      await ref.read(authNotifierProvider.notifier).signOut();
      if (!mounted) return;
      AppSnackbar.success(
          context, 'Password changed successfully! Please log in.');
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      String message = e.toString();
      if (message.startsWith('Exception: ')) {
        message = message.substring('Exception: '.length);
      }
      AppSnackbar.error(context, message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.lock_outline,
                      color: AppColors.primary, size: 40),
                ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                const SizedBox(height: 32),
                CustomTextField(
                  label: 'Current Password',
                  controller: _currentCtrl,
                  obscureText: true,
                  prefixIcon: Icons.lock_open_rounded,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    return null;
                  },
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'New Password',
                  controller: _newCtrl,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (v.trim().length < 6) return 'Min 6 characters';
                    if (v.trim() == _currentCtrl.text.trim()) {
                      return 'New password cannot be the same as current';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Confirm New Password',
                  controller: _confirmCtrl,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (v.trim() != _newCtrl.text.trim()) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                const SizedBox(height: 32),
                GradientButton(
                  label: 'Change Password',
                  onTap: _isLoading ? null : _change,
                  isLoading: _isLoading,
                  icon: Icons.save_rounded,
                ).animate().fadeIn(delay: 250.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
