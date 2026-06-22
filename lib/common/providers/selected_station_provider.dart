import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shieldx/common/data/models/police_station_model.dart';

final selectedStationProvider = StateProvider<PoliceStation?>((ref) => null);

final selectedDivisionProvider = StateProvider<String?>((ref) => null);

final selectedStationThanaProvider = Provider<String?>((ref) {
  return ref.watch(selectedStationProvider)?.thana;
});

final selectedStationLabelProvider = Provider<String>((ref) {
  final station = ref.watch(selectedStationProvider);
  if (station == null) return 'All Stations';
  return station.jurisdiction ?? station.name;
});

final allStationsProvider = Provider<List<PoliceStation>>((ref) {
  return adminAllPoliceStations;
});

/// Returns stations filtered by selected division.
/// If no division is selected, returns all stations.
final filteredStationsProvider = Provider<List<PoliceStation>>((ref) {
  final selectedDivision = ref.watch(selectedDivisionProvider);
  if (selectedDivision == null) return adminAllPoliceStations;
  return adminAllPoliceStations
      .where((s) => s.division == selectedDivision)
      .toList();
});

/// Returns stations grouped by division as a Map<divisionName, List<PoliceStation>>.
final stationsByDivisionProvider =
    Provider<Map<String, List<PoliceStation>>>((ref) {
  final Map<String, List<PoliceStation>> grouped = {};
  for (final division in allDivisions) {
    grouped[division] =
        adminAllPoliceStations.where((s) => s.division == division).toList();
  }
  return grouped;
});
