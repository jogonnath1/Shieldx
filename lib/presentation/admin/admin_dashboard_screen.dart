import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_time_extensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/time_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/navigation_trigger_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/selected_station_provider.dart';
import '../../providers/activity_log_provider.dart';
import '../../data/models/activity_log_model.dart';
import '../widgets/admin/station_switcher_widget.dart';
import '../widgets/common/widgets.dart';
import 'admin_sos_alert_widget.dart';

final dashboardTabProvider = StateProvider.autoDispose<int>((ref) => 0);

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final triggerVal = ref.watch(navigationTriggerProvider.select((state) => state['/admin/dashboard'] ?? 0));
    final profile = ref.watch(authNotifierProvider).valueOrNull;
    final statsAsync = ref.watch(complaintStatsProvider);
    final categoryStatsAsync = ref.watch(categoryStatsProvider);
    final monthlyTrendsAsync = ref.watch(monthlyTrendsProvider);
    final locationStatsAsync = ref.watch(locationStatsProvider);
    final complaintsAsync = ref.watch(allComplaintsStreamProvider);
    final selectedTab = ref.watch(dashboardTabProvider);

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
                                // Modern Sub-tag with Pulsing Indicator
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFB300).withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: const Color(0xFFFFB300).withOpacity(0.2),
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
                                          color: Color(0xFFFFB300),
                                          shape: BoxShape.circle,
                                        ),
                                      ).animate(onPlay: (c) => c.repeat(reverse: true))
                                       .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.3, 1.3), duration: 800.ms),
                                      const SizedBox(width: 6),
                                      Text(
                                        "SHIELDX COMMAND CENTER",
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFFFFB300),
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Main Greeting Row with high-fidelity entry animations
                                Wrap(
                                  key: ValueKey('admin_greeting_$triggerVal'),
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    Text(
                                      'Welcome',
                                      style: GoogleFonts.inter(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w300,
                                        color: AppColors.textSecondary,
                                        letterSpacing: -0.5,
                                      ),
                                    ).animate()
                                     .fadeIn(duration: 600.ms, delay: 100.ms)
                                     .slideX(begin: -0.2, end: 0.0, duration: 600.ms, curve: Curves.easeOutQuad),
                                    ShaderMask(
                                      shaderCallback: (bounds) => const LinearGradient(
                                        colors: [Color(0xFFFFB300), Color(0xFFF59E0B)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                                      child: Text(
                                        profile?.displayName.split(' ').first ?? 'Admin',
                                        style: GoogleFonts.inter(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ).animate()
                                     .fadeIn(duration: 600.ms, delay: 250.ms)
                                     .slideX(begin: -0.15, end: 0.0, duration: 600.ms, curve: Curves.easeOutQuad)
                                     .shimmer(delay: 850.ms, duration: 1500.ms, color: Colors.white24),
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFB300).withOpacity(0.08),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFFFB300).withOpacity(0.25),
                                          width: 1.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFFB300).withOpacity(0.12),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          )
                                        ],
                                      ),
                                      child: const Text(
                                        '👑',
                                        style: TextStyle(fontSize: 16),
                                      )
                                          .animate(onPlay: (controller) => controller.repeat(reverse: true))
                                          .slideY(
                                            begin: 0.1,
                                            end: -0.1,
                                            duration: 1.seconds,
                                            curve: Curves.easeInOut,
                                          ),
                                    ).animate()
                                     .fadeIn(duration: 600.ms, delay: 400.ms)
                                     .scale(begin: const Offset(0.4, 0.4), end: const Offset(1.0, 1.0), duration: 600.ms, curve: Curves.elasticOut),
                                    const SizedBox(width: 2),
                                    _buildAdminDesignationBadge(profile?.isMainAdmin ?? false)
                                     .animate()
                                     .fadeIn(duration: 600.ms, delay: 550.ms)
                                     .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.0, 1.0), duration: 600.ms, curve: Curves.easeOutBack),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Date & Time with Icons (Live Ticking BDT Clock)
                                Consumer(
                                  builder: (context, ref, child) {
                                    final nowBDT = ref.watch(bangladeshTimeProvider).toBangladeshTime();
                                    return Row(
                                      children: [
                                        Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.textHint),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('EEEE, dd MMMM yyyy').format(nowBDT),
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
                                        Icon(Icons.access_time_rounded, size: 11, color: AppColors.textHint),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('hh:mm:ss a').format(nowBDT),
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
                          // Station switcher chip
                          const StationSwitcherChip(),
                          const SizedBox(width: 8),
                          Consumer(
                            builder: (context, ref, child) {
                              final unreadCount = ref.watch(unreadNotificationCountProvider);
                              return GestureDetector(
                                onTap: () => context.push('/notifications'),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: unreadCount > 0
                                            ? AppColors.error.withValues(alpha: 0.12)
                                            : AppColors.surface.withValues(alpha: 0.3),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: unreadCount > 0
                                              ? AppColors.error.withValues(alpha: 0.35)
                                              : AppColors.cardBorder,
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        unreadCount > 0
                                            ? Icons.notifications_rounded
                                            : Icons.notifications_none_rounded,
                                        color: unreadCount > 0
                                            ? AppColors.error
                                            : AppColors.textSecondary,
                                        size: 20,
                                      ),
                                    ),
                                    if (unreadCount > 0)
                                      Positioned(
                                        right: -4,
                                        top: -4,
                                        child: Container(
                                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: AppColors.error,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: AppColors.background, width: 2),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.error.withValues(alpha: 0.5),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                                            textAlign: TextAlign.center,
                                          ),
                                        ).animate(onPlay: (c) => c.repeat()).scale(
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

                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => context.push('/admin/profile'),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [Color(0xFF7B1FA2), Color(0xFF1565C0)]),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: AppColors.primary.withOpacity(0.4),
                                      blurRadius: 12)
                                ],
                              ),
                              child: ClipOval(
                                child: profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty
                                    ? Image.network(
                                        profile.avatarUrl!,
                                        width: 42,
                                        height: 42,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Center(
                                          child: Icon(Icons.admin_panel_settings_rounded,
                                              color: Colors.white, size: 22),
                                        ),
                                      )
                                    : const Center(
                                        child: Icon(Icons.admin_panel_settings_rounded,
                                            color: Colors.white, size: 22),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn().slideY(begin: -0.2),
                      const SizedBox(height: 10),

                      // Active station context banner
                      const StationContextBanner(),
                      const SizedBox(height: 14),

                      // Real-time Emergency SOS Alerts
                      const AdminActiveSOSAlertsWidget(),                      // Beautiful sliding segmented tab controller:
                      _buildSegmentController(context, ref, selectedTab),

                      if (selectedTab == 0) ...[
                        // Station context label for stats
                        Consumer(
                          builder: (context, ref, _) {
                            final label = ref.watch(selectedStationLabelProvider);
                            return Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF7B1FA2), Color(0xFF1565C0)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Showing stats for: $label',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textHint),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        // Stats Grid
                        statsAsync.when(
                          data: (stats) => _StatsGrid(stats: stats),
                          loading: () => const SizedBox(
                            height: 160,
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primary)),
                          ),
                          error: (e, _) => Text('Error: $e',
                              style: const TextStyle(color: AppColors.error)),
                        ).animate().fadeIn(delay: 100.ms),
                        const SizedBox(height: 24),

                        // Chart
                        statsAsync.when(
                          data: (stats) => _StatusChart(stats: stats),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 24),

                        // Category Bar Chart
                        categoryStatsAsync.when(
                          data: (catStats) => _CategoryChart(stats: catStats),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ).animate().fadeIn(delay: 280.ms),
                        const SizedBox(height: 24),

                        // Monthly Trends Chart
                        monthlyTrendsAsync.when(
                          data: (trends) => _MonthlyTrendsChart(monthlyData: trends),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ).animate().fadeIn(delay: 320.ms),
                        const SizedBox(height: 24),

                        // Location Stats Heatmap
                        locationStatsAsync.when(
                          data: (locStats) => _LocationStatsChart(stats: locStats),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ).animate().fadeIn(delay: 360.ms),
                        const SizedBox(height: 24),

                        SectionHeader(
                          title: 'Recent Cases',
                          action: 'View All',
                          onAction: () => context.go('/admin/complaints'),
                        ).animate().fadeIn(delay: 250.ms),
                        const SizedBox(height: 12),
                      ] else ...[
                        const _SystemActivitySection(),
                      ],
                    ],
                  ),
                ),
              ),

              if (selectedTab == 0)
                complaintsAsync.when(
                  data: (list) {
                    final recent = list.take(5).toList();
                    if (recent.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: EmptyState(
                          icon: Icons.assignment_outlined,
                          title: 'No Cases Yet',
                          subtitle: 'No crime reports have been submitted.',
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final c = recent[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GlassCard(
                                onTap: () =>
                                    context.push('/admin/complaints/${c.id}'),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.statusColor(c.status)
                                                .withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.description_rounded,
                                          color:
                                              AppColors.statusColor(c.status),
                                          size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              c.crimeCategory ?? 'Unknown',
                                              style: GoogleFonts.inter(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                  color:
                                                      AppColors.textPrimary)),
                                          const SizedBox(height: 3),
                                          Text('Case #${c.caseId}',
                                              style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color: AppColors.textHint)),
                                        ],
                                      ),
                                    ),
                                    StatusBadge(status: c.status, small: true),
                                  ],
                                ),
                              ).animate().fadeIn(delay: (300 + i * 60).ms),
                            );
                          },
                          childCount: recent.length,
                        ),
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary)),
                    ),
                  ),
                  error: (e, _) => SliverToBoxAdapter(
                    child: Center(
                        child: Text('$e',
                            style: const TextStyle(color: AppColors.error))),
                  ),
                )
              else
                const SliverToBoxAdapter(child: SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminDesignationBadge(bool isMainAdmin) {
    final color = isMainAdmin ? const Color(0xFFFFB300) : const Color(0xFFC084FC); // Vibrant Gold, Soft Light Purple for dark mode
    final bgColor = isMainAdmin 
        ? const Color(0xFFFFB300).withOpacity(0.12) 
        : const Color(0xFFC084FC).withOpacity(0.12);
    final borderColor = isMainAdmin 
        ? const Color(0xFFFFB300).withOpacity(0.35) 
        : const Color(0xFFC084FC).withOpacity(0.35);
    final label = isMainAdmin ? 'Main Admin' : 'Admin';
    final icon = isMainAdmin ? Icons.workspace_premium_rounded : Icons.admin_panel_settings_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 6,
            spreadRadius: 1,
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, int> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Total Cases', stats['total'] ?? 0, Icons.assignment_rounded, AppColors.primary),
      ('Submitted', stats['submitted'] ?? 0, Icons.inbox_rounded, AppColors.submitted),
      ('In Progress', stats['in_progress'] ?? 0, Icons.timelapse_rounded, AppColors.inProgress),
      ('Resolved', stats['resolved'] ?? 0, Icons.check_circle_rounded, AppColors.resolved),
      ('Investigating', stats['under_investigation'] ?? 0, Icons.search_rounded, AppColors.underInvestigation),
      ('Rejected', stats['rejected'] ?? 0, Icons.cancel_rounded, AppColors.rejected),
    ];
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 900;
    final double childAspectRatio = isWide ? 1.3 : 0.95;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(items[i].$3, color: items[i].$4, size: 24),
            const SizedBox(height: 6),
            Text('${items[i].$2}',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: AppColors.textPrimary)),
            Text(items[i].$1,
                style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _StatusChart extends StatelessWidget {
  final Map<String, int> stats;
  const _StatusChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats['total'] ?? 1;
    if (total == 0) return const SizedBox.shrink();
    final sections = [
      PieChartSectionData(
        value: (stats['submitted'] ?? 0).toDouble(),
        color: AppColors.submitted,
        title: '',
        radius: 50,
      ),
      PieChartSectionData(
        value: (stats['in_progress'] ?? 0).toDouble(),
        color: AppColors.inProgress,
        title: '',
        radius: 50,
      ),
      PieChartSectionData(
        value: (stats['under_investigation'] ?? 0).toDouble(),
        color: AppColors.underInvestigation,
        title: '',
        radius: 50,
      ),
      PieChartSectionData(
        value: (stats['resolved'] ?? 0).toDouble(),
        color: AppColors.resolved,
        title: '',
        radius: 50,
      ),
      PieChartSectionData(
        value: (stats['rejected'] ?? 0).toDouble(),
        color: AppColors.rejected,
        title: '',
        radius: 50,
      ),
    ].where((s) => s.value > 0).toList();

    if (sections.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cases Overview',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                height: 130,
                width: 130,
                child: PieChart(PieChartData(sections: sections, sectionsSpace: 2, centerSpaceRadius: 35)),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Legend('Submitted', AppColors.submitted, stats['submitted'] ?? 0),
                    _Legend('In Progress', AppColors.inProgress, stats['in_progress'] ?? 0),
                    _Legend('Investigating', AppColors.underInvestigation, stats['under_investigation'] ?? 0),
                    _Legend('Resolved', AppColors.resolved, stats['resolved'] ?? 0),
                    _Legend('Rejected', AppColors.rejected, stats['rejected'] ?? 0),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final String label;
  final Color color;
  final int count;
  const _Legend(this.label, this.color, this.count);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(width: 10, height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label,
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary))),
          Text('$count',
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

/// Category Bar Chart - shows top crime categories as horizontal bars
class _CategoryChart extends StatelessWidget {
  final Map<String, int> stats;
  const _CategoryChart({required this.stats});

  static const List<Color> _barColors = [
    Color(0xFF7C3AED),
    Color(0xFF2563EB),
    Color(0xFF059669),
    Color(0xFFD97706),
    Color(0xFFDC2626),
    Color(0xFF0891B2),
    Color(0xFF7C2D12),
  ];

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();

    final entries = stats.entries.toList();
    final maxVal = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Crime by Category',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(entries.length, (i) {
            final entry = entries[i];
            final barColor = _barColors[i % _barColors.length];
            final ratio = maxVal > 0 ? entry.value / maxVal : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${entry.value}',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: barColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Container(
                            height: 8,
                            width: constraints.maxWidth,
                            decoration: BoxDecoration(
                              color: barColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          AnimatedContainer(
                            duration: Duration(milliseconds: 500 + i * 80),
                            curve: Curves.easeOut,
                            height: 8,
                            width: constraints.maxWidth * ratio,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: barColor.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MonthlyTrendsChart extends StatelessWidget {
  final List<int> monthlyData;
  const _MonthlyTrendsChart({required this.monthlyData});

  @override
  Widget build(BuildContext context) {
    if (monthlyData.every((e) => e == 0)) return const SizedBox.shrink();

    final maxVal = monthlyData.reduce((a, b) => a > b ? a : b).toDouble();
    final spots = <FlSpot>[];
    for (int i = 0; i < monthlyData.length; i++) {
      spots.add(FlSpot(i.toDouble(), monthlyData[i].toDouble()));
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Monthly Trends',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxVal > 0 ? (maxVal / 4).ceilToDouble() : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.cardBorder.withOpacity(0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                        final idx = value.toInt();
                        if (idx < 0 || idx >= 12) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(months[idx],
                              style: GoogleFonts.inter(
                                  color: AppColors.textHint,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxVal > 0 ? (maxVal / 4).ceilToDouble() : 1,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString(),
                            style: GoogleFonts.inter(color: AppColors.textHint, fontSize: 11));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 11,
                minY: 0,
                maxY: maxVal + (maxVal * 0.2), // 20% padding top
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: const LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFF1565C0)]),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF7B1FA2).withOpacity(0.3),
                          const Color(0xFF1565C0).withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationStatsChart extends StatelessWidget {
  final Map<String, int> stats;
  const _LocationStatsChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();

    final entries = stats.entries.toList();
    final maxVal = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.map_rounded, color: Color(0xFF00897B), size: 20),
              const SizedBox(width: 8),
              Text('Top Locations Heatmap',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(entries.length, (i) {
            final entry = entries[i];
            final ratio = maxVal > 0 ? entry.value / maxVal : 0.0;
            // Hotter colors for higher numbers
            final Color barColor = Color.lerp(const Color(0xFF00897B), const Color(0xFFE65100), ratio) ?? const Color(0xFF00897B);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${entry.value}',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: barColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Container(
                            height: 6,
                            width: constraints.maxWidth,
                            decoration: BoxDecoration(
                              color: barColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          AnimatedContainer(
                            duration: Duration(milliseconds: 500 + i * 80),
                            curve: Curves.easeOut,
                            height: 6,
                            width: constraints.maxWidth * ratio,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [
                                BoxShadow(
                                  color: barColor.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ==========================================
// System Activity tracking & auditing widgets
// ==========================================

Widget _buildSegmentController(BuildContext context, WidgetRef ref, int selectedTab) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 16),
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AppColors.surface.withOpacity(0.4),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: Row(
      children: [
        Expanded(
          child: _SegmentTab(
            label: 'Case Analytics',
            icon: Icons.analytics_rounded,
            isSelected: selectedTab == 0,
            onTap: () => ref.read(dashboardTabProvider.notifier).state = 0,
          ),
        ),
        Expanded(
          child: _SegmentTab(
            label: 'System Activity',
            icon: Icons.shield_rounded,
            isSelected: selectedTab == 1,
            onTap: () => ref.read(dashboardTabProvider.notifier).state = 1,
          ),
        ),
      ],
    ),
  );
}

class _SegmentTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF7B1FA2), Color(0xFF1565C0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF7B1FA2).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemActivitySection extends ConsumerWidget {
  const _SystemActivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(activeUsersMetricsProvider);
    final officersStatsAsync = ref.watch(officerActivityStatsProvider);
    final logsAsync = ref.watch(activityLogsStreamProvider);

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 950;

    Widget content;
    if (isWide) {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column (60% width)
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                metricsAsync.hasValue
                    ? Column(
                        children: [
                          _ActiveUsersGrid(metrics: metricsAsync.value!),
                          _SuspiciousLoginsWarning(count: metricsAsync.value!['suspicious_logins'] ?? 0),
                        ],
                      )
                    : metricsAsync.when(
                        data: (metrics) => Column(
                          children: [
                            _ActiveUsersGrid(metrics: metrics),
                            _SuspiciousLoginsWarning(count: metrics['suspicious_logins'] ?? 0),
                          ],
                        ),
                        loading: () => const SizedBox(
                          height: 120,
                          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        ),
                        error: (e, _) => Text('Error loading metrics: $e', style: const TextStyle(color: AppColors.error)),
                      ),
                const SizedBox(height: 24),
                const _ActivityTrendsChart(),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Right Column (40% width)
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                logsAsync.hasValue
                    ? _CurrentlyActiveUsersList(logs: logsAsync.value!, isVertical: true)
                    : logsAsync.when(
                        data: (logs) => _CurrentlyActiveUsersList(logs: logs, isVertical: true),
                        loading: () => const SizedBox(
                          height: 80,
                          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        ),
                        error: (e, _) => Text('Error loading active users: $e', style: const TextStyle(color: AppColors.error)),
                      ),
                const SizedBox(height: 24),
                officersStatsAsync.hasValue
                    ? _MostActiveOfficersList(officersStats: officersStatsAsync.value!)
                    : officersStatsAsync.when(
                        data: (stats) => _MostActiveOfficersList(officersStats: stats),
                        loading: () => const SizedBox(
                          height: 150,
                          child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        ),
                        error: (e, _) => Text('Error loading officers: $e', style: const TextStyle(color: AppColors.error)),
                      ),
              ],
            ),
          ),
        ],
      );
    } else {
      // Mobile / Single column layout
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metrics
          metricsAsync.hasValue
              ? Column(
                  children: [
                    _ActiveUsersGrid(metrics: metricsAsync.value!),
                    _SuspiciousLoginsWarning(count: metricsAsync.value!['suspicious_logins'] ?? 0),
                  ],
                )
              : metricsAsync.when(
                  data: (metrics) => Column(
                    children: [
                      _ActiveUsersGrid(metrics: metrics),
                      _SuspiciousLoginsWarning(count: metrics['suspicious_logins'] ?? 0),
                    ],
                  ),
                  loading: () => const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  ),
                  error: (e, _) => Text('Error loading metrics: $e', style: const TextStyle(color: AppColors.error)),
                ),
          const SizedBox(height: 24),
          // Active users online list
          logsAsync.hasValue
              ? _CurrentlyActiveUsersList(logs: logsAsync.value!, isVertical: false)
              : logsAsync.when(
                  data: (logs) => _CurrentlyActiveUsersList(logs: logs, isVertical: false),
                  loading: () => const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  ),
                  error: (e, _) => Text('Error loading active users: $e', style: const TextStyle(color: AppColors.error)),
                ),
          const SizedBox(height: 24),
          // Trends Chart
          const _ActivityTrendsChart(),
          const SizedBox(height: 24),
          // Officers List
          officersStatsAsync.hasValue
              ? _MostActiveOfficersList(officersStats: officersStatsAsync.value!)
              : officersStatsAsync.when(
                  data: (stats) => _MostActiveOfficersList(officersStats: stats),
                  loading: () => const SizedBox(
                    height: 150,
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  ),
                  error: (e, _) => Text('Error loading officers: $e', style: const TextStyle(color: AppColors.error)),
                ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        content,
        const SizedBox(height: 24),
        // Live Timeline (always full-width at the bottom)
        logsAsync.hasValue
            ? _ActivityTimeline(logs: logsAsync.value!)
            : logsAsync.when(
                data: (logs) => _ActivityTimeline(logs: logs),
                loading: () => const SizedBox(
                  height: 150,
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
                error: (e, _) => Text('Error loading audit log: $e', style: const TextStyle(color: AppColors.error)),
              ),
        const SizedBox(height: 100),
      ],
    );
  }
}

class _ActiveUsersGrid extends StatelessWidget {
  final Map<String, int> metrics;

  const _ActiveUsersGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final active24h = metrics['active_24h'] ?? 0;
    final active7d = metrics['active_7d'] ?? 0;
    final active30d = metrics['active_30d'] ?? 0;
    final suspicious = metrics['suspicious_logins'] ?? 0;

    final cards = [
      ('Active (24h)', active24h, Icons.query_builder_rounded, const Color(0xFF00E676), const Color(0xFF00B0FF)),
      ('Active (7d)', active7d, Icons.calendar_view_week_rounded, const Color(0xFF2979FF), const Color(0xFF00B0FF)),
      ('Active (30d)', active30d, Icons.calendar_today_rounded, const Color(0xFFD500F9), const Color(0xFF2979FF)),
      ('Threats Blocked', suspicious, Icons.shield_rounded, const Color(0xFFFF1744), const Color(0xFFFF5252)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final bool isDesktop = width > 900;
        final int crossAxisCount = isDesktop ? 4 : 2;
        final double itemWidth = (width - (crossAxisCount - 1) * 12) / crossAxisCount;
        final double itemHeight = isDesktop ? 125.0 : 120.0;
        final double childAspectRatio = itemWidth / itemHeight;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: childAspectRatio > 0 ? childAspectRatio : 1.4,
          ),
          itemCount: cards.length,
          itemBuilder: (ctx, i) {
            final card = cards[i];
            final name = card.$1;
            final count = card.$2;
            final icon = card.$3;
            final startColor = card.$4;

            return Container(
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: startColor.withOpacity(0.03),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Positioned(
                      right: -15,
                      bottom: -15,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [startColor.withOpacity(0.1), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: startColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: startColor.withOpacity(0.2), width: 0.8),
                                ),
                                child: Icon(icon, color: startColor, size: 14),
                              ),
                              if (name.contains('Threats') && count > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF1744).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'ALERT',
                                    style: GoogleFonts.inter(
                                      fontSize: 7,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFFFF1744),
                                    ),
                                  ),
                                ).animate(onPlay: (c) => c.repeat(reverse: true))
                                 .fadeIn(duration: 500.ms)
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$count',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                name,
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().scale(
                  begin: const Offset(0.97, 0.97),
                  end: const Offset(1.0, 1.0),
                  duration: 400.ms,
                  curve: Curves.easeOutBack,
                );
          },
        );
      },
    );
  }
}

