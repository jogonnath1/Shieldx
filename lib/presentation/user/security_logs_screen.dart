import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_time_extensions.dart';
import '../../data/models/activity_log_model.dart';
import '../../providers/activity_log_provider.dart';
import '../widgets/common/widgets.dart';

class SecurityLogsScreen extends ConsumerWidget {
  const SecurityLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(userSecurityLogsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // High-fidelity App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Security History',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                      onPressed: () => ref.refresh(userSecurityLogsProvider),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  onRefresh: () async {
                    ref.invalidate(userSecurityLogsProvider);
                    await ref.read(userSecurityLogsProvider.future);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Introductory Description Card
                        _buildIntroCard(),
                        const SizedBox(height: 24),

                        // Main Content
                        logsAsync.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 80),
                            child: Center(
                              child: CircularProgressIndicator(color: AppColors.primary),
                            ),
                          ),
                          error: (err, stack) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 80),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: AppColors.error,
                                    size: 40,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Failed to load security logs',
                                    style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    err.toString(),
                                    style: GoogleFonts.inter(
                                      color: AppColors.textHint,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          data: (logs) {
                            if (logs.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 60),
                                child: EmptyState(
                                  title: 'No Security History',
                                  subtitle: 'Your recent secure logins, logouts, and security audits will appear here.',
                                  icon: Icons.shield_outlined,
                                ),
                              );
                            }

                            // Filter or analyze if there is a recent suspicious attempt on their user account
                            final hasSuspicious = logs.any((l) => l.actionType == 'suspicious_login');

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (hasSuspicious) ...[
                                  _buildSuspiciousWarningBanner(logs),
                                  const SizedBox(height: 24),
                                ],
                                _buildTimelineCard(context, logs),
                                const SizedBox(height: 30),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: AppColors.primaryLight,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Integrity',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Monitor security audits, successful authentications, and warning reports associated with your profile to guarantee your account security.',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSuspiciousWarningBanner(List<ActivityLogModel> logs) {
    final suspiciousLogs = logs.where((l) => l.actionType == 'suspicious_login').toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withOpacity(0.05),
            blurRadius: 12,
            spreadRadius: 1,
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Security Alerts Detected',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We registered ${suspiciousLogs.length} unexpected failed/suspicious login attempts on your account profile. If this wasn\'t you, please immediately update your credentials.',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack);
  }

  Widget _buildTimelineCard(BuildContext context, List<ActivityLogModel> logs) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.security_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Access History',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final isLast = index == logs.length - 1;
              final bdtTime = log.createdAt.toBangladeshTime();

              IconData icon;
              Color color;
              switch (log.actionType) {
                case 'login':
                  icon = Icons.vpn_key_rounded;
                  color = const Color(0xFF00E676);
                  break;
                case 'logout':
                  icon = Icons.logout_rounded;
                  color = const Color(0xFF90A4AE);
                  break;
                case 'suspicious_login':
                  icon = Icons.shield_rounded;
                  color = const Color(0xFFFF1744);
                  break;
                default:
                  icon = Icons.info_outline_rounded;
                  color = AppColors.primary;
              }

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.08),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: color.withOpacity(0.35),
                              width: 1.2,
                            ),
                          ),
                          child: Icon(icon, color: color, size: 16),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 1.5,
                              color: AppColors.cardBorder.withOpacity(0.3),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: InkWell(
                        onTap: () => _showLogDetailsBottomSheet(context, log),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 18.0, right: 8.0, left: 4.0, top: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log.actionDescription,
                                style: GoogleFonts.inter(
                                  fontWeight: log.actionType == 'suspicious_login'
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  fontSize: 13,
                                  color: log.actionType == 'suspicious_login'
                                      ? const Color(0xFFFF1744)
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 10,
                                    color: AppColors.textHint,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('hh:mm:ss a').format(bdtTime),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 2,
                                    height: 2,
                                    decoration: const BoxDecoration(
                                      color: AppColors.textHint,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(bdtTime),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.1, end: 0);
  }

  void _showLogDetailsBottomSheet(BuildContext context, ActivityLogModel log) {
    final bdtTime = log.createdAt.toBangladeshTime();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF111827),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: AppColors.cardBorder, width: 1.5),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bottom sheet handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title and icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (log.actionType == 'suspicious_login'
                              ? AppColors.error
                              : log.actionType == 'login'
                                  ? const Color(0xFF00E676)
                                  : AppColors.textHint)
                          .withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      log.actionType == 'suspicious_login'
                          ? Icons.shield_outlined
                          : log.actionType == 'login'
                              ? Icons.vpn_key_rounded
                              : Icons.logout_rounded,
                      color: log.actionType == 'suspicious_login'
                          ? AppColors.error
                          : log.actionType == 'login'
                              ? const Color(0xFF00E676)
                              : AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.actionType == 'suspicious_login'
                              ? 'Security Warning'
                              : log.actionType == 'login'
                                  ? 'Successful Sign In'
                                  : 'Account Sign Out',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          log.actionDescription,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: log.actionType == 'suspicious_login'
                                ? const Color(0xFFFF1744)
                                : AppColors.textSecondary,
                            fontWeight: log.actionType == 'suspicious_login'
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),

              // Details section
              Text(
                'AUDIT METADATA',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textHint,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 16),

              _buildDetailRow(
                label: 'Correlation ID (Session)',
                value: log.sessionId ?? 'N/A',
              ),
              _buildDetailRow(
                label: 'Activity Time',
                value: DateFormat('EEEE, dd MMMM yyyy - hh:mm:ss a').format(bdtTime),
              ),
              _buildDetailRow(
                label: 'Security Status',
                value: log.actionType == 'suspicious_login' ? 'SUSPICIOUS / FAILED' : 'VERIFIED & SECURE',
                valueColor: log.actionType == 'suspicious_login' ? AppColors.error : const Color(0xFF00E676),
              ),
              if (log.details.containsKey('reason'))
                _buildDetailRow(
                  label: 'Incident Reason',
                  value: log.details['reason'].toString(),
                  valueColor: AppColors.error,
                ),
              if (log.details.containsKey('ip'))
                _buildDetailRow(
                  label: 'Source Network Address',
                  value: log.details['ip'].toString(),
                ),
              if (log.details.containsKey('device'))
                _buildDetailRow(
                  label: 'Client Device Details',
                  value: log.details['device'].toString(),
                ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceLight,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.cardBorder),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Dismiss',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textHint,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: valueColor != null ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
