import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/sos_provider.dart';

class SOSButtonSheet extends ConsumerWidget {
  const SOSButtonSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sosState = ref.watch(sosNotifierProvider);
    final sosNotifier = ref.read(sosNotifierProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Premium sleek dark blue-grey
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: Color(0xFF334155), width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF475569),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          if (sosState.status == SOSStatus.idle || sosState.status == SOSStatus.error) ...[
            Text(
              'EMERGENCY SOS',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Holding this button triggers a direct high-priority alert to the nearest station and begins broadcasting your live coordinates.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF94A3B8),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 36),

            // Pulsing emergency button
            GestureDetector(
              onTap: () => sosNotifier.startSOS(),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glowing rings
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withOpacity(0.12),
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.3, 1.3), duration: 1.8.seconds, curve: Curves.easeOut)
                      .fadeOut(duration: 1.8.seconds),
                  
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withOpacity(0.2),
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.15, 1.15), duration: 1.2.seconds, curve: Curves.easeOut)
                      .fadeOut(duration: 1.2.seconds),

                  // Main Crimson button
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFF991B1B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.55),
                          blurRadius: 30,
                          spreadRadius: 5,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'SOS',
                        style: GoogleFonts.inter(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .scale(begin: const Offset(0.96, 0.96), end: const Offset(1.04, 1.04), duration: 800.ms, curve: Curves.easeInOutSine),
                ],
              ),
            ),
            const SizedBox(height: 36),

            if (sosState.status == SOSStatus.error)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    sosState.errorMessage ?? 'An error occurred.',
                    style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ] else if (sosState.status == SOSStatus.countingDown) ...[
            Text(
              'ACTIVATING SOS IN',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFEF4444),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // Giant animated countdown circle
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.1),
                border: Border.all(color: Colors.red.withOpacity(0.4), width: 3),
              ),
              child: Center(
                child: Text(
                  '${sosState.countdown}',
                  style: GoogleFonts.inter(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                )
                    .animate(key: ValueKey(sosState.countdown))
                    .scale(begin: const Offset(0.4, 0.4), end: const Offset(1.1, 1.1), duration: 300.ms, curve: Curves.bounceOut)
                    .animate(delay: 700.ms)
                    .fadeOut(duration: 250.ms),
              ),
            ),
            const SizedBox(height: 32),

            // Sleek flat button to cancel immediately
            OutlinedButton(
              onPressed: () => sosNotifier.cancelSOSCountdown(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF475569), width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'CANCEL ALARM',
                style: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ),
          ] else if (sosState.status == SOSStatus.active) ...[
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEF4444),
              ),
              child: const Icon(Icons.radar_rounded, color: Colors.white, size: 28),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .shake(hz: 8, duration: 1.2.seconds)
                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.15, 1.15), curve: Curves.easeInOut, duration: 800.ms),
            const SizedBox(height: 16),
            Text(
              'SOS BROADCAST ACTIVE',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFEF4444),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Continuous high-accuracy location tracking is currently broadcasting to the emergency dispatch desk.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF94A3B8),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Live coordinates display
            if (sosState.currentLatitude != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.my_location_rounded, color: Colors.blueAccent, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      'GPS: ${sosState.currentLatitude!.toStringAsFixed(5)}, ${sosState.currentLongitude!.toStringAsFixed(5)}',
                      style: GoogleFonts.robotoMono(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ).animate().fadeIn(),
            const SizedBox(height: 32),

            // Big, premium "I AM SAFE" button
            ElevatedButton(
              onPressed: () {
                sosNotifier.markSafe();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981), // Emerald green
                shadowColor: const Color(0xFF10B981).withOpacity(0.4),
                elevation: 10,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Text(
                'I AM SAFE • END ALARM',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
