import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/selected_station_provider.dart';
import '../widgets/admin/station_switcher_widget.dart';
import '../widgets/common/widgets.dart';
import 'admin_sos_alert_widget.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authNotifierProvider).valueOrNull;
    final statsAsync = ref.watch(complaintStatsProvider);
    final categoryStatsAsync = ref.watch(categoryStatsProvider);
    final monthlyTrendsAsync = ref.watch(monthlyTrendsProvider);
    final locationStatsAsync = ref.watch(locationStatsProvider);
    final complaintsAsync = ref.watch(allComplaintsStreamProvider);

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
                                Text('Admin Panel',
                                    style: GoogleFonts.inter(
                                        color: AppColors.textHint, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text('Welcome, ${profile?.displayName.split(' ').first ?? 'Admin'} 👑',
                                    style: GoogleFonts.inter(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary)),
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
                              child: const Icon(Icons.admin_panel_settings_rounded,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                        ],
                      ).animate().fadeIn().slideY(begin: -0.2),
                      const SizedBox(height: 10),

                      // Active station context banner
                      const StationContextBanner(),
                      const SizedBox(height: 14),

                      // Real-time Emergency SOS Alerts
                      const AdminActiveSOSAlertsWidget(),

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
                    ],
                  ),
                ),
              ),

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
              ),
            ],
          ),
        ),
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
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
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
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
