import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shieldx/common/core/constants/app_colors.dart';
import 'package:shieldx/common/core/constants/app_constants.dart';
import 'package:shieldx/common/providers/complaint_provider.dart';

class FilterBottomSheetContent extends ConsumerWidget {
  final bool isAdmin;
  const FilterBottomSheetContent({
    super.key,
    required this.isAdmin,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(
        isAdmin ? adminComplaintFilterProvider : userComplaintFilterProvider);
    final filterNotifier = ref.read(
        (isAdmin ? adminComplaintFilterProvider : userComplaintFilterProvider)
            .notifier);
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Advanced Filters',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      filterNotifier.state = filterState.copyWith(
                        category: 'all',
                        date: () => null,
                      );
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Reset All',
                      style: GoogleFonts.inter(
                          color: AppColors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Crime Category',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: filterState.category,
                    dropdownColor: const Color(0xFF0F172A),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary),
                    isExpanded: true,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                    items: [
                      const DropdownMenuItem(
                        value: 'all',
                        child: Text('All Categories'),
                      ),
                      ...AppConstants.crimeCategories.map(
                        (cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        filterNotifier.state =
                            filterState.copyWith(category: val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Date',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: filterState.date ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppColors.primary,
                            onPrimary: Colors.white,
                            surface: Color(0xFF0F172A),
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    filterNotifier.state =
                        filterState.copyWith(date: () => picked);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded,
                          color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          filterState.date == null
                              ? 'Select Date'
                              : DateFormat('dd MMM yyyy')
                                  .format(filterState.date!),
                          style: GoogleFonts.inter(
                            color: filterState.date == null
                                ? AppColors.textHint
                                : Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (filterState.date != null)
                        GestureDetector(
                          onTap: () {
                            filterNotifier.state =
                                filterState.copyWith(date: () => null);
                          },
                          child: const Icon(Icons.close_rounded,
                              color: AppColors.error, size: 18),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Apply Filters',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.white,
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
}
