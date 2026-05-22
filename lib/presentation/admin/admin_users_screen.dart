import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/utils/date_time_extensions.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/profile_service.dart';
import '../../data/models/profile_model.dart';
import '../widgets/common/widgets.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await ProfileService().getAllUsers();
    if (mounted) setState(() { _users = list; _isLoading = false; });
  }

  List<ProfileModel> get _filtered {
    if (_search.isEmpty) return _users;
    final q = _search.toLowerCase();
    return _users.where((u) =>
        (u.name?.toLowerCase().contains(q) ?? false) ||
        (u.email?.toLowerCase().contains(q) ?? false) ||
        (u.phone?.contains(q) ?? false)).toList();
  }

  Future<void> _toggleRole(ProfileModel user) async {
    final newRole = user.isAdmin ? 'user' : 'admin';
    await ProfileService().setUserRole(user.id, newRole);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Role updated to $newRole'),
          backgroundColor: AppColors.success,
        ),
      );
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
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.stars_rounded,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(makeMainAdmin ? 'Promote to Main Admin' : 'Demote Main Admin',
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
              backgroundColor: makeMainAdmin ? AppColors.primary : AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(makeMainAdmin ? 'Promote' : 'Demote', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(makeMainAdmin
                  ? '${user.displayName} is now a Main Administrator'
                  : '${user.displayName} has been demoted'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update: $e'),
              backgroundColor: AppColors.error,
            ),
          );
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
                color: AppColors.error.withOpacity(0.15),
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
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: '? This will delete their account and all profile data permanently. This action cannot be undone.'),
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
            child: Text('Delete', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove user: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              color: AppColors.primaryLight,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Divider(color: AppColors.cardBorder, height: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String? value) {
    final hasValue = value != null && value.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primaryLight, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: AppColors.textHint,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasValue ? value : 'Not Provided',
                  style: GoogleFonts.inter(
                    color: hasValue ? AppColors.textPrimary : AppColors.textHint.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
                    fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(ProfileModel u) {
    showDialog(
      context: context,
      builder: (context) {
        final hasAvatar = u.avatarUrl != null && u.avatarUrl!.isNotEmpty;
        return Dialog(
          backgroundColor: const Color(0xFF0F172A), // Premium dark slate background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.cardBorder, width: 1),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with close button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'User Profile Details',
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: AppColors.textHint),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.cardBorder, height: 1),
                
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar and name header
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: u.isAdmin
                                      ? const LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFF1565C0)])
                                      : AppColors.primaryGradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (u.isAdmin ? const Color(0xFF7B1FA2) : AppColors.primary).withValues(alpha: 0.25),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: u.isAdmin ? const Color(0xFF9C27B0) : AppColors.primaryLight,
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: hasAvatar
                                      ? Image.network(
                                          u.avatarUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Center(
                                            child: Text(
                                              u.initials,
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 28,
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
                                              fontSize: 28,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      u.displayName,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        color: AppColors.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    u.isVerified
                                        ? Icons.verified_rounded
                                        : Icons.gpp_maybe_rounded,
                                    color: u.isVerified
                                        ? const Color(0xFF2196F3)
                                        : const Color(0xFFFFB300),
                                    size: 20,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: u.isMainAdmin
                                      ? const Color(0xFFE53935).withValues(alpha: 0.15)
                                      : (u.isAdmin
                                          ? AppColors.warning.withValues(alpha: 0.15)
                                          : AppColors.primary.withValues(alpha: 0.15)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: u.isMainAdmin
                                        ? const Color(0xFFE53935).withValues(alpha: 0.3)
                                        : (u.isAdmin
                                            ? AppColors.warning.withValues(alpha: 0.3)
                                            : AppColors.primaryLight.withValues(alpha: 0.3)),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  u.isMainAdmin
                                      ? '👑 Main Admin'
                                      : (u.isAdmin ? 'Admin' : 'User Account'),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: u.isMainAdmin
                                        ? const Color(0xFFEF5350)
                                        : (u.isAdmin ? AppColors.warning : AppColors.primaryLight),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        _buildSectionHeader('Registration Info'),
                        _buildDetailRow(
                          Icons.fingerprint_rounded,
                          'USER ID',
                          u.id,
                        ),
                        _buildDetailRow(
                          Icons.calendar_today_rounded,
                          'REGISTRATION DATE & TIME',
                          u.createdAt != null
                              ? u.createdAt!.formatBDT('dd MMMM yyyy, hh:mm:ss a')
                              : 'Not Available',
                        ),
                        
                        _buildSectionHeader('Contact Details'),
                        _buildDetailRow(
                          Icons.email_outlined,
                          'EMAIL ADDRESS',
                          u.email,
                        ),
                        _buildDetailRow(
                          Icons.phone_outlined,
                          'PHONE NUMBER',
                          u.phone,
                        ),
                        
                        _buildSectionHeader('Personal Information'),
                        _buildDetailRow(
                          Icons.badge_outlined,
                          'NATIONAL ID (NID)',
                          u.nid,
                        ),
                        _buildDetailRow(
                          Icons.work_outline_rounded,
                          'PROFESSION',
                          u.profession,
                        ),
                        _buildDetailRow(
                          Icons.location_on_outlined,
                          'PRESENT ADDRESS',
                          u.presentAddress,
                        ),
                        _buildDetailRow(
                          Icons.home_outlined,
                          'PERMANENT ADDRESS',
                          u.permanentAddress,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Divider(color: AppColors.cardBorder, height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Dismiss',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: GoogleFonts.inter(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _filtered.isEmpty
                      ? const EmptyState(
                          icon: Icons.people_outline,
                          title: 'No Users Found',
                          subtitle: 'No users match your search.')
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.primary,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
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
                                            ? const LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFF1565C0)])
                                            : AppColors.primaryGradient,
                                        shape: BoxShape.circle,
                                      ),
                                      child: ClipOval(
                                        child: u.avatarUrl != null && u.avatarUrl!.isNotEmpty
                                            ? Image.network(
                                                u.avatarUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Center(
                                                  child: Text(
                                                    u.initials,
                                                    style: GoogleFonts.inter(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w700,
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
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(u.displayName,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.inter(
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 14,
                                                        color: AppColors.textPrimary)),
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
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: u.isMainAdmin
                                                        ? const Color(0xFFE53935).withOpacity(0.15)
                                                        : AppColors.warning.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: u.isMainAdmin
                                                        ? Border.all(color: const Color(0xFFE53935).withOpacity(0.3), width: 1)
                                                        : null,
                                                  ),
                                                  child: Text(
                                                      u.isMainAdmin ? '👑 Main Admin' : 'Admin',
                                                      style: GoogleFonts.inter(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w700,
                                                          color: u.isMainAdmin
                                                              ? const Color(0xFFE53935)
                                                              : AppColors.warning)),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(u.email ?? u.phone ?? '',
                                              style: GoogleFonts.inter(
                                                  fontSize: 12, color: AppColors.textSecondary)),
                                          if (u.createdAt != null)
                                            Text('Joined ${u.createdAt!.formatBDT('dd MMM yyyy, hh:mm a')}',
                                                style: GoogleFonts.inter(
                                                    fontSize: 11, color: AppColors.textHint)),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      color: AppColors.card,
                                      icon: const Icon(Icons.more_vert, color: AppColors.textHint),
                                      onSelected: (v) {
                                        if (v == 'role') _toggleRole(u);
                                        if (v == 'verify') _toggleVerified(u);
                                        if (v == 'main_admin') _toggleMainAdmin(u);
                                        if (v == 'delete') _deleteUser(u);
                                      },
                                      itemBuilder: (_) {
                                        final currentAdminId = Supabase.instance.client.auth.currentUser?.id;
                                        final currentAdmin = _users.firstWhere((usr) => usr.id == currentAdminId, orElse: () => u);
                                        final isSelf = u.id == currentAdminId;
                                        final isMainAdmin = u.isMainAdmin;
                                        final iAmMainAdmin = currentAdmin.isMainAdmin;
                                        return [
                                          PopupMenuItem(
                                            value: 'role',
                                            enabled: !isSelf && !isMainAdmin, // Prevent self demotion & main admin demotion
                                            child: Text(u.isAdmin ? 'Demote to User' : 'Promote to Admin',
                                                style: GoogleFonts.inter(
                                                    color: (isSelf || isMainAdmin) ? AppColors.textHint : AppColors.textPrimary)),
                                          ),
                                          PopupMenuItem(
                                            value: 'verify',
                                            child: Text(u.isVerified ? 'Unverify' : 'Verify',
                                                style: GoogleFonts.inter(color: AppColors.textPrimary)),
                                          ),
                                          if (iAmMainAdmin && !isSelf) ...[
                                            PopupMenuItem(
                                              value: 'main_admin',
                                              child: Text(u.isMainAdmin ? 'Remove Main Admin' : 'Make Main Admin',
                                                  style: GoogleFonts.inter(color: AppColors.textPrimary)),
                                            ),
                                          ],
                                          if (!isSelf && !isMainAdmin) ...[
                                            const PopupMenuDivider(),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                                                  const SizedBox(width: 8),
                                                  Text('Delete User',
                                                      style: GoogleFonts.inter(color: AppColors.error)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ];
                                      },
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(delay: (i * 40).ms).slideY(begin: 0.1);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
