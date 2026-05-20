import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/complaint_model.dart';
import '../data/services/complaint_service.dart';
import 'selected_station_provider.dart';

final complaintServiceProvider =
    Provider<ComplaintService>((ref) => ComplaintService());

// ─────────────────────────────────────────────────────────────────────────────
// Core streams — both react to the selected police station
// ─────────────────────────────────────────────────────────────────────────────

final allComplaintsStreamProvider = StreamProvider<List<ComplaintModel>>((ref) async* {
  final thana = ref.watch(selectedStationThanaProvider);
  
  try {
    final stream = ref.watch(complaintServiceProvider).watchAllComplaints(stationThana: thana);
    await for (final list in stream) {
      yield list;
    }
  } catch (e) {
    debugPrint('ADMIN COMPLAINTS STREAM ERROR: $e');
  }
});

final userComplaintsStreamProvider =
    StreamProvider.family<List<ComplaintModel>, String>((ref, userId) async* {
  try {
    final stream = ref.watch(complaintServiceProvider).watchUserComplaints(userId);
    await for (final list in stream) {
      yield list;
    }
  } catch (e) {
    debugPrint('USER COMPLAINTS STREAM ERROR: $e');
  }
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

class ComplaintFilterState {
  final String searchQuery;
  final String category;
  final String status;
  final DateTimeRange? dateRange;

  const ComplaintFilterState({
    this.searchQuery = '',
    this.category = 'all',
    this.status = 'all',
    this.dateRange,
  });

  ComplaintFilterState copyWith({
    String? searchQuery,
    String? category,
    String? status,
    DateTimeRange? Function()? dateRange,
  }) {
    return ComplaintFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      category: category ?? this.category,
      status: status ?? this.status,
      dateRange: dateRange != null ? dateRange() : this.dateRange,
    );
  }
}

final adminComplaintFilterProvider =
    StateProvider<ComplaintFilterState>((ref) => const ComplaintFilterState());

final userComplaintFilterProvider =
    StateProvider<ComplaintFilterState>((ref) => const ComplaintFilterState());

// Backward compatibility chip selectedStatusFilterProvider
final selectedStatusFilterProvider = StateProvider<String>((ref) {
  final adminFilter = ref.watch(adminComplaintFilterProvider);
  return adminFilter.status;
});

final filteredComplaintsProvider =
    Provider<AsyncValue<List<ComplaintModel>>>((ref) {
  final complaints = ref.watch(allComplaintsStreamProvider);
  final filter = ref.watch(adminComplaintFilterProvider);
  return complaints.when(
    data: (list) {
      final filteredList = list.where((c) {
        // 1. Status Filter
        if (filter.status != 'all' && c.status != filter.status) {
          return false;
        }

        // 2. Category Filter
        if (filter.category != 'all' && c.crimeCategory != filter.category) {
          return false;
        }

        // 3. Search Query (FullName, CaseID, Description, Category)
        if (filter.searchQuery.isNotEmpty) {
          final query = filter.searchQuery.toLowerCase();
          final caseIdMatch = c.caseId.toLowerCase().contains(query);
          final nameMatch = c.fullName.toLowerCase().contains(query);
          final descMatch = (c.description ?? '').toLowerCase().contains(query);
          final categoryMatch = (c.crimeCategory ?? '').toLowerCase().contains(query);
          if (!caseIdMatch && !nameMatch && !descMatch && !categoryMatch) {
            return false;
          }
        }

        // 4. Date Range Filter
        if (filter.dateRange != null) {
          final date = c.createdAt;
          if (date != null) {
            final start = DateTime(
              filter.dateRange!.start.year,
              filter.dateRange!.start.month,
              filter.dateRange!.start.day,
            );
            final end = DateTime(
              filter.dateRange!.end.year,
              filter.dateRange!.end.month,
              filter.dateRange!.end.day,
              23,
              59,
              59,
            );
            if (date.isBefore(start) || date.isAfter(end)) {
              return false;
            }
          } else {
            return false;
          }
        }

        return true;
      }).toList();

      return AsyncValue.data(filteredList);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

final userFilteredComplaintsProvider =
    Provider.family<AsyncValue<List<ComplaintModel>>, String>((ref, userId) {
  final complaints = ref.watch(userComplaintsStreamProvider(userId));
  final filter = ref.watch(userComplaintFilterProvider);
  return complaints.when(
    data: (list) {
      final filteredList = list.where((c) {
        // 1. Status Filter
        if (filter.status != 'all' && c.status != filter.status) {
          return false;
        }

        // 2. Category Filter
        if (filter.category != 'all' && c.crimeCategory != filter.category) {
          return false;
        }

        // 3. Search Query
        if (filter.searchQuery.isNotEmpty) {
          final query = filter.searchQuery.toLowerCase();
          final caseIdMatch = c.caseId.toLowerCase().contains(query);
          final descMatch = (c.description ?? '').toLowerCase().contains(query);
          final categoryMatch = (c.crimeCategory ?? '').toLowerCase().contains(query);
          if (!caseIdMatch && !descMatch && !categoryMatch) {
            return false;
          }
        }

        // 4. Date Range Filter
        if (filter.dateRange != null) {
          final date = c.createdAt;
          if (date != null) {
            final start = DateTime(
              filter.dateRange!.start.year,
              filter.dateRange!.start.month,
              filter.dateRange!.start.day,
            );
            final end = DateTime(
              filter.dateRange!.end.year,
              filter.dateRange!.end.month,
              filter.dateRange!.end.day,
              23,
              59,
              59,
            );
            if (date.isBefore(start) || date.isAfter(end)) {
              return false;
            }
          } else {
            return false;
          }
        }

        return true;
      }).toList();

      return AsyncValue.data(filteredList);
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
