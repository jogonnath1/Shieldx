import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shieldx/common/data/models/complaint_model.dart';
import 'package:shieldx/common/data/models/profile_model.dart';
import 'package:shieldx/common/data/models/police_station_model.dart';
import 'package:shieldx/common/data/services/complaint_service.dart';
import 'package:shieldx/common/providers/selected_station_provider.dart';
import 'package:shieldx/common/core/utils/date_time_extensions.dart';

final complaintServiceProvider =
    Provider<ComplaintService>((ref) => ComplaintService());
final allComplaintsStreamProvider =
    StreamProvider<List<ComplaintModel>>((ref) async* {
  final thana = ref.watch(selectedStationThanaProvider);
  try {
    final stream = ref
        .watch(complaintServiceProvider)
        .watchAllComplaints(stationThana: thana);
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
    final stream =
        ref.watch(complaintServiceProvider).watchUserComplaints(userId);
    await for (final list in stream) {
      yield list;
    }
  } catch (e) {
    debugPrint('USER COMPLAINTS STREAM ERROR: $e');
  }
});
final allProfilesStreamProvider = StreamProvider<List<ProfileModel>>((ref) {
  return Supabase.instance.client.from('profiles').stream(primaryKey: [
    'id'
  ]).map((data) => data.map((e) => ProfileModel.fromMap(e)).toList());
});
final complaintStatsProvider = FutureProvider<Map<String, int>>((ref) {
  final thana = ref.watch(selectedStationThanaProvider);
  return ref
      .watch(complaintServiceProvider)
      .getStatsForStation(stationThana: thana);
});
final categoryStatsProvider = FutureProvider<Map<String, int>>((ref) {
  final thana = ref.watch(selectedStationThanaProvider);
  return ref
      .watch(complaintServiceProvider)
      .getCategoryStatsForStation(stationThana: thana);
});
final crimeHotspotProvider = StreamProvider<List<ComplaintModel>>((ref) {
  return ref.watch(complaintServiceProvider).watchAllComplaints().map((list) =>
      list
          .where((c) =>
              c.latitude != null && c.longitude != null && c.deletedAt == null)
          .toList());
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
            .map((w) =>
                w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' ');
        map[displayLoc] = (map[displayLoc] ?? 0) + 1;
      }
    }
    final sortedEntries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sortedEntries.take(8));
  });
});

class ComplaintFilterState {
  final String searchQuery;
  final String category;
  final String status;
  final DateTime? date;
  final String userVerification;
  const ComplaintFilterState({
    this.searchQuery = '',
    this.category = 'all',
    this.status = 'all',
    this.date,
    this.userVerification = 'all',
  });
  ComplaintFilterState copyWith({
    String? searchQuery,
    String? category,
    String? status,
    DateTime? Function()? date,
    String? userVerification,
  }) {
    return ComplaintFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      category: category ?? this.category,
      status: status ?? this.status,
      date: date != null ? date() : this.date,
      userVerification: userVerification ?? this.userVerification,
    );
  }
}

final adminComplaintFilterProvider =
    StateProvider<ComplaintFilterState>((ref) => const ComplaintFilterState());
final userComplaintFilterProvider =
    StateProvider<ComplaintFilterState>((ref) => const ComplaintFilterState());
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
          final verifiedMap = {for (var p in profiles) p.id: p.isVerified};
          final resolvedList = complaints.map((c) {
            final isVerified =
                c.userId != null ? (verifiedMap[c.userId] ?? false) : false;
            return c.copyWith(userIsVerified: isVerified);
          }).toList();
          final filteredList = resolvedList.where((c) {
            if (filter.status != 'all' && c.status != filter.status) {
              return false;
            }
            if (filter.category != 'all' &&
                c.crimeCategory != filter.category) {
              return false;
            }
            if (filter.searchQuery.isNotEmpty) {
              final query = filter.searchQuery.toLowerCase();
              final caseIdMatch = c.caseId.toLowerCase().contains(query);
              final nameMatch = c.fullName.toLowerCase().contains(query);
              final descMatch =
                  (c.description ?? '').toLowerCase().contains(query);
              final categoryMatch =
                  (c.crimeCategory ?? '').toLowerCase().contains(query);
              if (!caseIdMatch && !nameMatch && !descMatch && !categoryMatch) {
                return false;
              }
            }
            if (filter.date != null) {
              final createdDate = c.createdAt;
              if (createdDate != null) {
                final dateBDT = createdDate.toBangladeshTime();
                final targetDate = DateTime(
                  filter.date!.year,
                  filter.date!.month,
                  filter.date!.day,
                );
                final complaintDate = DateTime(
                  dateBDT.year,
                  dateBDT.month,
                  dateBDT.day,
                );
                if (complaintDate != targetDate) {
                  return false;
                }
              } else {
                return false;
              }
            }
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
        if (filter.status != 'all' && c.status != filter.status) {
          return false;
        }
        if (filter.category != 'all' && c.crimeCategory != filter.category) {
          return false;
        }
        if (filter.searchQuery.isNotEmpty) {
          final query = filter.searchQuery.toLowerCase();
          final caseIdMatch = c.caseId.toLowerCase().contains(query);
          final descMatch = (c.description ?? '').toLowerCase().contains(query);
          final categoryMatch =
              (c.crimeCategory ?? '').toLowerCase().contains(query);
          if (!caseIdMatch && !descMatch && !categoryMatch) {
            return false;
          }
        }
        if (filter.date != null) {
          final createdDate = c.createdAt;
          if (createdDate != null) {
            final dateBDT = createdDate.toBangladeshTime();
            final targetDate = DateTime(
              filter.date!.year,
              filter.date!.month,
              filter.date!.day,
            );
            final complaintDate = DateTime(
              dateBDT.year,
              dateBDT.month,
              dateBDT.day,
            );
            if (complaintDate != targetDate) {
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
final allStationsStatsProvider =
    FutureProvider<Map<String, Map<String, int>>>((ref) async {
  final service = ref.watch(complaintServiceProvider);
  // Build thana list from ALL stations across all 8 divisions — not just 6 Sylhet thanas
  final thanas = dummyPoliceStations
      .map((s) => s.thana)
      .where((t) => t.isNotEmpty)
      .toSet()
      .toList();
  return service.getAllStationsStats(thanas);
});
