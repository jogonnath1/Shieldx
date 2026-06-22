import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shieldx/common/data/models/police_station_model.dart';
import 'package:shieldx/common/providers/gps_simulation_provider.dart';

String? thanaToStationName(String? thana) {
  const map = {
    thanaKotwali: 'Kotwali Model Police Station',
    thanaJalalabad: 'Jalalabad Police Station',
    thanaMoglabazar: 'Moglabazar Police Station',
    thanaSouthSurma: 'South Surma Police Station',
    thanaShahPoran: 'Shahporan Police Station',
    thanaAirport: 'Airport Police Station',
  };
  return thana == null ? null : map[thana];
}

final detectedStationProvider =
    FutureProvider.autoDispose<String?>((ref) async {
  final link = ref.keepAlive();
  final _ = link;
  final sim = ref.watch(gpsSimulationProvider);
  if (sim.isSimulationActive) {
    final thana = resolveSmpThana(sim.latitude, sim.longitude);
    return thanaToStationName(thana);
  }
  try {
    final permission =
        await Geolocator.checkPermission().timeout(const Duration(seconds: 3));
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    final pos = await Geolocator.getLastKnownPosition()
        .timeout(const Duration(seconds: 2));
    if (pos == null) return null;
    final thana = resolveSmpThana(pos.latitude, pos.longitude);
    return thanaToStationName(thana);
  } catch (_) {
    return null;
  }
});
Future<String?> resolveStationFromGps({
  bool forceFresh = false,
  WidgetRef? ref,
  Ref? riverpodRef,
}) async {
  try {
    final sim = ref != null
        ? ref.read(gpsSimulationProvider)
        : riverpodRef?.read(gpsSimulationProvider);
    if (sim != null && sim.isSimulationActive) {
      final thana = resolveSmpThana(sim.latitude, sim.longitude);
      return thanaToStationName(thana);
    }
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
    Position? pos;
    if (!forceFresh) {
      try {
        pos = await Geolocator.getLastKnownPosition()
            .timeout(const Duration(seconds: 2));
      } catch (_) {
        pos = null;
      }
    }
    if (pos == null) {
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        ).timeout(const Duration(seconds: 8));
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
