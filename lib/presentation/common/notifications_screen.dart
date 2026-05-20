import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationProvider);
    final isAdmin = ref.watch(authNotifierProvider).valueOrNull?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, ref),
              Expanded(
                child: notificationsAsync.when(
                  data: (notifications) => notifications.isEmpty
                      ? _buildEmpty()
                      : _buildList(context, ref, notifications, isAdmin),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryLight),
                  ),
                  error: (e, _) => _buildError(e),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        border: const Border(
          bottom: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Stay updated on your complaints & alerts',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          // Mark all as read button
          Consumer(
            builder: (context, ref, _) {
              final count = ref.watch(unreadNotificationCountProvider);
              if (count == 0) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () =>
                    ref.read(notificationProvider.notifier).markAllAsRead(),
                icon: const Icon(Icons.done_all_rounded,
                    size: 16, color: AppColors.primaryLight),
                label: Text(
                  'Mark all read',
                  style: GoogleFonts.inter(
                      color: AppColors.primaryLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildList(BuildContext context, WidgetRef ref,
      List<NotificationModel> notifications, bool isAdmin) {
    // Group notifications into Today and Earlier
    final today = DateTime.now();
    final todayItems = notifications.where((n) {
      final d = n.createdAt.toLocal();
      return d.year == today.year &&
          d.month == today.month &&
          d.day == today.day;
    }).toList();
    final earlierItems = notifications.where((n) {
      final d = n.createdAt.toLocal();
      return !(d.year == today.year &&
          d.month == today.month &&
          d.day == today.day);
    }).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (todayItems.isNotEmpty) ...[
          _sectionHeader('Today'),
          ...todayItems.asMap().entries.map((e) => _buildCard(
              context, ref, e.value, isAdmin, e.key)),
        ],
        if (earlierItems.isNotEmpty) ...[
          _sectionHeader('Earlier'),
          ...earlierItems.asMap().entries.map((e) => _buildCard(
              context, ref, e.value, isAdmin, e.key + todayItems.length)),
        ],
      ],
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textHint,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, WidgetRef ref,
      NotificationModel n, bool isAdmin, int index) {
    final isUnread = !n.isRead;
    final typeColor = _colorForType(n.type);
    final typeIcon = _iconForType(n.type);

    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.error, size: 24),
      ),
      onDismissed: (_) {},
      child: GestureDetector(
        onTap: () {
          if (isUnread) {
            ref.read(notificationProvider.notifier).markAsRead(n.id);
          }
          if (n.relatedId != null) {
            if (n.isSos) {
              // Navigate to admin dashboard for SOS alerts
              context.pop();
            } else if (isAdmin) {
              context.push('/admin/complaints/${n.relatedId}');
            } else {
              context.push('/complaint/${n.relatedId}');
            }
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUnread
                ? typeColor.withValues(alpha: 0.08)
                : AppColors.surface.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread
                  ? typeColor.withValues(alpha: 0.35)
                  : AppColors.cardBorder,
              width: isUnread ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(typeIcon, color: typeColor, size: 22),
                    if (isUnread)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: typeColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.background, width: 1.5),
                          ),
                        ),
                      ).animate(onPlay: (c) => c.repeat()).scale(
                            begin: const Offset(0.85, 0.85),
                            end: const Offset(1.15, 1.15),
                            duration: 1.seconds,
                          ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isUnread
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          _timeAgo(n.createdAt),
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.textHint),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.message,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Type chip
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _labelForType(n.type),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: typeColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: index * 40), duration: 300.ms)
            .slideX(begin: 0.05, duration: 300.ms),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded,
                color: AppColors.textHint, size: 56),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1.05, 1.05),
                  duration: 2.seconds),
          const SizedBox(height: 24),
          Text(
            'All caught up!',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have no notifications right now.\nWe\'ll let you know when something happens.',
            style: GoogleFonts.inter(
                fontSize: 14, color: AppColors.textSecondary, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale(
        begin: const Offset(0.9, 0.9), duration: 500.ms);
  }

  Widget _buildError(Object e) {
    return Center(
      child: Text(
        'Error loading notifications:\n$e',
        style: GoogleFonts.inter(color: AppColors.error, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _colorForType(String type) {
    switch (type) {
      case 'sos':
        return AppColors.error;
      case 'complaint':
        return AppColors.primaryLight;
      default:
        return AppColors.accent;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'sos':
        return Icons.emergency_rounded;
      case 'complaint':
        return Icons.description_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _labelForType(String type) {
    switch (type) {
      case 'sos':
        return '🚨 SOS ALERT';
      case 'complaint':
        return '📋 COMPLAINT UPDATE';
      default:
        return '🔔 SYSTEM';
    }
  }

  String _timeAgo(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    final diff = now.difference(local);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM').format(local);
  }
}
