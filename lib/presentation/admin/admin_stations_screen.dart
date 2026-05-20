import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/police_station_model.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/selected_station_provider.dart';

class AdminStationsScreen extends ConsumerWidget {
  const AdminStationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stationsStatsAsync = ref.watch(allStationsStatsProvider);
    final selectedStation = ref.watch(selectedStationProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // ── App Bar ──────────────────────────────────────────────────
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
                                Text('Sylhet Metropolitan Police',
                                    style: GoogleFonts.inter(
                                        color: AppColors.textHint,
                                        fontSize: 12)),
                                const SizedBox(height: 4),
                                Text('Station Overview',
                                    style: GoogleFonts.inter(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7B1FA2), Color(0xFF1565C0)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.account_balance_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Summary bar
                      _SummaryBar(stationsStatsAsync: stationsStatsAsync),
                      const SizedBox(height: 20),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: -0.2),
              ),

              // ── Station Cards ─────────────────────────────────────────────
              stationsStatsAsync.when(
                data: (allStats) => SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final station = dummyPoliceStations[i];
                        final stats = allStats[station.thana] ?? {};
                        final isActive = selectedStation?.id == station.id;
                        return _StationCard(
                          station: station,
                          stats: stats,
                          isActive: isActive,
                          colorIndex: i,
                          onTap: () {
                            ref.read(selectedStationProvider.notifier).state =
                                isActive ? null : station;
                          },
                        ).animate().fadeIn(delay: (i * 80).ms).slideY(begin: 0.15);
                      },
                      childCount: dummyPoliceStations.length,
                    ),
                  ),
                ),
                loading: () => const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(60),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Center(
                    child: Text('$e',
                        style: const TextStyle(color: AppColors.error)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary bar
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final AsyncValue<Map<String, Map<String, int>>> stationsStatsAsync;
  const _SummaryBar({required this.stationsStatsAsync});

  @override
  Widget build(BuildContext context) {
    return stationsStatsAsync.when(
      data: (allStats) {
        int totalCases = 0;
        int resolved = 0;
        int inProgress = 0;
        for (final s in allStats.values) {
          totalCases += s['total'] ?? 0;
          resolved += s['resolved'] ?? 0;
          inProgress += (s['in_progress'] ?? 0) + (s['under_investigation'] ?? 0);
        }
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1040), Color(0xFF0D2060)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryLight.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              _SummaryItem('Total', totalCases.toString(), AppColors.primaryLight),
              _SummaryDivider(),
              _SummaryItem('Active', inProgress.toString(), AppColors.inProgress),
              _SummaryDivider(),
              _SummaryItem('Resolved', resolved.toString(), AppColors.resolved),
              _SummaryDivider(),
              _SummaryItem('Stations', '6', AppColors.accent),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 72,
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryItem(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1, height: 36,
      color: AppColors.cardBorder,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Station Card
// ─────────────────────────────────────────────────────────────────────────────

const _cardColors = [
  Color(0xFF7B1FA2),
  Color(0xFF1565C0),
  Color(0xFF00897B),
  Color(0xFFD84315),
  Color(0xFF283593),
  Color(0xFF00838F),
];

const _stationEmojis = ['🏙️', '🎓', '🏗️', '🕌', '🏫', '✈️'];

class _StationCard extends StatelessWidget {
  final PoliceStation station;
  final Map<String, int> stats;
  final bool isActive;
  final int colorIndex;
  final VoidCallback onTap;

  const _StationCard({
    required this.station,
    required this.stats,
    required this.isActive,
    required this.colorIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _cardColors[colorIndex % _cardColors.length];
    final emoji = _stationEmojis[colorIndex % _stationEmojis.length];
    final total = stats['total'] ?? 0;
    final resolved = stats['resolved'] ?? 0;
    final active = (stats['in_progress'] ?? 0) + (stats['under_investigation'] ?? 0);
    final submitted = stats['submitted'] ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
                )
              : const LinearGradient(
                  colors: [Color(0xFF1C2333), Color(0xFF1A2540)],
                ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive ? color.withOpacity(0.7) : AppColors.cardBorder,
            width: isActive ? 1.8 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(station.name,
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary)),
                        Text(station.thana,
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: color.withOpacity(0.9),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.5)),
                      ),
                      child: Text('Active',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: color)),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Stats row
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _StatCell('Total', total, AppColors.primaryLight),
                    _StatCell('Active', active, AppColors.inProgress),
                    _StatCell('Resolved', resolved, AppColors.resolved),
                    _StatCell('Pending', submitted, AppColors.submitted),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Progress bar
              if (total > 0) ...[
                Row(
                  children: [
                    Text('Resolution Rate',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textHint)),
                    const Spacer(),
                    Text(
                      '${total > 0 ? ((resolved / total) * 100).toStringAsFixed(0) : 0}%',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.resolved),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total > 0 ? resolved / total : 0,
                    backgroundColor: AppColors.cardBorder,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.resolved),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Phone & address
              Row(
                children: [
                  const Icon(Icons.phone_outlined,
                      size: 12, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(station.phone,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.textHint)),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isActive ? 'Tap to deselect' : 'Tap to filter',
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatCell(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$value',
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color)),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textHint)),
        ],
      ),
    );
  }
}
