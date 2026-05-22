import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';

import 'dart:convert';
import 'dart:ui' show ImageFilter;
import 'package:http/http.dart' as http;

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/police_station_model.dart';
import '../../data/models/complaint_model.dart';
import '../../providers/station_map_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/gps_simulation_provider.dart';
import '../../providers/officer_provider.dart';
import '../widgets/common/widgets.dart';

class PoliceStationsScreen extends ConsumerStatefulWidget {
  const PoliceStationsScreen({super.key});

  @override
  ConsumerState<PoliceStationsScreen> createState() =>
      _PoliceStationsScreenState();
}

class _PoliceStationsScreenState extends ConsumerState<PoliceStationsScreen> {
  final MapController _mapController = MapController();
  bool _isMapReady = false;
  bool _isUserLocationHighlighted = false;
  bool _isLocating = false;
  bool _showHeatmap = false;
  bool _showSafeZones = true;
  bool _showHotspots = true;
  String _selectedCategoryFilter = 'All';
  String _selectedTimelineFilter = 'All';
  bool _isFilterPanelOpen = false;
  bool _onDutyExpanded = false;

  LatLng? _searchPinLocation;
  String? _searchPinName;

  // ─── Route state ────────────────────────────────────────────────────────────
  List<LatLng> _routePoints = [];
  bool _isFetchingRoute = false;
  bool _showRoute = false;
  // Debounce tap events to prevent double-tap from firing two state changes
  Timer? _tapDebounce;

