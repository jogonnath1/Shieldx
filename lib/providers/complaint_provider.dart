import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/complaint_model.dart';
import '../data/models/profile_model.dart';
import '../data/services/complaint_service.dart';
import 'selected_station_provider.dart';
import '../core/utils/date_time_extensions.dart';

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

final allProfilesStreamProvider = StreamProvider<List<ProfileModel>>((ref) {
  return Supabase.instance.client
      .from('profiles')
      .stream(primaryKey: ['id'])
      .map((data) => data.map((e) => ProfileModel.fromMap(e)).toList());
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

final crimeHotspotProvider = StreamProvider<List<ComplaintModel>>((ref) {
  return ref.watch(complaintServiceProvider).watchAllComplaints().map((list) =>
      list.where((c) => c.latitude != null && c.longitude != null && c.deletedAt == null).toList());
});

final monthlyTrendsProvider = Provider<AsyncValue<List<int>>>((ref) {
  final complaintsAsync = ref.watch(allComplaintsStreamProvider);
  return complaintsAsync.whenData((complaints) {
    final currentYear = DateTime.now().toBangladeshTime().year;
    final counts = List.filled(12, 0);
    for (var c in complaints) {
      final date = c.incidentDatetime ?? c.createdAt;
      if (date != null) {
        final dateBDT = date.toBangladeshTime();
        if (dateBDT.year == currentYear) {
          counts[dateBDT.month - 1]++;
        }
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
  final String userVerification; // 'all', 'verified', 'unverified'

  const ComplaintFilterState({
    this.searchQuery = '',
    this.category = 'all',
    this.status = 'all',
    this.dateRange,
    this.userVerification = 'all',
  });

  ComplaintFilterState copyWith({
    String? searchQuery,
    String? category,
    String? status,
    DateTimeRange? Function()? dateRange,
    String? userVerification,
  }) {
    return ComplaintFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      category: category ?? this.category,
      status: status ?? this.status,
      dateRange: dateRange != null ? dateRange() : this.dateRange,
      userVerification: userVerification ?? this.userVerification,
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
  final complaintsAsync = ref.watch(allComplaintsStreamProvider);
  final profilesAsync = ref.watch(allProfilesStreamProvider);
  final filter = ref.watch(adminComplaintFilterProvider);

  return complaintsAsync.when(
    data: (complaints) {
      return profilesAsync.when(
        data: (profiles) {
          // Map profiles to isVerified lookup
          final verifiedMap = {for (var p in profiles) p.id: p.isVerified};

          final resolvedList = complaints.map((c) {
            final isVerified = c.userId != null ? (verifiedMap[c.userId] ?? false) : false;
            return c.copyWith(userIsVerified: isVerified);
          }).toList();

          final filteredList = resolvedList.where((c) {
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

            // 4. Date Range Filter (BDT aligned)
            if (filter.dateRange != null) {
              final date = c.createdAt;
              if (date != null) {
                final dateBDT = date.toBangladeshTime();
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
                if (dateBDT.isBefore(start) || dateBDT.isAfter(end)) {
                  return false;
                }
              } else {
                return false;
              }
            }

            // 5. Submitter Verification Filter
            if (filter.userVerification != 'all') {
              final isVerified = c.userIsVerified ?? false;
              if (filter.userVerification == 'verified' && !isVerified) {
                return false;
              }
              if (filter.userVerification == 'unverified' && isVerified) {
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

        // 4. Date Range Filter (BDT aligned)
        if (filter.dateRange != null) {
          final date = c.createdAt;
          if (date != null) {
            final dateBDT = date.toBangladeshTime();
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
            if (dateBDT.isBefore(start) || dateBDT.isAfter(end)) {
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
  final thanas = [
    'Kotwali Model Thana',
    'Moglabazar Thana',
    'South Surma Thana',
    'Shahporan Thana',
    'Jalalabad Thana',
    'Airport Thana',
  ];
  return service.getAllStationsStats(thanas);
});
