import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/complaint_model.dart';
import '../data/services/complaint_service.dart';

final complaintServiceProvider =
    Provider<ComplaintService>((ref) => ComplaintService());

final allComplaintsStreamProvider = StreamProvider<List<ComplaintModel>>((ref) {
  return ref.watch(complaintServiceProvider).watchAllComplaints();
});

final userComplaintsStreamProvider =
    StreamProvider.family<List<ComplaintModel>, String>((ref, userId) {
  return ref.watch(complaintServiceProvider).watchUserComplaints(userId);
});

final complaintStatsProvider = FutureProvider<Map<String, int>>((ref) {
  return ref.watch(complaintServiceProvider).getStats();
});

final categoryStatsProvider = FutureProvider<Map<String, int>>((ref) {
  return ref.watch(complaintServiceProvider).getCategoryStats();
});

final monthlyTrendsProvider = Provider<AsyncValue<List<int>>>((ref) {
  final complaintsAsync = ref.watch(allComplaintsStreamProvider);
  return complaintsAsync.whenData((complaints) {
    // Return a list of 12 integers representing the counts for each month (Jan-Dec) for the current year
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
        // Simple normalization: take the first part of the address up to the first comma, or just the string if no comma
        final normalizedLoc = loc.split(',').first.trim().toLowerCase();
        // Capitalize words
        final displayLoc = normalizedLoc.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
        
        map[displayLoc] = (map[displayLoc] ?? 0) + 1;
      }
    }
    // Sort by count descending
    final sortedEntries = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sortedEntries.take(8)); // Take top 8 locations
  });
});
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
