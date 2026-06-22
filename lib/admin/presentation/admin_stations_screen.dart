import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shieldx/common/core/constants/app_colors.dart';
import 'package:shieldx/common/data/models/police_station_model.dart';
import 'package:shieldx/common/data/models/officer_model.dart';
import 'package:shieldx/common/providers/complaint_provider.dart';
import 'package:shieldx/common/providers/selected_station_provider.dart';
import 'package:shieldx/common/providers/officer_provider.dart';

class AdminStationsScreen extends ConsumerWidget {
  const AdminStationsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stationsStatsAsync = ref.watch(allStationsStatsProvider);
    final selectedStation = ref.watch(selectedStationProvider);
    final selectedDivision = ref.watch(selectedDivisionProvider);
    final filteredStations = ref.watch(filteredStationsProvider);
    // Watch officers ONCE here — not inside each card
    final officersAsync = ref.watch(officersProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            // Pre-render cards 800px off-screen for smoother scrolling
            cacheExtent: 800,
            slivers: [
              // ── Header ──────────────────────────────────────────────
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
                                Text('Bangladesh Police',
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
                      _SummaryBar(
                        stationsStatsAsync: stationsStatsAsync,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: -0.2),
              ),

              // ── Division Filter Chips ───────────────────────────────
              SliverToBoxAdapter(
                child: _DivisionFilterBar(
                  selectedDivision: selectedDivision,
                  onSelect: (division) {
                    ref.read(selectedDivisionProvider.notifier).state =
                        division;
                    // Clear station selection when switching division
                    ref.read(selectedStationProvider.notifier).state = null;
                  },
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 10)),

              // ── Station Cards ───────────────────────────────────────
              stationsStatsAsync.when(
                data: (allStats) => SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final station = filteredStations[i];
                        final stats = allStats[station.thana] ?? {};
                        final isActive = selectedStation?.id == station.id;
                        // Resolve officers list once (from parent-level watch)
                        final officers = officersAsync.valueOrNull ?? const [];
                        // RepaintBoundary isolates each card's repaint
                        return RepaintBoundary(
                          child: _StationCard(
                            station: station,
                            stats: stats,
                            isActive: isActive,
                            colorIndex: i,
                            officers: officers,
                            onTap: () {
                              ref.read(selectedStationProvider.notifier).state =
                                  isActive ? null : station;
                            },
                          ),
                        );
                      },
                      childCount: filteredStations.length,
                    ),
                  ),
                ),
                loading: () => const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(60),
                      child:
                          CircularProgressIndicator(color: AppColors.primary),
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

// ─── Division Filter Bar ──────────────────────────────────────────────

class _DivisionFilterBar extends StatelessWidget {
  final String? selectedDivision;
  final void Function(String?) onSelect;

  const _DivisionFilterBar({
    required this.selectedDivision,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // "All" chip
          _DivisionChip(
            label: 'All',
            emoji: '🇧🇩',
            isSelected: selectedDivision == null,
            color: AppColors.accent,
            onTap: () => onSelect(null),
          ),
          const SizedBox(width: 8),
          ...allDivisions.map((division) {
            final emoji = divisionEmojis[division] ?? '📍';
            final color = _divisionColors[division] ?? AppColors.primary;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _DivisionChip(
                label: division,
                emoji: emoji,
                isSelected: selectedDivision == division,
                color: color,
                onTap: () => onSelect(division),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DivisionChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _DivisionChip({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [color, color.withValues(alpha: 0.7)])
              : null,
          color: isSelected ? null : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? color : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const Map<String, Color> _divisionColors = {
  divisionDhaka: Color(0xFF1565C0),
  divisionChattogram: Color(0xFF00897B),
  divisionSylhet: Color(0xFF7B1FA2),
  divisionRajshahi: Color(0xFFD84315),
  divisionKhulna: Color(0xFF283593),
  divisionBarishal: Color(0xFF00838F),
  divisionRangpur: Color(0xFFF9A825),
  divisionMymensingh: Color(0xFF558B2F),
};

// ─── Summary Bar ──────────────────────────────────────────────────────────

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
          inProgress +=
              (s['in_progress'] ?? 0) + (s['under_investigation'] ?? 0);
        }
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1040), Color(0xFF0D2060)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.primaryLight.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              _SummaryItem(
                  'Total', totalCases.toString(), AppColors.primaryLight),
              _SummaryDivider(),
              _SummaryItem(
                  'Active', inProgress.toString(), AppColors.inProgress),
              _SummaryDivider(),
              _SummaryItem('Resolved', resolved.toString(), AppColors.resolved),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 72,
        child:
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
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
                  fontSize: 20, fontWeight: FontWeight.w900, color: color)),
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
    return Container(width: 1, height: 36, color: AppColors.cardBorder);
  }
}

const _cardColors = [
  Color(0xFF7B1FA2),
  Color(0xFF1565C0),
  Color(0xFF00897B),
  Color(0xFFD84315),
  Color(0xFF283593),
  Color(0xFF00838F),
  Color(0xFFF9A825),
  Color(0xFF558B2F),
];
const _stationEmojis = ['🏙️', '🎓', '🏢', '🕌', '🏫', '✈️', '⚓', '🌿'];

// ─── Station Card ─────────────────────────────────────────────────────────

class _StationCard extends StatelessWidget {
  final PoliceStation station;
  final Map<String, int> stats;
  final bool isActive;
  final int colorIndex;
  final VoidCallback onTap;
  final List<OfficerModel> officers;

