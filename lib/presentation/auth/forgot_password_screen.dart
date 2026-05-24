import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/activity_log_service.dart';
import '../../providers/auth_provider.dart';
import '../widgets/common/widgets.dart';

enum ResetStep {
  enterEmail,
  enterOtp,
  newPassword,
}

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _passFormKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  ResetStep _step = ResetStep.enterEmail;
  bool _isLoading = false;
  bool _resending = false;
  bool _isDemoMode = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _showDemoModeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2540),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AppColors.warning,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Supabase Email OTP Blocked',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'We detected that your local network or Supabase SMTP settings are preventing the email OTP from being dispatched.\n\nTo allow seamless testing of the password recovery flow, would you like to enable ShieldX Demo/Mock OTP Mode?',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.cardBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _isDemoMode = true;
                _step = ResetStep.enterOtp;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🎉 Enabled ShieldX Demo OTP Mode! Use code "123456" to verify.'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Enable Demo Mode'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.sendPasswordResetOtp(_emailCtrl.text.trim());
      
      if (mounted) {
        setState(() {
          _step = ResetStep.enterOtp;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('A 6-digit verification code has been sent to ${_emailCtrl.text.trim()}.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString();
        if (errorStr.contains('AuthRetryableFetchException') || errorStr.contains('Failed to fetch')) {
          setState(() => _isLoading = false);
          _showDemoModeDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error sending code: ${e.toString().replaceAll('AuthException: ', '')}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_isDemoMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demo Mode: Code is statically locked to "123456".'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    setState(() => _resending = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.sendPasswordResetOtp(_emailCtrl.text.trim());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Verification code resent successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resending code: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_isDemoMode) {
        final entered = _otpCtrl.text.trim();
        if (entered == '123456') {
          setState(() {
            _step = ResetStep.newPassword;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Code verified in Demo Mode! Please set a new password.'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          throw Exception('Invalid verification code for Demo Mode.');
        }
        return;
      }

      final authService = ref.read(authServiceProvider);
      await authService.verifyPasswordResetOtp(
        _emailCtrl.text.trim(),
        _otpCtrl.text.trim(),
      );
      await ref.read(authNotifierProvider.notifier).refresh();

      if (mounted) {
        setState(() {
          _step = ResetStep.newPassword;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Code verified! Please set a new password.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    if (!_passFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_isDemoMode) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 [Demo Mode] Password reset simulated successfully for ${_emailCtrl.text.trim()}!'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
        context.go('/login');
        return;
      }

      final newPassword = _passwordCtrl.text.trim();
      final authService = ref.read(authServiceProvider);
      await authService.updatePassword(newPassword);

      // Refresh to ensure the updated profile and authenticated session is loaded
      await ref.read(authNotifierProvider.notifier).refresh();

      final profile = ref.read(authNotifierProvider).valueOrNull;
      if (profile != null) {
        await ActivityLogService().logEvent(
          actionType: 'password_change',
          profile: profile,
          details: {'info': 'Password reset via email OTP verified'},
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password updated successfully! Welcome back to your account.'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
        
        final isAdmin = profile?.role == 'admin';
        context.go(isAdmin ? '/admin/dashboard' : '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating password: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildEmailStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Forgot Password',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ).animate().fadeIn().slideX(begin: -0.15),
          const SizedBox(height: 8),
          Text(
            'Enter your email address to receive a secure 6-digit OTP verification code.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 36),
          CustomTextField(
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
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15),
          const SizedBox(height: 28),
          GradientButton(
            label: 'Send Verification Code',
            onTap: _isLoading ? null : _sendOtp,
            isLoading: _isLoading,
            icon: Icons.send_rounded,
          ).animate().fadeIn(delay: 250.ms),
        ],
      ),
    );
  }

  Widget _buildOtpStep() {
    return Form(
      key: _otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verify Code',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ).animate().fadeIn().slideX(begin: -0.15),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: 'We have sent a secure 6-digit code to '),
                TextSpan(
                  text: _emailCtrl.text.trim(),
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: '. Enter it below to continue.'),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 20),
          if (_isDemoMode) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Demo Mode Active: Enter "123456" as the verification code.',
                      style: GoogleFonts.inter(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          CustomTextField(
            label: 'Verification Code',
            hint: '123456',
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.security_rounded,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Code is required';
              if (v.trim().length != 6) return 'Enter 6-digit code';
              return null;
            },
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _step = ResetStep.enterEmail;
                    _otpCtrl.clear();
                  });
                },
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: Text(
                  'Change Email',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
              _resending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryLight,
                      ),
                    )
                  : TextButton.icon(
                      onPressed: _isLoading ? null : _resendOtp,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(
                        'Resend Code',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),
            ],
          ).animate().fadeIn(delay: 250.ms),
          const SizedBox(height: 24),
          GradientButton(
            label: 'Verify & Continue',
            onTap: _isLoading ? null : _verifyOtp,
            isLoading: _isLoading,
            icon: Icons.check_circle_outline_rounded,
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildPasswordStep() {
    return Form(
      key: _passFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Password',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ).animate().fadeIn().slideX(begin: -0.15),
          const SizedBox(height: 8),
          Text(
            'Create a strong, secure new password for your ShieldX account.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 36),
          CustomTextField(
            label: 'New Password',
            hint: '••••••••',
            controller: _passwordCtrl,
            obscureText: true,
            prefixIcon: Icons.lock_outline,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Confirm New Password',
            hint: '••••••••',
            controller: _confirmPasswordCtrl,
            obscureText: true,
            prefixIcon: Icons.lock_outline,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v.trim() != _passwordCtrl.text.trim()) {
                return 'Passwords do not match';
              }
              return null;
            },
          ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.15),
          const SizedBox(height: 32),
          GradientButton(
            label: 'Reset Password',
            onTap: _isLoading ? null : _updatePassword,
            isLoading: _isLoading,
            icon: Icons.vpn_key_rounded,
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
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
                if (_step != ResetStep.newPassword)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary),
                    onPressed: () => context.go('/login'),
                  ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (_step == ResetStep.enterEmail) _buildEmailStep(),
                        if (_step == ResetStep.enterOtp) _buildOtpStep(),
                        if (_step == ResetStep.newPassword) _buildPasswordStep(),
                      ],
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
}
