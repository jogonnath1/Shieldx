import 'package:flutter/material.dart';
import 'package:shieldx/common/core/utils/app_snackbar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shieldx/common/core/utils/date_time_extensions.dart';
import 'package:shieldx/common/core/constants/app_colors.dart';
import 'package:shieldx/common/data/services/profile_service.dart';
import 'package:shieldx/common/data/models/profile_model.dart';
import 'package:shieldx/common/presentation/widgets/common/widgets.dart';
import 'package:shieldx/common/presentation/widgets/common/user_profile_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  List<ProfileModel> _users = [];
  bool _isLoading = true;
  String _search = '';
  bool _viewingAdmins = true;
  String _verificationFilter = 'all';
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await ProfileService().getAllUsers();
    if (mounted) {
      setState(() {
        _users = list;
        _isLoading = false;
      });
    }
  }

  List<ProfileModel> get _filtered {
    var list = _users.where((u) {
      final isUserAdmin = u.isAdmin || u.isMainAdmin;
      return _viewingAdmins ? isUserAdmin : !isUserAdmin;
    }).toList();
    if (_verificationFilter == 'verified') {
      list = list.where((u) => u.isVerified && !u.isBlocked).toList();
    } else if (_verificationFilter == 'unverified') {
      list = list.where((u) => !u.isVerified && !u.isBlocked).toList();
    } else if (_verificationFilter == 'blocked') {
      list = list.where((u) => u.isBlocked).toList();
    }
    if (_search.isEmpty) return list;
    final q = _search.toLowerCase();
    return list
        .where((u) =>
            (u.name?.toLowerCase().contains(q) ?? false) ||
            (u.email?.toLowerCase().contains(q) ?? false) ||
            (u.phone?.contains(q) ?? false))
        .toList();
  }

  Future<void> _toggleRole(ProfileModel user) async {
    final newRole = user.isAdmin ? 'user' : 'admin';
    await ProfileService().setUserRole(user.id, newRole);
    await _load();
    if (mounted) {
      AppSnackbar.success(context, 'Role updated to $newRole');
    }
  }

  Future<void> _toggleMainAdmin(ProfileModel user) async {
    final makeMainAdmin = !user.isMainAdmin;
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
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.stars_rounded,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                  makeMainAdmin ? 'Promote to Main Admin' : 'Demote Main Admin',
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
            ),
          ],
        ),
        content: Text(
          makeMainAdmin
              ? 'Are you sure you want to promote ${user.displayName} to Main Administrator? They will get full controls, including the ability to manage other administrators.'
              : 'Are you sure you want to demote ${user.displayName} from Main Administrator role?',
          style: GoogleFonts.inter(
              color: AppColors.textSecondary, fontSize: 14, height: 1.5),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.cardBorder),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  makeMainAdmin ? AppColors.primary : AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(makeMainAdmin ? 'Promote' : 'Demote',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);
        await ProfileService().setMainAdmin(user.id, makeMainAdmin);
        await _load();
        if (mounted) {
          AppSnackbar.success(
              context,
              makeMainAdmin
                  ? '${user.displayName} is now a Main Administrator'
                  : '${user.displayName} has been demoted');
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          AppSnackbar.error(context, 'Failed to update: $e');
        }
      }
    }
  }

  Future<void> _toggleVerified(ProfileModel user) async {
    await ProfileService().setVerified(user.id, !user.isVerified);
    await _load();
  }

  Future<void> _deleteUser(ProfileModel user) async {
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
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_remove_rounded,
                  color: AppColors.error, size: 22),
            ),
            const SizedBox(width: 12),
            Text('Remove User',
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
                  text: 'Are you sure you want to permanently remove '),
              TextSpan(
                text: user.displayName,
                style: GoogleFonts.inter(
                    color: AppColors.primaryLight, fontWeight: FontWeight.w700),
              ),
              const TextSpan(
                  text:
                      '? This will delete their account and all profile data permanently. This action cannot be undone.'),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text('Delete',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);
        await ProfileService().deleteUser(user.id);
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User removed successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          AppSnackbar.error(context, 'Failed to remove user: $e');
        }
      }
    }
  }

  Future<void> _toggleBlock(ProfileModel user) async {
    final block = !user.isBlocked;
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
                color: (block ? AppColors.error : AppColors.success)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                block
                    ? Icons.block_flipped
                    : Icons.check_circle_outline_rounded,
                color: block ? AppColors.error : AppColors.success,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(block ? 'Block User' : 'Unblock User',
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 17)),
          ],
        ),
        content: Text(
          block
              ? 'Are you sure you want to block ${user.displayName}? They will be immediately locked out of their account and will not be able to log in or use the application.'
              : 'Are you sure you want to unblock ${user.displayName}? They will be able to log in and access the application again.',
          style: GoogleFonts.inter(
              color: AppColors.textSecondary, fontSize: 14, height: 1.5),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.cardBorder),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: block ? AppColors.error : AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(block ? 'Block' : 'Unblock',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);
        await ProfileService().setBlocked(user.id, block);
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${user.displayName} has been successfully ${block ? 'blocked' : 'unblocked'}.'),
              backgroundColor: block ? AppColors.error : AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          AppSnackbar.error(
              context, 'Failed to ${block ? 'block' : 'unblock'} user: $e');
        }
      }
    }
  }

  void _showUserDetails(ProfileModel u) {
    UserProfileDialog.show(context, u);
  }

  Widget _buildRoleSegmentedControl() {
    final adminCount = _users.where((u) => u.isAdmin || u.isMainAdmin).length;
    final userCount = _users.where((u) => !u.isAdmin && !u.isMainAdmin).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFF0D1224),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final double tabWidth = width / 2;
              return Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOutCubic,
                    alignment: _viewingAdmins
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Container(
                      width: tabWidth,
                      height: 46,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF8B5CF6),
                            Color(0xFF2563EB),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              setState(() {
                                _viewingAdmins = true;
                              });
                            },
                            child: Center(
                              child: Text(
                                'Admins ($adminCount)',
                                style: GoogleFonts.inter(
                                  color: _viewingAdmins
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
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
                                _viewingAdmins = false;
                              });
                            },
                            child: Center(
                              child: Text(
                                'Users ($userCount)',
                                style: GoogleFonts.inter(
                                  color: !_viewingAdmins
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
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
    );
  }

  Widget _buildVerificationFilterRow() {
    final currentRoleUsers = _users.where((u) {
      final isUserAdmin = u.isAdmin || u.isMainAdmin;
      return _viewingAdmins ? isUserAdmin : !isUserAdmin;
    }).toList();
    final allCount = currentRoleUsers.length;
    final verifiedCount =
        currentRoleUsers.where((u) => u.isVerified && !u.isBlocked).length;
    final unverifiedCount =
        currentRoleUsers.where((u) => !u.isVerified && !u.isBlocked).length;
    final blockedCount = currentRoleUsers.where((u) => u.isBlocked).length;
    Widget buildFilterChip(
        String filterType, String label, IconData icon, Color iconColor) {
      final isSelected = _verificationFilter == filterType;
      return GestureDetector(
        onTap: () {
          setState(() {
            _verificationFilter = filterType;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0D1224) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF8B5CF6)
                  : Colors.white.withValues(alpha: 0.05),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color:
                      isSelected ? iconColor : iconColor.withValues(alpha: 0.5),
                  size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            buildFilterChip(
                'all', 'All ($allCount)', Icons.layers_rounded, Colors.white),
            const SizedBox(width: 8),
            buildFilterChip('verified', 'Verified ($verifiedCount)',
                Icons.verified_rounded, const Color(0xFF2196F3)),
            const SizedBox(width: 8),
            buildFilterChip('unverified', 'Unverified ($unverifiedCount)',
                Icons.gpp_maybe_rounded, const Color(0xFFFFB300)),
            const SizedBox(width: 8),
            buildFilterChip('blocked', 'Blocked ($blockedCount)',
                Icons.block_flipped, const Color(0xFFEF4444)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style: GoogleFonts.inter(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon:
                          const Icon(Icons.search, color: AppColors.textHint),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF2563EB)],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'All User List',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildRoleSegmentedControl(),
                _buildVerificationFilterRow(),
                _isLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary)),
                      )
                    : _filtered.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: EmptyState(
                                icon: Icons.people_outline,
                                title: 'No Users Found',
                                subtitle: 'No users match your search.'),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (ctx, i) {
                              final u = _filtered[i];
                              return GlassCard(
                                onTap: () => _showUserDetails(u),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: u.isAdmin
                                            ? const LinearGradient(colors: [
                                                Color(0xFF7B1FA2),
                                                Color(0xFF1565C0)
                                              ])
                                            : AppColors.primaryGradient,
                                        shape: BoxShape.circle,
                                      ),
                                      child: ClipOval(
                                        child: u.avatarUrl != null &&
                                                u.avatarUrl!.isNotEmpty
                                            ? Image.network(
                                                u.avatarUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    Center(
                                                  child: Text(
                                                    u.initials,
                                                    style: GoogleFonts.inter(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 18,
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
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(u.displayName,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: GoogleFonts.inter(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 14,
                                                        color: AppColors
                                                            .textPrimary)),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                u.isVerified
                                                    ? Icons.verified_rounded
                                                    : Icons.gpp_maybe_rounded,
                                                color: u.isVerified
                                                    ? const Color(0xFF2196F3)
                                                    : const Color(0xFFFFB300),
                                                size: 16,
                                              ),
                                              const SizedBox(width: 8),
                                              if (u.isAdmin || u.isMainAdmin)
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: u.isMainAdmin
                                                        ? const Color(
                                                                0xFFE53935)
                                                            .withValues(
                                                                alpha: 0.15)
                                                        : AppColors.warning
                                                            .withValues(
                                                                alpha: 0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    border: u.isMainAdmin
                                                        ? Border.all(
                                                            color: const Color(
                                                                    0xFFE53935)
                                                                .withValues(
                                                                    alpha: 0.3),
                                                            width: 1)
                                                        : null,
                                                  ),
                                                  child: Text(
                                                      u.isMainAdmin
                                                          ? '👑 Main Admin'
                                                          : 'Admin',
                                                      style: GoogleFonts.inter(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: u.isMainAdmin
                                                              ? const Color(
                                                                  0xFFE53935)
                                                              : AppColors
                                                                  .warning)),
                                                ),
                                              if (u.isBlocked) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.error
                                                        .withValues(
                                                            alpha: 0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    border: Border.all(
                                                        color: AppColors.error
                                                            .withValues(
                                                                alpha: 0.3),
                                                        width: 1),
                                                  ),
                                                  child: Text(
                                                    '🚫 Blocked',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: AppColors.error,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(u.email ?? u.phone ?? '',
                                              style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textSecondary)),
                                          if (u.createdAt != null)
                                            Text(
                                                'Joined ${u.createdAt!.formatBDT('dd MMM yyyy, hh:mm a')}',
                                                style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    color: AppColors.textHint)),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      color: AppColors.card,
                                      icon: const Icon(Icons.more_vert,
                                          color: AppColors.textHint),
                                      onSelected: (v) {
                                        if (v == 'role') _toggleRole(u);
                                        if (v == 'verify') _toggleVerified(u);
                                        if (v == 'main_admin') {
                                          _toggleMainAdmin(u);
                                        }
                                        if (v == 'block') _toggleBlock(u);
                                        if (v == 'delete') _deleteUser(u);
                                      },
                                      itemBuilder: (_) {
                                        final currentAdminId = Supabase.instance
                                            .client.auth.currentUser?.id;
                                        final currentAdmin = _users.firstWhere(
                                            (usr) => usr.id == currentAdminId,
                                            orElse: () => u);
                                        final isSelf = u.id == currentAdminId;
                                        final isMainAdmin = u.isMainAdmin;
                                        final iAmMainAdmin =
                                            currentAdmin.isMainAdmin;
                                        return [
                                          PopupMenuItem(
                                            value: 'role',
                                            enabled: !isSelf && !isMainAdmin,
                                            child: Text(
                                                u.isAdmin
                                                    ? 'Demote to User'
                                                    : 'Promote to Admin',
                                                style: GoogleFonts.inter(
                                                    color:
                                                        (isSelf || isMainAdmin)
                                                            ? AppColors.textHint
                                                            : AppColors
                                                                .textPrimary)),
                                          ),
                                          PopupMenuItem(
                                            value: 'verify',
                                            child: Text(
                                                u.isVerified
                                                    ? 'Unverify'
                                                    : 'Verify',
                                                style: GoogleFonts.inter(
                                                    color:
                                                        AppColors.textPrimary)),
                                          ),
                                          if (iAmMainAdmin && !isSelf) ...[
                                            PopupMenuItem(
                                              value: 'main_admin',
                                              child: Text(
                                                  u.isMainAdmin
                                                      ? 'Remove Main Admin'
                                                      : 'Make Main Admin',
                                                  style: GoogleFonts.inter(
                                                      color: AppColors
                                                          .textPrimary)),
                                            ),
                                          ],
                                          if (!isSelf && !isMainAdmin) ...[
                                            PopupMenuItem(
                                              value: 'block',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    u.isBlocked
                                                        ? Icons
                                                            .check_circle_outline_rounded
                                                        : Icons.block_flipped,
                                                    color: u.isBlocked
                                                        ? AppColors.success
                                                        : AppColors.error,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    u.isBlocked
                                                        ? 'Unblock User'
                                                        : 'Block User',
                                                    style: GoogleFonts.inter(
                                                      color: u.isBlocked
                                                          ? AppColors.success
                                                          : AppColors.error,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuDivider(),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                      Icons
                                                          .delete_outline_rounded,
                                                      color: AppColors.error,
                                                      size: 18),
                                                  const SizedBox(width: 8),
                                                  Text('Delete User',
                                                      style: GoogleFonts.inter(
                                                          color:
                                                              AppColors.error)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ];
                                      },
                                    ),
                                  ],
                                ),
                              )
                                  .animate()
                                  .fadeIn(delay: (i * 40).ms)
                                  .slideY(begin: 0.1);
                            },
                          ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
