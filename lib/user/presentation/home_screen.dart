import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shieldx/common/core/constants/app_colors.dart';
import 'package:shieldx/common/core/utils/date_time_extensions.dart';
import 'package:shieldx/common/providers/auth_provider.dart';
import 'package:shieldx/common/providers/complaint_provider.dart';
import 'package:shieldx/common/providers/notification_provider.dart';
import 'package:shieldx/user/providers/sos_provider.dart';
import 'package:shieldx/common/providers/time_provider.dart';
import 'package:shieldx/common/providers/navigation_trigger_provider.dart';
import 'package:shieldx/common/presentation/widgets/common/widgets.dart';
import 'package:shieldx/common/presentation/widgets/common/sos_button_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          await Geolocator.requestPermission();
        }
      } catch (e) {
        debugPrint('Error requesting location permission on home: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final triggerVal = ref.watch(
        navigationTriggerProvider.select((state) => state['/home'] ?? 0));
    ref.listen<SOSState>(sosNotifierProvider, (previous, next) {
      if (previous?.status == SOSStatus.active &&
          next.status == SOSStatus.idle) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                        color: Colors.white24, shape: BoxShape.circle),
                    child: const Icon(Icons.verified_user_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EMERGENCY SOS RESOLVED',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 0.5,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'The administration has resolved your SOS signal.',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              duration: const Duration(seconds: 6),
            ),
          );
        }
      }
    });
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
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          color: AppColors.success,
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                          .animate(
                                              onPlay: (c) =>
                                                  c.repeat(reverse: true))
                                          .scale(
                                              begin: const Offset(0.8, 0.8),
                                              end: const Offset(1.3, 1.3),
                                              duration: 800.ms),
                                      const SizedBox(width: 6),
                                      Text(
                                        "SECURE CITIZEN PORTAL",
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primaryLight,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  key: ValueKey('user_greeting_$triggerVal'),
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    Text(
                                      'Hey',
                                      style: GoogleFonts.inter(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w300,
                                        color: AppColors.textSecondary,
                                        letterSpacing: -0.5,
                                      ),
                                    )
                                        .animate()
                                        .fadeIn(duration: 600.ms, delay: 100.ms)
                                        .slideX(
                                            begin: -0.2,
                                            end: 0.0,
                                            duration: 600.ms,
                                            curve: Curves.easeOutQuad),
                                    ShaderMask(
                                      shaderCallback: (bounds) =>
                                          const LinearGradient(
                                        colors: [
                                          Color(0xFF3B82F6),
                                          Color(0xFF10B981)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(Rect.fromLTWH(0, 0,
                                              bounds.width, bounds.height)),
                                      child: Text(
                                        profile?.displayName.split(' ').first ??
                                            'User',
                                        style: GoogleFonts.inter(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    )
                                        .animate()
                                        .fadeIn(duration: 600.ms, delay: 250.ms)
                                        .slideX(
                                            begin: -0.15,
                                            end: 0.0,
                                            duration: 600.ms,
                                            curve: Curves.easeOutQuad)
                                        .shimmer(
                                            delay: 850.ms,
                                            duration: 1500.ms,
                                            color: Colors.white24),
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981)
                                            .withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF10B981)
                                              .withValues(alpha: 0.25),
                                          width: 1.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF10B981)
                                                .withValues(alpha: 0.12),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          )
                                        ],
                                      ),
                                      child: const Text(
                                        '👋',
                                        style: TextStyle(fontSize: 16),
                                      )
                                          .animate(
                                              onPlay: (controller) => controller
                                                  .repeat(reverse: true))
                                          .rotate(
                                            begin: -0.08,
                                            end: 0.08,
                                            duration: 750.ms,
                                            curve: Curves.easeInOut,
                                          ),
                                    )
                                        .animate()
                                        .fadeIn(duration: 600.ms, delay: 400.ms)
                                        .scale(
                                            begin: const Offset(0.4, 0.4),
                                            end: const Offset(1.0, 1.0),
                                            duration: 600.ms,
                                            curve: Curves.elasticOut),
                                    _buildVerificationBadge(
                                            profile?.isVerified ?? false,
                                            compact: true)
                                        .animate()
                                        .fadeIn(duration: 600.ms, delay: 550.ms)
                                        .scale(
                                            begin: const Offset(0.5, 0.5),
                                            end: const Offset(1.0, 1.0),
                                            duration: 600.ms,
                                            curve: Curves.easeOutBack),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Consumer(
                                  builder: (context, ref, child) {
                                    final nowBDT = ref
                                        .watch(bangladeshTimeProvider)
                                        .toBangladeshTime();
                                    return Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded,
                                            size: 11,
                                            color: AppColors.textHint),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('EEEE, dd MMMM yyyy')
                                              .format(nowBDT),
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 3,
                                          height: 3,
                                          decoration: const BoxDecoration(
                                            color: AppColors.textHint,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.access_time_rounded,
                                            size: 11,
                                            color: AppColors.textHint),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('hh:mm:ss a')
                                              .format(nowBDT),
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
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
                                            .animate(onPlay: (c) => c.repeat())
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
                                    color: AppColors.primary
                                        .withValues(alpha: 0.4),
                                    blurRadius: 12,
                                  )
                                ],
                              ),
                              child: ClipOval(
                                child: profile?.avatarUrl != null &&
                                        profile!.avatarUrl!.isNotEmpty
                                    ? Image.network(
                                        profile.avatarUrl!,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Center(
                                          child: Text(
                                            profile.initials,
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(
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
                          ),
                        ],
                      ).animate().fadeIn().slideY(begin: -0.2),
                      const SizedBox(height: 28),
                      Consumer(
                        builder: (context, ref, child) {
                          final sosState = ref.watch(sosNotifierProvider);
                          final sosNotifier =
                              ref.read(sosNotifierProvider.notifier);
                          final isActive = sosState.status == SOSStatus.active;
                          final isCountdown =
                              sosState.status == SOSStatus.countingDown;
                          if (isActive || isCountdown) {
                            return Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7F1D1D),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: const Color(0xFFEF4444), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFEF4444)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  )
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.radar_rounded,
                                          color: Color(0xFFEF4444), size: 36)
                                      .animate(
                                          onPlay: (controller) =>
                                              controller.repeat())
                                      .shake(hz: 8, duration: 1.seconds)
                                      .scale(
                                          begin: const Offset(0.9, 0.9),
                                          end: const Offset(1.15, 1.15),
                                          duration: 600.ms),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isCountdown
                                              ? 'ACTIVATING SOS...'
                                              : 'SOS ALARM ACTIVE',
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
                                              color: const Color(0xFFFCA5A5),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600),
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
                                        color: const Color(0xFFEF4444)
                                            .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: const Color(0xFFEF4444)
                                                .withValues(alpha: 0.5)),
                                      ),
                                      child: Text('CANCEL',
                                          style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12)),
                                    ),
                                  ),
                                ],
                              ),
                            )
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .shimmer(
                                    color:
                                        Colors.redAccent.withValues(alpha: 0.1),
                                    duration: 2.seconds);
                          }
                          return GestureDetector(
                            onTap: () {
                              if (profile?.isVerified != true) {
                                _showVerificationRequiredDialog(context);
                                return;
                              }
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
                                  colors: [
                                    Color(0xFF7B1FA2),
                                    Color(0xFF1565C0)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  )
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.emergency_rounded,
                                          color: Colors.white, size: 36)
                                      .animate(
                                          onPlay: (c) =>
                                              c.repeat(reverse: true))
                                      .scale(
                                          begin: const Offset(0.95, 0.95),
                                          end: const Offset(1.05, 1.05),
                                          duration: 1.seconds),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Emergency SOS',
                                            style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 16)),
                                        Text(
                                            'Tap to trigger high-alert broadcast',
                                            style: GoogleFonts.inter(
                                                color: Colors.white70,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.white
                                              .withValues(alpha: 0.3)),
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

  void _showVerificationRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2540),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.gpp_maybe_rounded,
                  color: Colors.amber, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Verification Required',
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
          'Emergency SOS is reserved for verified citizens to prevent misuse and ensure rapid, high-priority police dispatch. Please verify your profile to access this feature.',
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 14,
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
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/profile');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Go to Profile',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBadge(bool isVerified, {bool compact = false}) {
    final icon = isVerified ? Icons.verified_rounded : Icons.gpp_maybe_rounded;
    final color =
        isVerified ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final bgColor = isVerified
        ? const Color(0xFF047857).withValues(alpha: 0.15)
        : const Color(0xFFB45309).withValues(alpha: 0.15);
    final borderColor = isVerified
        ? const Color(0xFF10B981).withValues(alpha: 0.3)
        : const Color(0xFFF59E0B).withValues(alpha: 0.3);
    final label = isVerified ? 'Verified' : 'Unverified';
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 6,
            spreadRadius: 1,
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: compact ? 13 : 15),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatefulWidget {
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
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_isTapped) return;
        setState(() => _isTapped = true);
        widget.onTap();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => _isTapped = false);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(widget.icon, color: widget.color, size: 28),
            const SizedBox(height: 8),
            Text(widget.label,
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
              color: AppColors.primary.withValues(alpha: 0.15),
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
