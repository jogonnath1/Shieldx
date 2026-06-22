import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shieldx/common/core/constants/app_colors.dart';
import 'package:shieldx/common/providers/auth_provider.dart';
import 'package:shieldx/common/core/services/preferences_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 3));
    while (mounted && ref.read(authNotifierProvider).isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (!mounted) return;
    final authState = ref.read(authNotifierProvider);
    final profile = authState.valueOrNull;
    if (profile != null) {
      final phone = profile.phone;
      final nid = profile.nid;
      final isIncomplete = phone == null ||
          phone.trim().isEmpty ||
          nid == null ||
          nid.trim().isEmpty;
      if (isIncomplete) {
        if (mounted) context.go('/register');
        return;
      }
      final prefs = ref.read(preferencesServiceProvider);
      final savedRoute = prefs.getLastRoute();
      final authRoutes = ['/login', '/register', '/forgot-password', '/splash'];
      final isAdmin = profile.isAdmin;
      if (savedRoute != null &&
          savedRoute.isNotEmpty &&
          !authRoutes.contains(savedRoute) &&
          !isAdmin) {
        context.go('/home');
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted && savedRoute != '/home') {
          context.push(savedRoute);
        }
      } else {
        if (mounted) context.go(isAdmin ? '/admin/dashboard' : '/home');
      }
    } else {
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Colors.white,
                  size: 60,
                ),
              )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut)
                  .fadeIn(duration: 400.ms),
              const SizedBox(height: 28),
              const Text(
                'ShieldX',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 500.ms)
                  .slideY(begin: 0.3),
              const SizedBox(height: 8),
              const Text(
                'Crime Reporting Portal',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.5,
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 500.ms),
              const SizedBox(height: 60),
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
              ).animate().fadeIn(delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }
}
