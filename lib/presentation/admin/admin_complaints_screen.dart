import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/complaint_provider.dart';
import '../widgets/common/widgets.dart';

class AdminComplaintsScreen extends ConsumerWidget {
  const AdminComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(selectedStatusFilterProvider);
    final complaintsAsync = ref.watch(filteredComplaintsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('All Cases')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Column(
          children: [
            // Filter chips
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _FilterChip(label: 'All', value: 'all', current: filter, ref: ref),
                  ...AppConstants.complaintStatuses.map(
                    (s) => _FilterChip(
                        label: AppConstants.statusLabel(s),
                        value: s,
                        current: filter,
                        ref: ref),
                  ),
                ],
              ),
            ),
            Expanded(
              child: complaintsAsync.when(
                data: (list) {
                  if (list.isEmpty) {
                    return const EmptyState(
                      icon: Icons.assignment_outlined,
                      title: 'No Cases Found',
                      subtitle: 'No cases match this filter.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final c = list[i];
                      return GlassCard(
                        onTap: () =>
                            context.push('/admin/complaints/${c.id}'),
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
                            const SizedBox(height: 10),
                            Text(c.crimeCategory ?? 'Unknown',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
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
                            const SizedBox(height: 10),
                            const Divider(color: AppColors.cardBorder, height: 1),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.person_outline,
                                    size: 14, color: AppColors.textHint),
                                const SizedBox(width: 4),
                                Text(c.fullName,
                                    style: GoogleFonts.inter(
                                        fontSize: 12, color: AppColors.textHint)),
                                const Spacer(),
                                const Icon(Icons.calendar_today_outlined,
                                    size: 14, color: AppColors.textHint),
                                const SizedBox(width: 4),
                                Text(
                                  c.createdAt != null
                                      ? DateFormat('dd MMM yyyy')
                                          .format(c.createdAt!)
                                      : '',
                                  style: GoogleFonts.inter(
                                      fontSize: 12, color: AppColors.textHint),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: (i * 50).ms).slideY(begin: 0.1);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => Center(
                  child: Text('$e',
                      style: const TextStyle(color: AppColors.error)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final WidgetRef ref;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.current,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final selected = current == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () =>
            ref.read(selectedStatusFilterProvider.notifier).state = value,
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
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.primaryLight
                      : AppColors.textSecondary)),
        ),
      ),
    );
  }
}
