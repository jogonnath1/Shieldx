import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/time_provider.dart';
import '../../../providers/complaint_provider.dart';
import '../../../data/models/activity_log_model.dart';
import '../../../data/models/profile_model.dart';
import 'widgets.dart';
import 'user_profile_dialog.dart';

class CurrentlyActiveUsersList extends ConsumerStatefulWidget {
  final List<ActivityLogModel> logs;
  final bool isVertical;

  const CurrentlyActiveUsersList({required this.logs, required this.isVertical, super.key});

  @override
  ConsumerState<CurrentlyActiveUsersList> createState() => _CurrentlyActiveUsersListState();
}

class _CurrentlyActiveUsersListState extends ConsumerState<CurrentlyActiveUsersList> {
  bool _showAdmins = true;
  int _selectedMinutes = 15;
  String _verificationFilter = 'all';

  Widget _buildFilterChip(String filterType, String label, IconData icon, Color iconColor) {
    final isSelected = _verificationFilter == filterType;
    return GestureDetector(
      onTap: () {
        setState(() {
          _verificationFilter = filterType;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D1224) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B5CF6) : Colors.white.withValues(alpha: 0.05),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 1.5),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? iconColor : iconColor.withValues(alpha: 0.5), size: 12),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(bangladeshTimeProvider);
    final profilesAsync = ref.watch(allProfilesStreamProvider);
    final profiles = profilesAsync.valueOrNull ?? [];
    final profileMap = {for (var p in profiles) p.id: p};

    final now = DateTime.now();
    final Map<String, ActivityLogModel> activeUsersMap = {};
    for (final log in widget.logs) {
      if (log.userId == null || log.userId!.isEmpty) continue;
      final diff = now.toUtc().difference(log.createdAt.toUtc()).inMinutes;
      final ageMinutes = diff < 0 ? 0 : diff;
      if (ageMinutes <= _selectedMinutes) {
        if (!activeUsersMap.containsKey(log.userId)) {
          activeUsersMap[log.userId!] = log;
        }
      }
    }

    final activeUsers = activeUsersMap.entries.toList();

    // Categorize active users into admins and regular users
    final activeAdmins = <MapEntry<String, ActivityLogModel>>[];
    final activeRegularUsers = <MapEntry<String, ActivityLogModel>>[];

    for (final entry in activeUsers) {
      final userId = entry.key;
      final lastLog = entry.value;
      final profile = profileMap[userId];
      final isAdmin = profile != null
          ? (profile.role == 'admin' || profile.isMainAdmin)
          : (lastLog.role == 'admin' || lastLog.role == 'main_admin');
      if (isAdmin) {
        activeAdmins.add(entry);
      } else {
        activeRegularUsers.add(entry);
      }
    }

    final currentRoleActiveUsers = _showAdmins ? activeAdmins : activeRegularUsers;

    final allCount = currentRoleActiveUsers.length;
    final verifiedCount = currentRoleActiveUsers.where((entry) {
      final p = profileMap[entry.key];
      return p?.isVerified ?? false;
    }).length;
    final unverifiedCount = currentRoleActiveUsers.where((entry) {
      final p = profileMap[entry.key];
      return !(p?.isVerified ?? false);
    }).length;

    var displayedUsers = currentRoleActiveUsers;
    if (_verificationFilter == 'verified') {
      displayedUsers = displayedUsers.where((entry) {
        final p = profileMap[entry.key];
        return p?.isVerified ?? false;
      }).toList();
    } else if (_verificationFilter == 'unverified') {
      displayedUsers = displayedUsers.where((entry) {
        final p = profileMap[entry.key];
        return !(p?.isVerified ?? false);
      }).toList();
    }

    Widget contentWidget;

    final String timeLabel = _selectedMinutes == 5
        ? 'right now'
        : _selectedMinutes == 60
            ? 'in the last hour'
            : 'in the last $_selectedMinutes minutes';

    if (displayedUsers.isEmpty) {
      final filterText = _verificationFilter == 'verified'
          ? ' verified'
          : _verificationFilter == 'unverified'
              ? ' unverified'
              : '';
      contentWidget = Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: Text(
            _showAdmins
                ? 'No$filterText admins active online $timeLabel.'
                : 'No$filterText users active online $timeLabel.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textHint,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    } else if (widget.isVertical) {
      contentWidget = ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: displayedUsers.length > 5 ? 5 : displayedUsers.length,
        separatorBuilder: (context, index) => Divider(color: AppColors.cardBorder.withOpacity(0.3), height: 12),
        itemBuilder: (context, index) {
          final entry = displayedUsers[index];
          final userId = entry.key;
          final lastLog = entry.value;
          final profile = profileMap[userId];
          
          final name = profile?.name ?? lastLog.userName ?? 'User';
          final isVerified = profile?.isVerified ?? false;
          final role = profile != null
              ? (profile.isMainAdmin ? 'main_admin' : profile.role)
              : lastLog.role;
          final diff = now.toUtc().difference(lastLog.createdAt.toUtc()).inMinutes;
          final ageMinutes = diff < 0 ? 0 : diff;
          
          final dotColor = ageMinutes <= 2
              ? const Color(0xFF00E676) // Neon Green
              : ageMinutes <= 5
                  ? const Color(0xFF059669) // Emerald Green
                  : const Color(0xFFFFB300); // Amber
          final pulseDurationMs = ageMinutes <= 2
              ? 600
              : ageMinutes <= 5
                  ? 1400
                  : 0;

          final resolvedProfile = profile ?? ProfileModel(
            id: userId,
            name: lastLog.userName,
            email: lastLog.userEmail,
            role: lastLog.role == 'main_admin' ? 'admin' : lastLog.role,
            isMainAdmin: lastLog.role == 'main_admin',
          );

          return GestureDetector(
            onTap: () => UserProfileDialog.show(context, resolvedProfile),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: role == 'main_admin'
                                ? [const Color(0xFFFFB300), const Color(0xFFFF9100)]
                                : role == 'admin'
                                    ? [const Color(0xFFC084FC), const Color(0xFF8B5CF6)]
                                    : [const Color(0xFF2979FF), const Color(0xFF00E5FF)],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            profile?.initials ?? lastLog.userName?[0].toUpperCase() ?? 'U',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Builder(
                              builder: (context) {
                                Widget dot = Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: dotColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: dotColor.withOpacity(0.5),
                                        blurRadius: 4,
                                        spreadRadius: 0.5,
                                      ),
                                    ],
                                  ),
                                );
                                if (pulseDurationMs > 0) {
                                  dot = dot
                                      .animate(onPlay: (c) => c.repeat(reverse: true))
                                      .scale(
                                        begin: const Offset(0.8, 0.8),
                                        end: const Offset(1.25, 1.25),
                                        delay: (index * 120).ms,
                                        duration: pulseDurationMs.ms,
                                      );
                                }
                                return dot;
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified_rounded,
                                size: 12,
                                color: Color(0xFF2979FF),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              role.toUpperCase().replaceAll('_', ' '),
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: role == 'main_admin'
                                    ? const Color(0xFFFFB300)
                                    : role == 'admin'
                                        ? const Color(0xFFC084FC)
                                        : const Color(0xFF00E676),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: AppColors.textHint.withOpacity(0.4),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                lastLog.actionDescription,
                                style: GoogleFonts.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary.withOpacity(0.8),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    ageMinutes == 0 ? 'Active now' : '$ageMinutes m ago',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      contentWidget = SizedBox(
        height: 54,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: displayedUsers.length,
          itemBuilder: (context, index) {
            final entry = displayedUsers[index];
            final userId = entry.key;
            final lastLog = entry.value;
            final profile = profileMap[userId];
            
            final name = profile?.name ?? lastLog.userName ?? 'User';
            final isVerified = profile?.isVerified ?? false;
            final role = profile != null
                ? (profile.isMainAdmin ? 'main_admin' : profile.role)
                : lastLog.role;
            final diff = now.toUtc().difference(lastLog.createdAt.toUtc()).inMinutes;
            final ageMinutes = diff < 0 ? 0 : diff;
            
            final dotColor = ageMinutes <= 2
                ? const Color(0xFF00E676)
                : ageMinutes <= 5
                    ? const Color(0xFF059669)
                    : const Color(0xFFFFB300);
            final pulseDurationMs = ageMinutes <= 2
                ? 600
                : ageMinutes <= 5
                    ? 1400
                    : 0;

            final resolvedProfile = profile ?? ProfileModel(
              id: userId,
              name: lastLog.userName,
              email: lastLog.userEmail,
              role: lastLog.role == 'main_admin' ? 'admin' : lastLog.role,
              isMainAdmin: lastLog.role == 'main_admin',
            );

            return GestureDetector(
              onTap: () => UserProfileDialog.show(context, resolvedProfile),
              behavior: HitTestBehavior.opaque,
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: role == 'main_admin'
                                  ? [const Color(0xFFFFB300), const Color(0xFFFF9100)]
                                  : role == 'admin'
                                      ? [const Color(0xFFC084FC), const Color(0xFF8B5CF6)]
                                      : [const Color(0xFF2979FF), const Color(0xFF00E5FF)],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              profile?.initials ?? lastLog.userName?[0].toUpperCase() ?? 'U',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Builder(
                                builder: (context) {
                                  Widget dot = Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: dotColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: dotColor.withOpacity(0.5),
                                          blurRadius: 3,
                                          spreadRadius: 0.5,
                                        ),
                                      ],
                                    ),
                                  );
                                  if (pulseDurationMs > 0) {
                                    dot = dot
                                        .animate(onPlay: (c) => c.repeat(reverse: true))
                                        .scale(
                                          begin: const Offset(0.8, 0.8),
                                          end: const Offset(1.25, 1.25),
                                          delay: (index * 120).ms,
                                          duration: pulseDurationMs.ms,
                                        );
                                  }
                                  return dot;
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified_rounded,
                                size: 10,
                                color: Color(0xFF2979FF),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 1),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ageMinutes == 0 ? 'Active now' : '$ageMinutes m ago',
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                color: AppColors.textHint,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 2,
                              height: 2,
                              decoration: BoxDecoration(
                                color: AppColors.textHint.withOpacity(0.4),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 80),
                              child: Text(
                                lastLog.actionDescription,
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  color: AppColors.textSecondary.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF00E676),
                  shape: BoxShape.circle,
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.4, 1.4), duration: 1000.ms)
               .boxShadow(end: const BoxShadow(color: Color(0xFF00E676), blurRadius: 4)),
              const SizedBox(width: 8),
              Text(
                'Active Users Online (${displayedUsers.length})',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [5, 15, 30, 60].map((mins) {
                    final isSelected = _selectedMinutes == mins;
                    final label = mins == 5
                        ? 'Now online'
                        : mins == 15
                            ? '15m'
                            : mins == 30
                                ? '30m'
                                : '1h';
                    return GestureDetector(
                      onTap: () => setState(() => _selectedMinutes = mins),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [Color(0xFF7C3AED), Color(0xFF2979FF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.textHint,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Segmented Control Switch (Premium sliding flush style)
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1224),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double width = constraints.maxWidth;
                  final double tabWidth = width / 2;
                  return Stack(
                    children: [
                      // Animated sliding gradient indicator (perfectly flush)
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOutCubic,
                        alignment: _showAdmins
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Container(
                          width: tabWidth,
                          height: 40,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF8B5CF6), // Vibrant Purple
                                Color(0xFF2563EB), // Electric Blue
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ),
                      // Text Labels row on top
                      Positioned.fill(
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  setState(() {
                                    _showAdmins = true;
                                  });
                                },
                                child: Center(
                                  child: Text(
                                    'Admins (${activeAdmins.length})',
                                    style: GoogleFonts.inter(
                                      color: _showAdmins ? Colors.white : Colors.white.withValues(alpha: 0.5),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  setState(() {
                                    _showAdmins = false;
                                  });
                                },
                                child: Center(
                                  child: Text(
                                    'Users (${activeRegularUsers.length})',
                                    style: GoogleFonts.inter(
                                      color: !_showAdmins ? Colors.white : Colors.white.withValues(alpha: 0.5),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Verification Filters Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'All ($allCount)', Icons.layers_rounded, Colors.white),
                const SizedBox(width: 8),
                _buildFilterChip('verified', 'Verified ($verifiedCount)', Icons.verified_rounded, const Color(0xFF2196F3)),
                const SizedBox(width: 8),
                _buildFilterChip('unverified', 'Unverified ($unverifiedCount)', Icons.gpp_maybe_rounded, const Color(0xFFFFB300)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          contentWidget,
        ],
      ),
    );
  }
}
