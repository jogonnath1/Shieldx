import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shieldx/common/data/models/police_station_model.dart';
import 'package:shieldx/common/data/services/map_service.dart';
import 'package:shieldx/common/providers/gps_simulation_provider.dart';

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
  final String? activeThana;
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
      selectedStation: clearSelectedStation
          ? null
          : (selectedStation ?? this.selectedStation),
      selectionSource: selectionSource ?? this.selectionSource,
      jurisdictionName: jurisdictionName ?? this.jurisdictionName,
      jurisdictionPolygon: clearPolygon
          ? null
          : (jurisdictionPolygon ?? this.jurisdictionPolygon),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isPermissionDenied: isPermissionDenied ?? this.isPermissionDenied,
      activeThana: clearActiveThana ? null : (activeThana ?? this.activeThana),
      shouldPanToStation: shouldPanToStation ?? false,
    );
  }
}

class StationMapNotifier extends StateNotifier<StationMapState> {
  final MapService _mapService = MapService();
  final Ref _ref;
  static const LatLng _sylhetCentre = LatLng(24.89996, 91.87030);
  bool _isInitializing = false;
  StationMapNotifier(this._ref) : super(const StationMapState()) {
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

  void selectStation(PoliceStation? station) {
    state = state.copyWith(
      selectedStation: station,
      clearSelectedStation: station == null,
      selectionSource: SelectionSource.manual,
      activeThana: station?.thana,
    );
  }

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

  void setThanaFilter(String? thana) {
    if (thana == null || thana == state.activeThana) {
      state =
          state.copyWith(clearActiveThana: true, clearSelectedStation: true);
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
      var serviceEnabled = true;
      try {
        serviceEnabled = await Future.any([
          Geolocator.isLocationServiceEnabled(),
          Future.delayed(const Duration(seconds: 3), () => true),
        ]);
      } catch (_) {
        serviceEnabled = true;
      }
      if (!serviceEnabled) {
        await _loadSmpStations(_sylhetCentre, silentLoad: true);
        state = state.copyWith(
          userLocation: _sylhetCentre,
          isLoading: false,
        );
        return;
      }
      LocationPermission permission;
      try {
        permission = await Future.any([
          Geolocator.checkPermission(),
          Future.delayed(
              const Duration(seconds: 3), () => LocationPermission.denied),
        ]);
      } catch (_) {
        permission = LocationPermission.denied;
      }
      if (permission == LocationPermission.denied) {
        try {
          permission = await Future.any([
            Geolocator.requestPermission(),
            Future.delayed(
                const Duration(seconds: 5), () => LocationPermission.denied),
          ]);
        } catch (_) {
          permission = LocationPermission.denied;
        }
      }
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
      Position? position;
      try {
        position = await Future.any([
          Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
            ),
          ),
          Future.delayed(const Duration(seconds: 6), () => null),
        ]);
      } catch (_) {
        position = null;
      }
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
      final loc = position != null
          ? LatLng(position.latitude, position.longitude)
          : _sylhetCentre;
      state = state.copyWith(userLocation: loc);
      await _loadSmpStations(loc);
    } catch (e) {
      if (mounted) {
        state = state.copyWith(userLocation: _sylhetCentre, isLoading: false);
        await _loadSmpStations(_sylhetCentre, silentLoad: true);
      }
    }
  }

  Future<void> _loadSmpStations(LatLng loc, {bool silentLoad = false}) async {
    if (!mounted) return;
    if (!silentLoad) state = state.copyWith(isLoading: true);
    final stations =
        dummyPoliceStations.where((s) => s.id.startsWith('smp_')).toList();
    const distCalc = Distance();
    stations.sort((a, b) => distCalc
        .as(LengthUnit.Meter, loc, a.location)
        .compareTo(distCalc.as(LengthUnit.Meter, loc, b.location)));
    final detectedThana = resolveSmpThana(loc.latitude, loc.longitude);
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
    _fetchJurisdictionInBackground(loc);
  }

  void _fetchJurisdictionInBackground(LatLng loc) async {
    try {
      final jurInfo = await _mapService
          .getJurisdictionInfo(loc)
          .timeout(const Duration(seconds: 8));
      if (!mounted || jurInfo == null) return;
      state = state.copyWith(jurisdictionName: jurInfo['name'] as String?);
      final id = jurInfo['id'];
      if (id != null) {
        final polygon = await _mapService
            .getAreaPolygon(id as int)
            .timeout(const Duration(seconds: 8));
        if (mounted && polygon != null) {
          state = state.copyWith(jurisdictionPolygon: polygon);
        }
      }
    } catch (_) {}
  }

  void selectUserJurisdiction() {
    final loc = state.userLocation;
    if (loc == null || state.stations.isEmpty) return;
    final detectedThana = resolveSmpThana(loc.latitude, loc.longitude);
    final updatedStations = state.stations.map((s) {
      final isDetected = s.thana == detectedThana;
      return s.copyWith(isAutoSelected: isDetected);
    }).toList();
    final autoSelected = updatedStations.firstWhere(
      (s) => s.thana == detectedThana,
      orElse: () => updatedStations.first,
    );
    state = state.copyWith(
      stations: updatedStations,
      selectedStation: autoSelected,
      selectionSource: SelectionSource.jurisdiction,
      activeThana: detectedThana,
      shouldPanToStation: true,
    );
  }
}

final stationMapProvider =
    StateNotifierProvider<StationMapNotifier, StationMapState>(
  (ref) => StationMapNotifier(ref),
);
