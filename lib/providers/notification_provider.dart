import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/notification_model.dart';
import 'auth_provider.dart';

final notificationProvider = StateNotifierProvider<NotificationNotifier, AsyncValue<List<NotificationModel>>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return NotificationNotifier(authState.valueOrNull?.id);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationProvider);
  return notifications.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

class NotificationNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
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
          .order('created_at', ascending: false);

      final notifications = (response as List).map((json) => NotificationModel.fromJson(json)).toList();
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
    _subscription = _supabase.channel('public:notifications')
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
          .update({'is_read': true})
          .eq('id', notificationId);
          
      // Optimistic update
      state.whenData((notifications) {
        final updated = notifications.map((n) {
          if (n.id == notificationId) {
            return NotificationModel(
              id: n.id,
              userId: n.userId,
              title: n.title,
              message: n.message,
              type: n.type,
              relatedId: n.relatedId,
              isRead: true,
              createdAt: n.createdAt,
            );
          }
          return n;
        }).toList();
        state = AsyncValue.data(updated);
      });
    } catch (e) {
      // Handle error if needed
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', _userId!)
          .eq('is_read', false);
          
      // Optimistic update
      state.whenData((notifications) {
        final updated = notifications.map((n) {
          return NotificationModel(
            id: n.id,
            userId: n.userId,
            title: n.title,
            message: n.message,
            type: n.type,
            relatedId: n.relatedId,
            isRead: true,
            createdAt: n.createdAt,
          );
        }).toList();
        state = AsyncValue.data(updated);
      });
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}
