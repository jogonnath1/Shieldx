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
        .isFilter('deleted_at', null)
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
        .eq('is_read', false)
        .isFilter('deleted_at', null);
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

  // ── Soft-delete a single notification ─────────────────────────────────────
  Future<void> deleteNotification(String notificationId) async {
    await _client
        .from(AppConstants.notificationsTable)
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', notificationId);
  }

  // ── Get soft-deleted user notifications ──────────────────────────────────
  Future<List<NotificationModel>> getDeletedNotifications(String userId) async {
    final response = await _client
        .from(AppConstants.notificationsTable)
        .select()
        .eq('user_id', userId)
        .not('deleted_at', 'is', null)
        .order('deleted_at', ascending: false);
    return (response as List)
        .map((r) => NotificationModel.fromMap(r))
        .toList();
  }

  // ── Restore notification ──────────────────────────────────────────────────
  Future<void> restoreNotification(String notificationId) async {
    await _client
        .from(AppConstants.notificationsTable)
        .update({'deleted_at': null})
        .eq('id', notificationId);
  }

  // ── Restore multiple notifications ────────────────────────────────────────
  Future<void> restoreNotifications(List<String> ids) async {
    await _client
        .from(AppConstants.notificationsTable)
        .update({'deleted_at': null})
        .inFilter('id', ids);
  }

  // ── Hard delete multiple notifications ────────────────────────────────────
  Future<void> hardDeleteNotifications(List<String> ids) async {
    await _client
        .from(AppConstants.notificationsTable)
        .delete()
        .inFilter('id', ids);
  }

  // ── Hard delete all user's deleted notifications ─────────────────────────
  Future<void> hardDeleteAllUserNotifications(String userId) async {
    await _client
        .from(AppConstants.notificationsTable)
        .delete()
        .eq('user_id', userId)
        .not('deleted_at', 'is', null);
  }
}

