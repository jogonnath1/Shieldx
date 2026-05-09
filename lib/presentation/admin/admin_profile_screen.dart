import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../widgets/common/widgets.dart';

class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authNotifierProvider).valueOrNull;
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Profile')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF7B1FA2), Color(0xFF1565C0)]),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 20)
                  ],
                ),
                child: Center(
                  child: Text(profile.initials,
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800)),
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: 14),
              Text(profile.displayName,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF7B1FA2), Color(0xFF1565C0)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('👑 Administrator',
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 28),

              GlassCard(
                child: Column(
                  children: [
                    if (profile.email != null)
                      InfoTile(icon: Icons.email_outlined, label: 'Email', value: profile.email!, iconColor: AppColors.primary),
                    if (profile.phone != null)
                      InfoTile(icon: Icons.phone_outlined, label: 'Phone', value: profile.phone!, iconColor: AppColors.accent),
                    if (profile.profession != null)
                      InfoTile(icon: Icons.work_outline, label: 'Profession', value: profile.profession!, iconColor: AppColors.warning),
                    if (profile.createdAt != null)
                      InfoTile(icon: Icons.calendar_today_outlined, label: 'Member Since', value: DateFormat('dd MMM yyyy').format(profile.createdAt!), iconColor: AppColors.textHint),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
              const SizedBox(height: 16),

              _ProfileAction(
                icon: Icons.edit_outlined,
                label: 'Edit Profile',
                onTap: () => context.push('/edit-profile'),
              ).animate().fadeIn(delay: 250.ms),
              const SizedBox(height: 10),
              _ProfileAction(
                icon: Icons.lock_outline,
                label: 'Change Password',
                onTap: () => context.push('/change-password'),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 10),
              _ProfileAction(
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                color: AppColors.error,
                onTap: () => _showLogoutDialog(context, ref),
              ).animate().fadeIn(delay: 350.ms),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ProfileAction({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: c, size: 22),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: c))),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: c.withOpacity(0.5)),
        ],
      ),
    );
  }
}
