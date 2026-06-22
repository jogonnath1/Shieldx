import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shieldx/common/core/constants/app_colors.dart';
import 'package:shieldx/common/core/constants/app_constants.dart';
import 'package:shieldx/common/data/models/police_station_model.dart';
import 'package:shieldx/common/presentation/widgets/common/widgets.dart';

class IncidentStep extends StatelessWidget {
  final String? selectedCategory;
  final void Function(String?) onCategoryChanged;
  final TextEditingController descriptionCtrl, locationCtrl;
  final DateTime? incidentDate;
  final VoidCallback onPickDate;
  final String? selectedPoliceStation;
  final void Function(String?) onPoliceStationChanged;
  final bool isDetectingLocation;
  final VoidCallback onRetryDetect;
  final VoidCallback onTapLocation;
  final String? locationError;
  const IncidentStep({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.descriptionCtrl,
    required this.locationCtrl,
    required this.incidentDate,
    required this.onPickDate,
    required this.selectedPoliceStation,
    required this.onPoliceStationChanged,
    required this.isDetectingLocation,
    required this.onRetryDetect,
    required this.onTapLocation,
    this.locationError,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: selectedCategory,
          dropdownColor: AppColors.card,
          decoration: const InputDecoration(
            labelText: 'Crime Category',
            prefixIcon: Icon(Icons.category_outlined,
                color: AppColors.textHint, size: 20),
          ),
          items: AppConstants.crimeCategories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: onCategoryChanged,
          validator: (v) => v == null ? 'Select category' : null,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          label: 'Description',
          controller: descriptionCtrl,
          prefixIcon: Icons.description_outlined,
          maxLines: 4,
          validator: (v) =>
              v == null || v.isEmpty ? 'Description is required' : null,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          label: 'Incident Location',
          controller: locationCtrl,
          prefixIcon: Icons.place_outlined,
          maxLines: 2,
          readOnly: true,
          onTap: onTapLocation,
          validator: (v) =>
              v == null || v.isEmpty ? 'Incident location is required' : null,
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_police_outlined,
                    color: AppColors.textHint, size: 18),
                const SizedBox(width: 8),
                Text(
                  'That Incident Place is Under the Police Station',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _PoliceStationPicker(
              selectedPoliceStation: selectedPoliceStation,
              isDetectingLocation: isDetectingLocation,
              locationError: locationError,
              onPoliceStationChanged: onPoliceStationChanged,
              onRetryDetect: onRetryDetect,
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onPickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    color: AppColors.textHint, size: 20),
                const SizedBox(width: 12),
                Text(
                  incidentDate != null
                      ? DateFormat('dd MMM yyyy, hh:mm a').format(incidentDate!)
                      : 'Select Incident Date & Time',
                  style: GoogleFonts.inter(
                    color: incidentDate != null
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─── Searchable Division-Grouped Police Station Picker ───────────────────────

class _PoliceStationPicker extends StatelessWidget {
  final String? selectedPoliceStation;
  final bool isDetectingLocation;
  final String? locationError;
  final void Function(String?) onPoliceStationChanged;
  final VoidCallback onRetryDetect;

  const _PoliceStationPicker({
    required this.selectedPoliceStation,
    required this.isDetectingLocation,
    required this.locationError,
    required this.onPoliceStationChanged,
    required this.onRetryDetect,
  });

  void _openPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StationPickerSheet(
        selected: selectedPoliceStation,
        onSelect: (name) {
          Navigator.pop(context);
          onPoliceStationChanged(name);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: isDetectingLocation ? null : () => _openPicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selectedPoliceStation != null
                    ? AppColors.primary.withValues(alpha: 0.6)
                    : AppColors.cardBorder,
              ),
            ),
            child: Row(
              children: [
                if (isDetectingLocation)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                else
                  const Icon(Icons.account_balance_outlined,
                      color: AppColors.textHint, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isDetectingLocation
                        ? 'Detecting your location…'
                        : selectedPoliceStation ?? 'Select police station',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color:
                          selectedPoliceStation != null && !isDetectingLocation
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (selectedPoliceStation != null && !isDetectingLocation)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.gps_fixed_rounded,
                            color: AppColors.primary, size: 10),
                        const SizedBox(width: 3),
                        Text(
                          'Auto',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                IconButton(
                  tooltip: 'Detect location',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.my_location_rounded,
                    color: selectedPoliceStation != null
                        ? AppColors.primary
                        : AppColors.textHint,
                    size: 18,
                  ),
                  onPressed: onRetryDetect,
                ),
              ],
            ),
          ),
        ),
        if (!isDetectingLocation && selectedPoliceStation == null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 12, color: AppColors.textHint),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    locationError ??
                        'Location access denied — please select manually.',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppColors.textHint),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StationPickerSheet extends StatefulWidget {
  final String? selected;
  final void Function(String) onSelect;
  const _StationPickerSheet({required this.selected, required this.onSelect});

  @override
  State<_StationPickerSheet> createState() => _StationPickerSheetState();
}

class _StationPickerSheetState extends State<_StationPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Group stations by division, filtering by query
    final q = _query.toLowerCase();
    final Map<String, List<PoliceStation>> grouped = {};
    for (final division in allDivisions) {
      final stations = dummyPoliceStations
          .where((s) =>
              s.division == division &&
              (q.isEmpty ||
                  s.name.toLowerCase().contains(q) ||
                  s.thana.toLowerCase().contains(q) ||
                  s.division.toLowerCase().contains(q)))
          .toList();
      if (stations.isNotEmpty) {
        grouped[division] = stations;
      }
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F1629),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Police Station',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${dummyPoliceStations.length} stations across all 8 divisions',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.textHint),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchCtrl,
                      autofocus: true,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search by name, thana or division…',
                        hintStyle: GoogleFonts.inter(
                            color: AppColors.textHint, fontSize: 13),
                        prefixIcon: const Icon(Icons.search,
                            color: AppColors.textHint, size: 18),
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFF1E2A45)),
              Expanded(
                child: grouped.isEmpty
                    ? Center(
                        child: Text(
                          'No stations found',
                          style: GoogleFonts.inter(
                              color: AppColors.textHint, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: grouped.length,
                        itemBuilder: (ctx, divIdx) {
                          final division = grouped.keys.elementAt(divIdx);
                          final stations = grouped[division]!;
                          final emoji = divisionEmojis[division] ?? '📍';
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Division header
                              Container(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 6),
                                color: const Color(0xFF0A0E1A),
                                child: Row(
                                  children: [
                                    Text(emoji,
                                        style: const TextStyle(fontSize: 14)),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$division Division',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${stations.length}',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: AppColors.textHint,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Station tiles
                              ...stations.map((station) {
                                final isSelected =
                                    station.name == widget.selected;
                                return InkWell(
                                  onTap: () => widget.onSelect(station.name),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary
                                              .withValues(alpha: 0.12)
                                          : Colors.transparent,
                                      border: const Border(
                                        bottom: BorderSide(
                                          color: Color(0xFF1E2A45),
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.account_balance_rounded,
                                          size: 16,
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.textHint,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                station.name,
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                  color: isSelected
                                                      ? AppColors.primary
                                                      : AppColors.textPrimary,
                                                ),
                                              ),
                                              if (station.thana.isNotEmpty)
                                                Text(
                                                  station.thana,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    color: AppColors.textHint,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: AppColors.primary,
                                            size: 16,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
