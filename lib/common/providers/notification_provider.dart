import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shieldx/common/data/models/notification_model.dart';
import 'package:shieldx/common/data/services/notification_service.dart';
import 'package:shieldx/common/providers/auth_provider.dart';

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());
final notificationFilterProvider = StateProvider<String>((ref) => 'all');
final notificationProvider = StateNotifierProvider<NotificationNotifier,
    AsyncValue<List<NotificationModel>>>((ref) {
  final user = ref.watch(currentUserProvider);
  return NotificationNotifier(user?.id);
});
final filteredNotificationProvider =
    Provider<AsyncValue<List<NotificationModel>>>((ref) {
  final filter = ref.watch(notificationFilterProvider);
  final notificationsAsync = ref.watch(notificationProvider);
  return notificationsAsync.whenData((list) {
    if (filter == 'all') return list;
    if (filter == 'unread') return list.where((n) => !n.isRead).toList();
    return list.where((n) => n.type == filter).toList();
  });
});
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationProvider);
  return notificationsAsync.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

class NotificationNotifier
    extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final String? _userId;
  final _supabase = Supabase.instance.client;
  RealtimeChannel? _subscription;
  NotificationNotifier(this._userId) : super(const AsyncValue.loading()) {
    if (_userId != null) {
      _loadNotifications();
      _subscribeToNotifications();
    } else {
      state = const AsyncValue.data([]);
    }
  }
  Future<void> _loadNotifications() async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', _userId!)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);
      final notifications = (response as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
      if (mounted) {
        state = AsyncValue.data(notifications);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  void _subscribeToNotifications() {
    _subscription = _supabase
        .channel('public:notifications:all')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _userId,
          ),
          callback: (payload) {
            _loadNotifications();
          },
        )
        .subscribe();
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true}).eq('id', notificationId);
      state.whenData((notifications) {
        final updated = notifications.map((n) {
          if (n.id == notificationId) {
            return n.copyWith(isRead: true);
          }
          return n;
        }).toList();
        state = AsyncValue.data(updated);
      });
    } catch (e) {
      debugPrint('[NotificationProvider] Error: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', _userId!)
          .eq('is_read', false);
      state.whenData((notifications) {
        final updated =
            notifications.map((n) => n.copyWith(isRead: true)).toList();
        state = AsyncValue.data(updated);
      });
    } catch (e) {
      debugPrint('[NotificationProvider] Error: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'deleted_at': DateTime.now().toIso8601String()}).eq(
              'id', notificationId);
      state.whenData((notifications) {
        final updated =
            notifications.where((n) => n.id != notificationId).toList();
        state = AsyncValue.data(updated);
      });
    } catch (e) {
      debugPrint('[NotificationProvider] Error: $e');
    }
  }

  Future<void> deleteAllNotifications() async {
    try {
      await _supabase
          .from('notifications')
          .update({'deleted_at': DateTime.now().toIso8601String()}).eq(
              'user_id', _userId!);
      if (mounted) {
        state = const AsyncValue.data([]);
      }
    } catch (e) {
      debugPrint('[NotificationProvider] Error: $e');
    }
  }

  Future<void> markMultipleAsRead(List<String> notificationIds) async {
    try {
      await Future.wait(notificationIds.map((id) => _supabase
          .from('notifications')
          .update({'is_read': true}).eq('id', id)));
      state.whenData((notifications) {
        final updated = notifications.map((n) {
          if (notificationIds.contains(n.id)) {
            return n.copyWith(isRead: true);
          }
          return n;
        }).toList();
        state = AsyncValue.data(updated);
      });
    } catch (e) {
      debugPrint('[NotificationProvider] Error: $e');
    }
  }

  Future<void> deleteMultipleNotifications(List<String> notificationIds) async {
    try {
      await Future.wait(notificationIds.map((id) => _supabase
          .from('notifications')
          .update({'deleted_at': DateTime.now().toIso8601String()}).eq(
              'id', id)));
      state.whenData((notifications) {
        final updated = notifications
            .where((n) => !notificationIds.contains(n.id))
            .toList();
        state = AsyncValue.data(updated);
      });
    } catch (e) {
      debugPrint('[NotificationProvider] Error: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}
