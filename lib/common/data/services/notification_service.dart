import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shieldx/common/data/models/notification_model.dart';
import 'package:shieldx/common/core/constants/app_constants.dart';

class NotificationService {
  final SupabaseClient _client = Supabase.instance.client;
  Stream<List<NotificationModel>> watchNotifications(String userId) {
    return _client
        .from(AppConstants.notificationsTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map((r) => NotificationModel.fromMap(r)).toList());
  }

  Future<List<NotificationModel>> getNotifications(String userId,
      {int limit = 50}) async {
    final response = await _client
        .from(AppConstants.notificationsTable)
        .select()
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(limit);
    return (response as List).map((r) => NotificationModel.fromMap(r)).toList();
  }

  Future<int> getUnreadCount(String userId) async {
    final response = await _client
        .from(AppConstants.notificationsTable)
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false)
        .isFilter('deleted_at', null);
    return (response as List).length;
  }

  Future<void> markAsRead(String notificationId) async {
    await _client
        .from(AppConstants.notificationsTable)
        .update({'is_read': true}).eq('id', notificationId);
  }

  Future<void> markAllAsRead(String userId) async {
    await _client
        .from(AppConstants.notificationsTable)
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  Future<void> deleteNotification(String notificationId) async {
    await _client
        .from(AppConstants.notificationsTable)
        .update({'deleted_at': DateTime.now().toIso8601String()}).eq(
            'id', notificationId);
  }

  Future<List<NotificationModel>> getDeletedNotifications(String userId) async {
    final response = await _client
        .from(AppConstants.notificationsTable)
        .select()
        .eq('user_id', userId)
        .not('deleted_at', 'is', null)
        .order('deleted_at', ascending: false);
    return (response as List).map((r) => NotificationModel.fromMap(r)).toList();
  }

  Future<void> restoreNotification(String notificationId) async {
    await _client
        .from(AppConstants.notificationsTable)
        .update({'deleted_at': null}).eq('id', notificationId);
  }

  Future<void> restoreNotifications(List<String> ids) async {
    await _client
        .from(AppConstants.notificationsTable)
        .update({'deleted_at': null}).inFilter('id', ids);
  }

  Future<void> hardDeleteNotifications(List<String> ids) async {
    await _client
        .from(AppConstants.notificationsTable)
        .delete()
        .inFilter('id', ids);
  }

  Future<void> hardDeleteAllUserNotifications(String userId) async {
    await _client
        .from(AppConstants.notificationsTable)
        .delete()
        .eq('user_id', userId)
        .not('deleted_at', 'is', null);
  }
}
