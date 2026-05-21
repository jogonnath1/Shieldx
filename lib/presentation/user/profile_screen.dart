import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/profile_service.dart';
import '../../providers/auth_provider.dart';
import '../widgets/common/widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploading = false;

  Future<void> _pickAndUploadAvatar(String userId, String? currentAvatarUrl) async {
    if (_isUploading) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final bytes = await pickedFile.readAsBytes();
      final storageService = StorageService();
      final downloadUrl = await storageService.uploadAvatarBytes(
        bytes: bytes,
        userId: userId,
        fileName: pickedFile.name,
      );

      final profileService = ProfileService();
      await profileService.updateProfile(userId, {'avatar_url': downloadUrl});

      // Delete the old file from Supabase storage if it exists
      if (currentAvatarUrl != null && currentAvatarUrl.isNotEmpty) {
        try {
          final uri = Uri.parse(currentAvatarUrl);
          final pathSegments = uri.pathSegments;
          final bucketIndex = pathSegments.indexOf('avatars');
          if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
            final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
            await storageService.deleteFile('avatars', filePath);
          }
        } catch (e) {
          debugPrint('Failed to delete old physical avatar file: $e');
        }
      }

      // Refresh Auth State so UI updates immediately
      await ref.read(authNotifierProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload profile picture: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _deleteAvatar(String userId, String? currentAvatarUrl) async {
    if (_isUploading) return;

    setState(() => _isUploading = true);

    try {
      final profileService = ProfileService();
      await profileService.updateProfile(userId, {'avatar_url': null});

      if (currentAvatarUrl != null && currentAvatarUrl.isNotEmpty) {
        try {
          final storageService = StorageService();
          final uri = Uri.parse(currentAvatarUrl);
          final pathSegments = uri.pathSegments;
          final bucketIndex = pathSegments.indexOf('avatars');
          if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
            final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
            await storageService.deleteFile('avatars', filePath);
          }
        } catch (e) {
          debugPrint('Failed to delete physical avatar file: $e');
        }
      }

      // Refresh Auth State so UI updates immediately
      await ref.read(authNotifierProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture deleted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete profile picture: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showAvatarOptions(BuildContext context, dynamic profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final hasAvatar = profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty;
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Profile Photo',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: AppColors.primaryLight),
                ),
                title: Text(
                  'Upload New Photo',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadAvatar(profile.id, profile.avatarUrl);
                },
              ),
              if (hasAvatar) ...[
                const Divider(color: Colors.white10),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  ),
                  title: Text(
                    'Delete Current Photo',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteAvatar(profile.id, profile.avatarUrl);
                  },
                ),
              ],
              const Divider(color: Colors.white10),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white70),
                ),
                title: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authNotifierProvider).valueOrNull;
    if (profile == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textPrimary),
                      onPressed: () => context.go('/home'),
                    ),
                    Expanded(
                      child: Text('Profile',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                          textAlign: TextAlign.center),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 24),

                // Avatar
                GestureDetector(
                  onTap: () => _showAvatarOptions(context, profile),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: ClipOval(
                          child: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                              ? Image.network(
                                  profile.avatarUrl!,
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Center(
                                    child: Text(profile.initials,
                                        style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 32,
                                            fontWeight: FontWeight.w800)),
                                  ),
                                )
                              : Center(
                                  child: Text(profile.initials,
                                      style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.w800)),
                                ),
                        ),
                      ),
                      if (_isUploading)
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          ),
                        )
                      else
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                )
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                const SizedBox(height: 14),
                Text(profile.displayName,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: (profile.isAdmin ? AppColors.warning : AppColors.primary)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: (profile.isAdmin ? AppColors.warning : AppColors.primaryLight).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(profile.isAdmin ? '👑 Admin' : '👤 User',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: profile.isAdmin ? AppColors.warning : AppColors.primaryLight)),
                    ),
                    const SizedBox(width: 8),
                    _buildVerificationBadge(profile.isVerified, compact: false),
                  ],
                ).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 28),

                // Info cards
                GlassCard(
                  child: Column(
                    children: [
                      if (profile.email != null)
                        InfoTile(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: profile.email!,
                          iconColor: AppColors.primary,
                        ),
                      if (profile.phone != null)
                        InfoTile(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: profile.phone!,
                          iconColor: AppColors.accent,
                        ),
                      if (profile.profession != null)
                        InfoTile(
                          icon: Icons.work_outline,
                          label: 'Profession',
                          value: profile.profession!,
                          iconColor: AppColors.warning,
                        ),
                      if (profile.presentAddress != null)
                        InfoTile(
                          icon: Icons.location_on_outlined,
                          label: 'Present Address',
                          value: profile.presentAddress!,
                          iconColor: AppColors.error,
                        ),
                      if (profile.createdAt != null)
                        InfoTile(
                          icon: Icons.calendar_today_outlined,
                          label: 'Member Since',
                          value: DateFormat('dd MMM yyyy, hh:mm a').format(profile.createdAt!),
                          iconColor: AppColors.textHint,
                        ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                const SizedBox(height: 16),

                // Actions
                _ProfileAction(
                  icon: Icons.edit_outlined,
                  label: 'Edit Profile',
                  onTap: () => context.push('/edit-profile'),
                ).animate().fadeIn(delay: 250.ms),
                const SizedBox(height: 10),
                _ProfileAction(
                  icon: Icons.lock_outline,
                  label: 'Change Password',
                  onTap: () => context.push('/change-password'),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 10),
                _ProfileAction(
                  icon: Icons.folder_open_rounded,
                  label: 'My Reports',
                  onTap: () => context.go('/my-complaints'),
                ).animate().fadeIn(delay: 350.ms),
                const SizedBox(height: 10),
                _ProfileAction(
                  icon: Icons.delete_outline_rounded,
                  label: 'Recycle Bin',
                  onTap: () => context.push('/recycle-bin'),
                ).animate().fadeIn(delay: 380.ms),
                const SizedBox(height: 10),
                _ProfileAction(
                  icon: Icons.logout_rounded,
                  label: 'Sign Out',
                  color: AppColors.error,
                  onTap: () => _showLogoutDialog(context, ref),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBadge(bool isVerified, {bool compact = false}) {
    final icon = isVerified ? Icons.verified_rounded : Icons.gpp_maybe_rounded;
    final color = isVerified ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final bgColor = isVerified 
        ? const Color(0xFF047857).withOpacity(0.15) 
        : const Color(0xFFB45309).withOpacity(0.15);
    final borderColor = isVerified 
        ? const Color(0xFF10B981).withOpacity(0.3) 
        : const Color(0xFFF59E0B).withOpacity(0.3);
    final label = isVerified ? 'Verified' : 'Unverified';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12, 
        vertical: compact ? 3 : 5
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 6,
            spreadRadius: 1,
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon, 
            color: color, 
            size: compact ? 13 : 15
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ProfileAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: c, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, fontSize: 15, color: c)),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: c.withOpacity(0.5)),
        ],
      ),
    );
  }
}
