import 'package:flutter/material.dart';
import 'package:shieldx/common/core/utils/app_snackbar.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shieldx/common/core/constants/app_colors.dart';
import 'package:shieldx/common/providers/auth_provider.dart';
import 'package:shieldx/common/presentation/widgets/common/widgets.dart';

class BlockedScreen extends ConsumerStatefulWidget {
  const BlockedScreen({super.key});
  @override
  ConsumerState<BlockedScreen> createState() => _BlockedScreenState();
}

class _BlockedScreenState extends ConsumerState<BlockedScreen> {
  bool _isLoggingOut = false;
  void _copyEmail() {
    Clipboard.setData(const ClipboardData(text: 'support@shieldx.gov'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.copy_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'Support email copied to clipboard!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _signOut() async {
    setState(() => _isLoggingOut = true);
    try {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoggingOut = false);
        AppSnackbar.error(context, 'Failed to sign out: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GlassCard(
                    borderRadius: 24,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error.withValues(alpha: 0.2),
                                blurRadius: 25,
                                spreadRadius: 5,
                              )
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.gpp_bad_rounded,
                              color: AppColors.error,
                              size: 46,
                            ),
                          ),
                        )
                            .animate(
                                onPlay: (controller) =>
                                    controller.repeat(reverse: true))
                            .scale(
                              begin: const Offset(0.94, 0.94),
                              end: const Offset(1.06, 1.06),
                              duration: 1800.ms,
                              curve: Curves.easeInOutBack,
                            ),
                        const SizedBox(height: 28),
                        Text(
                          'Access Suspended',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 200.ms)
                            .slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 12),
                        Text(
                          'Your account has been blocked by the ShieldX Administrator. This security restriction is placed when an account violates platform guidelines, exhibits anomalous activity, or requires verification.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 350.ms)
                            .slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.04),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Need Assistance?',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryLight,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Contact administrative support at:',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textHint,
                                ),
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: _copyEmail,
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'support@shieldx.gov',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.copy_rounded,
                                        color: AppColors.textHint,
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 500.ms),
                        const SizedBox(height: 32),
                        GradientButton(
                          label: 'Copy Support Email',
                          onTap: _copyEmail,
                          icon: Icons.mail_outline_rounded,
                        ).animate().fadeIn(delay: 600.ms),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: _isLoggingOut ? null : _signOut,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: AppColors.error.withValues(alpha: 0.3),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              foregroundColor: AppColors.error,
                            ),
                            child: _isLoggingOut
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: AppColors.error,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.logout_rounded,
                                          size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Sign Out',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ).animate().fadeIn(delay: 650.ms),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
