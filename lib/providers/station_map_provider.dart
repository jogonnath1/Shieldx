import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../data/models/police_station_model.dart';
import '../data/services/map_service.dart';
import 'gps_simulation_provider.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum SelectionSource { jurisdiction, nearest, manual }

class StationMapState {
  final LatLng? userLocation;
  final List<PoliceStation> stations;
  final PoliceStation? selectedStation;
  final SelectionSource selectionSource;
  final String? jurisdictionName;
  final List<LatLng>? jurisdictionPolygon;
  final bool isLoading;
  final String? errorMessage;
  final bool isPermissionDenied;
  /// Currently highlighted thana (null = show all)
  final String? activeThana;
  /// Signals the map widget to pan to the selected station
  final bool shouldPanToStation;

  const StationMapState({
    this.userLocation,
    this.stations = const [],
    this.selectedStation,
    this.selectionSource = SelectionSource.nearest,
    this.jurisdictionName,
    this.jurisdictionPolygon,
    this.isLoading = false,
    this.errorMessage,
    this.isPermissionDenied = false,
    this.activeThana,
    this.shouldPanToStation = false,
  });

  bool get hasStations => stations.isNotEmpty;

  /// Unique thana names from the loaded SMP stations.
  List<String> get availableThanas {
    final seen = <String>{};
    final result = <String>[];
    for (final s in stations) {
      if (s.thana.isNotEmpty && seen.add(s.thana)) result.add(s.thana);
    }
    return result;
  }