class _CurrentlyActiveUsersList extends ConsumerWidget {
  final List<ActivityLogModel> logs;
  final bool isVertical;

  const _CurrentlyActiveUsersList({required this.logs, required this.isVertical});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(allProfilesStreamProvider);
    final profiles = profilesAsync.valueOrNull ?? [];
    final profileMap = {for (var p in profiles) p.id: p};

    final now = DateTime.now();
    final Map<String, ActivityLogModel> activeUsersMap = {};
    for (final log in logs) {
      if (log.userId == null || log.userId!.isEmpty) continue;
      final ageMinutes = now.difference(log.createdAt).inMinutes;
      if (ageMinutes <= 15) {
        if (!activeUsersMap.containsKey(log.userId)) {
          activeUsersMap[log.userId!] = log;
        }
      }
    }

    final activeUsers = activeUsersMap.entries.toList();

    Widget contentWidget;

    if (activeUsers.isEmpty) {
      contentWidget = Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: Text(
            'No users active online in the last 15 minutes.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textHint,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    } else if (isVertical) {
      contentWidget = ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activeUsers.length > 5 ? 5 : activeUsers.length,
        separatorBuilder: (context, index) => Divider(color: AppColors.cardBorder.withOpacity(0.3), height: 12),
        itemBuilder: (context, index) {
          final entry = activeUsers[index];
          final userId = entry.key;
          final lastLog = entry.value;
          final profile = profileMap[userId];
          
          final name = profile?.name ?? lastLog.userName ?? 'User';
          final isVerified = profile?.isVerified ?? false;
          final role = profile?.role ?? lastLog.role;
          final ageMinutes = now.difference(lastLog.createdAt).inMinutes;
          final dotColor = ageMinutes <= 5 ? const Color(0xFF00E676) : const Color(0xFFFFB300);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: role == 'main_admin'
                              ? [const Color(0xFFFFB300), const Color(0xFFFF9100)]
                              : role == 'admin'
                                  ? [const Color(0xFFC084FC), const Color(0xFF8B5CF6)]
                                  : [const Color(0xFF2979FF), const Color(0xFF00E5FF)],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          profile?.initials ?? lastLog.userName?[0].toUpperCase() ?? 'U',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          ).animate(onPlay: (c) => c.repeat(reverse: true))
                           .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), delay: (index * 150).ms, duration: 800.ms),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified_rounded,
                              size: 12,
                              color: Color(0xFF2979FF),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        role.toUpperCase().replaceAll('_', ' '),
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: role == 'main_admin'
                              ? const Color(0xFFFFB300)
                              : role == 'admin'
                                  ? const Color(0xFFC084FC)
                                  : const Color(0xFF00E676),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  ageMinutes == 0 ? 'Active now' : '$ageMinutes m ago',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      contentWidget = SizedBox(
        height: 54,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: activeUsers.length,
          itemBuilder: (context, index) {
            final entry = activeUsers[index];
            final userId = entry.key;
            final lastLog = entry.value;
            final profile = profileMap[userId];
            
            final name = profile?.name ?? lastLog.userName ?? 'User';
            final isVerified = profile?.isVerified ?? false;
            final role = profile?.role ?? lastLog.role;
            final ageMinutes = now.difference(lastLog.createdAt).inMinutes;
            final dotColor = ageMinutes <= 5 ? const Color(0xFF00E676) : const Color(0xFFFFB300);

            return Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: role == 'main_admin'
                                ? [const Color(0xFFFFB300), const Color(0xFFFF9100)]
                                : role == 'admin'
                                    ? [const Color(0xFFC084FC), const Color(0xFF8B5CF6)]
                                    : [const Color(0xFF2979FF), const Color(0xFF00E5FF)],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            profile?.initials ?? lastLog.userName?[0].toUpperCase() ?? 'U',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: dotColor,
                                shape: BoxShape.circle,
                              ),
                            ).animate(onPlay: (c) => c.repeat(reverse: true))
                             .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), delay: (index * 150).ms, duration: 800.ms),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified_rounded,
                              size: 10,
                              color: Color(0xFF2979FF),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        ageMinutes == 0 ? 'Active now' : '$ageMinutes m ago',
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          color: AppColors.textHint,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF00E676),
                  shape: BoxShape.circle,
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.4, 1.4), duration: 1000.ms)
               .boxShadow(end: const BoxShadow(color: Color(0xFF00E676), blurRadius: 4)),
              const SizedBox(width: 8),
              Text(
                'Active Users Online (${activeUsers.length})',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'Last 15m',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          contentWidget,
        ],
      ),
    );
  }
}

