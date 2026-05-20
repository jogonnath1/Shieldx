import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/sos_provider.dart';
import '../widgets/common/widgets.dart';
import '../widgets/common/sos_button_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authNotifierProvider).valueOrNull;
    final complaintsAsync = profile != null
        ? ref.watch(userComplaintsStreamProvider(profile.id))
        : const AsyncValue<dynamic>.data([]);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, ${profile?.displayName.split(' ').first ?? 'User'} 👋',
                                  style: GoogleFonts.inter(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('EEEE, dd MMMM yyyy, hh:mm a')
                                      .format(DateTime.now()),
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Consumer(
                            builder: (context, ref, child) {
                              final unreadCount =
                                  ref.watch(unreadNotificationCountProvider);
                              return GestureDetector(
                                onTap: () => context.push('/notifications'),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: unreadCount > 0
                                            ? AppColors.primaryLight
                                                .withValues(alpha: 0.12)
                                            : AppColors.surface
                                                .withValues(alpha: 0.3),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: unreadCount > 0
                                              ? AppColors.primaryLight
                                                  .withValues(alpha: 0.3)
                                              : AppColors.cardBorder,
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        unreadCount > 0
                                            ? Icons.notifications_rounded
                                            : Icons.notifications_none_rounded,
                                        color: unreadCount > 0
                                            ? AppColors.primaryLight
                                            : AppColors.textSecondary,
                                        size: 22,
                                      ),
                                    ),
                                    if (unreadCount > 0)
                                      Positioned(
                                        right: -4,
                                        top: -4,
                                        child: Container(
                                          constraints: const BoxConstraints(
                                              minWidth: 18, minHeight: 18),
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: AppColors.error,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: AppColors.background,
                                                width: 2),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.error
                                                    .withValues(alpha: 0.5),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            unreadCount > 99
                                                ? '99+'
                                                : unreadCount.toString(),
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        )
                                            .animate(
                                                onPlay: (c) => c.repeat())
                                            .scale(
                                              begin: const Offset(0.85, 0.85),
                                              end: const Offset(1.1, 1.1),
                                              duration: 900.ms,
                                              curve: Curves.easeInOut,
                                            ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => context.push('/profile'),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                  )
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  profile?.initials ?? 'U',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn().slideY(begin: -0.2),
                      const SizedBox(height: 28),

                      // Emergency SOS Banner
                      Consumer(
                        builder: (context, ref, child) {
                          final sosState = ref.watch(sosNotifierProvider);
                          final sosNotifier = ref.read(sosNotifierProvider.notifier);
                          final isActive = sosState.status == SOSStatus.active;
                          final isCountdown = sosState.status == SOSStatus.countingDown;

                          if (isActive || isCountdown) {
                            return Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7F1D1D),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFEF4444).withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  )
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.radar_rounded, color: Color(0xFFEF4444), size: 36)
                                      .animate(onPlay: (controller) => controller.repeat())
                                      .shake(hz: 8, duration: 1.seconds)
                                      .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.15, 1.15), duration: 600.ms),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isCountdown ? 'ACTIVATING SOS...' : 'SOS ALARM ACTIVE',
                                          style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16),
                                        ),
                                        Text(
                                          isCountdown
                                              ? 'Initiating alert in ${sosState.countdown}s...'
                                              : 'Broadcasting live GPS location to police...',
                                          style: GoogleFonts.inter(
                                              color: const Color(0xFFFCA5A5), fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      if (isCountdown) {
                                        sosNotifier.cancelSOSCountdown();
                                      } else {
                                        sosNotifier.markSafe();
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: const Color(0xFFEF4444).withOpacity(0.5)),
                                      ),
                                      child: Text(
                                          'CANCEL',
                                          style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12)),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate(onPlay: (c) => c.repeat(reverse: true))
                                .shimmer(color: Colors.redAccent.withOpacity(0.1), duration: 2.seconds);
                          }

                          return GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                isScrollControlled: true,
                                builder: (_) => const SOSButtonSheet(),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF7B1FA2), Color(0xFF1565C0)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  )
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.emergency_rounded,
                                      color: Colors.white, size: 36)
                                      .animate(onPlay: (c) => c.repeat(reverse: true))
                                      .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 1.seconds),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Emergency SOS',
                                            style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 16)),
                                        Text('Tap to trigger high-alert broadcast',
                                            style: GoogleFonts.inter(
                                                color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.white.withOpacity(0.3)),
                                    ),
                                    child: Text('TRIGGER',
                                        style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2);
                        },
                      ),
                      const SizedBox(height: 28),

                      // Quick Actions
                      Text('Quick Actions',
                              style: Theme.of(context).textTheme.titleLarge)
                          .animate()
                          .fadeIn(delay: 200.ms),
                      const SizedBox(height: 14),
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _QuickActionCard(
                                  icon: Icons.report_problem_rounded,
                                  label: 'Report Crime',
                                  color: AppColors.primary,
                                  onTap: () =>
                                      context.push('/submit-complaint'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _QuickActionCard(
                                  icon: Icons.folder_open_rounded,
                                  label: 'My Reports',
                                  color: const Color(0xFF00897B),
                                  onTap: () => context.push('/my-complaints'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _QuickActionCard(
                                  icon: Icons.privacy_tip_rounded,
                                  label: 'Anonymous',
                                  color: const Color(0xFFE65100),
                                  onTap: () => context
                                      .push('/submit-complaint?anonymous=true'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _QuickActionCard(
                                  icon: Icons.local_police_rounded,
                                  label: 'Stations Map',
                                  color: const Color(0xFF1565C0),
                                  onTap: () => context.push('/police-stations'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2),
                      const SizedBox(height: 28),

                      SectionHeader(
                        title: 'Recent Reports',
                        action: 'View All',
                        onAction: () => context.push('/my-complaints'),
                      ).animate().fadeIn(delay: 300.ms),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),

              // Complaints list
              complaintsAsync.when(
                data: (list) {
                  if (list.isEmpty) {
                    return SliverToBoxAdapter(
                      child: EmptyState(
                        icon: Icons.assignment_outlined,
                        title: 'No Reports Yet',
                        subtitle:
                            'Submit your first crime report to get started.',
                        buttonLabel: 'Report Crime',
                        onButton: () => context.push('/submit-complaint'),
                      ),
                    );
                  }
                  final recent = list.take(5).toList();
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ComplaintCard(
                            complaint: recent[i],
                            onTap: () =>
                                context.push('/complaint/${recent[i].id}'),
                          )
                              .animate()
                              .fadeIn(delay: (300 + i * 80).ms)
                              .slideY(begin: 0.2),
                        ),
                        childCount: recent.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Center(
                      child: Text('Error: $e',
                          style: const TextStyle(color: AppColors.error))),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/submit-complaint'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Report Crime',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, color: Colors.white)),
      ).animate().scale(delay: 500.ms, curve: Curves.elasticOut),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final dynamic complaint;
  final VoidCallback onTap;

  const _ComplaintCard({required this.complaint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.description_rounded,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  complaint.crimeCategory ?? 'Complaint',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 3),
                Text(
                  'Case #${complaint.caseId}',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          StatusBadge(status: complaint.status, small: true),
        ],
      ),
    );
  }
}
