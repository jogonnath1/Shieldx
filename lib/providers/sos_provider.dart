import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../data/services/emergency_service.dart';
import '../data/models/emergency_model.dart';

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

final emergencyServiceProvider = Provider<EmergencyService>((ref) => EmergencyService());

final sosNotifierProvider = StateNotifierProvider<SOSNotifier, SOSState>((ref) {
  final service = ref.read(emergencyServiceProvider);
  return SOSNotifier(service);
});

class SOSNotifier extends StateNotifier<SOSState> {
  final EmergencyService _service;
  Timer? _countdownTimer;
  StreamSubscription<Position>? _positionSubscription;

  SOSNotifier(this._service) : super(const SOSState(status: SOSStatus.idle));

  // Starts the SOS sequence
  Future<void> startSOS() async {
    // 1. Guard against double-tap or active state
    if (state.status != SOSStatus.idle) return;

    // 2. Check location permissions first so countdown isn't interrupted by system prompts
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(status: SOSStatus.error, errorMessage: 'Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        state = state.copyWith(status: SOSStatus.error, errorMessage: 'Location permissions are denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      state = state.copyWith(
          status: SOSStatus.error,
          errorMessage: 'Location permissions are permanently denied. Enable them in settings.');
      return;
    }

    // 3. Initiate the 3-second countdown
    state = state.copyWith(status: SOSStatus.countingDown, countdown: 3, errorMessage: null);
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.countdown > 1) {
        state = state.copyWith(countdown: state.countdown - 1);
      } else {
        timer.cancel();
        _countdownTimer = null;
        _triggerSOSAlert();
      }
    });
  }

  // Cancel the SOS sequence during countdown
  void cancelSOSCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    state = const SOSState(status: SOSStatus.idle);
  }

  // Under-the-hood trigger once countdown reaches zero
  Future<void> _triggerSOSAlert() async {
    try {
      // 1. Fetch current GPS position
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      // 2. Insert into Supabase
      final emergency = await _service.triggerSOS(pos.latitude, pos.longitude);

      state = state.copyWith(
        status: SOSStatus.active,
        activeEmergencyId: emergency.id,
        currentLatitude: pos.latitude,
        currentLongitude: pos.longitude,
      );

      // 3. Start live location streaming to database
      _startLiveLocationTracking(emergency.id);
    } catch (e) {
      state = state.copyWith(status: SOSStatus.error, errorMessage: 'Failed to trigger SOS. Check internet connection.');
    }
  }

  // Track coordinates continuously in background and update database
  void _startLiveLocationTracking(String id) {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update when moved 5 meters
      ),
    ).listen((position) {
      state = state.copyWith(
        currentLatitude: position.latitude,
        currentLongitude: position.longitude,
      );
      // Fire-and-forget database update
      _service.updateEmergencyLocation(id, position.latitude, position.longitude).catchError((_) {});
    });
  }

  // User manually marks themselves safe / cancels the alarm
  Future<void> markSafe() async {
    final id = state.activeEmergencyId;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    state = const SOSState(status: SOSStatus.idle);

    if (id != null) {
      try {
        await _service.cancelEmergency(id);
      } catch (_) {}
    }
  }

  // Clear error back to idle
  void resetToIdle() {
    state = const SOSState(status: SOSStatus.idle);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }
}

// Watch a single active emergency live (for tracking purposes)
final currentEmergencyStreamProvider = StreamProvider.family<EmergencyModel?, String>((ref, id) {
  final service = ref.read(emergencyServiceProvider);
  return service.watchEmergency(id);
});
