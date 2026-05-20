import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/police_station_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Global selected police station provider
// null  → "All Stations" (no filter)
// non-null → filter everything to that specific station's jurisdiction/thana
// ─────────────────────────────────────────────────────────────────────────────

final selectedStationProvider = StateProvider<PoliceStation?>((ref) => null);

/// Convenience: returns the thana/jurisdiction string of the currently
/// selected station, or null if "All Stations" is active.
final selectedStationThanaProvider = Provider<String?>((ref) {
  return ref.watch(selectedStationProvider)?.thana;
});

/// Short display label for the app bar / header chip.
final selectedStationLabelProvider = Provider<String>((ref) {
  final station = ref.watch(selectedStationProvider);
  if (station == null) return 'All Stations';
  // Shorten long names: "Kotwali Model Police Station" → "Kotwali"
  return station.jurisdiction ?? station.name;
});

/// The 6 SMP stations list — constant, no async needed.
final allStationsProvider = Provider<List<PoliceStation>>((ref) {
  return dummyPoliceStations;
});
