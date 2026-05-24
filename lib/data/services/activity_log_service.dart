import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity_log_model.dart';
import '../models/profile_model.dart';
import '../../providers/activity_log_provider.dart' show ChartRange, ChartRangeX;

class ActivityLogService {
  final SupabaseClient _client = Supabase.instance.client;

  /// General event logging helper that automatically resolves the active session if profile is omitted.
  Future<void> logEvent({
    required String actionType,
    ProfileModel? profile,
    Map<String, dynamic> details = const {},
    int durationSeconds = 0,
    String? sessionId,
    String? fallbackEmail,
    String? fallbackName,
    String? fallbackRole,
  }) async {
    try {
      ProfileModel? resolvedProfile = profile;
      final currentUser = _client.auth.currentUser;

      if (resolvedProfile == null && currentUser != null) {
        final data = await _client
            .from('profiles')
            .select()
            .eq('id', currentUser.id)
            .maybeSingle();
        if (data != null) {
          final modifiableData = Map<String, dynamic>.from(data);
          modifiableData['email'] = currentUser.email;
          resolvedProfile = ProfileModel.fromMap(modifiableData);
        }
      }

      String resolvedRole = 'user';
      if (resolvedProfile != null) {
        resolvedRole = resolvedProfile.isMainAdmin ? 'main_admin' : resolvedProfile.role;
      } else if (fallbackRole != null) {
        resolvedRole = fallbackRole;
      }

      final logData = {
        'user_id': resolvedProfile?.id,
        'user_email': resolvedProfile?.email ?? currentUser?.email ?? fallbackEmail,
        'user_name': resolvedProfile?.displayName ?? fallbackName,
        'role': resolvedRole,
        'action_type': actionType,
        'details': details,
        'duration_seconds': durationSeconds,
        'session_id': sessionId,
      };

      await _client.from('activity_logs').insert(logData);
    } catch (e) {
      debugPrint('ACTIVITY LOGGING SERVICE ERROR: $e');
    }
  }

  /// Streams recent activity logs in real-time for the admin dashboard (excludes soft-deleted).
  /// Dynamically merges any suspicious login attempts from the last 30 days to guarantee they are visible.
  Stream<List<ActivityLogModel>> watchRecentLogs({int limit = 100}) async* {
    while (true) {
      try {
        final response = await _client
            .from('activity_logs')
            .select()
            .isFilter('deleted_at', null)
            .neq('action_type', 'app_heartbeat')
            .order('created_at', ascending: false)
            .limit(limit);

        final thirtyDaysAgo = DateTime.now().toUtc().subtract(const Duration(days: 30)).toIso8601String();
        final suspiciousResponse = await _client
            .from('activity_logs')
            .select()
            .eq('action_type', 'suspicious_login')
            .gte('created_at', thirtyDaysAgo)
            .isFilter('deleted_at', null);

        final List<Map<String, dynamic>> responseList = List<Map<String, dynamic>>.from(response as List);
        final Set<String> loadedIds = responseList.map((e) => e['id'] as String).toSet();

        for (final row in suspiciousResponse as List) {
          if (!loadedIds.contains(row['id'])) {
            responseList.add(Map<String, dynamic>.from(row));
          }
        }

        responseList.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));

        yield responseList.map((e) => ActivityLogModel.fromMap(e)).toList();
      } catch (e) {
        debugPrint('ERROR in watchRecentLogs: $e');
        yield [];
      }
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  /// Fetches recent activity logs as a one-shot query (excludes soft-deleted).
  /// Dynamically merges any suspicious login attempts from the last 30 days.
  Future<List<ActivityLogModel>> getRecentLogs({int limit = 100}) async {
    try {
      final response = await _client
          .from('activity_logs')
          .select()
          .isFilter('deleted_at', null)
          .neq('action_type', 'app_heartbeat')
          .order('created_at', ascending: false)
          .limit(limit);

      final thirtyDaysAgo = DateTime.now().toUtc().subtract(const Duration(days: 30)).toIso8601String();
      final suspiciousResponse = await _client
          .from('activity_logs')
          .select()
          .eq('action_type', 'suspicious_login')
          .gte('created_at', thirtyDaysAgo)
          .isFilter('deleted_at', null);

      final List<Map<String, dynamic>> responseList = List<Map<String, dynamic>>.from(response as List);
      final Set<String> loadedIds = responseList.map((e) => e['id'] as String).toSet();

      for (final row in suspiciousResponse as List) {
        if (!loadedIds.contains(row['id'])) {
          responseList.add(Map<String, dynamic>.from(row));
        }
      }

      responseList.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));

