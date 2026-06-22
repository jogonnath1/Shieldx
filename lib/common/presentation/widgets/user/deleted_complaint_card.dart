import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shieldx/common/core/constants/app_colors.dart';
import 'package:shieldx/common/core/utils/date_time_extensions.dart';
import 'package:shieldx/common/data/models/complaint_model.dart';

class DeletedComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onRestore;
  final VoidCallback onDeletePermanently;
  const DeletedComplaintCard({
    super.key,
    required this.complaint,
    required this.isSelected,
    required this.onTap,
    required this.onRestore,
    required this.onDeletePermanently,
  });
  @override
  Widget build(BuildContext context) {
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Case #${complaint.caseId}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Deleted',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    complaint.crimeCategory ?? 'Unknown',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (complaint.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      complaint.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
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
                          complaint.deletedAt != null
                              ? 'Deleted on: ${complaint.deletedAt!.formatBDT('dd MMM, hh:mm a')}'
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