  @override
  void initState() {
    super.initState();
    // Defer provider init to avoid calling ref during widget construction
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkAndInit();
    });
  }

  Future<void> _checkAndInit() async {
    // Reset stale state so re-entry is always clean
    ref.read(stationMapProvider.notifier).reset();
    // Initialize the provider (handles all permission + GPS internally)
    await ref.read(stationMapProvider.notifier).init();
    // Start the blue-dot live stream
    if (mounted) _initPositionStream();
  }

  StreamSubscription? _simSubscription;

  void _initPositionStream() {
    _simSubscription?.cancel();
    _simSubscription = null;

    final simState = ref.read(gpsSimulationProvider);

    if (simState.isSimulationActive) {
      // Seed initial simulation location immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(stationMapProvider.notifier).updateUserLocation(
            LatLng(simState.latitude, simState.longitude),
          );
        }
      });

      _simSubscription = ref.read(gpsSimulationProvider.notifier).stream.listen((state) {
        if (state.isSimulationActive && mounted) {
          ref.read(stationMapProvider.notifier).updateUserLocation(
            LatLng(state.latitude, state.longitude),
          );
        }
      });
    } else {
      final geolocatorStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 10,
        ),
      );

      _simSubscription = geolocatorStream.listen(
        (pos) {
          if (mounted) {
            ref.read(stationMapProvider.notifier).updateUserLocation(
              LatLng(pos.latitude, pos.longitude),
            );
          }
        },
        onError: (e) {
          debugPrint('[Geolocator Stream] error: $e');
        },
      );
    }
  }

  @override
  void dispose() {
    _tapDebounce?.cancel();
    _simSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _moveMap(LatLng loc, double zoom) {
    if (_isMapReady) {
      _mapController.move(loc, zoom);
    } else {
      // Retry after a short delay if map isn't ready yet
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _mapController.move(loc, zoom);
      });
    }
  }



  Future<void> _goToMyLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    try {
      // Fetch the live location to ensure the highlight marker is perfectly synced
      Position? pos;
      try {
        pos = await Future.any([
          Geolocator.getCurrentPosition(
            locationSettings:
                const LocationSettings(accuracy: LocationAccuracy.high),
          ),
          Future.delayed(
            const Duration(seconds: 10),
            () => throw Exception('GPS Timeout'),
          ),
        ]);
      } catch (_) {
        try {
          pos = await Future.any([
            Geolocator.getLastKnownPosition(),
            Future.delayed(const Duration(seconds: 2), () => null)
          ]);
        } catch (_) {}
      }

      LatLng? liveLoc;
      if (pos != null) {
        liveLoc = LatLng(pos.latitude, pos.longitude);
      } else {
        // If all GPS requests fail, gracefully fallback to the map provider's cached location!
        liveLoc = ref.read(stationMapProvider).userLocation;
      }

      if (liveLoc == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Could not fetch location. Please check your device GPS settings.')),
          );
        }
        return;
      }

      if (mounted) {
        ref.read(stationMapProvider.notifier).updateUserLocation(liveLoc);
        ref.read(stationMapProvider.notifier).selectUserJurisdiction();
        _moveMap(liveLoc, 16.0);
        setState(() => _isUserLocationHighlighted = true);
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) setState(() => _isUserLocationHighlighted = false);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  String _distLabel(LatLng? userLoc, LatLng stationLoc) {
    if (userLoc == null) return '';
    final m = const Distance().as(LengthUnit.Meter, userLoc, stationLoc);
    return m < 1000
        ? '${m.round()} m away'
        : '${(m / 1000).toStringAsFixed(1)} km away';
  }

  // ─── Route fetching via OSRM ────────────────────────────────────────────────

  void _clearRoute() {
    if (mounted) {
      setState(() {
        _routePoints = [];
        _showRoute = false;
      });
    }
  }

  Future<void> _fetchRoute(LatLng from, LatLng to) async {
    if (_isFetchingRoute) return;
    setState(() => _isFetchingRoute = true);
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/foot/'
        '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson&steps=false',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'ShieldX/1.0'
      }).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final coords = routes[0]['geometry']['coordinates'] as List;
          final points = coords
              .map<LatLng>((c) =>
                  LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
              .toList();
          if (mounted) {
            setState(() {
              _routePoints = [from, ...points, to];
            });
            // Fit map to show both user and station — deferred to avoid mid-rebuild calls
            if (_isMapReady && points.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || !_isMapReady) return;
                try {
                  final bounds = LatLngBounds.fromPoints([from, ...points, to]);
                  if (from.latitude != to.latitude ||
                      from.longitude != to.longitude) {
                    _mapController.fitCamera(
                      CameraFit.bounds(
                        bounds: bounds,
                        padding: const EdgeInsets.only(
                          top: 100,
                          bottom: 240,
                          left: 45,
                          right: 45,
                        ),
                        maxZoom: 16.0,
                      ),
                    );
                  } else {
                    _mapController.move(from, 16.0);
                  }
                } catch (e) {
                  debugPrint('[Route] fitCamera error: $e');
                }
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[Route] fetch error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Failed to calculate route. Please check your connection.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingRoute = false);
    }
  }

  Future<void> _callStation(String phone) async {
    final uri = Uri.parse('tel:${phone.replaceAll(' ', '')}');
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot open dialer')),
        );
      }
    }
  }

  Future<void> _openMaps(PoliceStation s) async {
    ref.read(stationMapProvider.notifier).selectStation(s);
    
    final userLoc = ref.read(stationMapProvider).userLocation;
    if (userLoc != null) {
      setState(() {
        _showRoute = true;
        _isUserLocationHighlighted = true;
      });
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _isUserLocationHighlighted = false);
      });

      // Fit bounds immediately to show both user and station with clean padding avoiding overlays
      if (_isMapReady) {
        try {
          final bounds = LatLngBounds.fromPoints([userLoc, s.location]);
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.only(
                top: 100,
                bottom: 240,
                left: 45,
                right: 45,
              ),
              maxZoom: 16.0,
            ),
          );
        } catch (e) {
          debugPrint('[Navigate] Immediate fitCamera error: $e');
        }
      }

      await _fetchRoute(userLoc, s.location);
    } else {
      _moveMap(s.location, 16.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stationMapProvider);
    final notifier = ref.read(stationMapProvider.notifier);

    ref.listen<GpsSimulationState>(gpsSimulationProvider, (prev, next) {
      if (prev?.isSimulationActive != next.isSimulationActive ||
          prev?.latitude != next.latitude ||
          prev?.longitude != next.longitude) {
        _initPositionStream();
        if (next.isSimulationActive && prev?.isSimulationActive != next.isSimulationActive) {
          _moveMap(LatLng(next.latitude, next.longitude), 15.0);
        }
      }
    });

    // Auto-pan and initialize stream when permission/location becomes available
    // Using Future.microtask instead of addPostFrameCallback to avoid accumulation
    ref.listen(stationMapProvider, (prev, next) {
      Future.microtask(() {
        if (!mounted) return;

        final stationChanged =
            prev?.selectedStation?.id != next.selectedStation?.id;
        if (stationChanged) {
          setState(() {
            _onDutyExpanded = false;
          });
        }

        if ((prev == null || prev.isPermissionDenied) &&
            !next.isPermissionDenied) {
          _initPositionStream();
        }

        // Pan to station if the flag is set, or if it's the initial auto-selection
        if (next.selectedStation != null) {
          final stationChanged =
              prev?.selectedStation?.id != next.selectedStation?.id;
          final isInitialLoad =
              stationChanged && next.selectionSource != SelectionSource.manual;

          if (isInitialLoad || next.shouldPanToStation) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted && _isMapReady) {
                _moveMap(next.selectedStation!.location, 14.5);
              }
            });
            if (next.shouldPanToStation) {
              ref.read(stationMapProvider.notifier).resetPanFlag();
            }
          }
        }

        // Update route line reactively to location or selected station changes
        if (next.selectedStation != null && next.userLocation != null) {
          final stationChanged =
              prev?.selectedStation?.id != next.selectedStation?.id;
          final locationChanged = prev?.userLocation != next.userLocation;
          if (stationChanged || locationChanged) {
            setState(() => _showRoute = true);
            _fetchRoute(next.userLocation!, next.selectedStation!.location);
          }
        } else {
          final stationChanged =
              prev?.selectedStation?.id != next.selectedStation?.id;
          if (stationChanged) {
            _clearRoute();
          }
        }

        // Pan to user location the first time it becomes available
        if (prev?.userLocation == null && next.userLocation != null) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && _isMapReady) _moveMap(next.userLocation!, 14.0);
          });
        }
      });
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(state, notifier),
      body: Stack(
        children: [
          _buildMap(state, notifier),
          _buildSearchOverlay(state),
          _buildHeatmapFilterPanel(state),
          if (state.isLoading) _buildLoadingOverlay(state),
          if (!state.isLoading &&
              (state.isPermissionDenied ||
                  (state.errorMessage != null && state.stations.isEmpty)))
            _buildErrorOverlay(state, notifier),
          if (state.hasStations) _buildThanaChips(state, notifier),

          _buildZoomControls(state),
          if (state.selectedStation != null) _buildStationDetailCard(state),
        ],
      ),
    );
  }

  // ─── AppBar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(
      StationMapState state, StationMapNotifier notifier) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
      ),
      title: Text(
        'Station Map',
        style: GoogleFonts.inter(
            fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white),
      ),
      actions: [
        if (state.activeThana != null &&
            thanaDetailedInfo.containsKey(state.activeThana))
          IconButton(
            icon:
                const Icon(Icons.info_outline_rounded, color: AppColors.accent),
            tooltip: 'Thana Details',
            onPressed: () => _showThanaInfo(state.activeThana!),
          ),
        IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              Icons.my_location_rounded,
              key: ValueKey(_isUserLocationHighlighted),
              color: _isUserLocationHighlighted
                  ? Colors.blue
                  : state.userLocation != null
                      ? AppColors.primaryLight
                      : AppColors.textHint,
              size: _isUserLocationHighlighted ? 28 : 24,
            ),
          ),
          tooltip: 'Go to my location',
          onPressed: _goToMyLocation,
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          tooltip: 'Refresh',
          onPressed: () => notifier.refreshLocation(),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ─── Thana Info Bottom Sheet ─────────────────────────────────────────────────

  void _showThanaInfo(String thanaKey) {
    final info = thanaDetailedInfo[thanaKey];
    if (info == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: AppColors.cardBorder, width: 1),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    height: 5,
                    width: 40,
                    decoration: BoxDecoration(
                      color: AppColors.textHint.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          info.emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                info.thana,
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                info.subtitle,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.primaryLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: AppColors.textHint),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: AppColors.cardBorder, height: 30),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                      itemCount: info.sections.length +
                          (info.overlapNotes.isNotEmpty ? 1 : 0),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 24),
                      itemBuilder: (context, index) {
                        if (index == info.sections.length) {
                          // Overlap Notes
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      AppColors.warning.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline_rounded,
                                    color: AppColors.warning, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    info.overlapNotes,
                                    style: GoogleFonts.inter(
                                      color: AppColors.warning,
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final section = info.sections[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(section.emoji,
                                    style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    section.heading,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...section.areas.map((area) => Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 8, left: 28),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(
                                            top: 6, right: 8),
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primaryLight,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          area,
                                          style: GoogleFonts.inter(
                                            color: AppColors.textSecondary,
                                            fontSize: 14,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Map ────────────────────────────────────────────────────────────────────

  Widget _buildMap(StationMapState state, StationMapNotifier notifier) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: state.userLocation ?? const LatLng(24.8949, 91.8687),
        initialZoom: 13.0,
        minZoom: 3.0,
        maxZoom: 18.0,
        onMapReady: () {
          // Defer setState to avoid calling it during the map's own build phase
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _isMapReady = true);
            final loc = ref.read(stationMapProvider).userLocation;
            if (loc != null) {
              Future.delayed(const Duration(milliseconds: 200), () {
                if (mounted) _mapController.move(loc, 14.0);
              });
            }
          });
        },
        onTap: (tapPos, latLng) {
          // Debounce: ignore rapid taps (e.g. double-tap) to prevent
          // state-change collisions during map zoom animation
          _tapDebounce?.cancel();
          _tapDebounce = Timer(const Duration(milliseconds: 300), () {
            if (!mounted) return;

            final sim = ref.read(gpsSimulationProvider);
            if (sim.isSimulationActive) {
              ref.read(gpsSimulationProvider.notifier).updatePosition(
                    latLng.latitude,
                    latLng.longitude,
                    'Custom Location',
                  );
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Updated simulated location to: ${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFF10B981),
                  duration: const Duration(seconds: 2),
                ),
              );
              return;
            }

            setState(() {
              _searchPinLocation = null;
              _searchPinName = null;
            });
            notifier.onMapTap(latLng);
          });
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
          userAgentPackageName: 'com.shieldx.app',
        ),
        // Jurisdiction boundary polygon
        if (state.jurisdictionPolygon != null &&
            state.jurisdictionPolygon!.length > 2)
          PolygonLayer(
            polygons: [
              Polygon(
                points: state.jurisdictionPolygon!,
                color: AppColors.primary.withValues(alpha: 0.12),
                borderColor: AppColors.primary.withValues(alpha: 0.6),
                borderStrokeWidth: 2.5,
              ),
            ],
          ),
        // Crime Hotspot Heatmap Overlay Layer
        if (_showHeatmap)
          ref.watch(crimeHotspotProvider).when(
                data: (complaints) => CircleLayer<Object>(
                  circles: _buildHeatmapCircles(complaints, state.stations),
                ),
                loading: () => const CircleLayer<Object>(circles: []),
                error: (e, s) => const CircleLayer<Object>(circles: []),
              ),
        // Route polyline — drawn below the user dot
        if (_showRoute && _routePoints.length > 1)
          PolylineLayer(
            polylines: [
              // Thick shadow/border line
              Polyline(
                points: _routePoints,
                strokeWidth: 9,
                color: Colors.blue.withValues(alpha: 0.25),
                borderStrokeWidth: 0,
              ),
              // Main route line
              Polyline(
                points: _routePoints,
                strokeWidth: 5,
                color: const Color(0xFF1A73E8),
                borderColor: Colors.white,
                borderStrokeWidth: 1.5,
              ),
              // Dashed overlay for Google Maps look
              Polyline(
                points: _routePoints,
                strokeWidth: 2,
                color: Colors.white.withValues(alpha: 0.6),
                pattern: const StrokePattern.dotted(spacingFactor: 2.0),
                borderStrokeWidth: 0,
              ),
            ],
          ),
        // User Location Layer — Custom glowing double-pulse blue GPS dot.
        if (state.userLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: state.userLocation!,
                width: 80,
                height: 80,
                alignment: Alignment.center,
                child: const _GpsUserLocationMarker(),
              ),
            ],
          ),
        // User location highlight marker — shown when "go to my location" is tapped
        if (_isUserLocationHighlighted && state.userLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: state.userLocation!,
                width: 120,
                height: 120,
                alignment: Alignment.center,
                child: const _UserLocationHighlightMarker(),
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            // Temporary search pin
            if (_searchPinLocation != null)
              Marker(
                point: _searchPinLocation!,
                width: 140,
                height: 60,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.4),
                              blurRadius: 6,
                              spreadRadius: 1),
                        ],
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.place_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _searchPinName ?? 'Search Result',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        shadows: [
                          const Shadow(color: Colors.black87, blurRadius: 4),
                          const Shadow(color: Colors.black54, blurRadius: 2),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                    ),
                  ],
                ),
              ),
            // City landmarks
            ...cityLandmarks.map((lm) {
              final color = _getColorForType(lm.type);
              final icon = _getIconForType(lm.type);
              return Marker(
                point: lm.location,
                width: 140,
                height: 60,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 4,
                              spreadRadius: 1),
                        ],
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.8),
                            width: 1),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lm.name,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          const Shadow(color: Colors.black87, blurRadius: 4),
                          const Shadow(color: Colors.black54, blurRadius: 2),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                    ),
                  ],
                ),
              );
            }),
            // Station markers
            ...state.stations.map((s) {
              final isSelected = state.selectedStation?.id == s.id;
              return Marker(
                point: s.location,
                width: isSelected ? 84 : 64,
                height: isSelected ? 84 : 64,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _searchPinLocation = null;
                      _searchPinName = null;
                    });
                    notifier.selectStation(s);
                    // ref.listen handles _fetchRoute automatically
                  },
                  child: _StationMarker(
                    isSelected: isSelected,
                    isAutoSelected: s.isAutoSelected,
                    selectionSource: state.selectionSource,
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  List<CircleMarker<Object>> _buildHeatmapCircles(
      List<ComplaintModel> complaints, List<PoliceStation> stations) {
    final circles = <CircleMarker<Object>>[];

    // 1. Add Safe Zones around Police Stations (concentric soft green shields)
    if (_showSafeZones) {
      for (final s in stations) {
        final point = s.location;
        const radius = 400.0;
        final baseColor = HSLColor.fromAHSL(1.0, 140, 0.85, 0.45); // vibrant green

        // concentric ring 1: Outer faint green glow
        circles.add(
          CircleMarker(
            point: point,
            radius: radius,
            useRadiusInMeter: true,
            color: baseColor.withAlpha(0.04).toColor(),
            borderStrokeWidth: 0,
          ),
        );

        // concentric ring 2: Middle green shield
        circles.add(
          CircleMarker(
            point: point,
            radius: radius * 0.625, // 250m
            useRadiusInMeter: true,
            color: baseColor.withAlpha(0.09).toColor(),
            borderStrokeWidth: 0,
          ),
        );

        // concentric ring 3: Inner core shield
        circles.add(
          CircleMarker(
            point: point,
            radius: radius * 0.25, // 100m
            useRadiusInMeter: true,
            color: baseColor.withAlpha(0.18).toColor(),
            borderColor: baseColor.withLightness(0.35).withAlpha(0.4).toColor(),
            borderStrokeWidth: 1.0,
          ),
        );
      }
    }

    // Helper functions for complaint filtering
    bool matchesCategory(ComplaintModel c) {
      if (_selectedCategoryFilter == 'All') return true;
      final cat = (c.crimeCategory ?? 'Other').toLowerCase();
      return cat == _selectedCategoryFilter.toLowerCase();
    }

    bool matchesTimeline(ComplaintModel c) {
      if (_selectedTimelineFilter == 'All') return true;
      final date = c.incidentDatetime ?? c.createdAt;
      if (date == null) return false;
      final diff = DateTime.now().difference(date).inDays;
      if (_selectedTimelineFilter == '30days') return diff <= 30;
      if (_selectedTimelineFilter == '90days') return diff <= 90;
      return true;
    }

    // 2. Perform density spatial clustering
    final distance = const Distance();
    final clusters = <_HotspotCluster>[];

    for (final c in complaints) {
      if (c.latitude == null || c.longitude == null) continue;
      if (!matchesCategory(c) || !matchesTimeline(c)) continue;

      final point = LatLng(c.latitude!, c.longitude!);
      
      // Determine complaint weight based on severity
      final cat = (c.crimeCategory ?? 'Other').toLowerCase();
      double weight = 1.0;
      if (cat.contains('murder') ||
          cat.contains('kill') ||
          cat.contains('violence') ||
          cat.contains('assault') ||
          cat.contains('weapon') ||
          cat.contains('armed') ||
          cat.contains('shooting') ||
          cat.contains('riot')) {
        weight = 3.0; // High severity
      } else if (cat.contains('robbery') ||
          cat.contains('hijack') ||
          cat.contains('theft') ||
          cat.contains('burglary') ||
          cat.contains('harassment') ||
          cat.contains('drug') ||
          cat.contains('kidnap')) {
        weight = 2.0; // Medium severity
      }

      _HotspotCluster? nearestCluster;
      double minDistance = double.infinity;

      for (final cluster in clusters) {
        final dist = distance.as(LengthUnit.Meter, cluster.center, point);
        if (dist < minDistance) {
          minDistance = dist;
          nearestCluster = cluster;
        }
      }

      // If within 150 meters, aggregate to nearest cluster
      if (nearestCluster != null && minDistance < 150.0) {
        nearestCluster.sumLat += point.latitude;
        nearestCluster.sumLng += point.longitude;
        nearestCluster.count++;
        nearestCluster.totalWeight += weight;
        nearestCluster.complaints.add(c);
      } else {
        // Create new cluster
        clusters.add(
          _HotspotCluster()
            ..sumLat = point.latitude
            ..sumLng = point.longitude
            ..count = 1
            ..totalWeight = weight
            ..complaints.add(c),
        );
      }
    }

    // 3. Draw Crime Hotspots (with concentric glowing circles)
    if (_showHotspots) {
      for (final cluster in clusters) {
        final w = cluster.totalWeight;
        final point = cluster.center;

        double radius;
        HSLColor hslColor;

        if (w < 2.0) {
          // Low severity / Single incident: Yellow
          radius = 160.0;
          hslColor = const HSLColor.fromAHSL(1.0, 48, 1.0, 0.5);
        } else if (w < 5.0) {
          // Medium severity / 2-3 incidents: Orange
          radius = 220.0;
          hslColor = const HSLColor.fromAHSL(1.0, 28, 1.0, 0.5);
        } else {
          // High severity / 4+ incidents: Red/Crimson
          radius = 290.0;
          hslColor = const HSLColor.fromAHSL(1.0, 0, 1.0, 0.48);
        }

        // concentric ring 1: Outer faint glow
        circles.add(
          CircleMarker(
            point: point,
            radius: radius,
            useRadiusInMeter: true,
            color: hslColor.withAlpha(0.06).toColor(),
            borderStrokeWidth: 0,
          ),
        );

        // concentric ring 2: Middle glow
        circles.add(
          CircleMarker(
            point: point,
            radius: radius * 0.65,
            useRadiusInMeter: true,
            color: hslColor.withAlpha(0.14).toColor(),
            borderStrokeWidth: 0,
          ),
        );

        // concentric ring 3: Inner core glow
        circles.add(
          CircleMarker(
            point: point,
            radius: radius * 0.35,
            useRadiusInMeter: true,
            color: hslColor.withAlpha(0.24).toColor(),
            borderStrokeWidth: 0,
          ),
        );

        // concentric ring 4: Hotspot center core
        circles.add(
          CircleMarker(
            point: point,
            radius: radius * 0.15,
            useRadiusInMeter: true,
            color: hslColor.withAlpha(0.42).toColor(),
            borderColor: hslColor.withLightness(hslColor.lightness * 0.7).withAlpha(0.7).toColor(),
            borderStrokeWidth: 1.0,
          ),
        );
      }
    }

    return circles;
  }

  // ─── Search / Dropdown Overlay ───────────────────────────────────────────────

  Widget _buildSearchOverlay(StationMapState state) {
    return Positioned(
      top: kToolbarHeight + MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: SearchAnchor(
        viewBackgroundColor: Colors.white,
        viewSurfaceTintColor: Colors.transparent,
        dividerColor: Colors.grey.shade200,
        headerTextStyle: GoogleFonts.inter(color: Colors.black87, fontSize: 16),
        headerHintStyle: GoogleFonts.inter(color: Colors.black54, fontSize: 16),
        builder: (context, controller) {
          return SearchBar(
            controller: controller,
            padding: const WidgetStatePropertyAll<EdgeInsets>(
              EdgeInsets.symmetric(horizontal: 16),
            ),
            onTap: () => controller.openView(),
            onChanged: (_) => controller.openView(),
            leading: const Icon(Icons.search_rounded, color: Colors.black54),
            hintText: state.hasStations
                ? 'Search places, stations...'
                : 'Search police stations...',
            hintStyle: WidgetStatePropertyAll(
              GoogleFonts.inter(color: Colors.black54, fontSize: 14),
            ),
            backgroundColor: WidgetStatePropertyAll(
              Colors.white.withValues(alpha: 0.95),
            ),
            surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
            shadowColor: const WidgetStatePropertyAll(Colors.transparent),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side:
                    BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
            ),
            textStyle: WidgetStatePropertyAll(
              GoogleFonts.inter(color: Colors.black87, fontSize: 14),
            ),
          );
        },
        suggestionsBuilder: (context, controller) {
          final query = controller.text;
          final normalizedQuery = query.toLowerCase().trim();
          final queryWords = normalizedQuery.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();

          final filteredStations = queryWords.isEmpty
              ? state.stations
              : state.stations
                  .where((s) {
                    final nameLower = s.name.toLowerCase();
                    final addressLower = s.address.toLowerCase();
                    return queryWords.every((word) => nameLower.contains(word) || addressLower.contains(word));
                  })
                  .toList();

          final filteredLandmarks = queryWords.isEmpty
              ? cityLandmarks
              : cityLandmarks
                  .where((lm) {
                    final nameLower = lm.name.toLowerCase();
                    return queryWords.every((word) => nameLower.contains(word) || 
                                                     (word == 'leading' && nameLower.contains('lu')) ||
                                                     (word == 'lu' && nameLower.contains('leading')));
                  })
                  .toList();

          final stationTiles = filteredStations.map((s) {
            final dist = _distLabel(state.userLocation, s.location);
            return ListTile(
              tileColor: Colors.white.withValues(alpha: 0.98),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: s.isAutoSelected
                      ? AppColors.accent.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_police_rounded,
                  color:
                      s.isAutoSelected ? AppColors.accent : AppColors.primary,
                  size: 18,
                ),
              ),
              title: Text(s.name,
                  style: GoogleFonts.inter(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              subtitle: Text(
                dist.isEmpty ? s.address : dist,
                style: GoogleFonts.inter(color: Colors.black54, fontSize: 12),
              ),
              trailing: s.isAutoSelected
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        state.selectionSource == SelectionSource.jurisdiction
                            ? 'YOURS'
                            : 'NEAREST',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                      ),
                    )
                  : null,
              onTap: () {
                setState(() {
                  _searchPinLocation = null;
                  _searchPinName = null;
                });
                controller.closeView(s.name);
                Future.delayed(const Duration(milliseconds: 400), () {
                  if (!mounted) return;
                  ref.read(stationMapProvider.notifier).selectStation(s);
                  _moveMap(s.location, 15.0);
                });
              },
            );
          });

          final landmarkTiles = filteredLandmarks.map((lm) {
            final dist = _distLabel(state.userLocation, lm.location);
            final color = _getColorForType(lm.type);
            final icon = _getIconForType(lm.type);

            return ListTile(
              tileColor: Colors.white.withValues(alpha: 0.98),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
              title: Text(lm.name,
                  style:
                      GoogleFonts.inter(color: Colors.black87, fontSize: 14)),
              subtitle: Text(
                dist.isEmpty ? 'Sylhet' : dist,
                style: GoogleFonts.inter(color: Colors.black54, fontSize: 12),
              ),
              onTap: () {
                setState(() {
                  _searchPinLocation = null;
                  _searchPinName = null;
                });
                controller.closeView(lm.name);
                Future.delayed(const Duration(milliseconds: 400), () {
                  if (mounted) _moveMap(lm.location, 16.0);
                });
              },
            );
          });

          return [
            ...stationTiles,
            ...landmarkTiles,
            if (query.isNotEmpty)
              FutureBuilder<http.Response>(
                // Native debounce: wait 400ms before making the API request.
                // Because SearchAnchor rebuilds on every keystroke, this prevents hammering the API.
                future:
                    Future.delayed(const Duration(milliseconds: 400), () async {
                  try {
                    String searchQ = query;
                    final lowerQ = query.toLowerCase();
                    if (!lowerQ.contains('sylhet') && !lowerQ.contains('bangladesh')) {
                      searchQ = '$query, Sylhet';
                    }
                    return await http.get(
                      Uri.parse(
                          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(searchQ)}&format=json&limit=8&viewbox=91.75,24.98,92.00,24.80'),
                      headers: {'User-Agent': 'ShieldX_Safety_Application/1.0.0 (contact: support@shieldx.com)'},
                    );
                  } catch (e) {
                    // Return empty json array on failure to prevent app crash
                    return http.Response('[]', 500);
                  }
                }),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const SizedBox.shrink();
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }

                  if (snapshot.hasData && snapshot.data?.statusCode == 200) {
                    final List data = jsonDecode(snapshot.data!.body);

                    if (data.isEmpty &&
                        filteredStations.isEmpty &&
                        filteredLandmarks.isEmpty) {
                      return ListTile(
                        title: Text(
                          'No results found',
                          style: GoogleFonts.inter(color: Colors.black54),
                        ),
                      );
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: data.map((place) {
                        final lat = double.parse(place['lat']);
                        final lon = double.parse(place['lon']);
                        final location = LatLng(lat, lon);
                        final name = place['display_name'].split(',').first;
                        return ListTile(
                          tileColor: Colors.white.withValues(alpha: 0.98),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.place_rounded,
                                color: Colors.orange, size: 18),
                          ),
                          title: Text(name,
                              style: GoogleFonts.inter(
                                  color: Colors.black87, fontSize: 14)),
                          subtitle: Text(
                            'Global Search',
                            style: GoogleFonts.inter(
                                color: Colors.black54, fontSize: 12),
                          ),
                          onTap: () {
                            setState(() {
                              _searchPinLocation = location;
                              _searchPinName = name;
                            });
                            controller.closeView(name);
                            Future.delayed(const Duration(milliseconds: 400),
                                () {
                              if (mounted) _moveMap(location, 16.0);
                            });
                          },
                        );
                      }).toList(),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            if (query.length <= 3 &&
                filteredStations.isEmpty &&
                filteredLandmarks.isEmpty)
              ListTile(
                title: Text(
                  'No results found',
                  style: GoogleFonts.inter(color: Colors.black54),
                ),
              ),
          ];
        },
      )
          .animate()
          .fadeIn(duration: 400.ms)
          .slideY(begin: -0.15, duration: 400.ms),
    );
  }

  // ─── Thana Filter Chips ──────────────────────────────────────────────────────

  Widget _buildThanaChips(StationMapState state, StationMapNotifier notifier) {
    final thanas = state.availableThanas;
    if (thanas.isEmpty) return const SizedBox.shrink();
    // Check if the current selected station has assigned officers to know if the collapsible is shown
    final hasAssignedOfficers = state.selectedStation != null &&
        ref.watch(officersProvider).when(
          data: (allOfficers) {
            final s = state.selectedStation!;
            final assigned = allOfficers.where((o) {
              if (o.station == null || o.station!.isEmpty) return false;
              final oStation = o.station!.toLowerCase().trim();
              final sName = s.name.toLowerCase();
              final sThana = s.thana.toLowerCase();
              final sJurisdiction = (s.jurisdiction ?? '').toLowerCase();

              return oStation.contains(sThana) ||
                  sThana.contains(oStation) ||
                  oStation.contains(sName) ||
                  sName.contains(oStation) ||
                  (sJurisdiction.isNotEmpty && (oStation.contains(sJurisdiction) || sJurisdiction.contains(oStation))) ||
                  (sThana.contains('kotwali') && (oStation.contains('kawt') || oStation.contains('kotw') || oStation.contains('qotw')));
            }).toList();
            return assigned.isNotEmpty;
          },
          loading: () => false,
          error: (_, __) => false,
        );

    final bottomOffset = state.selectedStation != null
        ? (hasAssignedOfficers
            ? (_onDutyExpanded ? 310.0 : 255.0)
            : 220.0) // If no officers, card is much shorter!
        : 16.0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      bottom: bottomOffset,
      left: 0,
      right: 0,
      height: 40,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: thanas.length,
        itemBuilder: (context, i) {
          final thana = thanas[i];
          final active = state.activeThana == thana;
          return GestureDetector(
            onTap: () => notifier.setThanaFilter(thana),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? AppColors.primary : Colors.grey.shade300,
                  width: active ? 0 : 1,
                ),
                boxShadow: [
                  if (active)
                    BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 8)
                  else
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    active
                        ? Icons.local_police_rounded
                        : Icons.location_city_rounded,
                    size: 13,
                    color: active ? Colors.white : Colors.black54,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    thana,
                    style: GoogleFonts.inter(
                      color: active ? Colors.white : Colors.black87,
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ).animate().fadeIn(duration: 350.ms),
    );
  }


  // ─── Station Detail Card ─────────────────────────────────────────────────────

  Widget _buildStationDetailCard(StationMapState state) {
    final s = state.selectedStation!;
    final isJurisdiction = s.isAutoSelected;

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, -4),
              )
            ]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row: icon + name + close ───────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_police_rounded,
                      color: AppColors.primaryLight, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Row(
                        children: [
                          Text(
                            _distLabel(state.userLocation, s.location),
                            style: GoogleFonts.inter(
                                color: AppColors.primaryLight,
                                fontWeight: FontWeight.w600,
                                fontSize: 11),
                          ),
                          if (isJurisdiction) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Your Jurisdiction',
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    ref.read(stationMapProvider.notifier).selectStation(null);
                  },
                  child: const Icon(Icons.close_rounded,
                      color: Colors.black38, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Info Section (address / hours / phone) ──────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(Icons.location_on_outlined,
                    s.address.isNotEmpty ? s.address : '—'),
                const SizedBox(height: 5),
                _infoRow(Icons.access_time_rounded,
                    s.details.isNotEmpty ? s.details : 'Open 24 Hours'),
                const SizedBox(height: 5),
                _infoRow(Icons.phone_outlined,
                    s.phone.isNotEmpty ? s.phone : '—'),
              ],
            ),
            const SizedBox(height: 12),

            // ── Buttons Row (horizontal, side by side, full width) ────
            Row(
              children: [
                Expanded(
                  child: _compactActionButton(
                    icon: Icons.phone_in_talk_rounded,
                    label: 'Call',
                    color: AppColors.primary,
                    filled: true,
                    onTap: s.phone.isNotEmpty
                        ? () => _callStation(s.phone)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _compactActionButton(
                    icon: Icons.report_problem_rounded,
                    label: 'Report',
                    color: const Color(0xFFE65100),
                    filled: true,
                    onTap: () {
                      final stationName = Uri.encodeComponent(s.name);
                      context.push('/submit-complaint?station=$stationName');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _compactActionButton(
                    icon: Icons.directions_rounded,
                    label: 'Navigate',
                    color: AppColors.primary,
                    filled: true,
                    onTap: () => _openMaps(s),
                  ),
                ),
              ],
            ),

            // ── On-Duty Officers collapsible ──────────────────────────
            ref.watch(officersProvider).when(
              data: (allOfficers) {
                final assigned = allOfficers.where((o) {
                  if (o.station == null || o.station!.isEmpty) return false;
                  final oStation = o.station!.toLowerCase().trim();
                  final sName = s.name.toLowerCase();
                  final sThana = s.thana.toLowerCase();
                  final sJurisdiction = (s.jurisdiction ?? '').toLowerCase();

                  return oStation.contains(sThana) ||
                      sThana.contains(oStation) ||
                      oStation.contains(sName) ||
                      sName.contains(oStation) ||
                      (sJurisdiction.isNotEmpty && (oStation.contains(sJurisdiction) || sJurisdiction.contains(oStation))) ||
                      (sThana.contains('kotwali') && (oStation.contains('kawt') || oStation.contains('kotw') || oStation.contains('qotw')));
                }).toList();

                if (assigned.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 14, color: Colors.black12),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _onDutyExpanded = !_onDutyExpanded;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
                        child: Row(
                          children: [
                            const Icon(Icons.badge_outlined, size: 12, color: AppColors.primary),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'On-Duty Officers (${assigned.length})',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            AnimatedRotation(
                              turns: _onDutyExpanded ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 15,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: _onDutyExpanded
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                SizedBox(
                                  height: 48,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: assigned.length,
                                    itemBuilder: (context, index) {
                                      final officer = assigned[index];
                                      return Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.grey.shade200),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 11,
                                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                              child: const Icon(Icons.person_rounded, size: 11, color: AppColors.primary),
                                            ),
                                            const SizedBox(width: 6),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      officer.name ?? 'Officer',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w700,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 3),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                                      decoration: BoxDecoration(
                                                        color: (officer.isActive ? AppColors.success : AppColors.textHint)
                                                            .withValues(alpha: 0.12),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        officer.isActive ? 'Active' : 'Off',
                                                        style: GoogleFonts.inter(
                                                          fontSize: 6,
                                                          fontWeight: FontWeight.w800,
                                                          color: officer.isActive ? AppColors.success : AppColors.textHint,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  officer.rank ?? 'Constable',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 8,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (officer.contact != null && officer.contact!.isNotEmpty) ...[
                                              const SizedBox(width: 6),
                                              GestureDetector(
                                                onTap: () => _callStation(officer.contact!),
                                                child: const Icon(Icons.phone_in_talk_rounded, size: 12, color: AppColors.primary),
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 2),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, duration: 300.ms),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 11, color: Colors.black45),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 10, color: Colors.black54, height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _compactActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool filled,
    required VoidCallback? onTap,
    double width = double.infinity,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: onTap == null
              ? Colors.grey.shade200
              : filled
                  ? color
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: filled ? null : Border.all(color: color, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 12,
                color: onTap == null
                    ? Colors.grey
                    : filled
                        ? Colors.white
                        : color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: onTap == null
                    ? Colors.grey
                    : filled
                        ? Colors.white
                        : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Zoom Controls ─────────────────────────────────────────────────────────

  // ─── Zoom Controls ─────────────────────────────────────────────────────────


  // ─── Heatmap Filter Overlay ──────────────────────────────────────────────────

  Widget _buildHeatmapFilterPanel(StationMapState state) {
    if (!_showHeatmap) return const SizedBox.shrink();

    return Positioned(
      top: kToolbarHeight + MediaQuery.of(context).padding.top + 74, // Sits nicely below the search bar
      left: 16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: _isFilterPanelOpen ? 250 : 42,
        height: _isFilterPanelOpen ? 370 : 42,
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.55)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: _isFilterPanelOpen
              ? _buildExpandedFilterPanel()
              : _buildCollapsedFilterPanel(),
        ),
      ),
    );
  }

  Widget _buildCollapsedFilterPanel() {
    return InkWell(
      onTap: () => setState(() => _isFilterPanelOpen = true),
      child: const Center(
        child: Icon(
          Icons.tune_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildExpandedFilterPanel() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_fire_department_rounded,
                      color: AppColors.error, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Heatmap Settings',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => setState(() => _isFilterPanelOpen = false),
                child: const Icon(Icons.close_rounded,
                    color: AppColors.textHint, size: 16),
              ),
            ],
          ),
          const Divider(color: AppColors.cardBorder, height: 16),
          
          // Layer Toggles
          Text(
            'LAYERS',
            style: GoogleFonts.inter(
              color: AppColors.textHint,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          _buildFilterSwitchRow(
            label: 'Safe Zones',
            color: Colors.greenAccent,
            value: _showSafeZones,
            onChanged: (val) => setState(() => _showSafeZones = val),
          ),
          _buildFilterSwitchRow(
            label: 'Crime Hotspots',
            color: AppColors.error,
            value: _showHotspots,
            onChanged: (val) => setState(() => _showHotspots = val),
          ),
          const SizedBox(height: 12),

          // Crime Category Filter
          Text(
            'CRIME TYPE',
            style: GoogleFonts.inter(
              color: AppColors.textHint,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => _showCrimeTypePicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.cardBorder.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          _selectedCategoryFilter == 'All'
                              ? Icons.grid_view_rounded
                              : _getIconForCategory(_selectedCategoryFilter),
                          color: _selectedCategoryFilter == 'All'
                              ? AppColors.primaryLight
                              : _getColorForCategory(_selectedCategoryFilter),
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedCategoryFilter == 'All'
                                ? 'All Crime Types'
                                : _selectedCategoryFilter,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textHint,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Recency / Time Filter
          Text(
            'RECENCY',
            style: GoogleFonts.inter(
              color: AppColors.textHint,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildTimelineChip('All', 'All Time'),
              const SizedBox(width: 4),
              _buildTimelineChip('90days', '90 Days'),
              const SizedBox(width: 4),
              _buildTimelineChip('30days', '30 Days'),
            ],
          ),
          const SizedBox(height: 16),

          // Legend description
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegendItem(Colors.greenAccent, 'Safe Zone (Station Buffer)'),
                const SizedBox(height: 4),
                _buildLegendItem(Colors.yellow, 'Low Risk (1 Incident)'),
                const SizedBox(height: 4),
                _buildLegendItem(Colors.orange, 'Moderate Risk (2-3 Incidents)'),
                const SizedBox(height: 4),
                _buildLegendItem(Colors.red, 'High Risk (4+ / Major Crimes)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSwitchRow({
    required String label,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Transform.scale(
            scale: 0.65,
            child: SizedBox(
              height: 16,
              width: 28,
              child: Switch(
                value: value,
                activeColor: color,
                activeTrackColor: color.withValues(alpha: 0.3),
                inactiveThumbColor: Colors.grey.shade400,
                inactiveTrackColor: Colors.grey.shade700,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForCategory(String cat) {
    switch (cat) {
      case 'Theft': return Icons.shopping_bag_outlined;
      case 'Robbery': return Icons.dangerous_outlined;
      case 'Assault': return Icons.flash_on_rounded;
      case 'Fraud': return Icons.credit_card_off_rounded;
      case 'Cybercrime': return Icons.phonelink_lock_rounded;
      case 'Drug Offense': return Icons.medical_services_outlined;
      case 'Murder': return Icons.gavel_rounded;
      case 'Kidnapping': return Icons.person_search_rounded;
      case 'Sexual Harassment': return Icons.warning_amber_rounded;
      case 'Domestic Violence': return Icons.home_repair_service_rounded;
      case 'Vandalism': return Icons.format_paint_rounded;
      case 'Corruption': return Icons.monetization_on_outlined;
      case 'Traffic Violation': return Icons.traffic_rounded;
      case 'Other':
      default: return Icons.help_outline_rounded;
    }
  }

  Color _getColorForCategory(String cat) {
    switch (cat) {
      case 'Theft': return const Color(0xFFF59E0B);
      case 'Robbery': return const Color(0xFFEF4444);
      case 'Assault': return const Color(0xFFFF5252);
      case 'Fraud': return const Color(0xFFAB47BC);
      case 'Cybercrime': return const Color(0xFF29B6F6);
      case 'Drug Offense': return const Color(0xFF66BB6A);
      case 'Murder': return const Color(0xFFD32F2F);
      case 'Kidnapping': return const Color(0xFF78909C);
      case 'Sexual Harassment': return const Color(0xFFFF4081);
      case 'Domestic Violence': return const Color(0xFFEC407A);
      case 'Vandalism': return const Color(0xFF8D6E63);
      case 'Corruption': return const Color(0xFFFFB300);
      case 'Traffic Violation': return const Color(0xFF26A69A);
      case 'Other':
      default: return const Color(0xFF90A4AE);
    }
  }

  void _showCrimeTypePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        final categories = ['All', ...AppConstants.crimeCategories];
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select Crime Type',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: categories.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.white.withValues(alpha: 0.1),
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = _selectedCategoryFilter == cat;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (cat == 'All' ? AppColors.primary : _getColorForCategory(cat)).withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              cat == 'All' ? Icons.grid_view_rounded : _getIconForCategory(cat),
                              color: isSelected
                                  ? (cat == 'All' ? AppColors.primaryLight : _getColorForCategory(cat))
                                  : Colors.white.withValues(alpha: 0.6),
                              size: 16,
                            ),
                          ),
                          title: Text(
                            cat == 'All' ? 'All Crime Types' : cat,
                            style: GoogleFonts.inter(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18)
                              : null,
                          onTap: () {
                            setState(() => _selectedCategoryFilter = cat);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildTimelineChip(String code, String label) {
    final active = _selectedTimelineFilter == code;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTimelineFilter = code),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: active ? AppColors.primaryLight : Colors.transparent,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: active ? Colors.white : AppColors.textSecondary,
              fontSize: 8,
              fontWeight: active ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 4,
                spreadRadius: 1,
              )
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 8, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // ─── Zoom Controls ─────────────────────────────────────────────────────────

  Widget _buildZoomControls(StationMapState state) {
    // Offset the zoom buttons so they sit above the Thana chips and Station list
    final bottomOffset = state.selectedStation != null ? 215.0 : 16.0;
    final simActive = ref.watch(gpsSimulationProvider).isSimulationActive;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      right: 16,
      bottom: state.hasStations ? bottomOffset + 180 : bottomOffset,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'gps_simulation_toggle',
            backgroundColor: simActive
                ? const Color(0xFF10B981)
                : Colors.white.withValues(alpha: 0.95),
            foregroundColor: simActive ? Colors.white : AppColors.primary,
            elevation: 3,
            onPressed: _showGpsControlPanel,
            child: Icon(
              simActive
                  ? Icons.sensors_rounded
                  : Icons.sensors_off_rounded,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: 'heatmap_toggle',
            backgroundColor: _showHeatmap
                ? AppColors.error
                : Colors.white.withValues(alpha: 0.95),
            foregroundColor: _showHeatmap ? Colors.white : AppColors.primary,
            elevation: 3,
            onPressed: () {
              setState(() {
                _showHeatmap = !_showHeatmap;
                if (_showHeatmap) {
                  _isFilterPanelOpen = true; // Auto-open settings overlay
                }
              });
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _showHeatmap
                        ? 'Crime Hotspot Heatmap enabled. Showing safe zones (green) & crime hotspots (yellow/red).'
                        : 'Heatmap disabled.',
                    style: GoogleFonts.inter(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  duration: const Duration(seconds: 3),
                  backgroundColor:
                      _showHeatmap ? AppColors.error : AppColors.primary,
                ),
              );
            },
            child: Icon(
              _showHeatmap
                  ? Icons.local_fire_department_rounded
                  : Icons.bubble_chart_rounded,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: 'zoom_in',
            backgroundColor: Colors.white.withValues(alpha: 0.95),
            foregroundColor: AppColors.primary,
            elevation: 3,
            onPressed: () {
              if (_isMapReady) {
                final currentZoom = _mapController.camera.zoom;
                _mapController.move(_mapController.camera.center,
                    (currentZoom + 1.0).clamp(3.0, 18.0));
              }
            },
            child: const Icon(Icons.add_rounded, size: 24),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'zoom_out',
            backgroundColor: Colors.white.withValues(alpha: 0.95),
            foregroundColor: AppColors.primary,
            elevation: 3,
            onPressed: () {
              if (_isMapReady) {
                final currentZoom = _mapController.camera.zoom;
                _mapController.move(_mapController.camera.center,
                    (currentZoom - 1.0).clamp(3.0, 18.0));
              }
            },
            child: const Icon(Icons.remove_rounded, size: 24),
          ),
        ],
      ),
    );
  }

  void _showGpsControlPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final currentSimState = ref.watch(gpsSimulationProvider);
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: AppColors.cardBorder, width: 1.5),
                ),
              ),
              padding: const EdgeInsets.only(
                top: 16,
                left: 20,
                right: 20,
                bottom: 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.textHint.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(
                        Icons.sensors_rounded,
                        color: AppColors.accent,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GPS Simulation Panel',
                              style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Override browser GPS with live simulated coordinates',
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildGpsOptionTile(
                    title: 'Real Browser GPS',
                    subtitle: 'Use default device/browser geolocation sensor',
                    icon: Icons.gps_off_rounded,
                    isActive: !currentSimState.isSimulationActive,
                    onTap: () {
                      ref.read(gpsSimulationProvider.notifier).disableSimulation();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Switched to Real Browser GPS mode.',
                            style: GoogleFonts.inter(
                                color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildGpsOptionTile(
                    title: 'Simulate Kajolshah beside Medinova',
                    subtitle: '24.89996, 91.87030 (Your Actual Location)',
                    icon: Icons.location_on_rounded,
                    isActive: currentSimState.isSimulationActive &&
                        currentSimState.latitude == 24.89996 &&
                        currentSimState.longitude == 91.87030,
                    onTap: () {
                      ref.read(gpsSimulationProvider.notifier).enableSimulation(
                            lat: 24.89996,
                            lng: 91.87030,
                            name: 'Kajolshah (beside Medinova)',
                          );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Simulating location: Kajolshah beside Medinova Diagnostic Center',
                            style: GoogleFonts.inter(
                                color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildGpsOptionTile(
                    title: 'Custom Map Pin',
                    subtitle: currentSimState.isSimulationActive &&
                            (currentSimState.latitude != 24.89996 ||
                                currentSimState.longitude != 91.87030)
                        ? 'Active: ${currentSimState.latitude.toStringAsFixed(5)}, ${currentSimState.longitude.toStringAsFixed(5)}'
                        : 'Tap anywhere on the map to place your custom pin',
                    icon: Icons.touch_app_rounded,
                    isActive: currentSimState.isSimulationActive &&
                        (currentSimState.latitude != 24.89996 ||
                            currentSimState.longitude != 91.87030),
                    onTap: () {
                      ref.read(gpsSimulationProvider.notifier).enableSimulation(
                            lat: currentSimState.latitude,
                            lng: currentSimState.longitude,
                            name: 'Custom Location',
                          );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Custom location override enabled. Tap anywhere on the map to set coordinates.',
                            style: GoogleFonts.inter(
                                color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: Colors.indigoAccent,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGpsOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accent.withValues(alpha: 0.1)
              : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppColors.accent
                : AppColors.cardBorder.withValues(alpha: 0.5),
            width: isActive ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.accent.withValues(alpha: 0.2)
                    : AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(
                icon,
                color: isActive ? AppColors.accent : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: isActive ? AppColors.accent : AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.accent,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(StationMapState state) {
    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primaryLight),
            const SizedBox(height: 24),
            Text(
              'Detecting Your Jurisdiction...',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Finding the correct police station for your area',
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ).animate().fadeIn(),
    );
  }

  // ─── Error Overlay ───────────────────────────────────────────────────────────

  Widget _buildErrorOverlay(
      StationMapState state, StationMapNotifier notifier) {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              state.isPermissionDenied
                  ? Icons.lock_outline_rounded
                  : Icons.location_off_rounded,
              color: AppColors.error,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              state.isPermissionDenied
                  ? 'Location Access Denied'
                  : 'Location Unavailable',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              state.errorMessage ??
                  'Please enable location permissions to detect your nearest police station automatically.',
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GradientButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              onTap: () => notifier.refreshLocation(),
              width: 200,
            ),
          ],
        ),
      ),
    );
  }
}

class _GpsUserLocationMarker extends StatelessWidget {
  const _GpsUserLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer pulsing ring 1: wide soft glow
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .scale(
              begin: const Offset(0.4, 0.4),
              end: const Offset(1.0, 1.0),
              duration: 1600.ms,
              curve: Curves.easeOutCubic,
            )
            .fadeOut(begin: 0.8, duration: 1600.ms),
        // Outer pulsing ring 2: tighter glow
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1.0, 1.0),
              duration: 1600.ms,
              delay: 350.ms,
              curve: Curves.easeOutCubic,
            )
            .fadeOut(begin: 1.0, duration: 1600.ms, delay: 350.ms),
        // Static white background circle for contrast/border
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2.0),
              ),
            ],
          ),
        ),
        // Central bright blue solid dot - beautiful and BIG!
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class _UserLocationHighlightMarker extends StatelessWidget {
  const _UserLocationHighlightMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer pulse ring
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .scale(
              begin: const Offset(0.6, 0.6),
              end: const Offset(1.0, 1.0),
              duration: 1200.ms,
              curve: Curves.easeOut,
            )
            .fadeOut(begin: 0.8, duration: 1200.ms),
        // Middle ring
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .scale(
              begin: const Offset(0.7, 0.7),
              end: const Offset(1.0, 1.0),
              duration: 1200.ms,
              delay: 200.ms,
              curve: Curves.easeOut,
            )
            .fadeOut(begin: 1.0, duration: 1200.ms, delay: 200.ms),
        // Center marker
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.55),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.my_location_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Text(
                'You are here',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  shadows: [
                    const Shadow(color: Colors.black45, blurRadius: 3),
                  ],
                ),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 300.ms).scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1.0, 1.0),
              duration: 400.ms,
              curve: Curves.elasticOut,
            ),
      ],
    );
  }
}

