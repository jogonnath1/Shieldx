import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_time_extensions.dart';
import '../../data/models/activity_log_model.dart';
import '../../data/models/complaint_model.dart';
import '../../data/models/notification_model.dart';
import '../../providers/activity_log_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/notification_provider.dart';
import '../widgets/common/widgets.dart';

class AdminRecycleBinScreen extends ConsumerStatefulWidget {
  const AdminRecycleBinScreen({super.key});

  @override
  ConsumerState<AdminRecycleBinScreen> createState() => _AdminRecycleBinScreenState();
}

class _AdminRecycleBinScreenState extends ConsumerState<AdminRecycleBinScreen> {
  bool _isLoading = false;
  int _selectedTab = 0; // 0 = Cases, 1 = Notifications, 2 = Audit Logs

  List<ComplaintModel> _deletedComplaints = [];
  final Set<String> _selectedIds = {};

  List<NotificationModel> _deletedNotifications = [];
  final Set<String> _selectedNotificationIds = {};

  List<ActivityLogModel> _deletedAuditLogs = [];
  final Set<String> _selectedAuditLogIds = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _fetchDeletedComplaints();
      _fetchDeletedNotifications();
      _fetchDeletedAuditLogs();
    });
  }

  Future<void> _fetchDeletedComplaints() async {
    setState(() => _isLoading = true);
    try {
      final complaints = await ref
          .read(complaintServiceProvider)
          .getDeletedAllComplaints();
      setState(() {
        _deletedComplaints = complaints;
        _selectedIds.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load deleted complaints: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchDeletedNotifications() async {
    final adminUser = ref.read(currentUserProvider);
    if (adminUser == null) return;

    setState(() => _isLoading = true);
    try {
      final notifications = await ref
          .read(notificationServiceProvider)
          .getDeletedNotifications(adminUser.id);
      setState(() {
        _deletedNotifications = notifications;
        _selectedNotificationIds.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load deleted notifications: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedTab == 0) {
        if (_selectedIds.length == _deletedComplaints.length) {
          _selectedIds.clear();
        } else {
          _selectedIds.addAll(_deletedComplaints.map((c) => c.id));
        }
      } else if (_selectedTab == 1) {
        if (_selectedNotificationIds.length == _deletedNotifications.length) {
          _selectedNotificationIds.clear();
        } else {
          _selectedNotificationIds.addAll(_deletedNotifications.map((n) => n.id));
        }
      } else {
        if (_selectedAuditLogIds.length == _deletedAuditLogs.length) {
          _selectedAuditLogIds.clear();
        } else {
          _selectedAuditLogIds.addAll(_deletedAuditLogs.map((l) => l.id));
        }
      }
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedTab == 0) {
        if (_selectedIds.contains(id)) {
          _selectedIds.remove(id);
        } else {
          _selectedIds.add(id);
        }
      } else if (_selectedTab == 1) {
        if (_selectedNotificationIds.contains(id)) {
          _selectedNotificationIds.remove(id);
        } else {
          _selectedNotificationIds.add(id);
        }
      } else {
        if (_selectedAuditLogIds.contains(id)) {
          _selectedAuditLogIds.remove(id);
        } else {
          _selectedAuditLogIds.add(id);
        }
      }
    });
  }

  // ── Cases Actions ──────────────────────────────────────────────────────────
  Future<void> _restoreSelected() async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await _showConfirmDialog(
      title: 'Restore Selected Cases',
      content: 'Are you sure you want to restore the ${_selectedIds.length} selected case(s)? They will return to the active cases list for all admins.',
      confirmLabel: 'Restore',
      confirmColor: AppColors.primary,
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(complaintServiceProvider)
          .restoreComplaints(_selectedIds.toList());
      
      ref.invalidate(allComplaintsStreamProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedIds.length} case(s) restored successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _fetchDeletedComplaints();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore cases: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _hardDeleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await _showConfirmDialog(
      title: 'Permanently Delete Selected',
      content: 'Are you sure you want to permanently delete the ${_selectedIds.length} selected case(s)? This action is completely irreversible and will destroy all records permanently from the database.',
      confirmLabel: 'Delete Permanently',
      confirmColor: AppColors.error,
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(complaintServiceProvider)
          .hardDeleteComplaints(_selectedIds.toList());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedIds.length} case(s) permanently deleted.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _fetchDeletedComplaints();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete cases: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _emptyRecycleBin() async {
    if (_deletedComplaints.isEmpty) return;

    final confirmed = await _showConfirmDialog(
      title: 'Empty Platform Recycle Bin',
      content: 'Are you sure you want to permanently delete ALL ${_deletedComplaints.length} cases in the Recycle Bin? This action is absolute, highly destructive, and cannot be undone.',
      confirmLabel: 'Empty Platform Bin',
      confirmColor: AppColors.error,
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(complaintServiceProvider)
          .hardDeleteAllComplaints();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recycle bin emptied successfully.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _fetchDeletedComplaints();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to empty recycle bin: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _singleRestore(String id, String caseId) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(complaintServiceProvider).restoreComplaint(id);
      
      ref.invalidate(allComplaintsStreamProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Case #$caseId restored successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _fetchDeletedComplaints();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore Case #$caseId: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _singleHardDelete(String id, String caseId) async {
    final confirmed = await _showConfirmDialog(
      title: 'Permanently Delete Case',
      content: 'Are you sure you want to permanently delete Case #$caseId? This action will erase all case files and records forever.',
      confirmLabel: 'Delete Permanently',
      confirmColor: AppColors.error,
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(complaintServiceProvider).hardDeleteComplaints([id]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Case #$caseId permanently deleted.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _fetchDeletedComplaints();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete Case #$caseId: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  // ── Notifications Actions ──────────────────────────────────────────────────
  Future<void> _restoreSelectedNotifications() async {
    if (_selectedNotificationIds.isEmpty) return;

    final confirmed = await _showConfirmDialog(
      title: 'Restore Notifications',
      content: 'Are you sure you want to restore the ${_selectedNotificationIds.length} selected notification(s)? They will return to your active notifications list.',
      confirmLabel: 'Restore',
      confirmColor: AppColors.primary,
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(notificationServiceProvider)
          .restoreNotifications(_selectedNotificationIds.toList());
      
      ref.invalidate(notificationProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedNotificationIds.length} notification(s) restored successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _fetchDeletedNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore notifications: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _hardDeleteSelectedNotifications() async {
    if (_selectedNotificationIds.isEmpty) return;

    final confirmed = await _showConfirmDialog(
      title: 'Permanently Delete Selected',
      content: 'Are you sure you want to permanently delete the ${_selectedNotificationIds.length} selected notification(s)? This action cannot be undone.',
      confirmLabel: 'Delete Permanently',
      confirmColor: AppColors.error,
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(notificationServiceProvider)
          .hardDeleteNotifications(_selectedNotificationIds.toList());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedNotificationIds.length} notification(s) permanently deleted.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _fetchDeletedNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete notifications: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _emptyNotificationsBin() async {
    final adminUser = ref.read(currentUserProvider);
    if (adminUser == null || _deletedNotifications.isEmpty) return;

    final confirmed = await _showConfirmDialog(
      title: 'Empty Recycle Bin',
      content: 'Are you sure you want to permanently delete all ${_deletedNotifications.length} notifications in the Recycle Bin? This action is absolutely irreversible.',
      confirmLabel: 'Empty Bin',
      confirmColor: AppColors.error,
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(notificationServiceProvider)
          .hardDeleteAllUserNotifications(adminUser.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications recycle bin emptied successfully.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _fetchDeletedNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to empty recycle bin: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _singleRestoreNotification(String id) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(notificationServiceProvider).restoreNotification(id);
      ref.invalidate(notificationProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification restored successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _fetchDeletedNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore notification: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _singleHardDeleteNotification(String id) async {
    final confirmed = await _showConfirmDialog(
      title: 'Permanently Delete Notification',
      content: 'Are you sure you want to permanently delete this notification? This action cannot be undone.',
      confirmLabel: 'Delete Permanently',
      confirmColor: AppColors.error,
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(notificationServiceProvider).hardDeleteNotifications([id]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permanently deleted.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _fetchDeletedNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete notification: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  // ── Audit Log Actions ──────────────────────────────────────────────────────
  Future<void> _fetchDeletedAuditLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await ref.read(activityLogServiceProvider).getDeletedAuditLogs();
      setState(() {
        _deletedAuditLogs = logs;
        _selectedAuditLogIds.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load deleted audit logs: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _hardDeleteSelectedAuditLogs() async {
    if (_selectedAuditLogIds.isEmpty) return;
    final confirmed = await _showConfirmDialog(
      title: 'Permanently Delete Audit Logs',
      content: 'Are you sure you want to permanently delete the ${_selectedAuditLogIds.length} selected audit log(s)? This action cannot be undone.',
      confirmLabel: 'Delete Permanently',
      confirmColor: AppColors.error,
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(activityLogServiceProvider).permanentlyDeleteLogs(_selectedAuditLogIds.toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedAuditLogIds.length} audit log(s) permanently deleted.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _fetchDeletedAuditLogs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete audit logs: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _emptyAuditLogsBin() async {
    if (_deletedAuditLogs.isEmpty) return;
    final confirmed = await _showConfirmDialog(
      title: 'Empty Audit Logs Bin',
      content: 'Are you sure you want to permanently delete ALL ${_deletedAuditLogs.length} audit logs in the bin? This action is absolutely irreversible.',
      confirmLabel: 'Empty Bin',
      confirmColor: AppColors.error,
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(activityLogServiceProvider).permanentlyDeleteAllDeletedLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audit logs bin emptied successfully.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _fetchDeletedAuditLogs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to empty audit logs bin: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  // ── General Dialog Helper ──────────────────────────────────────────────────
  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161F37),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: confirmColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                confirmColor == AppColors.error
                    ? Icons.delete_forever_rounded
                    : Icons.settings_backup_restore_rounded,
                color: confirmColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          content,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.cardBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: Text('Cancel', style: GoogleFonts.inter(fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: Text(
              confirmLabel,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── Notification Helpers ───────────────────────────────────────────────────
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
        return 'SOS';
      case 'complaint':
        return 'COMPLAINT';
      default:
        return 'SYSTEM';
    }
  }

  // ── Tab Bar UI ─────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: _selectedTab == 0 ? AppColors.cardGradient : null,
                  color: _selectedTab == 0 ? AppColors.surfaceLight.withOpacity(0.3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: _selectedTab == 0
                      ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 1)
                      : null,
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 16,
                        color: _selectedTab == 0 ? Colors.white : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Cases (${_deletedComplaints.length})',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: _selectedTab == 0 ? FontWeight.w700 : FontWeight.w500,
                          color: _selectedTab == 0 ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: _selectedTab == 1 ? AppColors.cardGradient : null,
                  color: _selectedTab == 1 ? AppColors.surfaceLight.withOpacity(0.3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: _selectedTab == 1
                      ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 1)
                      : null,
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 16,
                        color: _selectedTab == 1 ? Colors.white : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Alerts (${_deletedNotifications.length})',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: _selectedTab == 1 ? FontWeight.w700 : FontWeight.w500,
                          color: _selectedTab == 1 ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: _selectedTab == 2 ? AppColors.cardGradient : null,
                  color: _selectedTab == 2 ? AppColors.surfaceLight.withOpacity(0.3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: _selectedTab == 2
                      ? Border.all(color: const Color(0xFFFF1744).withOpacity(0.4), width: 1)
                      : null,
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 16,
                        color: _selectedTab == 2 ? const Color(0xFFFF1744) : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Audit (${_deletedAuditLogs.length})',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: _selectedTab == 2 ? FontWeight.w700 : FontWeight.w500,
                          color: _selectedTab == 2 ? const Color(0xFFFF1744) : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Notification Card Renderer ─────────────────────────────────────────────
  Widget _buildNotificationCard(NotificationModel n, int i) {
    final isSelected = _selectedNotificationIds.contains(n.id);
    final typeColor = _colorForType(n.type);
    final typeIcon = _iconForType(n.type);

    return GestureDetector(
      onTap: () => _toggleSelect(n.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withOpacity(0.7)
                : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Checkbox Selection
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 4),
              child: Checkbox(
                value: isSelected,
                activeColor: AppColors.primary,
                onChanged: (_) => _toggleSelect(n.id),
              ),
            ),
            
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(typeIcon, color: typeColor, size: 20),
            ),
            const SizedBox(width: 12),

            // Card Details
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
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Type Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _labelForType(n.type),
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: typeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    n.message,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.cardBorder, height: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.delete_outline_rounded,
                        size: 13,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          n.deletedAt != null
                              ? 'Deleted: ${n.deletedAt!.formatBDT('dd MMM, hh:mm a')}'
                              : 'Unknown delete date',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                      
                      // Quick actions
                      IconButton(
                        icon: const Icon(
                          Icons.settings_backup_restore_rounded,
                          color: AppColors.success,
                          size: 18,
                        ),
                        tooltip: 'Restore',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _singleRestoreNotification(n.id),
                      ),
                      const SizedBox(width: 14),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_forever_rounded,
                          color: AppColors.error,
                          size: 18,
                        ),
                        tooltip: 'Delete Permanently',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _singleHardDeleteNotification(n.id),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (i * 50).ms).slideY(begin: 0.1);
  }

  // ── Build Method ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final hasSelection = _selectedTab == 0
        ? _selectedIds.isNotEmpty
        : _selectedTab == 1
            ? _selectedNotificationIds.isNotEmpty
            : _selectedAuditLogIds.isNotEmpty;
    final allSelected = _selectedTab == 0
        ? (_deletedComplaints.isNotEmpty && _selectedIds.length == _deletedComplaints.length)
        : _selectedTab == 1
            ? (_deletedNotifications.isNotEmpty && _selectedNotificationIds.length == _deletedNotifications.length)
            : (_deletedAuditLogs.isNotEmpty && _selectedAuditLogIds.length == _deletedAuditLogs.length);
    final currentItemCount = _selectedTab == 0
        ? _deletedComplaints.length
        : _selectedTab == 1
            ? _deletedNotifications.length
            : _deletedAuditLogs.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Recycle Bin'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/admin/profile'),
        ),
        actions: [
          if (_selectedTab == 0 && _deletedComplaints.isNotEmpty && !_isLoading)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.error),
              tooltip: 'Purge Platform Bin',
              onPressed: _emptyRecycleBin,
            ),
          if (_selectedTab == 1 && _deletedNotifications.isNotEmpty && !_isLoading)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.error),
              tooltip: 'Empty Notifications Bin',
              onPressed: _emptyNotificationsBin,
            ),
          if (_selectedTab == 2 && _deletedAuditLogs.isNotEmpty && !_isLoading)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.error),
              tooltip: 'Empty Audit Logs Bin',
              onPressed: _emptyAuditLogsBin,
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Stack(
          children: [
            Column(
              children: [
                // Top Tab Bar
                _buildTabBar(),

                // Selection & Action Bar
                if (currentItemCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight.withOpacity(0.3),
                      border: const Border(
                        bottom: BorderSide(color: AppColors.cardBorder, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: allSelected,
                          activeColor: AppColors.primary,
                          onChanged: (_) => _toggleSelectAll(),
                        ),
                        Text(
                          hasSelection
                              ? '${_selectedTab == 0 ? _selectedIds.length : _selectedNotificationIds.length} Selected'
                              : 'Select All',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: hasSelection
                                ? AppColors.primaryLight
                                : AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        if (hasSelection) ...[
                          if (_selectedTab != 2)
                            TextButton.icon(
                              onPressed: _selectedTab == 0 ? _restoreSelected : _restoreSelectedNotifications,
                              icon: const Icon(Icons.settings_backup_restore_rounded,
                                  size: 16, color: AppColors.success),
                              label: Text(
                                'Restore',
                                style: GoogleFonts.inter(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13),
                              ),
                            ),
                          if (_selectedTab != 2) const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: _selectedTab == 0
                                ? _hardDeleteSelected
                                : _selectedTab == 1
                                    ? _hardDeleteSelectedNotifications
                                    : _hardDeleteSelectedAuditLogs,
                            icon: const Icon(Icons.delete_forever_rounded,
                                size: 16, color: AppColors.error),
                            label: Text(
                              'Delete',
                              style: GoogleFonts.inter(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13),
                            ),
                          ),
                        ] else
                          Text(
                            '$currentItemCount item(s)',
                            style: GoogleFonts.inter(
                                color: AppColors.textHint,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                      ],
                    ),
                  ),

                // Main Content
                Expanded(
                  child: _isLoading && currentItemCount == 0
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : currentItemCount == 0
                          ? Center(
                              child: EmptyState(
                                icon: _selectedTab == 0
                                    ? Icons.delete_outline_rounded
                                    : _selectedTab == 1
                                        ? Icons.notifications_off_outlined
                                        : Icons.history_rounded,
                                title: _selectedTab == 0
                                    ? 'No Soft-deleted Cases'
                                    : _selectedTab == 1
                                        ? 'No Deleted Notifications'
                                        : 'No Deleted Audit Logs',
                                subtitle: _selectedTab == 0
                                    ? 'When reports are deleted, they will be archived here for administrative recovery.'
                                    : _selectedTab == 1
                                        ? 'When admin notifications are deleted, they will be archived here for recovery.'
                                        : 'Audit logs moved to bin from the Live Audit timeline will appear here.',
                              ),
                            )
                          : _selectedTab == 0
                              ? ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                                  itemCount: _deletedComplaints.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (ctx, i) {
                                    final c = _deletedComplaints[i];
                                    final isSelected = _selectedIds.contains(c.id);

                                    return GestureDetector(
                                      onTap: () => _toggleSelect(c.id),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          gradient: AppColors.cardGradient,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.primary.withOpacity(0.7)
                                                : AppColors.cardBorder,
                                            width: isSelected ? 1.5 : 1.0,
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Left Checkbox Selection
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8, top: 4),
                                              child: Checkbox(
                                                value: isSelected,
                                                activeColor: AppColors.primary,
                                                onChanged: (_) => _toggleSelect(c.id),
                                              ),
                                            ),
                                            
                                            // Card Details
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 8,
                                                            vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.primary
                                                              .withOpacity(0.15),
                                                          borderRadius:
                                                              BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          'Case #${c.caseId}',
                                                          style: GoogleFonts.inter(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: AppColors
                                                                .primaryLight,
                                                          ),
                                                        ),
                                                      ),
                                                      const Spacer(),
                                                      Text(
                                                        'Deleted',
                                                        style: GoogleFonts.inter(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: AppColors.error,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Text(
                                                    c.crimeCategory ?? 'Unknown',
                                                    style: GoogleFonts.inter(
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 15,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                  ),
                                                  if (c.description != null) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      c.description!,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: GoogleFonts.inter(
                                                        fontSize: 12,
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                  const SizedBox(height: 10),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.person_outline,
                                                        size: 13,
                                                        color: AppColors.textHint,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          'Filer: ${c.fullName}',
                                                          style: GoogleFonts.inter(
                                                            fontSize: 11,
                                                            color: AppColors.textHint,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  const Divider(
                                                      color: AppColors.cardBorder,
                                                      height: 1),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                          Icons
                                                              .delete_outline_rounded,
                                                          size: 13,
                                                          color: AppColors.textHint),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          c.deletedAt != null
                                                              ? 'Deleted on: ${c.deletedAt!.formatBDT('dd MMM, hh:mm a')}'
                                                              : 'Unknown delete date',
                                                          style: GoogleFonts.inter(
                                                            fontSize: 11,
                                                            color:
                                                                AppColors.textHint,
                                                          ),
                                                        ),
                                                      ),
                                                      
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.settings_backup_restore_rounded,
                                                            color: AppColors.success,
                                                            size: 18),
                                                        tooltip: 'Restore',
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(),
                                                        onPressed: () => _singleRestore(c.id, c.caseId),
                                                      ),
                                                      const SizedBox(width: 14),
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.delete_forever_rounded,
                                                            color: AppColors.error,
                                                            size: 18),
                                                        tooltip: 'Delete Permanently',
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(),
                                                        onPressed: () =>
                                                            _singleHardDelete(c.id, c.caseId),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ).animate().fadeIn(delay: (i * 50).ms).slideY(begin: 0.1);
                                  },
                                )
                              : _selectedTab == 1
                                  ? ListView.separated(
                                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                                      itemCount: _deletedNotifications.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 12),
                                      itemBuilder: (ctx, i) {
                                        final n = _deletedNotifications[i];
                                        return _buildNotificationCard(n, i);
                                      },
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                                      itemCount: _deletedAuditLogs.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 12),
                                      itemBuilder: (ctx, i) {
                                        final log = _deletedAuditLogs[i];
                                        return _buildAuditLogBinCard(log, i);
                                      },
                                    ),
                ),
              ],
            ),

            // Full screen transparent loader blocker
            if (_isLoading && currentItemCount > 0)
              Container(
                color: Colors.black.withOpacity(0.2),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Audit Log Bin Card ───────────────────────────────────────────────────────
  Widget _buildAuditLogBinCard(ActivityLogModel log, int i) {
    final isSelected = _selectedAuditLogIds.contains(log.id);
    final bdtDeletedAt = log.deletedAt?.toBangladeshTime();
    final bdtCreatedAt = log.createdAt.toBangladeshTime();

    IconData icon;
    Color color;
    switch (log.actionType) {
      case 'app_open': icon = Icons.phonelink_ring_rounded; color = const Color(0xFF00E676); break;
      case 'app_close': icon = Icons.power_settings_new_rounded; color = const Color(0xFF90A4AE); break;
      case 'login': icon = Icons.vpn_key_rounded; color = const Color(0xFFC084FC); break;
      case 'logout': icon = Icons.logout_rounded; color = const Color(0xFFFFB300); break;
      case 'report_submit': icon = Icons.add_task_rounded; color = const Color(0xFF2979FF); break;
      case 'report_edit': icon = Icons.edit_note_rounded; color = const Color(0xFFFF9100); break;
      case 'report_delete': icon = Icons.delete_sweep_rounded; color = const Color(0xFFFF1744); break;
      case 'profile_update': icon = Icons.manage_accounts_rounded; color = const Color(0xFF00E5FF); break;
      case 'suspicious_login': icon = Icons.shield_rounded; color = const Color(0xFFFF1744); break;
      default: icon = Icons.radio_button_checked_rounded; color = AppColors.primary;
    }

    String roleLabel;
    Color roleColor;
    if (log.role == 'main_admin') {
      roleLabel = 'MAIN ADMIN';
      roleColor = const Color(0xFFFFB300);
    } else if (log.role == 'admin') {
      roleLabel = 'ADMIN';
      roleColor = const Color(0xFFC084FC);
    } else {
      roleLabel = 'CITIZEN';
      roleColor = const Color(0xFF00E676);
    }

    return GestureDetector(
      onTap: () => _toggleSelect(log.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF1744).withOpacity(0.6)
                : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
          color: isSelected ? const Color(0xFFFF1744).withOpacity(0.04) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 2),
              child: Checkbox(
                value: isSelected,
                activeColor: const Color(0xFFFF1744),
                onChanged: (_) => _toggleSelect(log.id),
              ),
            ),
            // Action icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          log.userName ?? log.userEmail ?? 'Anonymous',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          roleLabel,
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: roleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log.actionDescription,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: AppColors.cardBorder, height: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 11, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        'Logged: ${DateFormat('dd MMM, hh:mm a').format(bdtCreatedAt)}',
                        style: GoogleFonts.inter(fontSize: 10, color: AppColors.textHint),
                      ),
                      const Spacer(),
                      const Icon(Icons.delete_outline_rounded, size: 11, color: AppColors.error),
                      const SizedBox(width: 4),
                      Text(
                        bdtDeletedAt != null
                            ? 'Binned: ${DateFormat('dd MMM, hh:mm a').format(bdtDeletedAt)}'
                            : 'Deleted',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Permanent delete
                      GestureDetector(
                        onTap: () async {
                          final ok = await _showConfirmDialog(
                            title: 'Delete Audit Log',
                            content: 'Permanently delete this audit log entry? This cannot be undone.',
                            confirmLabel: 'Delete Permanently',
                            confirmColor: AppColors.error,
                          );
                          if (ok == true) {
                            await ref.read(activityLogServiceProvider).permanentlyDeleteLogs([log.id]);
                            await _fetchDeletedAuditLogs();
                          }
                        },
                        child: const Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (i * 50).ms).slideY(begin: 0.1);
  }
}

