import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../data/models/police_station_model.dart';

/// Maps a thana key to the display name shown in the dropdown.
String? thanaToStationName(String? thana) {
  const map = {
    thanaKotwali:    'Kotwali Model Police Station',
    thanaJalalabad:  'Jalalabad Police Station',
    thanaMoglabazar: 'Moglabazar Police Station',
    thanaSouthSurma: 'South Surma Police Station',
    thanaShahPoran:  'Shahporan Police Station',
    thanaAirport:    'Airport Police Station',
  };
  return thana == null ? null : map[thana];
}

/// Lightweight cache provider — uses ONLY getLastKnownPosition() (instant,
/// no concurrent GPS lock needed). Never calls getCurrentPosition() so it
/// never conflicts with the Station Map's live GPS stream.
///
/// keepAlive so it persists across navigation without recomputing.
final detectedStationProvider = FutureProvider.autoDispose<String?>((ref) async {
  final link = ref.keepAlive();
  // ignore: unused_local_variable
  final _ = link;

  try {
    final permission = await Geolocator.checkPermission()
        .timeout(const Duration(seconds: 3));

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    // Only last-known — instant, no concurrent GPS conflict with Station Map
    final pos = await Geolocator.getLastKnownPosition()
        .timeout(const Duration(seconds: 2));

    if (pos == null) return null;

    final thana = resolveSmpThana(pos.latitude, pos.longitude);
    return thanaToStationName(thana);
  } catch (_) {
    return null;
  }
});

/// Full GPS resolver — called directly from SubmitComplaintScreen only when
/// the user explicitly opens that screen. Uses getLastKnownPosition() first
/// and only escalates to getCurrentPosition() as a fallback.
///
/// IMPORTANT: Do NOT call this while Station Map is open — both screens
/// should never run getCurrentPosition() concurrently.
Future<String?> resolveStationFromGps() async {
  try {
    // ── 1. Permission ─────────────────────────────────────────────────────
    LocationPermission permission;
    try {
      permission = await Geolocator.checkPermission()
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      permission = LocationPermission.denied;
    }

    if (permission == LocationPermission.denied) {
      try {
        permission = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 15));
      } catch (_) {
        permission = LocationPermission.denied;
      }
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    // ── 2. Last-known (device cache, nearly instant, no GPS lock) ─────────
    Position? pos;
    try {
      pos = await Geolocator.getLastKnownPosition()
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      pos = null;
    }

    // ── 3. Fresh fix — only if no cache available ──────────────────────────
    if (pos == null) {
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        ).timeout(const Duration(seconds: 10));
      } catch (_) {
        pos = null;
      }
    }

    if (pos == null) return null;
    final thana = resolveSmpThana(pos.latitude, pos.longitude);
    return thanaToStationName(thana);
  } catch (_) {
    return null;
  }
}
