import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shieldx/common/core/constants/app_colors.dart';
import 'package:shieldx/common/providers/station_map_provider.dart';

class StationMarkerWidget extends StatelessWidget {
  final bool isSelected;
  final bool isAutoSelected;
  final SelectionSource selectionSource;
  const StationMarkerWidget({
    super.key,
    required this.isSelected,
    required this.isAutoSelected,
    required this.selectionSource,
  });
  @override
  Widget build(BuildContext context) {
    final color = isAutoSelected ? AppColors.accent : AppColors.primary;
    final badgeLabel = isAutoSelected
        ? (selectionSource == SelectionSource.jurisdiction
            ? 'YOURS'
            : 'NEAREST')
        : null;
    return Stack(
      alignment: Alignment.center,
      children: [
        if (isSelected)
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
          ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                margin: const EdgeInsets.only(bottom: 3),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                        color: color.withValues(alpha: 0.45), blurRadius: 6)
                  ],
                ),
                child: Text(
                  badgeLabel,
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold),
                ),
              ),
            Container(
              padding: EdgeInsets.all(isSelected ? 11 : 8),
              decoration: BoxDecoration(
                color: isSelected ? color : AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                    color: isSelected ? Colors.white : color, width: 2),
                boxShadow: [
                  BoxShadow(
                      color: color.withValues(alpha: 0.45),
                      blurRadius: 12,
                      spreadRadius: 1)
                ],
              ),
              child: Icon(
                Icons.local_police_rounded,
                color: isSelected ? Colors.white : color,
                size: isSelected ? 22 : 18,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
