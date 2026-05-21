import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/admin_sos_provider.dart';
import '../../providers/auth_provider.dart';

class AdminActiveSOSAlertsWidget extends ConsumerWidget {
  const AdminActiveSOSAlertsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEmergenciesAsync = ref.watch(activeEmergenciesStreamProvider);
    final profile = ref.watch(authNotifierProvider).valueOrNull;

    return activeEmergenciesAsync.when(
      data: (emergencies) {
        if (emergencies.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.error,
                  size: 24,
                )
                    .animate(onPlay: (controller) => controller.repeat())
                    .shake(hz: 4, duration: 1.5.seconds)
                    .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 800.ms, curve: Curves.easeInOut),
                const SizedBox(width: 8),
                Text(
                  'CRITICAL: ACTIVE SOS ALERTS (${emergencies.length})',
                  style: GoogleFonts.inter(
                    color: AppColors.error,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...emergencies.map((emergency) {
              final user = emergency.userProfile;
              final lat = emergency.latitude;
              final lng = emergency.longitude;
              final timeString = DateFormat('hh:mm:ss a').format(emergency.createdAt.toLocal());

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFEF4444).withOpacity(0.15),
                      const Color(0xFF7F1D1D).withOpacity(0.08)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withOpacity(0.55),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withOpacity(0.12),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Glowing emergency avatar/icon
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFEF4444).withOpacity(0.2),
                                  ),
                                )
                                    .animate(onPlay: (controller) => controller.repeat())
                                    .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.35, 1.35), duration: 1.5.seconds, curve: Curves.easeOut)
                                    .fadeOut(duration: 1.5.seconds),
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFEF4444),
                                  ),
                                  child: const Icon(
                                    Icons.radar_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            // User Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.name ?? 'Unknown Citizen',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user?.phone ?? user?.email ?? 'No contact info',
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Time Badge
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFEF4444).withOpacity(0.4),
                                    ),
                                  ),
                                  child: Text(
                                    'ACTIVE',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFFFCA5A5),
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  timeString,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Colors.white.withOpacity(0.4),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Coordinates info bar
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.06),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.my_location_rounded,
                                color: Colors.blueAccent,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'GPS: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                                  style: GoogleFonts.robotoMono(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  final uri = Uri.parse(
                                    'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                                  );
                                  if (!await launchUrl(
                                    uri,
                                    mode: LaunchMode.platformDefault,
                                    webOnlyWindowName: '_self',
                                  )) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Could not open map.')),
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.blueAccent.withOpacity(0.3),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.map_rounded,
                                        color: Colors.blueAccent,
                                        size: 11,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Track Live',
                                        style: GoogleFonts.inter(
                                          color: Colors.blueAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Actions
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'A dispatcher has been notified. Dispatch police patrol immediately.',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.55),
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () async {
                                if (profile == null) return;

                                // Show premium confirmation dialog
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: const Color(0xFF1E1E2E),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: const Color(0xFF10B981).withOpacity(0.2),
                                        width: 1.5,
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: Color(0xFF10B981),
                                          size: 24,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Resolve Emergency?',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                    content: Text(
                                      'Are you sure you want to mark this active SOS emergency alert as resolved? This will close the case.',
                                      style: GoogleFonts.inter(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),
                                    actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: Text(
                                          'CANCEL',
                                          style: GoogleFonts.inter(
                                            color: Colors.white.withOpacity(0.5),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF10B981),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        ),
                                        child: Text(
                                          'RESOLVE',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm != true) return;

                                try {
                                  await ref.read(resolveEmergencyProvider)(
                                    emergency.id,
                                    profile.id,
                                  );
                                  
                                  // Force immediate client-side UI update by invalidating the stream provider
                                  ref.invalidate(activeEmergenciesStreamProvider);

                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Emergency resolved successfully.'),
                                      backgroundColor: Color(0xFF10B981),
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to resolve: $e')),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                shadowColor: const Color(0xFF10B981).withOpacity(0.3),
                                elevation: 4,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                              ),
                              label: Text(
                                'RESOLVE',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .shimmer(color: const Color(0xFFFF8A8A).withOpacity(0.18), duration: 2.seconds)
                  .fadeIn(begin: 0.65, duration: 1.seconds, curve: Curves.easeInOut)
                  .animate() // Entrance animation
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1);
            }),
            const SizedBox(height: 16),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, _) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          'Error loading active SOS: $err',
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }
}
