import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../../core/constants/app_constants.dart';

class NotificationService {
  final SupabaseClient _client = Supabase.instance.client;

  // ── Real-time stream of this user's notifications ────────────────────────
  Stream<List<NotificationModel>> watchNotifications(String userId) {
    return _client
        .from(AppConstants.notificationsTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) =>
            rows.map((r) => NotificationModel.fromMap(r)).toList());
  }

  // ── Fetch notifications once (initial load) ──────────────────────────────
  Future<List<NotificationModel>> getNotifications(String userId,
      {int limit = 50}) async {
    final response = await _client
        .from(AppConstants.notificationsTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (response as List)
        .map((r) => NotificationModel.fromMap(r))
        .toList();
  }

  // ── Unread count ─────────────────────────────────────────────────────────
  Future<int> getUnreadCount(String userId) async {
    final response = await _client
        .from(AppConstants.notificationsTable)
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);
    return (response as List).length;
  }

  // ── Mark single notification as read ────────────────────────────────────
  Future<void> markAsRead(String notificationId) async {
    await _client
        .from(AppConstants.notificationsTable)
        .update({'is_read': true}).eq('id', notificationId);
  }

  // ── Mark all notifications as read for a user ───────────────────────────
  Future<void> markAllAsRead(String userId) async {
    await _client
        .from(AppConstants.notificationsTable)
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  // ── Delete a single notification ─────────────────────────────────────────
  Future<void> deleteNotification(String notificationId) async {
    await _client
        .from(AppConstants.notificationsTable)
        .delete()
        .eq('id', notificationId);
  }
}
