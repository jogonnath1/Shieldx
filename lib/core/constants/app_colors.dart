import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF0D47A1);

  // Accent
  static const Color accent = Color(0xFF00BFA5);
  static const Color accentLight = Color(0xFF1DE9B6);

  // Background
  static const Color background = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF111827);
  static const Color surfaceLight = Color(0xFF1F2937);
  static const Color card = Color(0xFF1C2333);
  static const Color cardBorder = Color(0xFF2D3748);

  // Text
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textHint = Color(0xFF6B7280);

  // Status Colors
  static const Color submitted = Color(0xFF3B82F6);
  static const Color inProgress = Color(0xFFF59E0B);
  static const Color underInvestigation = Color(0xFF8B5CF6);
  static const Color resolved = Color(0xFF10B981);
  static const Color closed = Color(0xFF6B7280);
  static const Color rejected = Color(0xFFEF4444);

  // Utility
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A0E1A), Color(0xFF111827)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1C2333), Color(0xFF1A2540)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00BFA5), Color(0xFF1565C0)],
  );

  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'offline_pending':
        return Colors.orangeAccent;
      case 'submitted':
        return submitted;
      case 'in_progress':
        return inProgress;
      case 'under_investigation':
        return underInvestigation;
      case 'resolved':
        return resolved;
      case 'closed':
        return closed;
      case 'rejected':
        return rejected;
      default:
        return textSecondary;
    }
  }
}
