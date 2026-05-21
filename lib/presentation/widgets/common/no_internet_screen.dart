import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/connectivity_provider.dart';
import 'widgets.dart';

class NoInternetScreen extends ConsumerStatefulWidget {
  const NoInternetScreen({super.key});

  @override
  ConsumerState<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends ConsumerState<NoInternetScreen> {
  bool _isChecking = false;

  Future<void> _retryConnection() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isChecking = true);
    // Artificially delay slightly for a premium feel and animation feedback
    await Future.delayed(const Duration(milliseconds: 800));
    final isOnline = await ref.read(connectivityProvider.notifier).checkConnection();
    if (context.mounted) {
      setState(() => _isChecking = false);
      if (isOnline) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('🎉 Internet connection restored!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Connection failed. Please check your internet settings.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Premium pulse glow around offline icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.error.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.error.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.wifi_off_rounded,
                      color: AppColors.error,
                      size: 48,
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1.0, 1.0),
                        end: const Offset(1.08, 1.08),
                        duration: 1200.ms,
                        curve: Curves.easeInOut,
                      ),
                  const SizedBox(height: 32),
                  Text(
                    'Connection Lost',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 12),
                  Text(
                    'ShieldX requires an active internet connection to protect you and submit report data. Please check your network connection and try again.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 40),
                  GradientButton(
                    label: _isChecking ? 'Checking Connection...' : 'Retry Connection',
                    onTap: _isChecking ? null : _retryConnection,
                    isLoading: _isChecking,
                    width: 220,
                    icon: Icons.refresh_rounded,
                  ).animate().fadeIn(delay: 350.ms, duration: 400.ms).slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
