import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/constants/app_colors.dart';
import '../../data/models/police_station_model.dart';
import '../../providers/station_map_provider.dart';
import '../widgets/common/widgets.dart';

class PoliceStationsScreen extends ConsumerStatefulWidget {
  const PoliceStationsScreen({super.key});

  @override
  ConsumerState<PoliceStationsScreen> createState() =>
      _PoliceStationsScreenState();
}

class _PoliceStationsScreenState extends ConsumerState<PoliceStationsScreen> {
  final MapController _mapController = MapController();
  // Stream that tells CurrentLocationLayer to re-center on the GPS dot
  final _alignPositionStreamController = StreamController<double?>();
  // Position stream initialized once permissions are granted
  Stream<LocationMarkerPosition?>? _positionStream;
  bool _isMapReady = false;
  bool _isUserLocationHighlighted = false;

  LatLng? _searchPinLocation;
  String? _searchPinName;

  // ─── Route state ────────────────────────────────────────────────────────────
  List<LatLng> _routePoints = [];
  bool _isFetchingRoute = false;

  @override
  void initState() {
    super.initState();
    // Defer provider init to avoid calling ref during widget construction
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkAndInit();
    });
  }

  Future<void> _checkAndInit() async {
    // 1. Reset stale state so re-entry doesn't race with onMapReady
    ref.read(stationMapProvider.notifier).reset();
    // 2. Initialize the provider (requests permissions)
    await ref.read(stationMapProvider.notifier).init();

    // 2. If granted, initialize the stream for the blue dot
    final status = await Geolocator.checkPermission();
    if (status == LocationPermission.whileInUse ||
        status == LocationPermission.always) {
      _initPositionStream();
    }
  }

  void _initPositionStream() {
    if (!mounted || _positionStream != null) return;
    final stream =
        const LocationMarkerDataStreamFactory().fromGeolocatorPositionStream(
      stream: Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ),
    );
    // Only call setState if still mounted (safe after async gaps)
    if (mounted) {
      setState(() => _positionStream = stream);
    }
  }

  @override
  void dispose() {
    _alignPositionStreamController.close();
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
    // Push a zoom level into the stream — CurrentLocationLayer will center the map
    _alignPositionStreamController.add(16.0);

    // Fetch the live location to ensure the highlight marker is perfectly synced
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 3)),
      );
      final liveLoc = LatLng(pos.latitude, pos.longitude);
      if (mounted) {
        ref.read(stationMapProvider.notifier).updateUserLocation(liveLoc);
        setState(() => _isUserLocationHighlighted = true);
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) setState(() => _isUserLocationHighlighted = false);
        });
      }
    } catch (_) {
      // Fallback if live location fails
      final userLoc = ref.read(stationMapProvider).userLocation;
      if (userLoc != null && mounted) {
        setState(() => _isUserLocationHighlighted = true);
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) setState(() => _isUserLocationHighlighted = false);
        });
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
                  if (from.latitude != to.latitude || from.longitude != to.longitude) {
                    _mapController.fitCamera(
                      CameraFit.bounds(
                        bounds: bounds,
                        padding: const EdgeInsets.all(30),
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
            content: Text('Failed to calculate route. Please check your connection.'),
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
    _moveMap(s.location, 16.0);
    ref.read(stationMapProvider.notifier).selectStation(s);
    // Optionally close the bottom sheet if one is open
    // Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stationMapProvider);
    final notifier = ref.read(stationMapProvider.notifier);

    // Auto-pan and initialize stream when permission/location becomes available
    // All side-effects are deferred to post-frame to avoid setState-during-build errors
    ref.listen(stationMapProvider, (prev, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        // If permission was previously denied and now it's granted, start the stream
        if ((prev == null || prev.isPermissionDenied) &&
            !next.isPermissionDenied) {
          _initPositionStream();
        }

        // Pan to station if the flag is set, or if it's the initial auto-selection
        if (next.selectedStation != null) {
          final isInitialLoad =
              prev?.selectedStation?.id != next.selectedStation?.id &&
                  next.selectionSource != SelectionSource.manual;

          if (isInitialLoad || next.shouldPanToStation) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _moveMap(next.selectedStation!.location, 14.5);
            });
            // Reset the pan flag so we don't pan on every state rebuild
            if (next.shouldPanToStation) {
              Future.microtask(
                  () => ref.read(stationMapProvider.notifier).resetPanFlag());
            }
          }
          // Fetch route whenever selected station changes and user loc is known
          final stationChanged =
              prev?.selectedStation?.id != next.selectedStation?.id;
          if (stationChanged && next.userLocation != null) {
            _fetchRoute(next.userLocation!, next.selectedStation!.location);
          } else if (stationChanged) {
            _clearRoute();
          }
        } else {
          // Station deselected — clear route
          if (prev?.selectedStation != null) _clearRoute();
        }

        // Pan to user location the first time it becomes available;
        // also fetch route if a station is already selected
        if (prev?.userLocation == null && next.userLocation != null) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _moveMap(next.userLocation!, 14.0);
          });
          if (next.selectedStation != null) {
            _fetchRoute(next.userLocation!, next.selectedStation!.location);
          }
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
          if (state.isLoading) _buildLoadingOverlay(state),
          if (!state.isLoading &&
              (state.isPermissionDenied ||
                  (state.errorMessage != null && state.stations.isEmpty)))
            _buildErrorOverlay(state, notifier),
          if (state.hasStations) _buildThanaChips(state, notifier),
          if (state.hasStations) _buildStationList(state, notifier),
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
        onPressed: () => context.pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Station Map',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white),
          ),
          if (!state.isLoading)
            Text(
              state.activeThana ?? 'Sylhet Metropolitan Police',
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.primaryLight),
            ),
        ],
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
          // On map tap: auto-detect thana from tapped coordinates
          setState(() {
            _searchPinLocation = null;
            _searchPinName = null;
          });
          notifier.onMapTap(latLng);
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
        // Route polyline — drawn below the user dot
        if (_routePoints.length > 1)
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
        // User Location Layer — Google Maps-style blue GPS dot.
        if (_positionStream != null)
          CurrentLocationLayer(
            alignPositionOnUpdate: AlignOnUpdate.once,
            alignDirectionOnUpdate: AlignOnUpdate.never,
            alignPositionStream: _alignPositionStreamController.stream,
            positionStream: _positionStream,
            errorHandler: (e) {
              debugPrint('[LocationLayer] error: $e');
              return null;
            },
            style: LocationMarkerStyle(
              marker: const DefaultLocationMarker(
                color: Colors.blue,
              ),
              markerSize: const Size(20, 20),
              markerDirection: MarkerDirection.heading,
              accuracyCircleColor: Colors.blue.withValues(alpha: 0.18),
              headingSectorColor: Colors.blue.withValues(alpha: 0.35),
              headingSectorRadius: 52,
            ),
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
                child: _UserLocationHighlightMarker(),
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

  // ─── Search / Dropdown Overlay ───────────────────────────────────────────────

  Widget _buildSearchOverlay(StationMapState state) {
    return Positioned(
      top: kToolbarHeight + MediaQuery.of(context).padding.top + 8,
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
          final query = controller.text.toLowerCase();

          final filteredStations = query.isEmpty
              ? state.stations
              : state.stations
                  .where((s) =>
                      s.name.toLowerCase().contains(query) ||
                      s.address.toLowerCase().contains(query))
                  .toList();

          final filteredLandmarks = query.isEmpty
              ? cityLandmarks
              : cityLandmarks
                  .where((lm) =>
                      lm.name.toLowerCase().contains(query) ||
                      (query.contains('leading') && lm.name.contains('LU')))
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
                    return await http.get(
                      Uri.parse(
                          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&viewbox=91.80,24.95,91.95,24.85&bounded=1'),
                      headers: {'User-Agent': 'ShieldX Application'},
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
    final bottomOffset = state.selectedStation != null ? 215.0 : 16.0;
    return Positioned(
      bottom: bottomOffset + 124,
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

  // ─── Horizontal Station List ─────────────────────────────────────────────────

  Widget _buildStationList(StationMapState state, StationMapNotifier notifier) {
    final visibleStations = state.stations; // All 6 SMP stations always shown
    final bottomOffset = state.selectedStation != null ? 215.0 : 16.0;
    return Positioned(
      bottom: bottomOffset,
      left: 0,
      right: 0,
      height: 116,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: visibleStations.length,
        itemBuilder: (context, index) {
          final s = visibleStations[index];
          final isSelected = state.selectedStation?.id == s.id;
          final accent =
              s.isAutoSelected ? AppColors.accent : AppColors.primary;

          return GestureDetector(
            onTap: () {
              notifier.selectStation(s);
              // ref.listen handles _fetchRoute automatically
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 210,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.blue.shade50.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? accent : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                        color: accent.withValues(alpha: 0.25), blurRadius: 12)
                  else
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.name,
                          style: GoogleFonts.inter(
                              color: Colors.black87,
                              fontWeight: FontWeight.w700,
                              fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (s.isAutoSelected)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            state.selectionSource ==
                                    SelectionSource.jurisdiction
                                ? 'YOURS'
                                : 'NEAREST',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 7,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (s.thana.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        s.thana,
                        style: GoogleFonts.inter(
                            color: AppColors.primaryLight,
                            fontSize: 9,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: AppColors.textHint, size: 11),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          s.address,
                          style: GoogleFonts.inter(
                              color: Colors.black54, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _distLabel(state.userLocation, s.location),
                    style: GoogleFonts.inter(
                        color: accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        },
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, duration: 400.ms),
    );
  }

  // ─── Station Detail Card ─────────────────────────────────────────────────────

  Widget _buildStationDetailCard(StationMapState state) {
    final s = state.selectedStation!;
    final isJurisdiction = s.isAutoSelected &&
        state.selectionSource == SelectionSource.jurisdiction;

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(24),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_police_rounded,
                      color: AppColors.primaryLight, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            _distLabel(state.userLocation, s.location),
                            style: GoogleFonts.inter(
                                color: AppColors.primaryLight,
                                fontWeight: FontWeight.w600,
                                fontSize: 12),
                          ),
                          if (isJurisdiction) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Your Jurisdiction',
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.black54, size: 20),
                  onPressed: () {
                    ref.read(stationMapProvider.notifier).selectStation(null);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              s.details,
              style: GoogleFonts.inter(
                  color: Colors.black54, fontSize: 12, height: 1.5),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GradientButton(
                    label: 'Call Station',
                    icon: Icons.phone_in_talk_rounded,
                    onTap:
                        s.phone.isNotEmpty ? () => _callStation(s.phone) : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openMaps(s),
                    icon: const Icon(Icons.directions_rounded,
                        size: 16, color: AppColors.primary),
                    label: const Text('Navigate',
                        style: TextStyle(color: AppColors.primary)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, duration: 300.ms),
    );
  }

  // ─── Zoom Controls ─────────────────────────────────────────────────────────

  Widget _buildZoomControls(StationMapState state) {
    // Offset the zoom buttons so they sit above the Thana chips and Station list
    final bottomOffset = state.selectedStation != null ? 215.0 : 16.0;
    
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      right: 16,
      bottom: state.hasStations ? bottomOffset + 180 : bottomOffset,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'zoom_in',
            backgroundColor: Colors.white.withValues(alpha: 0.95),
            foregroundColor: AppColors.primary,
            elevation: 3,
            onPressed: () {
              if (_isMapReady) {
                final currentZoom = _mapController.camera.zoom;
                _mapController.move(
                    _mapController.camera.center,
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
                _mapController.move(
                    _mapController.camera.center,
                    (currentZoom - 1.0).clamp(3.0, 18.0));
              }
            },
            child: const Icon(Icons.remove_rounded, size: 24),
          ),
        ],
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

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

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