class _StationMarker extends StatelessWidget {
  final bool isSelected;
  final bool isAutoSelected;
  final SelectionSource selectionSource;

  const _StationMarker({
    required this.isSelected,
    required this.isAutoSelected,
    required this.selectionSource,
  });

  @override
  Widget build(BuildContext context) {
    final color = isAutoSelected ? AppColors.accent : AppColors.primary;
    final badgeLabel = isAutoSelected
        ? (selectionSource == SelectionSource.jurisdiction
            ? 'YOURS'
            : 'NEAREST')
        : null;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (isSelected)
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scale(duration: 1.5.seconds)
              .fadeOut(duration: 1.5.seconds),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                margin: const EdgeInsets.only(bottom: 3),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                        color: color.withValues(alpha: 0.4), blurRadius: 6)
                  ],
                ),
                child: Text(
                  badgeLabel,
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold),
                ),
              ).animate().fadeIn().slideY(begin: 0.5),
            Container(
              padding: EdgeInsets.all(isSelected ? 11 : 8),
              decoration: BoxDecoration(
                color: isSelected ? color : AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                    color: isSelected ? Colors.white : color, width: 2),
                boxShadow: [
                  BoxShadow(
                      color: color.withValues(alpha: 0.45),
                      blurRadius: 12,
                      spreadRadius: 1)
                ],
              ),
              child: Icon(
                Icons.local_police_rounded,
                color: isSelected ? Colors.white : color,
                size: isSelected ? 22 : 18,
              ),
            ),
          ],
        ),
      ],
    )
        .animate(target: isSelected ? 1 : 0)
        .scale(begin: const Offset(0.85, 0.85), end: const Offset(1.15, 1.15));
  }
}

