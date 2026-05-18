import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../data/models/police_station_model.dart';
import '../data/services/map_service.dart';

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
  // Sylhet city centre — fallback when GPS is unavailable
  static const LatLng _sylhetCentre = LatLng(24.8949, 91.8687);

  StationMapNotifier() : super(const StationMapState());

  void reset() => state = const StationMapState(isLoading: false);
  
  void resetPanFlag() {
    if (state.shouldPanToStation) {
      state = state.copyWith(shouldPanToStation: false);
    }
  }

  Future<void> init() async => _acquireLocationAndLoad();

  Future<void> refreshLocation() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _acquireLocationAndLoad();
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
  // Step 1 — Acquire GPS
  // ---------------------------------------------------------------------------
  Future<void> _acquireLocationAndLoad() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _handleLocationFailure(
          'Location services are disabled. Defaulting to Sylhet city centre.',
          permissionDenied: false,
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await _handleLocationFailure(
          permission == LocationPermission.deniedForever
              ? 'Location permission permanently denied. Open Settings to allow access.'
              : 'Location permission denied. Tap "Retry" to grant access.',
          permissionDenied: true,
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final loc = LatLng(position.latitude, position.longitude);
      state = state.copyWith(userLocation: loc);
      await _loadSmpStations(loc);
    } catch (_) {
      await _handleLocationFailure(
        'Could not determine your location. Defaulting to Sylhet city centre.',
        permissionDenied: false,
      );
    }
  }

  Future<void> _handleLocationFailure(
      String message, {required bool permissionDenied}) async {
    state = state.copyWith(
      isLoading: false,
      errorMessage: message,
      isPermissionDenied: permissionDenied,
      userLocation: _sylhetCentre,
    );
    await _loadSmpStations(_sylhetCentre, silentLoad: true);
  }

  // ---------------------------------------------------------------------------
  // Step 2 — Load SMP stations and auto-select based on GPS
  // ---------------------------------------------------------------------------
  Future<void> _loadSmpStations(LatLng loc, {bool silentLoad = false}) async {
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

    // Try to also get jurisdiction name from Overpass (best-effort, non-blocking)
    _fetchJurisdictionInBackground(loc);

    state = state.copyWith(
      stations: updatedStations,
      selectedStation: autoSelected,
      selectionSource: SelectionSource.jurisdiction,
      activeThana: detectedThana,
      isLoading: false,
    );
  }

  void _fetchJurisdictionInBackground(LatLng loc) async {
    try {
      final jurInfo = await _mapService.getJurisdictionInfo(loc);
      if (mounted && jurInfo != null) {
        state = state.copyWith(jurisdictionName: jurInfo['name'] as String?);
        final id = jurInfo['id'];
        if (id != null) {
          final polygon = await _mapService.getAreaPolygon(id as int);
          if (mounted && polygon != null) {
            state = state.copyWith(jurisdictionPolygon: polygon);
          }
        }
      }
    } catch (_) {
      // purely cosmetic — silently ignore
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final stationMapProvider =
    StateNotifierProvider<StationMapNotifier, StationMapState>(
  (ref) => StationMapNotifier(),
);
