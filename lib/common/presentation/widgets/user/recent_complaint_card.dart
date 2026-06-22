import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shieldx/common/core/constants/app_colors.dart';
import 'package:shieldx/common/presentation/widgets/common/widgets.dart';

class RecentComplaintCard extends StatelessWidget {
  final dynamic complaint;
  final VoidCallback onTap;
  const RecentComplaintCard(
      {super.key, required this.complaint, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.description_rounded,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  complaint.crimeCategory ?? 'Complaint',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 3),
                Text(
                  'Case #${complaint.caseId}',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          StatusBadge(status: complaint.status, small: true),
        ],
      ),
    );
  }
}
