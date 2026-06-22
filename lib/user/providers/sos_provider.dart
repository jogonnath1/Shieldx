import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shieldx/common/data/services/emergency_service.dart';
import 'package:shieldx/common/data/models/emergency_model.dart';
import 'package:shieldx/common/providers/auth_provider.dart';
import 'package:shieldx/common/providers/gps_simulation_provider.dart';

enum SOSStatus { idle, countingDown, active, error }

class SOSState {
  final SOSStatus status;
  final int countdown;
  final String? activeEmergencyId;
  final String? errorMessage;
  final double? currentLatitude;
  final double? currentLongitude;
  const SOSState({
    required this.status,
    this.countdown = 3,
    this.activeEmergencyId,
    this.errorMessage,
    this.currentLatitude,
    this.currentLongitude,
  });
  SOSState copyWith({
    SOSStatus? status,
    int? countdown,
    String? activeEmergencyId,
    String? errorMessage,
    double? currentLatitude,
    double? currentLongitude,
  }) {
    return SOSState(
      status: status ?? this.status,
      countdown: countdown ?? this.countdown,
      activeEmergencyId: activeEmergencyId ?? this.activeEmergencyId,
      errorMessage: errorMessage ?? this.errorMessage,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
    );
  }
}

final emergencyServiceProvider =
    Provider<EmergencyService>((ref) => EmergencyService());
final sosNotifierProvider = StateNotifierProvider<SOSNotifier, SOSState>((ref) {
  final service = ref.read(emergencyServiceProvider);
  return SOSNotifier(service, ref);
});

class SOSNotifier extends StateNotifier<SOSState> {
  final EmergencyService _service;
  final Ref _ref;
  Timer? _countdownTimer;
  StreamSubscription<dynamic>? _positionSubscription;
  StreamSubscription<EmergencyModel?>? _statusSubscription;
  SOSNotifier(this._service, this._ref)
      : super(const SOSState(status: SOSStatus.idle));
  Future<void> startSOS() async {
    if (state.status != SOSStatus.idle) return;
    final profile = _ref.read(authNotifierProvider).valueOrNull;
    if (profile == null || !profile.isVerified) {
      state = state.copyWith(
        status: SOSStatus.error,
        errorMessage: 'Emergency SOS is reserved for verified citizens only.',
      );
      return;
    }
    final simState = _ref.read(gpsSimulationProvider);
    if (!simState.isSimulationActive) {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
            status: SOSStatus.error,
            errorMessage: 'Location services are disabled.');
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(
              status: SOSStatus.error,
              errorMessage: 'Location permissions are denied.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
            status: SOSStatus.error,
            errorMessage:
                'Location permissions are permanently denied. Enable them in settings.');
        return;
      }
    }
    state = state.copyWith(
        status: SOSStatus.countingDown, countdown: 3, errorMessage: null);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = state.countdown - 1;
      if (next > 0) {
        state = state.copyWith(countdown: next);
      } else {
        timer.cancel();
        _countdownTimer = null;
        _triggerSOSAlert();
      }
    });
  }

  void cancelSOSCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    state = const SOSState(status: SOSStatus.idle);
  }

  Future<void> _triggerSOSAlert() async {
    double lat = 24.89996;
    double lng = 91.87030;
    try {
      final simState = _ref.read(gpsSimulationProvider);
      if (simState.isSimulationActive) {
        lat = simState.latitude;
        lng = simState.longitude;
      } else {
        Position? pos;
        try {
          pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 8),
            ),
          );
        } catch (_) {
          try {
            pos = await Geolocator.getLastKnownPosition();
          } catch (_) {}
        }
        if (pos != null) {
          lat = pos.latitude;
          lng = pos.longitude;
        }
      }
      final emergency = await _service.triggerSOS(lat, lng);
      state = state.copyWith(
        status: SOSStatus.active,
        activeEmergencyId: emergency.id,
        currentLatitude: lat,
        currentLongitude: lng,
      );
      _startLiveLocationTracking(emergency.id);
      _listenToEmergencyStatus(emergency.id);
    } catch (e) {
      state = state.copyWith(
          status: SOSStatus.error,
          errorMessage: 'Failed to trigger SOS. Check internet connection.');
    }
  }

  void _listenToEmergencyStatus(String id) {
    _statusSubscription?.cancel();
    _statusSubscription = _service.watchEmergency(id).listen((emergency) {
      if (emergency == null) return;
      if (emergency.status == 'resolved') {
        _positionSubscription?.cancel();
        _positionSubscription = null;
        _statusSubscription?.cancel();
        _statusSubscription = null;
        state = const SOSState(status: SOSStatus.idle);
      }
    });
  }

  void _startLiveLocationTracking(String id) {
    final simState = _ref.read(gpsSimulationProvider);
    if (simState.isSimulationActive) {
      _positionSubscription =
          _ref.read(gpsSimulationProvider.notifier).stream.listen((sim) {
        if (state.status == SOSStatus.active) {
          state = state.copyWith(
            currentLatitude: sim.latitude,
            currentLongitude: sim.longitude,
          );
          _service
              .updateEmergencyLocation(id, sim.latitude, sim.longitude)
              .catchError((_) {});
        }
      });
    } else {
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((position) {
        state = state.copyWith(
          currentLatitude: position.latitude,
          currentLongitude: position.longitude,
        );
        _service
            .updateEmergencyLocation(id, position.latitude, position.longitude)
            .catchError((_) {});
      });
    }
  }

  Future<void> markSafe() async {
    final id = state.activeEmergencyId;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _statusSubscription?.cancel();
    _statusSubscription = null;
    state = const SOSState(status: SOSStatus.idle);
    if (id != null) {
      try {
        await _service.cancelEmergency(id);
      } catch (_) {}
    }
  }

  void resetToIdle() {
    state = const SOSState(status: SOSStatus.idle);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _positionSubscription?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }
}

final currentEmergencyStreamProvider =
    StreamProvider.family<EmergencyModel?, String>((ref, id) {
  final service = ref.read(emergencyServiceProvider);
  return service.watchEmergency(id);
});
