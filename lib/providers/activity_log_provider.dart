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

/// Supported time ranges for the activity chart.
enum ChartRange {
  day,      // Last 24 hours (hourly)
  week,     // Last 7 days (daily)
  month,    // Last 30 days (daily)
  threeMonths, // Last 3 months (weekly)
  sixMonths,   // Last 6 months (weekly)
  year,     // Last 12 months (monthly)
}

extension ChartRangeX on ChartRange {
  String get label {
    switch (this) {
      case ChartRange.day: return '1D';
      case ChartRange.week: return '1W';
      case ChartRange.month: return '1M';
      case ChartRange.threeMonths: return '3M';
      case ChartRange.sixMonths: return '6M';
      case ChartRange.year: return '1Y';
    }
  }

  String get fullLabel {
    switch (this) {
      case ChartRange.day: return 'Today';
      case ChartRange.week: return '7 Days';
      case ChartRange.month: return '1 Month';
      case ChartRange.threeMonths: return '3 Months';
      case ChartRange.sixMonths: return '6 Months';
      case ChartRange.year: return '1 Year';
    }
  }

  Duration get duration {
    switch (this) {
      case ChartRange.day: return const Duration(hours: 24);
      case ChartRange.week: return const Duration(days: 7);
      case ChartRange.month: return const Duration(days: 30);
      case ChartRange.threeMonths: return const Duration(days: 91);
      case ChartRange.sixMonths: return const Duration(days: 182);
      case ChartRange.year: return const Duration(days: 365);
    }
  }
}

/// Selected chart range state.
final chartRangeProvider = StateProvider<ChartRange>((ref) => ChartRange.week);

/// Fetches activity log counts from the DB grouped by the appropriate interval for a given ChartRange.
final activityTrendsProvider = FutureProvider.family<List<Map<String, dynamic>>, ChartRange>((ref, range) async {
  final service = ref.watch(activityLogServiceProvider);
  return service.getActivityTrends(range);
});

/// Aggregates activity logs from the last 7 days dynamically for charting daily activity volumes.
/// Kept for backwards compatibility — used internally.
final dailyActivityTrendsProvider = Provider<AsyncValue<List<Map<String, dynamic>>>>((ref) {
  final range = ref.watch(chartRangeProvider);
  final trendsAsync = ref.watch(activityTrendsProvider(range));
  return trendsAsync;
});


/// Fetches security audit logs for the currently logged-in user.
final userSecurityLogsProvider = FutureProvider.autoDispose<List<ActivityLogModel>>((ref) async {
  return ref.watch(activityLogServiceProvider).getUserSecurityLogs();
});

/// Fetches all soft-deleted audit logs for the admin recycle bin (Audit Logs tab).
final deletedAuditLogsProvider = FutureProvider.autoDispose<List<ActivityLogModel>>((ref) async {
  return ref.watch(activityLogServiceProvider).getDeletedAuditLogs();
});
