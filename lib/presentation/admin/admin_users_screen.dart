import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/profile_service.dart';
import '../../data/models/profile_model.dart';
import '../widgets/common/widgets.dart';

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

  Future<void> _toggleVerified(ProfileModel user) async {
    await ProfileService().setVerified(user.id, !user.isVerified);
    await _load();
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
                                      child: Center(
                                        child: Text(u.initials,
                                            style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 18)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(u.displayName,
                                                    style: GoogleFonts.inter(
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 14,
                                                        color: AppColors.textPrimary)),
                                              ),
                                              if (u.isAdmin)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.warning.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text('Admin',
                                                      style: GoogleFonts.inter(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w700,
                                                          color: AppColors.warning)),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(u.email ?? u.phone ?? '',
                                              style: GoogleFonts.inter(
                                                  fontSize: 12, color: AppColors.textSecondary)),
                                          if (u.createdAt != null)
                                            Text('Joined ${DateFormat('dd MMM yyyy, hh:mm a').format(u.createdAt!)}',
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
                                      },
                                      itemBuilder: (_) => [
                                        PopupMenuItem(
                                          value: 'role',
                                          child: Text(u.isAdmin ? 'Demote to User' : 'Promote to Admin',
                                              style: GoogleFonts.inter(color: AppColors.textPrimary)),
                                        ),
                                        PopupMenuItem(
                                          value: 'verify',
                                          child: Text(u.isVerified ? 'Unverify' : 'Verify',
                                              style: GoogleFonts.inter(color: AppColors.textPrimary)),
                                        ),
                                      ],
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
