import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/activity_log_model.dart';
import '../data/services/activity_log_service.dart';
import 'complaint_provider.dart';
import 'officer_provider.dart';

final activityLogServiceProvider = Provider<ActivityLogService>((ref) => ActivityLogService());

/// Real-time stream of the recent 100 activity logs (excludes soft-deleted).
final activityLogsStreamProvider = StreamProvider<List<ActivityLogModel>>((ref) {
  return ref.watch(activityLogServiceProvider).watchRecentLogs(limit: 100);
});

/// Reactive metrics provider computed every time new activity logs are written.
final activeUsersMetricsProvider = FutureProvider<Map<String, int>>((ref) async {
  // Triggers recalculation dynamically when the logs stream updates.
  ref.watch(activityLogsStreamProvider);
  return ref.read(activityLogServiceProvider).getActiveUsersMetrics();
});

/// Computes active officer rankings by checking assigned cases from reactively cached streams.
final officerActivityStatsProvider = Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final officersAsync = ref.watch(officersProvider);
  final complaintsAsync = ref.watch(allComplaintsStreamProvider);

  if (officersAsync.isLoading || complaintsAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (officersAsync.hasError) {
    return AsyncValue.error(officersAsync.error!, officersAsync.stackTrace!);
  }
  if (complaintsAsync.hasError) {
    return AsyncValue.error(complaintsAsync.error!, complaintsAsync.stackTrace!);
  }

  final officers = officersAsync.value ?? [];
  final complaints = complaintsAsync.value ?? [];

  final stats = officers.map((officer) {
    final count = complaints.where((c) => c.assignedOfficerId == officer.id).length;
    final resolvedCount = complaints.where((c) => c.assignedOfficerId == officer.id && c.status == 'resolved').length;
    return {
      'officer': officer,
      'case_count': count,
      'resolved_count': resolvedCount,
    };
  }).toList();

  // Sort by cases assigned descending, then by resolved cases descending
  stats.sort((a, b) {
    final cmp = (b['case_count'] as int).compareTo(a['case_count'] as int);
    if (cmp != 0) return cmp;
    return (b['resolved_count'] as int).compareTo(a['resolved_count'] as int);
  });

  return AsyncValue.data(stats);
});

/// Aggregates activity logs from the last 7 days dynamically for charting daily activity volumes.
final dailyActivityTrendsProvider = Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final logsAsync = ref.watch(activityLogsStreamProvider);

  return logsAsync.whenData((logs) {
    final now = DateTime.now();
    final Map<String, int> counts = {};

    // Initialize the last 7 days with 0 to ensure all days are plotted
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key = '${day.day}/${day.month}';
      counts[key] = 0;
    }

    // Populate log counts per day
    for (var log in logs) {
      final difference = now.difference(log.createdAt).inDays;
      if (difference < 7) {
        final key = '${log.createdAt.day}/${log.createdAt.month}';
        if (counts.containsKey(key)) {
          counts[key] = counts[key]! + 1;
        }
      }
    }

    return counts.entries.map((e) => {
      'day': e.key,
      'count': e.value,
    }).toList();
  });
});

/// Fetches security audit logs for the currently logged-in user.
final userSecurityLogsProvider = FutureProvider.autoDispose<List<ActivityLogModel>>((ref) async {
  return ref.watch(activityLogServiceProvider).getUserSecurityLogs();
});

/// Fetches all soft-deleted audit logs for the admin recycle bin (Audit Logs tab).
final deletedAuditLogsProvider = FutureProvider.autoDispose<List<ActivityLogModel>>((ref) async {
  return ref.watch(activityLogServiceProvider).getDeletedAuditLogs();
});