      return responseList.map((e) => ActivityLogModel.fromMap(e)).toList();
    } catch (e) {
      debugPrint('ERROR in getRecentLogs: $e');
      return [];
    }
  }

  /// Soft-deletes the given log IDs by setting deleted_at = now().
  Future<void> softDeleteLogs(List<String> ids) async {
    if (ids.isEmpty) return;
    await _client
        .from('activity_logs')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .inFilter('id', ids);
  }

  /// Permanently deletes specific activity logs by ID.
  Future<void> permanentlyDeleteLogs(List<String> ids) async {
    if (ids.isEmpty) return;
    await _client
        .from('activity_logs')
        .delete()
        .inFilter('id', ids);
  }

  /// Permanently deletes ALL soft-deleted activity logs (empties the audit log bin).
  Future<void> permanentlyDeleteAllDeletedLogs() async {
    await _client
        .from('activity_logs')
        .delete()
        .not('deleted_at', 'is', null);
  }

  /// Fetches all soft-deleted audit logs for the recycle bin tab.
  Future<List<ActivityLogModel>> getDeletedAuditLogs() async {
    try {
      final response = await _client
          .from('activity_logs')
          .select()
          .not('deleted_at', 'is', null)
          .order('deleted_at', ascending: false);
      return (response as List).map((e) => ActivityLogModel.fromMap(e)).toList();
    } catch (e) {
      debugPrint('ERROR FETCHING DELETED AUDIT LOGS: $e');
      return [];
    }
  }

  /// Calculates statistics for active users and suspicious logins in the database.
  Future<Map<String, int>> getActiveUsersMetrics() async {
    final now = DateTime.now().toUtc();
    final oneDayAgo = now.subtract(const Duration(days: 1)).toIso8601String();
    final sevenDaysAgo = now.subtract(const Duration(days: 7)).toIso8601String();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30)).toIso8601String();

    try {
      // Fetch user activities in the last 30 days (exclude soft-deleted)
      final response = await _client
          .from('activity_logs')
          .select('user_id, created_at, action_type')
          .gte('created_at', thirtyDaysAgo)
          .isFilter('deleted_at', null);

      final list = response as List;

      final Set<String> active24h = {};
      final Set<String> active7d = {};
      final Set<String> active30d = {};
      int suspiciousCount = 0;

      for (final row in list) {
        final userId = row['user_id'] as String?;
        final actionType = row['action_type'] as String?;
        final createdAtStr = row['created_at'] as String;
        final createdAt = DateTime.parse(createdAtStr);

        if (actionType == 'suspicious_login') {
          suspiciousCount++;
        }

        if (userId != null && userId.isNotEmpty) {
          if (createdAt.isAfter(DateTime.parse(oneDayAgo))) {
            active24h.add(userId);
          }
          if (createdAt.isAfter(DateTime.parse(sevenDaysAgo))) {
            active7d.add(userId);
          }
          active30d.add(userId);
        }
      }

      return {
        'active_24h': active24h.length,
        'active_7d': active7d.length,
        'active_30d': active30d.length,
        'suspicious_logins': suspiciousCount,
      };
    } catch (e) {
      debugPrint('ERROR GETTING ACTIVE USERS METRICS: $e');
      return {
        'active_24h': 0,
        'active_7d': 0,
        'active_30d': 0,
        'suspicious_logins': 0,
      };
    }
  }

  /// Fetches security/login-related activity logs for the currently authenticated user.
  Future<List<ActivityLogModel>> getUserSecurityLogs() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return [];

      final response = await _client
          .from('activity_logs')
          .select()
          .eq('user_id', currentUser.id)
          .inFilter('action_type', ['login', 'suspicious_login', 'logout', 'password_change', 'email_change_attempt'])
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .limit(30);

      final list = response as List;
      return list.map((e) => ActivityLogModel.fromMap(e)).toList();
    } catch (e) {
      debugPrint('ERROR FETCHING USER SECURITY LOGS: $e');
      return [];
    }
  }
  /// Fetches activity trend data grouped by the correct interval for a given [ChartRange].
  /// - 1D  → last 24h, grouped hourly
  /// - 1W  → last 7 days, grouped daily (dd/MM)
  /// - 1M  → last 30 days, grouped daily
  /// - 3M  → last 91 days, grouped weekly (week label)
  /// - 6M  → last 182 days, grouped weekly
  /// - 1Y  → last 365 days, grouped monthly (MMM yy)
  Future<List<Map<String, dynamic>>> getActivityTrends(ChartRange range) async {
    try {
      final now = DateTime.now();
      final from = now.subtract(range.duration);
      final fromStr = from.toIso8601String();

      final response = await _client
          .from('activity_logs')
          .select('created_at')
          .gte('created_at', fromStr)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: true);

      final rows = response as List;

      if (range == ChartRange.day) {
        // Hourly buckets for last 24h
        final Map<int, int> hourly = {};
        for (int h = 0; h < 24; h++) {
          hourly[h] = 0;
        }
        for (final row in rows) {
          final dt = DateTime.parse(row['created_at'] as String).toLocal();
          hourly[dt.hour] = (hourly[dt.hour] ?? 0) + 1;
        }
        return hourly.entries.map((e) {
          final h = e.key;
          final label = h == 0
              ? '12am'
              : h < 12
                  ? '${h}am'
                  : h == 12
                      ? '12pm'
                      : '${h - 12}pm';
          return {'day': label, 'count': e.value};
        }).toList();
      } else if (range == ChartRange.week || range == ChartRange.month) {
        // Daily buckets
        final int days = range == ChartRange.week ? 7 : 30;
        final Map<String, int> daily = {};
        for (int i = days - 1; i >= 0; i--) {
          final d = now.subtract(Duration(days: i));
          daily[DateFormat('d/M').format(d)] = 0;
        }
        for (final row in rows) {
          final dt = DateTime.parse(row['created_at'] as String).toLocal();
          final key = DateFormat('d/M').format(dt);
          if (daily.containsKey(key)) daily[key] = daily[key]! + 1;
        }
        return daily.entries.map((e) => {'day': e.key, 'count': e.value}).toList();
      } else {
        // Weekly buckets for 3M / 6M, Monthly for 1Y
        if (range == ChartRange.year) {
          // Monthly buckets
          final Map<String, int> monthly = {};
          for (int i = 11; i >= 0; i--) {
            final d = DateTime(now.year, now.month - i, 1);
            monthly[DateFormat('MMM yy').format(d)] = 0;
          }
          for (final row in rows) {
            final dt = DateTime.parse(row['created_at'] as String).toLocal();
            final key = DateFormat('MMM yy').format(dt);
            if (monthly.containsKey(key)) monthly[key] = monthly[key]! + 1;
          }
          return monthly.entries.map((e) => {'day': e.key, 'count': e.value}).toList();
        } else {
          // Weekly buckets (3M or 6M)
          final int totalWeeks = range == ChartRange.threeMonths ? 13 : 26;
          final Map<String, int> weekly = {};
          for (int i = totalWeeks - 1; i >= 0; i--) {
            final weekStart = now.subtract(Duration(days: i * 7));
            weekly[DateFormat('d/M').format(weekStart)] = 0;
          }
          for (final row in rows) {
            final dt = DateTime.parse(row['created_at'] as String).toLocal();
            // Find which week bucket this belongs to
            for (int i = totalWeeks - 1; i >= 0; i--) {
              final weekStart = now.subtract(Duration(days: i * 7));
              final weekEnd = weekStart.add(const Duration(days: 7));
              if (dt.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                  dt.isBefore(weekEnd)) {
                final key = DateFormat('d/M').format(weekStart);
                if (weekly.containsKey(key)) weekly[key] = weekly[key]! + 1;
                break;
              }
            }
          }
          return weekly.entries.map((e) => {'day': e.key, 'count': e.value}).toList();
        }
      }
    } catch (e) {
      debugPrint('ERROR in getActivityTrends: $e');
      return [];
    }
  }

  /// Fetches all activity logs created today (since midnight local time).
  Future<List<ActivityLogModel>> getTodayLogs() async {
    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();

      final response = await _client
          .from('activity_logs')
          .select()
          .gte('created_at', startOfToday)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      final list = response as List;
      return list.map((e) => ActivityLogModel.fromMap(e)).toList();
    } catch (e) {
      debugPrint('ERROR in getTodayLogs: $e');
      return [];
    }
  }

  /// Calculates a specific user's total active duration (in seconds) today.
  Future<int> getUserTodayActiveDuration(String userId) async {
    try {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day).toUtc().toIso8601String();

      final response = await _client
          .from('activity_logs')
          .select('duration_seconds')
          .eq('user_id', userId)
          .gte('created_at', startOfToday)
          .isFilter('deleted_at', null);

      final list = response as List;
      int totalSeconds = 0;
      for (final row in list) {
        totalSeconds += (row['duration_seconds'] as int? ?? 0);
      }
      return totalSeconds;
    } catch (e) {
      debugPrint('ERROR in getUserTodayActiveDuration: $e');
      return 0;
    }
  }
}
