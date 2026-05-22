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

class ChangeEmailScreen extends ConsumerStatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  ConsumerState<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends ConsumerState<ChangeEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;
  bool _verificationSent = false;

  @override
  void dispose() {
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitEmailChange() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    try {
      final currentProfile = ref.read(authNotifierProvider).valueOrNull;
      final oldEmail = currentProfile?.email;
      final newEmail = _newCtrl.text.trim();

      // Trigger the email update in Supabase
      await AuthService().updateEmail(newEmail);

      // Log the email modification request to activity logs
      if (currentProfile != null) {
        await ActivityLogService().logEvent(
          actionType: 'email_change_attempt',
          profile: currentProfile,
          details: {
            'old_email': oldEmail ?? 'N/A',
            'new_email': newEmail,
          },
        );
      }

      setState(() => _verificationSent = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _verificationSent 
                ? _buildSuccessWidget(currentEmail, _newCtrl.text.trim())
                : _buildFormWidget(currentEmail),
          ),
        ),
      ),
    );
  }

  Widget _buildFormWidget(String currentEmail) {
    return Form(
      key: _formKey,
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
          
          // Current Email Card
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.primaryLight, size: 20),
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
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
          const SizedBox(height: 24),

          CustomTextField(
            label: 'New Email Address',
            controller: _newCtrl,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              final trimmed = v.trim();
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(trimmed)) {
                return 'Enter a valid email address';
              }
              if (trimmed == currentEmail) {
                return 'New email matches your current email';
              }
              return null;
            },
          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
          const SizedBox(height: 14),

          CustomTextField(
            label: 'Confirm New Email Address',
            controller: _confirmCtrl,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Confirm email is required';
              if (v.trim() != _newCtrl.text.trim()) {
                return 'Email addresses do not match';
              }
              return null;
            },
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
          const SizedBox(height: 32),

          GradientButton(
            label: 'Request Email Change',
            onTap: _isLoading ? null : _submitEmailChange,
            isLoading: _isLoading,
            icon: Icons.send_rounded,
          ).animate().fadeIn(delay: 250.ms),
        ],
      ),
    );
  }

  Widget _buildSuccessWidget(String oldEmail, String newEmail) {
    return Center(
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
            child: const Icon(
              Icons.mark_email_read_rounded,
              color: AppColors.success,
              size: 40,
            ),
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Text(
            'Verification Sent!',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 16),
          
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Action Required',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'To finalize your email change, Supabase requires you to click the confirmation link sent to both:',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                _buildEmailBullet(oldEmail, 'Old Email Address'),
                const SizedBox(height: 8),
                _buildEmailBullet(newEmail, 'New Email Address'),
                const SizedBox(height: 12),
                Text(
                  'Once BOTH links have been verified, your email will update, and you will be signed out to log in under your new email.',
                  style: GoogleFonts.inter(
                    color: AppColors.textHint,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms),
          
          const SizedBox(height: 36),
          GradientButton(
            label: 'Back to Profile',
            onTap: () {
              // Refresh notifier to catch state immediately if verified
              ref.read(authNotifierProvider.notifier).refresh();
              context.go('/profile');
            },
            icon: Icons.arrow_back_rounded,
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildEmailBullet(String email, String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.email_outlined, size: 16, color: AppColors.textHint),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              email,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              type,
              style: GoogleFonts.inter(
                color: AppColors.warning,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
