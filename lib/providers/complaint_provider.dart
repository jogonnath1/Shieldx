import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/complaint_model.dart';
import '../data/services/complaint_service.dart';
import 'selected_station_provider.dart';

final complaintServiceProvider =
    Provider<ComplaintService>((ref) => ComplaintService());

// ─────────────────────────────────────────────────────────────────────────────
// Core streams — both react to the selected police station
// ─────────────────────────────────────────────────────────────────────────────

final allComplaintsStreamProvider = StreamProvider<List<ComplaintModel>>((ref) {
  final thana = ref.watch(selectedStationThanaProvider);
  return ref.watch(complaintServiceProvider).watchAllComplaints(stationThana: thana);
});

final userComplaintsStreamProvider =
    StreamProvider.family<List<ComplaintModel>, String>((ref, userId) {
  return ref.watch(complaintServiceProvider).watchUserComplaints(userId);
});

// ─────────────────────────────────────────────────────────────────────────────
// Stats / Analytics — all scoped to selected station
// ─────────────────────────────────────────────────────────────────────────────

final complaintStatsProvider = FutureProvider<Map<String, int>>((ref) {
  final thana = ref.watch(selectedStationThanaProvider);
  return ref.watch(complaintServiceProvider).getStatsForStation(stationThana: thana);
});

final categoryStatsProvider = FutureProvider<Map<String, int>>((ref) {
  final thana = ref.watch(selectedStationThanaProvider);
  return ref.watch(complaintServiceProvider).getCategoryStatsForStation(stationThana: thana);
});

final crimeHotspotProvider = FutureProvider<List<ComplaintModel>>((ref) async {
  return ref.watch(complaintServiceProvider).getHistoricalCrimeCoordinates();
});

final monthlyTrendsProvider = Provider<AsyncValue<List<int>>>((ref) {
  final complaintsAsync = ref.watch(allComplaintsStreamProvider);
  return complaintsAsync.whenData((complaints) {
    final currentYear = DateTime.now().year;
    final counts = List.filled(12, 0);
    for (var c in complaints) {
      final date = c.incidentDatetime ?? c.createdAt;
      if (date != null && date.year == currentYear) {
        counts[date.month - 1]++;
      }
    }
    return counts;
  });
});

final locationStatsProvider = Provider<AsyncValue<Map<String, int>>>((ref) {
  final complaintsAsync = ref.watch(allComplaintsStreamProvider);
  return complaintsAsync.whenData((complaints) {
    final map = <String, int>{};
    for (var c in complaints) {
      final loc = c.locationAddress?.trim();
      if (loc != null && loc.isNotEmpty) {
        final normalizedLoc = loc.split(',').first.trim().toLowerCase();
        final displayLoc = normalizedLoc
            .split(' ')
            .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' ');
        map[displayLoc] = (map[displayLoc] ?? 0) + 1;
      }
    }
    final sortedEntries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sortedEntries.take(8));
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Filters for the complaints list screen
// ─────────────────────────────────────────────────────────────────────────────

final selectedStatusFilterProvider = StateProvider<String>((ref) => 'all');

final filteredComplaintsProvider =
    Provider<AsyncValue<List<ComplaintModel>>>((ref) {
  final complaints = ref.watch(allComplaintsStreamProvider);
  final filter = ref.watch(selectedStatusFilterProvider);
  return complaints.when(
    data: (list) {
      if (filter == 'all') return AsyncValue.data(list);
      return AsyncValue.data(
          list.where((c) => c.status == filter).toList());
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// Per-station quick stats for the station cards
// ─────────────────────────────────────────────────────────────────────────────

final allStationsStatsProvider =
    FutureProvider<Map<String, Map<String, int>>>((ref) async {
  final service = ref.watch(complaintServiceProvider);
  final result = <String, Map<String, int>>{};
  final thanas = [
    'Kotwali Model Thana',
    'Moglabazar Thana',
    'South Surma Thana',
    'Shahporan Thana',
    'Jalalabad Thana',
    'Airport Thana',
  ];
  for (final thana in thanas) {
    result[thana] = await service.getStatsForStation(stationThana: thana);
  }
  return result;
});