  const _StationCard({
    required this.station,
    required this.stats,
    required this.isActive,
    required this.colorIndex,
    required this.onTap,
    required this.officers,
  });

  Future<void> _callOfficer(String phone) async {
    final uri = Uri.parse('tel:${phone.replaceAll(' ', '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _cardColors[colorIndex % _cardColors.length];
    final emoji = _stationEmojis[colorIndex % _stationEmojis.length];
    final total = stats['total'] ?? 0;
    final resolved = stats['resolved'] ?? 0;
    final active =
        (stats['in_progress'] ?? 0) + (stats['under_investigation'] ?? 0);
    final submitted = stats['submitted'] ?? 0;

    // Filter officers synchronously — no async call inside the card
    final assigned = isActive
        ? officers.where((o) {
            if (o.station == null || o.station!.isEmpty) return false;
            final oStation = o.station!.toLowerCase().trim();
            final sName = station.name.toLowerCase();
            final sThana = station.thana.toLowerCase();
            final sJurisdiction = (station.jurisdiction ?? '').toLowerCase();
            return oStation.contains(sThana) ||
                sThana.contains(oStation) ||
                oStation.contains(sName) ||
                sName.contains(oStation) ||
                (sJurisdiction.isNotEmpty &&
                    (oStation.contains(sJurisdiction) ||
                        sJurisdiction.contains(oStation))) ||
                (sThana.contains('kotwali') &&
                    (oStation.contains('kawt') ||
                        oStation.contains('kotw') ||
                        oStation.contains('qotw')));
          }).toList()
        : const <OfficerModel>[];

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.3),
                    color.withValues(alpha: 0.1)
                  ],
                )
              : const LinearGradient(
                  colors: [Color(0xFF1C2333), Color(0xFF1A2540)],
                ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                isActive ? color.withValues(alpha: 0.7) : AppColors.cardBorder,
            width: isActive ? 1.8 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
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
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
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
                        Row(
                          children: [
                            Text(station.division,
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: color.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w700)),
                            if (station.thana.isNotEmpty) ...[
                              Text('  •  ',
                                  style: GoogleFonts.inter(
                                      fontSize: 10, color: AppColors.textHint)),
                              Expanded(
                                child: Text(station.thana,
                                    style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: AppColors.textHint),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withValues(alpha: 0.5)),
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
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
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
                      color: color.withValues(alpha: 0.1),
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
              // Officers section — only rendered when card is expanded
              if (isActive) ...[
                const Divider(color: AppColors.cardBorder, height: 24),
                Row(
                  children: [
                    const Icon(Icons.badge_outlined,
                        size: 14, color: AppColors.primaryLight),
                    const SizedBox(width: 6),
                    Text(
                      'Assigned Officers',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (assigned.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No officers assigned to this station yet.',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.textHint),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: assigned.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final officer = assigned[idx];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color:
                                  AppColors.cardBorder.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: color.withValues(alpha: 0.2),
                              child: Icon(Icons.person_rounded,
                                  size: 16, color: color),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          officer.name ?? 'Officer',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: (officer.isActive
                                                  ? AppColors.success
                                                  : AppColors.textHint)
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          officer.isActive
                                              ? 'On Duty'
                                              : 'Off Duty',
                                          style: GoogleFonts.inter(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w800,
                                            color: officer.isActive
                                                ? AppColors.success
                                                : AppColors.textHint,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    officer.rank ?? 'Constable',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (officer.contact != null &&
                                officer.contact!.isNotEmpty) ...[
                              const SizedBox(width: 10),
                              IconButton(
                                icon: const Icon(Icons.phone_in_talk_rounded,
                                    size: 16, color: AppColors.primaryLight),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _callOfficer(officer.contact!),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
              ],
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
                  fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          Text(label,
              style:
                  GoogleFonts.inter(fontSize: 10, color: AppColors.textHint)),
        ],
      ),
    );
  }
}
