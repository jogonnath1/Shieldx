import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shieldx/common/core/constants/app_colors.dart';

/// Centralized confirmation dialog helper to replace the 11 repeated
/// `showDialog<bool>` AlertDialog patterns across 8 files.
///
/// All confirmation dialogs shared the same visual structure:
///   - Dark background (#1A2540)
///   - Rounded corners (16px)
///   - Icon + title row
///   - Cancel + Confirm action buttons
///
/// Usage:
///   final confirmed = await AppDialog.confirm(
///     context,
///     title: 'Delete Complaint',
///     message: 'Are you sure you want to delete this complaint?',
///     confirmLabel: 'Delete',
///     confirmColor: AppColors.error,
///     icon: Icons.delete_outline_rounded,
///     iconColor: AppColors.error,
///   );
///   if (confirmed == true) { ... }
class AppDialog {
  AppDialog._();

  /// Shows a styled confirmation dialog and returns [true] if confirmed,
  /// [false] if cancelled, or [null] if dismissed.
  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    Color? confirmColor,
    IconData? icon,
    Color? iconColor,
  }) {
    final resolvedIconColor = iconColor ?? AppColors.primary;
    final resolvedConfirmColor = confirmColor ?? AppColors.primary;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2540),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: resolvedIconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: resolvedIconColor, size: 22),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(cancelLabel, style: GoogleFonts.inter(fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: resolvedConfirmColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(confirmLabel,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