enum PlaceType {
  hospital,
  education,
  transport,
  shopping,
  nature,
  worship,
  general
}

class CityLandmark {
  final String name;
  final LatLng location;
  final PlaceType type;
  const CityLandmark(this.name, this.location, {this.type = PlaceType.general});
}

IconData _getIconForType(PlaceType type) {
  switch (type) {
    case PlaceType.hospital:
      return Icons.local_hospital_rounded;
    case PlaceType.education:
      return Icons.school_rounded;
    case PlaceType.transport:
      return Icons.directions_bus_rounded;
    case PlaceType.shopping:
      return Icons.shopping_bag_rounded;
    case PlaceType.nature:
      return Icons.park_rounded;
    case PlaceType.worship:
      return Icons.mosque_rounded;
    case PlaceType.general:
      return Icons.location_on_rounded;
  }
}

Color _getColorForType(PlaceType type) {
  switch (type) {
    case PlaceType.hospital:
      return const Color(0xFFE57373);
    case PlaceType.education:
      return const Color(0xFFBA68C8);
    case PlaceType.transport:
      return const Color(0xFF64B5F6);
    case PlaceType.shopping:
      return const Color(0xFFFFB74D);
    case PlaceType.nature:
      return const Color(0xFF81C784);
    case PlaceType.worship:
      return const Color(0xFF4DB6AC);
    case PlaceType.general:
      return const Color(0xFF90A4AE);
  }
}

