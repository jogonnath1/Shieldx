import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:shieldx/common/core/constants/app_colors.dart';
import 'package:shieldx/common/data/models/officer_model.dart';
import 'package:shieldx/common/data/models/police_station_model.dart';
import 'package:shieldx/common/providers/officer_provider.dart';
import 'package:shieldx/common/presentation/widgets/common/widgets.dart';

class AdminOfficersScreen extends ConsumerStatefulWidget {
  const AdminOfficersScreen({super.key});
  @override
  ConsumerState<AdminOfficersScreen> createState() =>
      _AdminOfficersScreenState();
}

class _AdminOfficersScreenState extends ConsumerState<AdminOfficersScreen> {
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddDialog(List<OfficerModel> allOfficers,
      [OfficerModel? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name);
    final rankCtrl = TextEditingController(text: existing?.rank);
    final contactCtrl = TextEditingController(text: existing?.contact);
    final formKey = GlobalKey<FormState>();
    final officialStationsSet =
        adminAllPoliceStations.map((s) => s.name).toSet();
    for (final o in allOfficers) {
      if (o.station != null && o.station!.trim().isNotEmpty) {
        officialStationsSet.add(o.station!.trim());
      }
    }
    final officialStations = officialStationsSet.toList()..sort();
    String? selectedStation;
    if (existing != null &&
        existing.station != null &&
        existing.station!.isNotEmpty) {
      final currentVal = existing.station!.trim();
      final matched = adminAllPoliceStations.firstWhere(
        (s) {
          final oStation = currentVal.toLowerCase();
          final sName = s.name.toLowerCase();
          final sThana = s.thana.toLowerCase();
          return oStation.contains(sThana) ||
              sThana.contains(oStation) ||
              oStation.contains(sName) ||
              sName.contains(oStation) ||
              (sThana.contains('kotwali') &&
                  (oStation.contains('kawt') ||
                      oStation.contains('kotw') ||
                      oStation.contains('qotw')));
        },
        orElse: () => const PoliceStation(
          id: '',
          name: '',
          address: '',
          phone: '',
          location: LatLng(0, 0),
          details: '',
          jurisdiction: '',
          thana: '',
        ),
      );
      if (matched.name.isNotEmpty) {
        selectedStation = matched.name;
      } else {
        if (!officialStations.contains(currentVal)) {
          officialStations.add(currentVal);
        }
        selectedStation = currentVal;
      }
    } else {
      selectedStation = officialStations.first;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Officer' : 'Edit Officer'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  label: 'Name',
                  controller: nameCtrl,
                  prefixIcon: Icons.person_outline,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  label: 'Rank',
                  controller: rankCtrl,
                  prefixIcon: Icons.military_tech_outlined,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedStation,
                  decoration: const InputDecoration(
                    labelText: 'Station',
                    prefixIcon: Icon(Icons.location_city_outlined,
                        color: AppColors.textHint, size: 20),
                  ),
                  dropdownColor: AppColors.card,
                  icon: const Icon(Icons.arrow_drop_down_rounded,
                      color: AppColors.textHint),
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  items: officialStations.map((stationName) {
                    return DropdownMenuItem<String>(
                      value: stationName,
                      child: Text(stationName),
                    );
                  }).toList(),
                  onChanged: (val) {
                    selectedStation = val;
                  },
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  label: 'Contact',
                  controller: contactCtrl,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              final data = {
                'name': nameCtrl.text.trim(),
                'rank': rankCtrl.text.trim(),
                'station': selectedStation ?? '',
                'contact': contactCtrl.text.trim(),
              };
              final service = ref.read(officerServiceProvider);
              if (existing == null) {
                await service.addOfficer(data);
              } else {
                await service.updateOfficer(existing.id, data);
              }
              ref.invalidate(officersProvider);
              ref.invalidate(activeOfficersProvider);
            },
            child: Text(existing == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(OfficerModel o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Officer'),
        content: Text('Remove ${o.name ?? 'this officer'}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(officerServiceProvider).deleteOfficer(o.id);
      ref.invalidate(officersProvider);
      ref.invalidate(activeOfficersProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final officersAsync = ref.watch(officersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Officers')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: officersAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, stack) => Center(
            child: Text(
              'Error loading officers: $err',
              style: GoogleFonts.inter(color: AppColors.error),
            ),
          ),
          data: (allOfficers) {
            final officers = allOfficers
                .where(
                    (o) => (o.name ?? '').toLowerCase().contains(_searchQuery))
                .toList();

            return Column(
              children: [
                if (allOfficers.isNotEmpty || _searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: CustomTextField(
                      label: 'Search officers by name...',
                      controller: _searchCtrl,
                      prefixIcon: Icons.search_rounded,
                      onChanged: (v) =>
                          setState(() => _searchQuery = v.toLowerCase()),
                    ),
                  ),
                Expanded(
                  child: officers.isEmpty
                      ? EmptyState(
                          icon: Icons.badge_outlined,
                          title: _searchQuery.isNotEmpty
                              ? 'No Results'
                              : 'No Officers',
                          subtitle: _searchQuery.isNotEmpty
                              ? 'No officers match your search.'
                              : 'Add officers to manage assignments.',
                          buttonLabel: _searchQuery.isNotEmpty
                              ? 'Clear Search'
                              : 'Add Officer',
                          onButton: () {
                            if (_searchQuery.isNotEmpty) {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            } else {
                              _showAddDialog(allOfficers);
                            }
                          },
                        )
                      : RefreshIndicator(
                          onRefresh: () async =>
                              ref.refresh(officersProvider.future),
                          color: AppColors.primary,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                            itemCount: officers.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (ctx, i) {
                              final o = officers[i];
                              return GlassCard(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: o.isActive
                                            ? AppColors.primary
                                                .withValues(alpha: 0.15)
                                            : AppColors.surfaceLight,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(Icons.badge_rounded,
                                          color: o.isActive
                                              ? AppColors.primary
                                              : AppColors.textHint,
                                          size: 26),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(o.name ?? 'Officer',
                                                    style: GoogleFonts.inter(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 14,
                                                        color: AppColors
                                                            .textPrimary)),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: (o.isActive
                                                          ? AppColors.success
                                                          : AppColors.textHint)
                                                      .withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                    o.isActive
                                                        ? 'Active'
                                                        : 'Inactive',
                                                    style: GoogleFonts.inter(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: o.isActive
                                                            ? AppColors.success
                                                            : AppColors
                                                                .textHint)),
                                              ),
                                            ],
                                          ),
                                          if (o.rank != null)
                                            Text(o.rank!,
                                                style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color: AppColors
                                                        .textSecondary)),
                                          if (o.station != null)
                                            Text(o.station!,
                                                style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color: AppColors.textHint)),
                                          if (o.contact != null)
                                            Text(o.contact!,
                                                style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color: AppColors.textHint)),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      color: AppColors.card,
                                      icon: const Icon(Icons.more_vert,
                                          color: AppColors.textHint),
                                      onSelected: (v) async {
                                        final currentOfficers =
                                            officersAsync.valueOrNull ?? [];
                                        if (v == 'edit') {
                                          _showAddDialog(currentOfficers, o);
                                        }
                                        if (v == 'toggle') {
                                          await ref
                                              .read(officerServiceProvider)
                                              .toggleActive(o.id, !o.isActive);
                                          ref.invalidate(officersProvider);
                                          ref.invalidate(
                                              activeOfficersProvider);
                                        }
                                        if (v == 'delete') await _delete(o);
                                      },
                                      itemBuilder: (_) => [
                                        PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Edit',
                                                style: GoogleFonts.inter(
                                                    color: AppColors
                                                        .textPrimary))),
                                        PopupMenuItem(
                                            value: 'toggle',
                                            child: Text(
                                                o.isActive
                                                    ? 'Deactivate'
                                                    : 'Activate',
                                                style: GoogleFonts.inter(
                                                    color: AppColors
                                                        .textPrimary))),
                                        PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Delete',
                                                style: GoogleFonts.inter(
                                                    color: AppColors.error))),
                                      ],
                                    ),
                                  ],
                                ),
                              )
                                  .animate()
                                  .fadeIn(delay: (i * 50).ms)
                                  .slideY(begin: 0.1);
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final officers = officersAsync.valueOrNull ?? [];
          _showAddDialog(officers);
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}