  StationMapState copyWith({
    LatLng? userLocation,
    List<PoliceStation>? stations,
    PoliceStation? selectedStation,
    SelectionSource? selectionSource,
    String? jurisdictionName,
    List<LatLng>? jurisdictionPolygon,
    bool? isLoading,
    String? errorMessage,
    bool? isPermissionDenied,
    String? activeThana,
    bool? shouldPanToStation,
    bool clearError = false,
    bool clearPolygon = false,
    bool clearSelectedStation = false,
    bool clearActiveThana = false,
  }) {
    return StationMapState(
      userLocation: userLocation ?? this.userLocation,
      stations: stations ?? this.stations,
      selectedStation:
          clearSelectedStation ? null : (selectedStation ?? this.selectedStation),
      selectionSource: selectionSource ?? this.selectionSource,
      jurisdictionName: jurisdictionName ?? this.jurisdictionName,
      jurisdictionPolygon:
          clearPolygon ? null : (jurisdictionPolygon ?? this.jurisdictionPolygon),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isPermissionDenied: isPermissionDenied ?? this.isPermissionDenied,
      activeThana: clearActiveThana ? null : (activeThana ?? this.activeThana),
      shouldPanToStation: shouldPanToStation ?? false,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class StationMapNotifier extends StateNotifier<StationMapState> {
  final MapService _mapService = MapService();
  final Ref _ref;
  // Kajolshah beside Medinova Diagnostic Center — fallback when GPS is unavailable
  static const LatLng _sylhetCentre = LatLng(24.89996, 91.87030);

  // Prevent concurrent init calls
  bool _isInitializing = false;

  StationMapNotifier(this._ref) : super(const StationMapState()) {
    // Reactive: listen to GPS simulation provider changes to automatically refresh map locations
    _ref.listen<GpsSimulationState>(gpsSimulationProvider, (prev, next) {
      _acquireLocationAndLoad();
    });
  }

  void reset() {
    _isInitializing = false;
    state = const StationMapState(isLoading: false);
  }

  void resetPanFlag() {
    if (state.shouldPanToStation) {
      state = state.copyWith(shouldPanToStation: false);
    }
  }

  Future<void> init() async {
    if (_isInitializing) return;
    _isInitializing = true;
    try {
      await _acquireLocationAndLoad();
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> refreshLocation() async {
    if (_isInitializing) return;
    state = state.copyWith(isLoading: true, clearError: true);
    _isInitializing = true;
    try {
      await _acquireLocationAndLoad();
    } finally {
      _isInitializing = false;
    }
  }

  void updateUserLocation(LatLng loc) {
    state = state.copyWith(userLocation: loc);
  }

  /// Called when the user manually taps a station card or map marker.
  void selectStation(PoliceStation? station) {
    state = state.copyWith(
      selectedStation: station,
      clearSelectedStation: station == null,
      selectionSource: SelectionSource.manual,
      activeThana: station?.thana,
    );
  }

  // ---------------------------------------------------------------------------
  // Map-tap → instantly resolve SMP thana from tapped coordinates,
  // then auto-select the station for that thana.
  // ---------------------------------------------------------------------------
  void onMapTap(LatLng tappedPoint) {
    if (state.stations.isEmpty) return;

    final thana = resolveSmpThana(
      tappedPoint.latitude,
      tappedPoint.longitude,
    );

    final station = state.stations.firstWhere(
      (s) => s.thana == thana,
      orElse: () => state.stations.first,
    );

    state = state.copyWith(
      activeThana: thana,
      selectedStation: station,
      selectionSource: SelectionSource.nearest,
      shouldPanToStation: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Thana chip tap — select thana, signal map to pan to its station
  // ---------------------------------------------------------------------------
  void setThanaFilter(String? thana) {
    if (thana == null || thana == state.activeThana) {
      state = state.copyWith(clearActiveThana: true, clearSelectedStation: true);
      return;
    }
    final station = state.stations.firstWhere(
      (s) => s.thana == thana,
      orElse: () => state.stations.first,
    );
    state = state.copyWith(
      activeThana: thana,
      selectedStation: station,
      selectionSource: SelectionSource.nearest,
      shouldPanToStation: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1 — Acquire GPS with full timeout protection on every single call
  // ---------------------------------------------------------------------------
  Future<void> _acquireLocationAndLoad() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final simState = _ref.read(gpsSimulationProvider);
      if (simState.isSimulationActive) {
        final loc = LatLng(simState.latitude, simState.longitude);
        state = state.copyWith(userLocation: loc, isLoading: false);
        await _loadSmpStations(loc);
        return;
      }

      // ── 1a. Check if location service is enabled (3-second hard timeout) ──
      var serviceEnabled = true;
      try {
        serviceEnabled = await Future.any([
          Geolocator.isLocationServiceEnabled(),
          Future.delayed(const Duration(seconds: 3), () => true),
        ]);
      } catch (_) {
        serviceEnabled = true; // assume enabled on exception
      }

      if (!serviceEnabled) {
        await _loadSmpStations(_sylhetCentre, silentLoad: true);
        state = state.copyWith(
          userLocation: _sylhetCentre,
          isLoading: false,
        );
        return;
      }

      // ── 1b. Check permission (3-second hard timeout) ──
      LocationPermission permission;
      try {
        permission = await Future.any([
          Geolocator.checkPermission(),
          Future.delayed(const Duration(seconds: 3), () => LocationPermission.denied),
        ]);
      } catch (_) {
        permission = LocationPermission.denied;
      }

      // ── 1c. Request permission only if denied (5-second timeout) ──
      if (permission == LocationPermission.denied) {
        try {
          permission = await Future.any([
            Geolocator.requestPermission(),
            Future.delayed(const Duration(seconds: 5), () => LocationPermission.denied),
          ]);
        } catch (_) {
          permission = LocationPermission.denied;
        }
      }

      // ── 1d. If permanently denied → load with fallback location ──
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        await _loadSmpStations(_sylhetCentre, silentLoad: true);
        state = state.copyWith(
          userLocation: _sylhetCentre,
          isLoading: false,
          isPermissionDenied: permission == LocationPermission.deniedForever,
        );
        return;
      }

      // ── 1e. Fetch live GPS (6-second timeout) ──
      Position? position;
      try {
        position = await Future.any([
          Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium, // lighter than high — less CPU
            ),
          ),
          Future.delayed(const Duration(seconds: 6), () => null),
        ]);
      } catch (_) {
        position = null;
      }

      // ── 1f. Fallback: try last known position (2-second timeout) ──
      if (position == null) {
        try {
          position = await Future.any([
            Geolocator.getLastKnownPosition(),
            Future.delayed(const Duration(seconds: 2), () => null),
          ]);
        } catch (_) {
          position = null;
        }
      }

      // ── 1g. Final fallback: Sylhet city centre ──
      final loc = position != null
          ? LatLng(position.latitude, position.longitude)
          : _sylhetCentre;

      state = state.copyWith(userLocation: loc);
      await _loadSmpStations(loc);
    } catch (e) {
      // Absolute last-resort fallback — map will always load
      if (mounted) {
        state = state.copyWith(userLocation: _sylhetCentre, isLoading: false);
        await _loadSmpStations(_sylhetCentre, silentLoad: true);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Step 2 — Load SMP stations and auto-select based on GPS
  // ---------------------------------------------------------------------------
  Future<void> _loadSmpStations(LatLng loc, {bool silentLoad = false}) async {
    if (!mounted) return;
    if (!silentLoad) state = state.copyWith(isLoading: true);

    // Always use the 6 fixed SMP stations — sorted by distance from user
    final stations = List<PoliceStation>.from(dummyPoliceStations);
    const distCalc = Distance();
    stations.sort((a, b) =>
        distCalc.as(LengthUnit.Meter, loc, a.location)
            .compareTo(distCalc.as(LengthUnit.Meter, loc, b.location)));

    // Resolve thana from GPS using bounding boxes (no internet needed)
    final detectedThana = resolveSmpThana(loc.latitude, loc.longitude);

    // Mark the detected station as auto-selected
    PoliceStation? autoSelected;
    final updatedStations = stations.map((s) {
      if (s.thana == detectedThana) {
        final marked = s.copyWith(isAutoSelected: true);
        autoSelected = marked;
        return marked;
      }
      return s;
    }).toList();

    autoSelected ??= updatedStations.first.copyWith(isAutoSelected: true);

    if (!mounted) return;

    state = state.copyWith(
      stations: updatedStations,
      selectedStation: autoSelected,
      selectionSource: SelectionSource.jurisdiction,
      activeThana: detectedThana,
      isLoading: false,
      clearError: true,
    );

    // Try to fetch jurisdiction info — best-effort, never blocks UI
    _fetchJurisdictionInBackground(loc);
  }

  void _fetchJurisdictionInBackground(LatLng loc) async {
    try {
      final jurInfo = await _mapService.getJurisdictionInfo(loc)
          .timeout(const Duration(seconds: 8));
      if (!mounted || jurInfo == null) return;
      state = state.copyWith(jurisdictionName: jurInfo['name'] as String?);
      final id = jurInfo['id'];
      if (id != null) {
        final polygon = await _mapService.getAreaPolygon(id as int)
            .timeout(const Duration(seconds: 8));
        if (mounted && polygon != null) {
          state = state.copyWith(jurisdictionPolygon: polygon);
        }
      }
    } catch (_) {
      // purely cosmetic — silently ignore timeouts and errors
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final stationMapProvider =
    StateNotifierProvider<StationMapNotifier, StationMapState>(
  (ref) => StationMapNotifier(ref),
);