const cityLandmarks = [
  // Hospitals
  CityLandmark('Osmani Medical Hospital', LatLng(24.9015, 91.8519),
      type: PlaceType.hospital),
  CityLandmark('Mount Adora Hospital', LatLng(24.9069, 91.8582),
      type: PlaceType.hospital),
  CityLandmark('Al Haramain Hospital', LatLng(24.8872, 91.8797),
      type: PlaceType.hospital),
  CityLandmark('Ragib-Rabeya Medical', LatLng(24.9216, 91.8340),
      type: PlaceType.hospital),

  // Education
  CityLandmark('SUST', LatLng(24.9248, 91.8329), type: PlaceType.education),
  CityLandmark('MC College', LatLng(24.9063, 91.9022),
      type: PlaceType.education),
  CityLandmark('Agricultural Uni', LatLng(24.9069, 91.9038),
      type: PlaceType.education),
  CityLandmark('Engineering College', LatLng(24.9030, 91.9056),
      type: PlaceType.education),
  CityLandmark('Madan Mohan College', LatLng(24.8933, 91.8643),
      type: PlaceType.education),

  // Transport
  CityLandmark('Osmani Airport', LatLng(24.9632, 91.8681),
      type: PlaceType.transport),
  CityLandmark('Kadamtali Bus Terminal', LatLng(24.8778, 91.8706),
      type: PlaceType.transport),
  CityLandmark('Railway Station', LatLng(24.8812, 91.8661),
      type: PlaceType.transport),
  CityLandmark('Kumargaon Bus Stand', LatLng(24.9125, 91.8415),
      type: PlaceType.transport),

  // Shopping
  CityLandmark('Zindabazar', LatLng(24.8967, 91.8687),
      type: PlaceType.shopping),
  CityLandmark('Hasan Market', LatLng(24.8911, 91.8694),
      type: PlaceType.shopping),
  CityLandmark('Al Hamra', LatLng(24.8988, 91.8688), type: PlaceType.shopping),
  CityLandmark('Blue Water', LatLng(24.8962, 91.8681),
      type: PlaceType.shopping),

  // Nature/Tourist
  CityLandmark('Ali Amjad\'s Clock', LatLng(24.8885, 91.8671),
      type: PlaceType.nature),
  CityLandmark('Keane Bridge', LatLng(24.8890, 91.8667),
      type: PlaceType.nature),
  CityLandmark('Malnichhara Tea Estate', LatLng(24.9249, 91.8704),
      type: PlaceType.nature),
  CityLandmark('Lakkatura Tea Garden', LatLng(24.9351, 91.8722),
      type: PlaceType.nature),
  CityLandmark('Tilagor Eco Park', LatLng(24.9014, 91.9090),
      type: PlaceType.nature),

  // Worship/Historical
  CityLandmark('Shahjalal Mazar', LatLng(24.9013, 91.8714),
      type: PlaceType.worship),
  CityLandmark('Shah Poran Mazar', LatLng(24.9028, 91.9048),
      type: PlaceType.worship),
  CityLandmark('Shahi Eidgah', LatLng(24.9049, 91.8799),
      type: PlaceType.worship),

  // General Areas / Intersections
  CityLandmark('Chowhatta', LatLng(24.9015, 91.8698), type: PlaceType.general),
  CityLandmark('Ambarkhana', LatLng(24.9080, 91.8711), type: PlaceType.general),
  CityLandmark('Bandar Bazar', LatLng(24.8911, 91.8711),
      type: PlaceType.general),
  CityLandmark('Subidbazar', LatLng(24.9061, 91.8583), type: PlaceType.general),
  CityLandmark('Mirabazar', LatLng(24.8967, 91.8803), type: PlaceType.general),
  CityLandmark('Tukerbazar', LatLng(24.9079, 91.8336), type: PlaceType.general),
  CityLandmark('Shibganj', LatLng(24.8996, 91.8882), type: PlaceType.general),
  CityLandmark('Upashahar', LatLng(24.8906, 91.8903), type: PlaceType.general),
  CityLandmark('Rikabi Bazar', LatLng(24.8973, 91.8601),
      type: PlaceType.general),

  // Leading University Campus & Surrounding Area
  CityLandmark('LU Main Gate', LatLng(24.8687, 91.8495),
      type: PlaceType.education),
  CityLandmark('LU Central Library', LatLng(24.8692, 91.8488),
      type: PlaceType.education),
  CityLandmark('LU Playground', LatLng(24.8702, 91.8482),
      type: PlaceType.nature),
  CityLandmark('LU Shahid Minar', LatLng(24.8695, 91.8492),
      type: PlaceType.nature),
  CityLandmark('LU Student Hostels', LatLng(24.8680, 91.8510),
      type: PlaceType.general),
  CityLandmark('Ragibnagar Point', LatLng(24.8675, 91.8505),
      type: PlaceType.general),
  CityLandmark('Kamalbazar Mosque', LatLng(24.8655, 91.8530),
      type: PlaceType.worship),
  CityLandmark('Kamalbazar Point', LatLng(24.8648, 91.8542),
      type: PlaceType.transport),
  CityLandmark('Kamalbazar Market', LatLng(24.8652, 91.8545),
      type: PlaceType.shopping),
  CityLandmark('Bilarpar', LatLng(24.8630, 91.8520), type: PlaceType.general),
];

class _HotspotCluster {
  double sumLat = 0;
  double sumLng = 0;
  int count = 0;
  double totalWeight = 0;
  final List<ComplaintModel> complaints = [];

  LatLng get center => LatLng(sumLat / count, sumLng / count);
}