class _SuspiciousLoginsWarning extends StatelessWidget {
  final int count;
  const _SuspiciousLoginsWarning({required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF1744).withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF1744).withOpacity(0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF1744).withOpacity(0.04),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF1744).withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFF1744).withOpacity(0.3), width: 1),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF1744), size: 22),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 800.ms),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Critical security threat alert',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: const Color(0xFFFF1744),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Detected $count suspicious pre-auth/failed login attempts in the past 30 days. Review the system audit log below immediately.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().slideX(begin: -0.1, end: 0.0, duration: 500.ms, curve: Curves.easeOutQuad).fadeIn();
  }
}

class _ActivityTrendsChart extends ConsumerWidget {
  const _ActivityTrendsChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _ActivityTrendsChartBody();
  }
}

class _ActivityTrendsChartBody extends ConsumerStatefulWidget {
  const _ActivityTrendsChartBody();

  @override
  ConsumerState<_ActivityTrendsChartBody> createState() => _ActivityTrendsChartBodyState();
}

class _ActivityTrendsChartBodyState extends ConsumerState<_ActivityTrendsChartBody>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  // Cache last successful data — never show a spinner on range switch.
  List<Map<String, dynamic>>? _cachedTrends;
  ChartRange? _cachedRange;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _onRangeChange(ChartRange r) {
    ref.read(chartRangeProvider.notifier).state = r;
    _animCtrl.reset();
    _animCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(chartRangeProvider);
    final trendsAsync = ref.watch(activityTrendsProvider(selected));

    // Safely cache new data between frames — never mutate state inside build.
    ref.listen(activityTrendsProvider(selected), (prev, next) {
      next.whenData((data) {
        if (mounted) {
          setState(() {
            _cachedTrends = data;
            _cachedRange = selected;
          });
        }
      });
    });

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row ────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'System Activity Volume (${selected.fullLabel})',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Range Switcher ────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ChartRange.values.map((r) {
                final isActive = r == selected;
                return GestureDetector(
                  onTap: () => _onRangeChange(r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: isActive
                          ? const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFF2979FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isActive ? null : AppColors.surfaceLight.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF7C3AED).withOpacity(0.6)
                            : AppColors.cardBorder,
                        width: 1,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: const Color(0xFF7C3AED).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : null,
                    ),
                    child: Text(
                      r.label,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                        color: isActive ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // ── Chart ─────────────────────────────────────────────────
          Builder(builder: (context) {
            final isLoading = trendsAsync.isLoading;
            // Use fresh data if available, else keep cached data visible
            final displayTrends = trendsAsync.valueOrNull ?? _cachedTrends;

            // Very first load — no cache yet
            if (displayTrends == null) {
              return const SizedBox(
                height: 180,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              );
            }

            // No data for this range
            if (displayTrends.isEmpty) {
              return SizedBox(
                height: 180,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bar_chart_rounded,
                          color: AppColors.textHint.withOpacity(0.3), size: 40),
                      const SizedBox(height: 8),
                      Text(
                        'No data for this period',
                        style: GoogleFonts.inter(
                            color: AppColors.textHint, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            }

            final maxVal = displayTrends
                .map((e) => e['count'] as int)
                .reduce((a, b) => a > b ? a : b)
                .toDouble();
            final maxY =
                maxVal > 0 ? maxVal + (maxVal * 0.25).ceilToDouble() : 5.0;

            final int labelStep = selected == ChartRange.day
                ? 4
                : selected == ChartRange.month
                    ? 5
                    : selected == ChartRange.threeMonths
                        ? 2
                        : selected == ChartRange.sixMonths
                            ? 4
                            : 1;

            final spots = <FlSpot>[
              for (int i = 0; i < displayTrends.length; i++)
                FlSpot(i.toDouble(),
                    (displayTrends[i]['count'] as int).toDouble()),
            ];

            // While fetching new range: keep chart visible with subtle dim — no spinner
            return AnimatedOpacity(
              opacity: isLoading ? 0.55 : 1.0,
              duration: const Duration(milliseconds: 250),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SizedBox(
                  height: 180,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval:
                            maxY > 0 ? (maxY / 4).ceilToDouble() : 1.0,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppColors.cardBorder.withOpacity(0.4),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: labelStep.toDouble(),
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 ||
                                  idx >= displayTrends.length ||
                                  idx % labelStep != 0) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Text(
                                  displayTrends[idx]['day'] as String,
                                  style: GoogleFonts.inter(
                                    color: AppColors.textHint,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: maxY > 4
                                ? (maxY / 4).ceilToDouble()
                                : 1.0,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) => Text(
                              value.toInt().toString(),
                              style: GoogleFonts.inter(
                                  color: AppColors.textHint, fontSize: 10),
                            ),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (displayTrends.length - 1).toDouble(),
                      minY: 0,
                      maxY: maxY.toDouble(),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) =>
                              const Color(0xFF1E1E2E).withOpacity(0.95),
                          tooltipRoundedRadius: 10,
                          getTooltipItems: (spots) => spots.map((s) {
                            final idx = s.x.toInt();
                            final label = idx < displayTrends.length
                                ? displayTrends[idx]['day'] as String
                                : '';
                            return LineTooltipItem(
                              '$label\n${s.y.toInt()} events',
                              GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.35,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFF2979FF)],
                          ),
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: displayTrends.length <= 14,
                            getDotPainter: (spot, pct, bar, index) =>
                                FlDotCirclePainter(
                              radius: 3,
                              color: Colors.white,
                              strokeColor: const Color(0xFF7C3AED),
                              strokeWidth: 1.5,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF7C3AED).withOpacity(0.25),
                                const Color(0xFF2979FF).withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 300),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}


class _MostActiveOfficersList extends StatelessWidget {
  final List<Map<String, dynamic>> officersStats;

  const _MostActiveOfficersList({required this.officersStats});

  @override
  Widget build(BuildContext context) {
    if (officersStats.isEmpty) {
      return GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Officers Caseload',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No officer assignments recorded yet', style: TextStyle(color: AppColors.textHint)),
              ),
            ),
          ],
        ),
      );
    }

    final topOfficers = officersStats.take(5).toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.badge_rounded, color: Color(0xFFC084FC), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Active Officers Caseload',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFC084FC).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC084FC).withOpacity(0.2)),
                ),
                child: Text(
                  'TOP ACTIVE',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFC084FC),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topOfficers.length,
            separatorBuilder: (context, index) => Divider(color: AppColors.cardBorder.withOpacity(0.3), height: 16),
            itemBuilder: (context, index) {
              final item = topOfficers[index];
              final officer = item['officer'];
              final caseCount = item['case_count'] as int;
              final resolvedCount = item['resolved_count'] as int;

              final name = officer.name ?? 'Unknown Officer';
              final rank = officer.rank ?? 'N/A';
              final stationName = officer.station ?? 'General Duty';

              Widget rankLeading;
              if (index == 0) {
                rankLeading = const Text('🥇', style: TextStyle(fontSize: 18));
              } else if (index == 1) {
                rankLeading = const Text('🥈', style: TextStyle(fontSize: 18));
              } else if (index == 2) {
                rankLeading = const Text('🥉', style: TextStyle(fontSize: 18));
              } else {
                rankLeading = Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                    ),
                  ),
                );
              }

              return Row(
                children: [
                  rankLeading,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'Rank: $rank',
                              style: GoogleFonts.inter(fontSize: 10, color: AppColors.textHint),
                            ),
                            const SizedBox(width: 8),
                            Container(width: 3, height: 3, decoration: const BoxDecoration(color: AppColors.textHint, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                stationName,
                                style: GoogleFonts.inter(fontSize: 10, color: AppColors.textHint),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.assignment_ind_rounded, size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            '$caseCount cases',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$resolvedCount resolved',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF00E676),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActivityTimeline extends ConsumerStatefulWidget {
  final List<ActivityLogModel> logs;

  const _ActivityTimeline({super.key, required this.logs});

  @override
  ConsumerState<_ActivityTimeline> createState() => _ActivityTimelineState();
}

class _ActivityTimelineState extends ConsumerState<_ActivityTimeline> {
  String _searchQuery = '';
  String _roleFilter = 'all'; // 'all', 'admin', 'verified', 'unverified'
  String _actionFilter = 'all'; // 'all', 'auth', 'usage', 'reports', 'profile'
  int _displayLimit = 10;
  final TextEditingController _searchController = TextEditingController();

  // ── Selection Mode State ──────────────────────────────────────────────────
  bool _isSelectionMode = false;
  final Set<String> _selectedLogIds = {};
  bool _isBinning = false;

  void _enterSelectionMode(String id) {
    setState(() {
      _isSelectionMode = true;
      _selectedLogIds.add(id);
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedLogIds.contains(id)) {
        _selectedLogIds.remove(id);
        if (_selectedLogIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedLogIds.add(id);
      }
    });
  }

  void _cancelSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedLogIds.clear();
    });
  }

  void _toggleSelectAll(List<ActivityLogModel> visibleLogs) {
    setState(() {
      final allIds = visibleLogs.map((l) => l.id).toSet();
      if (_selectedLogIds.containsAll(allIds)) {
        _selectedLogIds.removeAll(allIds);
        if (_selectedLogIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedLogIds.addAll(allIds);
      }
    });
  }

  Future<void> _moveSelectedToBin() async {
    if (_selectedLogIds.isEmpty) return;
    final count = _selectedLogIds.length;

    setState(() => _isBinning = true);
    try {
      await ref.read(activityLogServiceProvider).softDeleteLogs(_selectedLogIds.toList());
      if (mounted) {
        setState(() {
          _isSelectionMode = false;
          _selectedLogIds.clear();
          _isBinning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.delete_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text('$count audit log${count > 1 ? 's' : ''} moved to recycle bin.',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: const Color(0xFFFF1744),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBinning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to move logs to bin: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(allProfilesStreamProvider);
    final profiles = profilesAsync.valueOrNull ?? [];
    final profileMap = {for (var p in profiles) p.id: p};

    // Filter logs
    final filteredLogs = widget.logs.where((log) {
      final profile = log.userId != null ? profileMap[log.userId] : null;
      final isVerified = profile?.isVerified ?? false;
      final role = profile?.role ?? log.role;

      // 1. Text Search Query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final name = (profile?.name ?? log.userName ?? '').toLowerCase();
        final email = (profile?.email ?? log.userEmail ?? '').toLowerCase();
        final desc = log.actionDescription.toLowerCase();
        if (!name.contains(query) && !email.contains(query) && !desc.contains(query)) {
          return false;
        }
      }

      // 2. Role Filter
      if (_roleFilter == 'admin') {
        if (role != 'admin' && role != 'main_admin') return false;
      } else if (_roleFilter == 'verified') {
        if (role != 'user' || !isVerified) return false;
      } else if (_roleFilter == 'unverified') {
        if (role != 'user' || isVerified) return false;
      }

      // 3. Action Type Filter
      if (_actionFilter == 'auth') {
        if (log.actionType != 'login' && log.actionType != 'logout' && log.actionType != 'suspicious_login') {
          return false;
        }
      } else if (_actionFilter == 'usage') {
        if (log.actionType != 'app_open' && log.actionType != 'app_close') return false;
      } else if (_actionFilter == 'reports') {
        if (log.actionType != 'report_submit' && log.actionType != 'report_edit' && log.actionType != 'report_delete') {
          return false;
        }
      } else if (_actionFilter == 'profile') {
        if (log.actionType != 'profile_update') return false;
      }

      return true;
    }).toList();

    // Visible logs list (up to display limit)
    final visibleLogs = filteredLogs.take(_displayLimit).toList();
    final allVisibleSelected = visibleLogs.isNotEmpty &&
        _selectedLogIds.containsAll(visibleLogs.map((l) => l.id));

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row (animates between normal and selection mode) ───────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.15),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: _isSelectionMode
                ? _buildSelectionHeader(visibleLogs, allVisibleSelected)
                : _buildNormalHeader(filteredLogs.length),
          ),
          const SizedBox(height: 16),

          // 1. Text Search Bar
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder.withOpacity(0.3)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textHint),
                hintText: 'Search audit logs by name, email or action...',
                hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textHint),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textHint),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 2. Role Filter Section
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                Text(
                  'User Role:',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textHint),
                ),
                const SizedBox(width: 10),
                _buildFilterChip(
                  label: 'All Roles',
                  isSelected: _roleFilter == 'all',
                  onTap: () => setState(() => _roleFilter = 'all'),
                  activeColor: AppColors.primary,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Admins & Officers',
                  isSelected: _roleFilter == 'admin',
                  onTap: () => setState(() => _roleFilter = 'admin'),
                  activeColor: const Color(0xFFC084FC),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Verified Citizens',
                  isSelected: _roleFilter == 'verified',
                  onTap: () => setState(() => _roleFilter = 'verified'),
                  activeColor: const Color(0xFF00E676),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Unverified Citizens',
                  isSelected: _roleFilter == 'unverified',
                  onTap: () => setState(() => _roleFilter = 'unverified'),
                  activeColor: const Color(0xFFFF5252),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 3. Action Category Filter Section
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                Text(
                  'Action Type:',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textHint),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'All Actions',
                  isSelected: _actionFilter == 'all',
                  onTap: () => setState(() => _actionFilter = 'all'),
                  activeColor: AppColors.primary,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Auth & Logins',
                  isSelected: _actionFilter == 'auth',
                  onTap: () => setState(() => _actionFilter = 'auth'),
                  activeColor: const Color(0xFFC084FC),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'App Activity',
                  isSelected: _actionFilter == 'usage',
                  onTap: () => setState(() => _actionFilter = 'usage'),
                  activeColor: const Color(0xFF90A4AE),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Safety Reports',
                  isSelected: _actionFilter == 'reports',
                  onTap: () => setState(() => _actionFilter = 'reports'),
                  activeColor: const Color(0xFF2979FF),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Profile Updates',
                  isSelected: _actionFilter == 'profile',
                  onTap: () => setState(() => _actionFilter = 'profile'),
                  activeColor: const Color(0xFF00E5FF),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 4. Timeline list or Empty placeholder
          if (filteredLogs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.manage_search_rounded, size: 42, color: AppColors.textHint.withOpacity(0.4)),
                    const SizedBox(height: 12),
                    Text(
                      'No system activities found.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try resetting search queries or changing your filters.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textHint.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visibleLogs.length,
              itemBuilder: (context, index) {
                final log = visibleLogs[index];
                final isLast = index == visibleLogs.length - 1;
                final bdtTime = log.createdAt.toBangladeshTime();
                final isSelected = _selectedLogIds.contains(log.id);

                IconData icon;
                Color color;
                switch (log.actionType) {
                  case 'app_open':
                    icon = Icons.phonelink_ring_rounded;
                    color = const Color(0xFF00E676);
                    break;
                  case 'app_close':
                    icon = Icons.power_settings_new_rounded;
                    color = const Color(0xFF90A4AE);
                    break;
                  case 'login':
                    icon = Icons.vpn_key_rounded;
                    color = const Color(0xFFC084FC);
                    break;
                  case 'logout':
                    icon = Icons.logout_rounded;
                    color = const Color(0xFFFFB300);
                    break;
                  case 'report_submit':
                    icon = Icons.add_task_rounded;
                    color = const Color(0xFF2979FF);
                    break;
                  case 'report_edit':
                    icon = Icons.edit_note_rounded;
                    color = const Color(0xFFFF9100);
                    break;
                  case 'report_delete':
                    icon = Icons.delete_sweep_rounded;
                    color = const Color(0xFFFF1744);
                    break;
                  case 'profile_update':
                    icon = Icons.manage_accounts_rounded;
                    color = const Color(0xFF00E5FF);
                    break;
                  case 'suspicious_login':
                    icon = Icons.shield_rounded;
                    color = const Color(0xFFFF1744);
                    break;
                  default:
                    icon = Icons.radio_button_checked_rounded;
                    color = AppColors.primary;
                }

                final userLabel = log.userName ?? log.userEmail ?? 'Anonymous Session';
                final profile = log.userId != null ? profileMap[log.userId] : null;
                final isVerified = profile?.isVerified ?? false;
                final role = profile?.role ?? log.role;

                String roleLabel;
                Color roleColor;
                Color roleBgColor;
                if (role == 'main_admin') {
                  roleLabel = 'MAIN ADMIN';
                  roleColor = const Color(0xFFFFB300);
                  roleBgColor = const Color(0xFFFFB300).withOpacity(0.12);
                } else if (role == 'admin') {
                  roleLabel = 'ADMIN';
                  roleColor = const Color(0xFFC084FC);
                  roleBgColor = const Color(0xFFC084FC).withOpacity(0.12);
                } else {
                  if (isVerified) {
                    roleLabel = 'VERIFIED CITIZEN';
                    roleColor = const Color(0xFF00E676);
                    roleBgColor = const Color(0xFF00E676).withOpacity(0.12);
                  } else {
                    roleLabel = 'UNVERIFIED';
                    roleColor = const Color(0xFFFF5252);
                    roleBgColor = const Color(0xFFFF5252).withOpacity(0.12);
                  }
                }

                return GestureDetector(
                  onLongPress: () => _enterSelectionMode(log.id),
                  onTap: _isSelectionMode ? () => _toggleSelection(log.id) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF1744).withOpacity(0.06)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border.all(color: const Color(0xFFFF1744).withOpacity(0.3), width: 1)
                          : Border.all(color: Colors.transparent),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isSelected ? 6 : 0),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                          Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFFF1744).withOpacity(0.15)
                                      : color.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFFF1744)
                                        : color.withOpacity(0.35),
                                    width: isSelected ? 2.0 : 1.2,
                                  ),
                                ),
                                child: Icon(
                                  isSelected ? Icons.check_rounded : icon,
                                  color: isSelected ? const Color(0xFFFF1744) : color,
                                  size: 16,
                                ),
                              ),
                              if (!isLast)
                                Expanded(
                                  child: Container(
                                    width: 1.5,
                                    color: AppColors.cardBorder.withOpacity(0.3),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 14),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 18.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            userLabel,
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: AppColors.textPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (role == 'user' && isVerified) ...[
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.verified_rounded,
                                            size: 13,
                                            color: Color(0xFF2979FF),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: roleBgColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: roleColor.withOpacity(0.2), width: 0.8),
                                    ),
                                    child: Text(
                                      roleLabel,
                                      style: GoogleFonts.inter(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        color: roleColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                log.actionDescription,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: log.actionType == 'suspicious_login' ? const Color(0xFFFF1744) : AppColors.textSecondary,
                                  fontWeight: log.actionType == 'suspicious_login' ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded, size: 10, color: AppColors.textHint),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('hh:mm:ss a').format(bdtTime),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(width: 2, height: 2, decoration: const BoxDecoration(color: AppColors.textHint, shape: BoxShape.circle)),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(bdtTime),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ],
                              ),
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
              },
            ),
            
            // "Show More" Pagination Button
            if (filteredLogs.length > _displayLimit) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _displayLimit += 15;
                    });
                  },
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.primary),
                  label: Text(
                    'Show More Activities (${filteredLogs.length - _displayLimit} remaining)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    backgroundColor: AppColors.primary.withOpacity(0.08),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ── Normal Header ──────────────────────────────────────────────────────────
  Widget _buildNormalHeader(int count) {
    return Row(
      key: const ValueKey('normal_header'),
      children: [
        const Icon(Icons.history_rounded, color: AppColors.primary, size: 22),
        const SizedBox(width: 8),
        Text(
          'Live System Audit Log',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
          ),
          child: Text(
            '$count events',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Long-press any log entry to start selecting',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.textHint.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app_rounded, size: 13, color: AppColors.textHint.withOpacity(0.5)),
                const SizedBox(width: 4),
                Text(
                  'Long press to select',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: AppColors.textHint.withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Selection Mode Header ──────────────────────────────────────────────────
  Widget _buildSelectionHeader(List<ActivityLogModel> visibleLogs, bool allSelected) {
    return Row(
      key: const ValueKey('selection_header'),
      children: [
        // Cancel button
        GestureDetector(
          onTap: _cancelSelection,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.textHint.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textHint),
          ),
        ),
        const SizedBox(width: 10),
        // Selected count badge
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF1744).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFF1744).withOpacity(0.3)),
                ),
                child: Text(
                  '${_selectedLogIds.length} selected',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFFF1744),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Select All toggle
        GestureDetector(
          onTap: () => _toggleSelectAll(visibleLogs),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: allSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.textHint.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: allSelected
                    ? AppColors.primary.withOpacity(0.4)
                    : AppColors.cardBorder.withOpacity(0.4),
              ),
            ),
            child: Text(
              allSelected ? 'Deselect All' : 'Select All',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: allSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Move to Bin button
        GestureDetector(
          onTap: _selectedLogIds.isEmpty ? null : _moveSelectedToBin,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: _selectedLogIds.isEmpty
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFFFF1744), Color(0xFFD50000)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: _selectedLogIds.isEmpty ? AppColors.textHint.withOpacity(0.1) : null,
              borderRadius: BorderRadius.circular(10),
              boxShadow: _selectedLogIds.isEmpty
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0xFFFF1744).withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
            ),
            child: _isBinning
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.delete_rounded,
                        size: 14,
                        color: _selectedLogIds.isEmpty
                            ? AppColors.textHint
                            : Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Move to Bin',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _selectedLogIds.isEmpty
                              ? AppColors.textHint
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.cardBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? activeColor : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
