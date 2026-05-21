import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

class GpsSimulationState {
  final bool isSimulationActive;
  final double latitude;
  final double longitude;
  final String name;

  const GpsSimulationState({
    required this.isSimulationActive,
    required this.latitude,
    required this.longitude,
    required this.name,
  });

  GpsSimulationState copyWith({
    bool? isSimulationActive,
    double? latitude,
    double? longitude,
    String? name,
  }) {
    return GpsSimulationState(
      isSimulationActive: isSimulationActive ?? this.isSimulationActive,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      name: name ?? this.name,
    );
  }
}

class GpsSimulationNotifier extends StateNotifier<GpsSimulationState> {
  GpsSimulationNotifier()
      : super(const GpsSimulationState(
          isSimulationActive: false,
          latitude: 24.89996, // Kajolshah beside Medinova Diagnostic Center
          longitude: 91.87030,
          name: 'Kajolshah (beside Medinova)',
        ));

  void enableSimulation({double? lat, double? lng, String? name}) {
    state = state.copyWith(
      isSimulationActive: true,
      latitude: lat ?? 24.89996,
      longitude: lng ?? 91.87030,
      name: name ?? 'Kajolshah (beside Medinova)',
    );
  }

  void disableSimulation() {
    state = state.copyWith(isSimulationActive: false);
  }

  void updatePosition(double lat, double lng, String name) {
    state = state.copyWith(
      latitude: lat,
      longitude: lng,
      name: name,
    );
  }
}

final gpsSimulationProvider =
    StateNotifierProvider<GpsSimulationNotifier, GpsSimulationState>((ref) {
  return GpsSimulationNotifier();
});
