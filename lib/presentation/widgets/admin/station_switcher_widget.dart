import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/selected_station_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Station Switcher — compact header chip that opens a bottom-sheet picker
// ─────────────────────────────────────────────────────────────────────────────

class StationSwitcherChip extends ConsumerWidget {
  const StationSwitcherChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final station = ref.watch(selectedStationProvider);
    final label = ref.watch(selectedStationLabelProvider);

    return GestureDetector(
      onTap: () => _showSwitcherSheet(context, ref),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: station == null
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF7B1FA2), Color(0xFF1565C0)],
                ),
          color: station == null ? AppColors.surfaceLight : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: station == null
                ? AppColors.cardBorder
                : AppColors.primaryLight.withOpacity(0.5),
            width: 1.2,
          ),
          boxShadow: station == null
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              station == null
                  ? Icons.account_balance_outlined
                  : Icons.local_police_rounded,
              size: 14,
              color: station == null ? AppColors.textHint : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: station == null ? AppColors.textSecondary : Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.expand_more_rounded,
              size: 14,
              color: station == null ? AppColors.textHint : Colors.white70,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Station context banner — shown below app bar when a specific station is active
// ─────────────────────────────────────────────────────────────────────────────

class StationContextBanner extends ConsumerWidget {
  const StationContextBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final station = ref.watch(selectedStationProvider);
    if (station == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1040), Color(0xFF0D2060)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_police_rounded,
                color: AppColors.primaryLight, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  station.name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${station.thana}  •  ${station.phone}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          // Clear / reset to All Stations
          GestureDetector(
            onTap: () =>
                ref.read(selectedStationProvider.notifier).state = null,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close_rounded,
                  size: 14, color: AppColors.textHint),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: -0.2);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet picker
// ─────────────────────────────────────────────────────────────────────────────

void _showSwitcherSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _StationPickerSheet(ref: ref),
  );
}

class _StationPickerSheet extends ConsumerWidget {
  final WidgetRef ref;
  const _StationPickerSheet({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final selected = widgetRef.watch(selectedStationProvider);
    final stations = widgetRef.watch(allStationsProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFF2D3748))),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B1FA2), Color(0xFF1565C0)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_police_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Select Police Station',
                          style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary)),
                      Text('Sylhet Metropolitan Police — SMP',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.textHint)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF2D3748), height: 1),
            const SizedBox(height: 8),

            // "All Stations" option
            _StationTile(
              icon: Icons.account_balance_outlined,
              title: 'All Stations',
              subtitle: 'Show data from all 6 SMP thanas',
              isSelected: selected == null,
              color: AppColors.accent,
              onTap: () {
                widgetRef.read(selectedStationProvider.notifier).state = null;
                Navigator.pop(context);
              },
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  Expanded(child: Divider(color: Color(0xFF2D3748))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('or pick a station',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
                  ),
                  Expanded(child: Divider(color: Color(0xFF2D3748))),
                ],
              ),
            ),

            // Individual stations
            ...stations.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              final isSelected = selected?.id == s.id;
              final stationColors = _stationColors[i % _stationColors.length];

              return _StationTile(
                icon: Icons.local_police_rounded,
                title: s.name,
                subtitle: '${s.thana}  •  ${s.phone}',
                isSelected: isSelected,
                color: stationColors,
                onTap: () {
                  widgetRef.read(selectedStationProvider.notifier).state = s;
                  Navigator.pop(context);
                },
              ).animate().fadeIn(delay: (i * 50).ms).slideX(begin: 0.1);
            }),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
          ],
        ),
      ),
    );
  }
}

const _stationColors = [
  Color(0xFF7B1FA2), // Kotwali — purple
  Color(0xFF1565C0), // Moglabazar — blue
  Color(0xFF00897B), // South Surma — teal
  Color(0xFFD84315), // Shahporan — deep orange
  Color(0xFF283593), // Jalalabad — indigo
  Color(0xFF00838F), // Airport — cyan
];

class _StationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _StationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : AppColors.surfaceLight.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.6) : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.textHint),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_rounded, color: color, size: 14),
              ),
          ],
        ),
      ),
    );
  }
}
