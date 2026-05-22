import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity_log_model.dart';
import '../models/profile_model.dart';

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

  /// Streams recent activity logs in real-time for the admin dashboard.
  Stream<List<ActivityLogModel>> watchRecentLogs({int limit = 100}) {
    return _client
        .from('activity_logs')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(limit)
        .map((data) => data.map((e) => ActivityLogModel.fromMap(e)).toList());
  }

  /// Fetches recent activity logs as a one-shot query.
  Future<List<ActivityLogModel>> getRecentLogs({int limit = 100}) async {
    final response = await _client
        .from('activity_logs')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return (response as List).map((e) => ActivityLogModel.fromMap(e)).toList();
  }

  /// Calculates statistics for active users and suspicious logins in the database.
  Future<Map<String, int>> getActiveUsersMetrics() async {
    final now = DateTime.now().toUtc();
    final oneDayAgo = now.subtract(const Duration(days: 1)).toIso8601String();
    final sevenDaysAgo = now.subtract(const Duration(days: 7)).toIso8601String();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30)).toIso8601String();

    try {
      // Fetch user activities in the last 30 days
      final response = await _client
          .from('activity_logs')
          .select('user_id, created_at, action_type')
          .gte('created_at', thirtyDaysAgo);

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
          .inFilter('action_type', ['login', 'suspicious_login', 'logout'])
          .order('created_at', ascending: false)
          .limit(30);

      final list = response as List;
      return list.map((e) => ActivityLogModel.fromMap(e)).toList();
    } catch (e) {
      debugPrint('ERROR FETCHING USER SECURITY LOGS: $e');
      return [];
    }
  }
}

