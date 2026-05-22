import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_time_extensions.dart';
import '../../data/models/complaint_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../widgets/common/widgets.dart';

class MyComplaintsScreen extends ConsumerWidget {
  const MyComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final filterState = ref.watch(userComplaintFilterProvider);
    final filterNotifier = ref.read(userComplaintFilterProvider.notifier);

    final complaintsAsync = user != null
        ? ref.watch(userFilteredComplaintsProvider(user.id))
        : const AsyncValue<List<ComplaintModel>>.data([]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Column(
          children: [
            // Modern Search and Filter Row for Citizen
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder, width: 1),
                      ),
                      child: TextField(
                        onChanged: (val) {
                          filterNotifier.state = filterState.copyWith(searchQuery: val);
                        },
                        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search by Case ID, category, keyword...',
                          hintStyle: GoogleFonts.inter(color: AppColors.textHint, fontSize: 13),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Advanced Filter Button
                  GestureDetector(
                    onTap: () => _showFilterBottomSheet(context, ref, false),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (filterState.category != 'all' || filterState.dateRange != null)
                            ? AppColors.primary.withOpacity(0.15)
                            : AppColors.surfaceLight.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: (filterState.category != 'all' || filterState.dateRange != null)
                              ? AppColors.primary
                              : AppColors.cardBorder,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: (filterState.category != 'all' || filterState.dateRange != null)
                            ? AppColors.primaryLight
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Active Filters indicator
            if (filterState.category != 'all' || filterState.dateRange != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'Active:',
                      style: GoogleFonts.inter(color: AppColors.textHint, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (filterState.category != 'all')
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Chip(
                                  label: Text(filterState.category),
                                  labelStyle: GoogleFonts.inter(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                                  backgroundColor: AppColors.primary.withOpacity(0.2),
                                  side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  onDeleted: () {
                                    filterNotifier.state = filterState.copyWith(category: 'all');
                                  },
                                ),
                              ),
                            if (filterState.dateRange != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Chip(
                                  label: Text(
                                    '${DateFormat('d MMM').format(filterState.dateRange!.start)} - ${DateFormat('d MMM').format(filterState.dateRange!.end)}',
                                  ),
                                  labelStyle: GoogleFonts.inter(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                                  backgroundColor: AppColors.primary.withOpacity(0.2),
                                  side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  onDeleted: () {
                                    filterNotifier.state = filterState.copyWith(dateRange: () => null);
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        filterNotifier.state = filterState.copyWith(
                          category: 'all',
                          dateRange: () => null,
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Clear All',
                        style: GoogleFonts.inter(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),

            // Status filter chips for citizen
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: filterState.status == 'all',
                    onTap: () => filterNotifier.state = filterState.copyWith(status: 'all'),
                  ),
                  ...AppConstants.complaintStatuses.map(
                    (s) => _FilterChip(
                      label: AppConstants.statusLabel(s),
                      selected: filterState.status == s,
                      onTap: () => filterNotifier.state = filterState.copyWith(status: s),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: complaintsAsync.when(
                data: (list) {
                  if (list.isEmpty) {
                    final hasActiveFilters = filterState.searchQuery.isNotEmpty ||
                        filterState.category != 'all' ||
                        filterState.status != 'all' ||
                        filterState.dateRange != null;

                    if (hasActiveFilters) {
                      return EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No Matches Found',
                        subtitle: 'Try adjusting or clearing your filters.',
                        buttonLabel: 'Clear All Filters',
                        onButton: () {
                          filterNotifier.state = const ComplaintFilterState();
                        },
                      );
                    }

                    return EmptyState(
                      icon: Icons.assignment_outlined,
                      title: 'No Reports Yet',
                      subtitle: 'You haven\'t submitted any crime reports.',
                      buttonLabel: 'Submit Report',
                      onButton: () => context.push('/submit-complaint'),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final c = list[i];
                return GlassCard(
                  onTap: () => context.push('/complaint/${c.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Case #${c.caseId}',
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryLight)),
                          ),
                          const Spacer(),
                          StatusBadge(status: c.status, small: true),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(c.crimeCategory ?? 'Unknown',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.textPrimary)),
                      if (c.description != null) ...[
                        const SizedBox(height: 4),
                        Text(c.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary)),
                      ],
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.cardBorder, height: 1),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 14, color: AppColors.textHint),
                          const SizedBox(width: 5),
                          Text(
                            c.createdAt != null
                                ? DateFormat('dd MMM yyyy, hh:mm a').format(c.createdAt!.toBangladeshTime())
                                : 'Unknown date',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppColors.textHint),
                          ),
                          const Spacer(),
                          if (c.status == 'submitted')
                            GestureDetector(
                              onTap: () =>
                                  _confirmDelete(context, ref, c.id, c.caseId),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 16,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          const SizedBox(width: 12),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: AppColors.textHint),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: (i * 60).ms).slideY(begin: 0.15);
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: AppColors.error)),
          ),
        ),
      ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/submit-complaint'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String id, String caseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2540),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_forever_rounded,
                  color: AppColors.error, size: 22),
            ),
            const SizedBox(width: 12),
            Text('Delete Case',
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 17)),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
                color: AppColors.textSecondary, fontSize: 14, height: 1.5),
            children: [
              const TextSpan(
                  text: 'Are you sure you want to permanently delete '),
              TextSpan(
                text: 'Case #$caseId',
                style: GoogleFonts.inter(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: '? This action cannot be undone.'),
            ],
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text('Cancel', style: GoogleFonts.inter(fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text('Delete',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(complaintServiceProvider).deleteComplaint(id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Case #$caseId deleted successfully.',
                  style: GoogleFonts.inter(fontSize: 13)),
              backgroundColor: const Color(0xFF1E7E34),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e',
                  style: GoogleFonts.inter(fontSize: 13)),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withOpacity(0.2)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.cardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.primaryLight : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

void _showFilterBottomSheet(BuildContext context, WidgetRef ref, bool isAdmin) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0F172A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return Consumer(
        builder: (ctx, ref, child) {
          final filterState = ref.watch(isAdmin ? adminComplaintFilterProvider : userComplaintFilterProvider);
          final filterNotifier = ref.read((isAdmin ? adminComplaintFilterProvider : userComplaintFilterProvider).notifier);

          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: 24 + MediaQuery.of(ctx).viewInsets.bottom,
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
                              dateRange: () => null,
                            );
                            Navigator.pop(ctx);
                          },
                          child: Text(
                            'Reset All',
                            style: GoogleFonts.inter(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Category Selector
                    Text(
                      'Crime Category',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
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
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
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
                              filterNotifier.state = filterState.copyWith(category: val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Date Range Selector
                    Text(
                      'Date Range',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                          initialDateRange: filterState.dateRange,
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
                          filterNotifier.state = filterState.copyWith(dateRange: () => picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: AppColors.textSecondary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                filterState.dateRange == null
                                    ? 'Select Date Range'
                                    : '${DateFormat('dd MMM yyyy').format(filterState.dateRange!.start)} - ${DateFormat('dd MMM yyyy').format(filterState.dateRange!.end)}',
                                style: GoogleFonts.inter(
                                  color: filterState.dateRange == null ? AppColors.textHint : Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (filterState.dateRange != null)
                              GestureDetector(
                                onTap: () {
                                  filterNotifier.state = filterState.copyWith(dateRange: () => null);
                                },
                                child: const Icon(Icons.close_rounded, color: AppColors.error, size: 18),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Apply Filters Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
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
        },
      );
    },
  );
}
