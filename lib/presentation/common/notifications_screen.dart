import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationProvider);
    final authState = ref.watch(authNotifierProvider);
    final isAdmin = authState.valueOrNull?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () {
              ref.read(notificationProvider.notifier).markAllAsRead();
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final bool isUnread = !notification.isRead;

              return Card(
                elevation: isUnread ? 2 : 0,
                color: isUnread ? AppColors.primary.withOpacity(0.15) : null,
                shape: isUnread
                    ? RoundedRectangleBorder(
                        side: const BorderSide(color: AppColors.primary, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isUnread ? AppColors.primary : Colors.grey.shade300,
                    child: Icon(
                      _getIconForType(notification.type),
                      color: isUnread ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(notification.message),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat.yMMMd().add_jm().format(notification.createdAt.toLocal()),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    if (isUnread) {
                      ref.read(notificationProvider.notifier).markAsRead(notification.id);
                    }
                    if (notification.relatedId != null) {
                      if (isAdmin) {
                        context.push('/admin/complaints/${notification.relatedId}');
                      } else {
                        context.push('/complaint/${notification.relatedId}');
                      }
                    }
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Error loading notifications: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'new_complaint':
        return Icons.report_problem;
      case 'status_update':
        return Icons.update;
      case 'new_message':
        return Icons.chat_bubble_outline;
      default:
        return Icons.notifications;
    }
  }
}
