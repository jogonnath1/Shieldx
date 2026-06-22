import 'package:flutter/material.dart';
import 'package:shieldx/common/core/constants/app_colors.dart';

/// Centralized SnackBar helper to eliminate the 84 repeated
/// `ScaffoldMessenger.of(context).showSnackBar(SnackBar(...))` calls
/// spread across 19 screen files.
///
/// Usage:
///   AppSnackbar.success(context, 'Profile updated successfully!');
///   AppSnackbar.error(context, 'Failed to submit complaint.');
///   AppSnackbar.warning(context, 'Network blocked — Demo Mode enabled.');
class AppSnackbar {
  AppSnackbar._();

  static void success(BuildContext context, String message,
      {Duration? duration}) {
    _show(
        context, message, AppColors.success, Icons.check_circle_outline_rounded,
        duration: duration);
  }

  static void error(BuildContext context, String message,
      {Duration? duration}) {
    _show(context, message, AppColors.error, Icons.error_outline_rounded,
        duration: duration);
  }

  static void warning(BuildContext context, String message,
      {Duration? duration}) {
    _show(context, message, AppColors.warning, Icons.warning_amber_rounded,
        duration: duration);
  }

  static void info(BuildContext context, String message, {Duration? duration}) {
    _show(context, message, AppColors.primary, Icons.info_outline_rounded,
        duration: duration);
  }

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon, {
    Duration? duration,
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }
}
