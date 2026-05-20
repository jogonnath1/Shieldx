import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/connectivity_provider.dart';

class GlobalOfflineBanner extends ConsumerStatefulWidget {
  const GlobalOfflineBanner({super.key});

  @override
  ConsumerState<GlobalOfflineBanner> createState() => _GlobalOfflineBannerState();
}

class _GlobalOfflineBannerState extends ConsumerState<GlobalOfflineBanner> {
  bool _wasOffline = false;
  bool _showSuccessSync = false;
  Timer? _dismissTimer;

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(connectivityProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    if (!isOnline && !_wasOffline) {
      _wasOffline = true;
    }

    if (isOnline && _wasOffline) {
      _wasOffline = false;
      _showSuccessSync = true;
      _dismissTimer?.cancel();
      _dismissTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _showSuccessSync = false;
          });
        }
      });
    }

    if (!isOnline) {
      return Positioned(
        top: topPadding + 12,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF3B30).withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.wifi_off_rounded,
                        color: Color(0xFFFF453A),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Offline Cache Mode Active',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'ShieldX is running offline. Reports will sync when connection restores.',
                            style: TextStyle(
                              color: Color(0xFFE5E5EA),
                              fontSize: 11,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).animate().slideY(begin: -1.2, end: 0, duration: 400.ms, curve: Curves.easeOutBack).fadeIn(),
      );
    }

    if (_showSuccessSync) {
      return Positioned(
        top: topPadding + 12,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF34C759).withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34C759).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_done_rounded,
                        color: Color(0xFF30D158),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Connection Restored',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'You are back online. Offline submissions synced successfully!',
                            style: TextStyle(
                              color: Color(0xFFE5E5EA),
                              fontSize: 11,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).animate().slideY(begin: -1.2, end: 0, duration: 400.ms, curve: Curves.easeOutBack).fadeIn().then(delay: 3200.ms).fadeOut(duration: 400.ms),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }
}
