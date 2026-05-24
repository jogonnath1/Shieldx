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

enum ChangeEmailStep {
  enterNewEmail,
  verifyNewEmail,
}

class ChangeEmailScreen extends ConsumerStatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  ConsumerState<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends ConsumerState<ChangeEmailScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _newOtpFormKey = GlobalKey<FormState>();

  final _newEmailCtrl = TextEditingController();
  final _confirmEmailCtrl = TextEditingController();
  final _newOtpCtrl = TextEditingController();

  ChangeEmailStep _step = ChangeEmailStep.enterNewEmail;
  bool _isLoading = false;
  bool _isDemoMode = false;

  @override
  void dispose() {
    _newEmailCtrl.dispose();
    _confirmEmailCtrl.dispose();
    _newOtpCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitEmailChange(String currentEmail) async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final currentProfile = ref.read(authNotifierProvider).valueOrNull;
      final newEmail = _newEmailCtrl.text.trim();

      await AuthService().updateEmail(newEmail);

      if (currentProfile != null) {
        await ActivityLogService().logEvent(
          actionType: 'email_change_attempt',
          profile: currentProfile,
          details: {
            'old_email': currentEmail,
            'new_email': newEmail,
          },
        );
      }

      if (mounted) {
        setState(() => _step = ChangeEmailStep.verifyNewEmail);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('A 6-digit verification code has been sent to $newEmail.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('AuthRetryableFetchException') ||
          errorStr.contains('Failed to fetch')) {
        setState(() {
          _isDemoMode = true;
          _step = ChangeEmailStep.verifyNewEmail;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network blocked — Demo Mode enabled. Use code "123456".'),
            backgroundColor: AppColors.warning,
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorStr.replaceAll('AuthException: ', '')),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyNewEmailOtp() async {
    if (!_newOtpFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final newEmail = _newEmailCtrl.text.trim();
      final otp = _newOtpCtrl.text.trim();

      if (_isDemoMode) {
        if (otp != '123456') throw Exception('Invalid verification code.');

        final currentProfile = ref.read(authNotifierProvider).valueOrNull;
        if (currentProfile != null) {
          await ActivityLogService().logEvent(
            actionType: 'email_change_success',
            profile: currentProfile,
            details: {
              'old_email': currentProfile.email ?? '',
              'new_email': newEmail,
              'mode': 'demo',
            },
          );
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('[Demo Mode] Email changed to $newEmail!'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/profile');
        }
        return;
      }

      await AuthService().verifyEmailChangeOtp(newEmail, otp);

      final currentProfile = ref.read(authNotifierProvider).valueOrNull;
      if (currentProfile != null) {
        await ActivityLogService().logEvent(
          actionType: 'email_change_success',
          profile: currentProfile,
          details: {
            'old_email': currentProfile.email ?? '',
            'new_email': newEmail,
          },
        );
      }

      await ref.read(authNotifierProvider.notifier).signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Email updated to $newEmail! Please sign in with your new email.'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 5),
          ),
        );
        context.go('/login');
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

  Future<void> _resendCode() async {
    if (_isDemoMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demo Mode: code is always "123456".'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await AuthService().updateEmail(_newEmailCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code resent to your new email.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentProfile = ref.watch(authNotifierProvider).valueOrNull;
    final currentEmail = currentProfile?.email ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Email'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (_step == ChangeEmailStep.verifyNewEmail) {
              setState(() {
                _step = ChangeEmailStep.enterNewEmail;
                _newOtpCtrl.clear();
              });
            } else {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/profile');
              }
            }
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _step == ChangeEmailStep.enterNewEmail
                ? _buildEnterEmailWidget(currentEmail)
                : _buildVerifyNewEmailWidget(_newEmailCtrl.text.trim()),
          ),
        ),
      ),
    );
  }

  // ─── Step 1: Enter new email ─────────────────────────────────────────────

  Widget _buildEnterEmailWidget(String currentEmail) {
    return Form(
      key: _emailFormKey,
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.alternate_email_rounded,
              color: AppColors.primary,
              size: 40,
            ),
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Text(
            'Change Email Address',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ).animate().fadeIn().slideX(begin: -0.1),
          const SizedBox(height: 8),
          Text(
            'Enter your new email below. A 6-digit OTP code will be sent to the new address to confirm the change.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 24),

          // Current email display card
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.primaryLight, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Email Address',
                        style: GoogleFonts.inter(
                          color: AppColors.textHint,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentEmail,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
          const SizedBox(height: 24),

          CustomTextField(
            label: 'New Email Address',
            controller: _newEmailCtrl,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              final t = v.trim();
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(t)) {
                return 'Enter a valid email address';
              }
              if (t == currentEmail) return 'New email matches your current email';
              return null;
            },
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
          const SizedBox(height: 14),

          CustomTextField(
            label: 'Confirm New Email Address',
            controller: _confirmEmailCtrl,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Confirm email is required';
              if (v.trim() != _newEmailCtrl.text.trim()) {
                return 'Email addresses do not match';
              }
              return null;
            },
          ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
          const SizedBox(height: 32),

          GradientButton(
            label: 'Send Verification Code',
            onTap: _isLoading ? null : () => _submitEmailChange(currentEmail),
            isLoading: _isLoading,
            icon: Icons.send_rounded,
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  // ─── Step 2: Verify new email OTP ────────────────────────────────────────

  Widget _buildVerifyNewEmailWidget(String newEmail) {
    return Form(
      key: _newOtpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
                border:
                    Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.mark_email_read_rounded,
                color: AppColors.success,
                size: 40,
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
          ),
          const SizedBox(height: 24),
          Text(
            'Verify New Email',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ).animate().fadeIn().slideX(begin: -0.1),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              children: [
                const TextSpan(
                    text: 'We sent a 6-digit verification code to '),
                TextSpan(
                  text: newEmail,
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(
                    text:
                        '. Enter it below to confirm and complete the email change.'),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 24),

          // Demo mode banner
          if (_isDemoMode) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.warning, size: 20),
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
            ).animate().fadeIn(),
            const SizedBox(height: 16),
          ],

          CustomTextField(
            label: 'Verification Code',
            hint: '123456',
            controller: _newOtpCtrl,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.pin_outlined,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Code is required';
              if (v.trim().length != 6) return 'Enter the 6-digit code';
              return null;
            },
          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.15),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _step = ChangeEmailStep.enterNewEmail;
                    _newOtpCtrl.clear();
                  });
                },
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: Text(
                  'Change Email',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
              TextButton.icon(
                onPressed: _isLoading ? null : _resendCode,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(
                  'Resend Code',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 24),

          GradientButton(
            label: 'Verify & Update Email',
            onTap: _isLoading ? null : _verifyNewEmailOtp,
            isLoading: _isLoading,
            icon: Icons.check_circle_outline_rounded,
          ).animate().fadeIn(delay: 250.ms),
          const SizedBox(height: 12),

          // Demo mode escape hatch
          if (!_isDemoMode)
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() => _isDemoMode = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Demo Mode enabled! Use code "123456" to verify.'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                },
                child: Text(
                  "Didn't receive the code? Use Demo Mode",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textHint,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}
