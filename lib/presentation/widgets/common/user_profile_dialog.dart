import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_time_extensions.dart';
import '../../../data/models/profile_model.dart';
import '../../../providers/activity_log_provider.dart';

class UserProfileDialog {
  static void show(BuildContext context, ProfileModel u) {
    showDialog(
      context: context,
      builder: (context) {
        final hasAvatar = u.avatarUrl != null && u.avatarUrl!.isNotEmpty;
        return Dialog(
          backgroundColor: const Color(0xFF0F172A), // Premium dark slate background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.cardBorder, width: 1),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with close button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'User Profile Details',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: AppColors.textHint),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.cardBorder, height: 1),
                
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar and name header
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: u.isAdmin
                                      ? const LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFF1565C0)])
                                      : AppColors.primaryGradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (u.isAdmin ? const Color(0xFF7B1FA2) : AppColors.primary).withValues(alpha: 0.25),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: u.isAdmin ? const Color(0xFF9C27B0) : AppColors.primaryLight,
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: hasAvatar
                                      ? Image.network(
                                          u.avatarUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Center(
                                            child: Text(
                                              u.initials,
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 28,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            u.initials,
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 28,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      u.displayName,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        color: AppColors.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    u.isVerified
                                        ? Icons.verified_rounded
                                        : Icons.gpp_maybe_rounded,
                                    color: u.isVerified
                                        ? const Color(0xFF2196F3)
                                        : const Color(0xFFFFB300),
                                    size: 20,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: u.isMainAdmin
                                      ? const Color(0xFFE53935).withValues(alpha: 0.15)
                                      : (u.isAdmin
                                          ? AppColors.warning.withValues(alpha: 0.15)
                                          : AppColors.primary.withValues(alpha: 0.15)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: u.isMainAdmin
                                        ? const Color(0xFFE53935).withValues(alpha: 0.3)
                                        : (u.isAdmin
                                            ? AppColors.warning.withValues(alpha: 0.3)
                                            : AppColors.primaryLight.withValues(alpha: 0.3)),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  u.isMainAdmin
                                      ? '👑 Main Admin'
                                      : (u.isAdmin ? 'Admin' : 'User Account'),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: u.isMainAdmin
                                        ? const Color(0xFFEF5350)
                                        : (u.isAdmin ? AppColors.warning : AppColors.primaryLight),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        _buildSectionHeader('Registration Info'),
                        _buildDetailRow(
                          Icons.fingerprint_rounded,
                          'USER ID',
                          u.id,
                        ),
                        _buildDetailRow(
                          Icons.calendar_today_rounded,
                          'REGISTRATION DATE & TIME',
                          u.createdAt != null
                              ? u.createdAt!.formatBDT('dd MMMM yyyy, hh:mm:ss a')
                              : 'Not Available',
                        ),
                        
                        _buildSectionHeader('Contact Details'),
                        _buildDetailRow(
                          Icons.email_outlined,
                          'EMAIL ADDRESS',
                          u.email,
                        ),
                        _buildDetailRow(
                          Icons.phone_outlined,
                          'PHONE NUMBER',
                          u.phone,
                        ),
                        
                        _buildSectionHeader('App Usage Activity'),
                        _UserTodayActiveTimeRow(userId: u.id),
                        
                        _buildSectionHeader('Personal Information'),
                        _buildDetailRow(
                          Icons.badge_outlined,
                          'NATIONAL ID (NID)',
                          u.nid,
                        ),
                        _buildDetailRow(
                          Icons.work_outline_rounded,
                          'PROFESSION',
                          u.profession,
                        ),
                        _buildDetailRow(
                          Icons.location_on_outlined,
                          'PRESENT ADDRESS',
                          u.presentAddress,
                        ),
                        _buildDetailRow(
                          Icons.home_outlined,
                          'PERMANENT ADDRESS',
                          u.permanentAddress,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Divider(color: AppColors.cardBorder, height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Dismiss',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              color: AppColors.primaryLight,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Divider(color: AppColors.cardBorder, height: 1),
          ),
        ],
      ),
    );
  }

  static Widget _buildDetailRow(IconData icon, String label, String? value) {
    final hasValue = value != null && value.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primaryLight, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: AppColors.textHint,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasValue ? value : 'Not Provided',
                  style: GoogleFonts.inter(
                    color: hasValue ? AppColors.textPrimary : AppColors.textHint.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                    fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTodayActiveTimeRow extends ConsumerStatefulWidget {
  final String userId;
  const _UserTodayActiveTimeRow({required this.userId});

  @override
  ConsumerState<_UserTodayActiveTimeRow> createState() => _UserTodayActiveTimeRowState();
}

class _UserTodayActiveTimeRowState extends ConsumerState<_UserTodayActiveTimeRow> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Refresh calculations every 10 seconds to make it highly responsive and update in real-time
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        ref.invalidate(userTodayActiveTimeProvider(widget.userId));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeTimeAsync = ref.watch(userTodayActiveTimeProvider(widget.userId));

    // Show 'Calculating...' ONLY on the initial load when there is no cached or previous value
    if (activeTimeAsync.isLoading && !activeTimeAsync.hasValue) {
      return UserProfileDialog._buildDetailRow(
        Icons.timer_outlined,
        "TODAY'S ACTIVE TIME",
        "Calculating...",
      );
    }

    if (activeTimeAsync.hasError && !activeTimeAsync.hasValue) {
      return UserProfileDialog._buildDetailRow(
        Icons.timer_outlined,
        "TODAY'S ACTIVE TIME",
        "Not Available",
      );
    }

    final totalSeconds = activeTimeAsync.value ?? 0;
    String formattedTime;
    if (totalSeconds == 0) {
      formattedTime = "0m (No activity logged today)";
    } else if (totalSeconds < 60) {
      formattedTime = "$totalSeconds seconds";
    } else {
      final int hours = totalSeconds ~/ 3600;
      final int minutes = (totalSeconds % 3600) ~/ 60;
      formattedTime = hours > 0 ? "${hours}h ${minutes}m" : "${minutes}m";
    }
    return UserProfileDialog._buildDetailRow(
      Icons.timer_outlined,
      "TODAY'S ACTIVE TIME",
      formattedTime,
    );
  }
}
