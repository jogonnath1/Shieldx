import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../widgets/common/widgets.dart';

class MyComplaintsScreen extends ConsumerWidget {
  const MyComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final complaintsAsync = user != null
        ? ref.watch(userComplaintsStreamProvider(user.id))
        : const AsyncValue<dynamic>.data([]);

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
        child: complaintsAsync.when(
          data: (list) {
            if (list.isEmpty) {
              return EmptyState(
                icon: Icons.assignment_outlined,
                title: 'No Reports Yet',
                subtitle: 'You haven\'t submitted any crime reports.',
                buttonLabel: 'Submit Report',
                onButton: () => context.push('/submit-complaint'),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
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
                                ? DateFormat('dd MMM yyyy, HH:mm')
                                    .format(c.createdAt!)
                                : 'Unknown date',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppColors.textHint),
                          ),
                          const Spacer(),
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
            child: Text('Error: $e', style: const TextStyle(color: AppColors.error)),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/submit-complaint'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}
