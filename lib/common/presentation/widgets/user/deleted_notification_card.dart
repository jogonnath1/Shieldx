import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shieldx/common/core/constants/app_colors.dart';
import 'package:shieldx/common/core/utils/date_time_extensions.dart';
import 'package:shieldx/common/data/models/notification_model.dart';

class DeletedNotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onRestore;
  final VoidCallback onDeletePermanently;
  const DeletedNotificationCard({
    super.key,
    required this.notification,
    required this.isSelected,
    required this.onTap,
    required this.onRestore,
    required this.onDeletePermanently,
  });
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

  @override
  Widget build(BuildContext context) {
    final typeColor = _colorForType(notification.type);
    final typeIcon = _iconForType(notification.type);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.7)
                : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 4),
              child: Checkbox(
                value: isSelected,
                activeColor: AppColors.primary,
                onChanged: (_) => onTap(),
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(typeIcon, color: typeColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _labelForType(notification.type),
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
                    notification.message,
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
                          notification.deletedAt != null
                              ? 'Deleted: ${notification.deletedAt!.formatBDT('dd MMM, hh:mm a')}'
                              : 'Unknown delete date',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.settings_backup_restore_rounded,
                          color: AppColors.success,
                          size: 18,
                        ),
                        tooltip: 'Restore',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onRestore,
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
                        onPressed: onDeletePermanently,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
