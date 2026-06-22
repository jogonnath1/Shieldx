import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shieldx/common/core/constants/app_colors.dart';
import 'package:shieldx/common/data/models/police_station_model.dart';
import 'package:shieldx/common/providers/selected_station_provider.dart';

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
                : AppColors.primaryLight.withValues(alpha: 0.5),
            width: 1.2,
          ),
          boxShadow: station == null
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
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
        border:
            Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.15),
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
                  '${station.division}  •  ${station.thana}  •  ${station.phone}',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.textHint),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
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

void _showSwitcherSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _StationPickerSheet(ref: ref),
  );
}

// ─── "All" tab index + all tab labels ────────────────────────────────────────
const List<String> _tabLabels = ['All', ...allDivisions]; // 9 tabs total

class _StationPickerSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _StationPickerSheet({required this.ref});

  @override
  ConsumerState<_StationPickerSheet> createState() =>
      _StationPickerSheetState();
}

class _StationPickerSheetState extends ConsumerState<_StationPickerSheet>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final ScrollController _chipScrollController;
  late final FocusNode _focusNode;
  int _currentTabIndex = 0; // 0 = All, 1..8 = divisions

  // Each chip's GlobalKey for auto-scroll into view
  final List<GlobalKey> _chipKeys =
      List.generate(_tabLabels.length, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _chipScrollController = ScrollController();
    _focusNode = FocusNode();
    // Request focus after first frame so the KeyboardListener receives events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _chipScrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Switch the tab programmatically (from chip tap or arrow buttons)
  void _goToTab(int index) {
    if (index < 0 || index >= _tabLabels.length) return;
    setState(() => _currentTabIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _scrollChipIntoView(index);
  }

  /// Auto-scroll the chip bar so the active chip is visible
  void _scrollChipIntoView(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _chipKeys[index].currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.5,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedStationProvider);
    final stationsByDivision = ref.watch(stationsByDivisionProvider);

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _goToTab(_currentTabIndex + 1);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _goToTab(_currentTabIndex - 1);
          }
        }
      },
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF111827),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0xFF2D3748))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle ──
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // ── Title ──
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Select Police Station',
                            style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary)),
                        Text('Bangladesh Police — All Divisions',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppColors.textHint)),
                      ],
                    ),
                  ),
                  // ── Arrow navigation buttons ──
                  _ArrowNavButton(
                    icon: Icons.chevron_left_rounded,
                    enabled: _currentTabIndex > 0,
                    onTap: () => _goToTab(_currentTabIndex - 1),
                  ),
                  const SizedBox(width: 4),
                  _ArrowNavButton(
                    icon: Icons.chevron_right_rounded,
                    enabled: _currentTabIndex < _tabLabels.length - 1,
                    onTap: () => _goToTab(_currentTabIndex + 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Division filter chips (horizontal scroll with ensureVisible) ──
            SizedBox(
              height: 40,
              child: ListView.builder(
                controller: _chipScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _tabLabels.length,
                itemBuilder: (context, index) {
                  final label = _tabLabels[index];
                  final isAll = index == 0;
                  final emoji =
                      isAll ? '🇧🇩' : (divisionEmojis[label] ?? '📍');
                  final color = isAll
                      ? AppColors.accent
                      : (_pickerDivisionColors[label] ?? AppColors.primary);
                  return Padding(
                    key: _chipKeys[index],
                    padding: EdgeInsets.only(
                      right: index < _tabLabels.length - 1 ? 8 : 0,
                    ),
                    child: _SheetDivisionChip(
                      label: label,
                      emoji: emoji,
                      isSelected: _currentTabIndex == index,
                      color: color,
                      onTap: () => _goToTab(index),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // ── Swipe hint indicator ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_tabLabels.length, (i) {
                final isActive = i == _currentTabIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: isActive ? 16 : 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive
                        ? (_currentTabIndex == 0
                            ? AppColors.accent
                            : (_pickerDivisionColors[
                                    _tabLabels[_currentTabIndex]] ??
                                AppColors.primary))
                        : AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),

            const Divider(color: Color(0xFF2D3748), height: 1),

            // ── PageView of division content (enables swipe) ──
            Flexible(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentTabIndex = index);
                  _scrollChipIntoView(index);
                },
                itemCount: _tabLabels.length,
                itemBuilder: (context, tabIndex) {
                  final division = tabIndex == 0 ? null : _tabLabels[tabIndex];
                  return _DivisionStationList(
                    division: division,
                    stationsByDivision: stationsByDivision,
                    selected: selected,
                    onSelectStation: (s) {
                      ref.read(selectedStationProvider.notifier).state = s;
                      Navigator.pop(context);
                    },
                    onClearStation: () {
                      ref.read(selectedStationProvider.notifier).state = null;
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Arrow nav button ────────────────────────────────────────────────────────

class _ArrowNavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _ArrowNavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.surfaceLight
              : AppColors.surfaceLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? AppColors.cardBorder : Colors.transparent,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? AppColors.textSecondary
              : AppColors.textHint.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

// ─── Per-division station list page ─────────────────────────────────────────

class _DivisionStationList extends StatelessWidget {
  final String? division;
  final Map<String, List<PoliceStation>> stationsByDivision;
  final PoliceStation? selected;
  final void Function(PoliceStation) onSelectStation;
  final VoidCallback onClearStation;

  const _DivisionStationList({
    required this.division,
    required this.stationsByDivision,
    required this.selected,
    required this.onSelectStation,
    required this.onClearStation,
  });

  @override
  Widget build(BuildContext context) {
    final isAll = division == null;

    // Build subtitle for "All Stations" tile
    String allSubtitle;
    if (isAll) {
      allSubtitle =
          'Show data from all ${adminAllPoliceStations.length} stations';
    } else {
      final count = stationsByDivision[division]?.length ?? 0;
      allSubtitle = 'Show all $division stations ($count)';
    }

    return ListView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      children: [
        // ── "All Stations" clear option ──
        _StationTile(
          icon: Icons.account_balance_outlined,
          title: 'All Stations',
          subtitle: allSubtitle,
          isSelected: selected == null,
          color: AppColors.accent,
          onTap: onClearStation,
        ),

        if (isAll) ...[
          // ── Show every division group ──
          ...allDivisions.map((div) {
            final divStations = stationsByDivision[div] ?? [];
            if (divStations.isEmpty) return const SizedBox.shrink();
            final divColor = _pickerDivisionColors[div] ?? AppColors.primary;
            final divEmoji = divisionEmojis[div] ?? '📍';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Row(
                    children: [
                      Text(divEmoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Text(
                        '$div Division',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: divColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: divColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${divStations.length}',
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: divColor),
                        ),
                      ),
                    ],
                  ),
                ),
                ...divStations.asMap().entries.map((entry) {
                  final i = entry.key;
                  final s = entry.value;
                  final isSelected = selected?.id == s.id;
                  return _StationTile(
                    icon: Icons.local_police_rounded,
                    title: s.name,
                    subtitle:
                        '${s.thana.isNotEmpty ? s.thana : s.jurisdiction ?? ''}  •  ${s.phone}',
                    isSelected: isSelected,
                    color: divColor,
                    onTap: () => onSelectStation(s),
                  ).animate().fadeIn(delay: (i * 30).ms);
                }),
              ],
            );
          }),
        ] else ...[
          // ── Single division header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              children: [
                Text(divisionEmojis[division!] ?? '📍',
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Text(
                  '$division Division',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color:
                        _pickerDivisionColors[division!] ?? AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        (_pickerDivisionColors[division!] ?? AppColors.primary)
                            .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${stationsByDivision[division!]?.length ?? 0}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color:
                          _pickerDivisionColors[division!] ?? AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Station tiles for selected division ──
          ...(stationsByDivision[division!] ?? []).asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final isSelected = selected?.id == s.id;
            final divColor =
                _pickerDivisionColors[division!] ?? AppColors.primary;
            return _StationTile(
              icon: Icons.local_police_rounded,
              title: s.name,
              subtitle:
                  '${s.thana.isNotEmpty ? s.thana : s.jurisdiction ?? ''}  •  ${s.phone}',
              isSelected: isSelected,
              color: divColor,
              onTap: () => onSelectStation(s),
            ).animate().fadeIn(delay: (i * 30).ms);
          }),

          // ── Empty state ──
          if ((stationsByDivision[division!] ?? []).isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded,
                      size: 48,
                      color: AppColors.textHint.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text(
                    'No stations in $division Division',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

const _pickerDivisionColors = {
  divisionDhaka: Color(0xFF1565C0),
  divisionChattogram: Color(0xFF00897B),
  divisionSylhet: Color(0xFF7B1FA2),
  divisionRajshahi: Color(0xFFD84315),
  divisionKhulna: Color(0xFF283593),
  divisionBarishal: Color(0xFF00838F),
  divisionRangpur: Color(0xFFF9A825),
  divisionMymensingh: Color(0xFF558B2F),
};

// ─── Sheet Division Chip ──────────────────────────────────────────────────────

class _SheetDivisionChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  const _SheetDivisionChip({
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
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
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

// ─── Station Tile ─────────────────────────────────────────────────────────────

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
          color: isSelected
              ? color.withValues(alpha: 0.12)
              : AppColors.surfaceLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.6)
                : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
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
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
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
                  color: color.withValues(alpha: 0.2),
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
