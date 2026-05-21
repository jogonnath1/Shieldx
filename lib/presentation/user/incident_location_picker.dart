import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_colors.dart';
import '../../data/models/police_station_model.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/station_map_provider.dart';
import '../../providers/gps_simulation_provider.dart';
import '../../providers/location_cache_provider.dart';
import '../../data/models/complaint_model.dart';

// Landmark helper local definitions
enum PickerPlaceType { hospital, education, transport, shopping, nature, worship, general }

class PickerLandmark {
  final String name;
  final LatLng location;
  final PickerPlaceType type;

  const PickerLandmark(this.name, this.location, {this.type = PickerPlaceType.general});
}

const List<PickerLandmark> pickerLandmarks = [
  // Hospitals
  PickerLandmark('Osmani Medical Hospital', LatLng(24.9015, 91.8519), type: PickerPlaceType.hospital),
  PickerLandmark('Mount Adora Hospital', LatLng(24.9069, 91.8582), type: PickerPlaceType.hospital),
  PickerLandmark('Al Haramain Hospital', LatLng(24.8872, 91.8797), type: PickerPlaceType.hospital),
  PickerLandmark('Ragib-Rabeya Medical', LatLng(24.9216, 91.8340), type: PickerPlaceType.hospital),
  
  // Education
  PickerLandmark('SUST University', LatLng(24.9248, 91.8329), type: PickerPlaceType.education),
  PickerLandmark('MC College', LatLng(24.9063, 91.9022), type: PickerPlaceType.education),
  PickerLandmark('Agricultural University', LatLng(24.9069, 91.9038), type: PickerPlaceType.education),
  PickerLandmark('Engineering College', LatLng(24.9030, 91.9056), type: PickerPlaceType.education),
  PickerLandmark('Madan Mohan College', LatLng(24.8933, 91.8643), type: PickerPlaceType.education),
  PickerLandmark('Sylhet Metropolitan University', LatLng(24.9012, 91.8864), type: PickerPlaceType.education),
  PickerLandmark('Leading University', LatLng(24.8622, 91.8115), type: PickerPlaceType.education),
  PickerLandmark('Sylhet Cadet College', LatLng(24.9388, 91.8624), type: PickerPlaceType.education),
  
  // Transport & Junctions
  PickerLandmark('Osmani Airport', LatLng(24.9632, 91.8681), type: PickerPlaceType.transport),
  PickerLandmark('Kadamtali Bus Terminal', LatLng(24.8778, 91.8706), type: PickerPlaceType.transport),
  PickerLandmark('Railway Station', LatLng(24.8812, 91.8661), type: PickerPlaceType.transport),
  PickerLandmark('Kumargaon Bus Stand', LatLng(24.9125, 91.8415), type: PickerPlaceType.transport),
  PickerLandmark('Amberkhana Point', LatLng(24.9082, 91.8682), type: PickerPlaceType.transport),
  PickerLandmark('Humayun Rashid Square', LatLng(24.8688, 91.8688), type: PickerPlaceType.transport),
  PickerLandmark('South Surma Bypass', LatLng(24.8588, 91.8681), type: PickerPlaceType.transport),
  
  // Neighborhoods & Major Points
  PickerLandmark('Zindabazar Point', LatLng(24.8967, 91.8687), type: PickerPlaceType.shopping),
  PickerLandmark('Subidbazar Point', LatLng(24.9038, 91.8569), type: PickerPlaceType.general),
  PickerLandmark('Shibgonj Point', LatLng(24.8989, 91.8906), type: PickerPlaceType.general),
  PickerLandmark('Kumarpara Point', LatLng(24.8985, 91.8795), type: PickerPlaceType.general),
  PickerLandmark('Mirabazar Point', LatLng(24.8942, 91.8785), type: PickerPlaceType.general),
  PickerLandmark('Chauhatta Point', LatLng(24.9006, 91.8669), type: PickerPlaceType.general),
  PickerLandmark('Rikabibazar Point', LatLng(24.8985, 91.8596), type: PickerPlaceType.general),
  PickerLandmark('Bandarbazar Point', LatLng(24.8898, 91.8698), type: PickerPlaceType.shopping),
  PickerLandmark('Lamabazar Point', LatLng(24.8915, 91.8592), type: PickerPlaceType.general),
  PickerLandmark('Pathantula Point', LatLng(24.9033, 91.8436), type: PickerPlaceType.general),
  PickerLandmark('Bagbari Point', LatLng(24.8995, 91.8488), type: PickerPlaceType.general),
  PickerLandmark('Shahjalal Uposhohar', LatLng(24.8912, 91.8845), type: PickerPlaceType.general),
  PickerLandmark('Kumargaon Power Plant', LatLng(24.9185, 91.8210), type: PickerPlaceType.general),
  PickerLandmark('Medinibhag Majortila', LatLng(24.9035, 91.9165), type: PickerPlaceType.general),
  
  // Shopping
  PickerLandmark('Hasan Market', LatLng(24.8911, 91.8694), type: PickerPlaceType.shopping),
  PickerLandmark('Al Hamra Shopping Mall', LatLng(24.8988, 91.8688), type: PickerPlaceType.shopping),
  PickerLandmark('Blue Water Mall', LatLng(24.8962, 91.8681), type: PickerPlaceType.shopping),
  PickerLandmark('Nayasharak Road', LatLng(24.8978, 91.8720), type: PickerPlaceType.shopping),
  PickerLandmark('Rose View Hotel', LatLng(24.8926, 91.8890), type: PickerPlaceType.shopping),
  PickerLandmark('Kamal Bazar Curry & Fish Market', LatLng(24.8465, 91.8252), type: PickerPlaceType.shopping),
  
  // Nature & Attractions
  PickerLandmark('Ali Amjad\'s Clock Tower', LatLng(24.8885, 91.8671), type: PickerPlaceType.nature),
  PickerLandmark('Keane Bridge', LatLng(24.8890, 91.8667), type: PickerPlaceType.nature),
  PickerLandmark('Malnichhara Tea Estate', LatLng(24.9249, 91.8704), type: PickerPlaceType.nature),
  PickerLandmark('Lakkatura Tea Garden', LatLng(24.9351, 91.8722), type: PickerPlaceType.nature),
  PickerLandmark('Kazi Bazar Bridge', LatLng(24.8875, 91.8615), type: PickerPlaceType.nature),
  PickerLandmark('Osmani Stadium', LatLng(24.8994, 91.8628), type: PickerPlaceType.nature),
  
  // Worship
  PickerLandmark('Hazrat Shahjalal Mazar', LatLng(24.9035, 91.8672), type: PickerPlaceType.worship),
  PickerLandmark('Hazrat Shah Paran Mazar', LatLng(24.9095, 91.9312), type: PickerPlaceType.worship),
  PickerLandmark('Shahi Eidgah', LatLng(24.9065, 91.8792), type: PickerPlaceType.worship),
];

class _HotspotCluster {
  double sumLat = 0;
  double sumLng = 0;
  int count = 0;
  double totalWeight = 0;
  final List<ComplaintModel> complaints = [];

  LatLng get center => LatLng(sumLat / count, sumLng / count);
}

class _SafetyInfo {
  final String level;
  final String description;
  final Color color;
  final IconData icon;

  _SafetyInfo({
    required this.level,
    required this.description,
    required this.color,
    required this.icon,
  });
}

class IncidentLocationPicker extends ConsumerStatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;

  const IncidentLocationPicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
  });

  @override
  ConsumerState<IncidentLocationPicker> createState() => _IncidentLocationPickerState();
}

class _IncidentLocationPickerState extends ConsumerState<IncidentLocationPicker> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  
  LatLng? _selectedPoint;
  String? _resolvedAddress;
  String? _detectedStationName;
  bool _isResolvingAddress = false;
  bool _isMapReady = false;
  
  // Search Overlay
  List<PickerLandmark> _searchResults = [];
  bool _showSearchResults = false;
  Timer? _debounce;
  
  // Cache variables for calculations
  final List<_HotspotCluster> _clusters = [];
  bool _isClustered = false;
  _SafetyInfo? _safetyInfo;
  
  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedPoint = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _resolvedAddress = widget.initialAddress;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Spatial Clustering for safety evaluation
  // ─────────────────────────────────────────────────────────────────────────────
  void _calculateClusters(List<ComplaintModel> complaints) {
    if (_isClustered) return;
    
    final distance = const Distance();
    _clusters.clear();

    for (final c in complaints) {
      if (c.latitude == null || c.longitude == null) continue;
      final point = LatLng(c.latitude!, c.longitude!);
      
      double weight = 1.0;
      final cat = (c.crimeCategory ?? 'Other').toLowerCase();
      if (cat.contains('murder') ||
          cat.contains('kill') ||
          cat.contains('violence') ||
          cat.contains('assault') ||
          cat.contains('weapon') ||
          cat.contains('armed') ||
          cat.contains('shooting') ||
          cat.contains('riot')) {
        weight = 3.0;
      } else if (cat.contains('robbery') ||
          cat.contains('hijack') ||
          cat.contains('theft') ||
          cat.contains('burglary') ||
          cat.contains('harassment') ||
          cat.contains('drug') ||
          cat.contains('kidnap')) {
        weight = 2.0;
      }

      _HotspotCluster? nearest;
      double minDistance = double.infinity;

      for (final cl in _clusters) {
        final dist = distance.as(LengthUnit.Meter, cl.center, point);
        if (dist < minDistance) {
          minDistance = dist;
          nearest = cl;
        }
      }

      if (nearest != null && minDistance < 150.0) {
        nearest.sumLat += point.latitude;
        nearest.sumLng += point.longitude;
        nearest.count++;
        nearest.totalWeight += weight;
        nearest.complaints.add(c);
      } else {
        _clusters.add(
          _HotspotCluster()
            ..sumLat = point.latitude
            ..sumLng = point.longitude
            ..count = 1
            ..totalWeight = weight
            ..complaints.add(c),
        );
      }
    }
    
    _isClustered = true;
    if (_selectedPoint != null) {
      _evaluateSafety(_selectedPoint!);
    }
  }

  void _evaluateSafety(LatLng point) {
    final distance = const Distance();
    
    // 1. Check Police Station proximity (Safe Zone)
    bool nearStation = false;
    for (final s in dummyPoliceStations) {
      if (distance.as(LengthUnit.Meter, point, s.location) < 300) {
        nearStation = true;
        break;
      }
    }

    if (nearStation) {
      setState(() {
        _safetyInfo = _SafetyInfo(
          level: 'Safe Zone',
          description: 'Highly secure environment. Close proximity to local police presence.',
          color: const Color(0xFF10B981),
          icon: Icons.gpp_good_rounded,
        );
      });
      return;
    }

    // 2. Check cluster proximity
    _HotspotCluster? nearestCluster;
    double minClusterDistance = double.infinity;

    for (final cl in _clusters) {
      final dist = distance.as(LengthUnit.Meter, point, cl.center);
      if (dist < minClusterDistance) {
        minClusterDistance = dist;
        nearestCluster = cl;
      }
    }

    if (nearestCluster != null && minClusterDistance < 250.0) {
      final w = nearestCluster.totalWeight;
      setState(() {
        if (w < 2.0) {
          _safetyInfo = _SafetyInfo(
            level: 'Low Risk',
            description: 'Isolated incidents reported. Normal caution recommended.',
            color: const Color(0xFFFBBF24),
            icon: Icons.info_outline_rounded,
          );
        } else if (w < 5.0) {
          _safetyInfo = _SafetyInfo(
            level: 'Moderate Risk',
            description: 'Active crime reports detected. Avoid travelling alone at night.',
            color: const Color(0xFFF97316),
            icon: Icons.warning_amber_rounded,
          );
        } else {
          _safetyInfo = _SafetyInfo(
            level: 'High Risk',
            description: 'Critical crime hotspot corridor. Exercise high vigilance.',
            color: const Color(0xFFEF4444),
            icon: Icons.gpp_maybe_rounded,
          );
        }
      });
      return;
    }

    setState(() {
      _safetyInfo = _SafetyInfo(
        level: 'Safe Zone',
        description: 'No significant crime incidents reported in this vicinity.',
        color: const Color(0xFF10B981),
        icon: Icons.verified_user_rounded,
      );
    });
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Geocoding & Thana Resolution
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> _handleMapTap(LatLng point, {String? placeName}) async {
    setState(() {
      _selectedPoint = point;
      _isResolvingAddress = true;
      _resolvedAddress = 'Resolving physical address…';
    });

    // Determine nearest thana
    final thana = resolveSmpThana(point.latitude, point.longitude);
    _detectedStationName = thanaToStationName(thana);

    // Evaluate safety zone
    _evaluateSafety(point);

    // If placeName is not passed, check if the tapped point is near any of our pre-defined landmarks
    String? resolvedPlaceName = placeName;
    if (resolvedPlaceName == null) {
      final distance = const Distance();
      for (final lm in pickerLandmarks) {
        if (distance.as(LengthUnit.Meter, point, lm.location) < 150.0) {
          resolvedPlaceName = lm.name;
          break;
        }
      }
    }

    // HTTP reverse lookup (Nominatim OpenStreetMap)
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1'),
        headers: {
          'User-Agent': 'ShieldX_Safety_Application/1.0.0 (contact: support@shieldx.com)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check if Nominatim itself returned a place name if resolvedPlaceName is still null
        if (resolvedPlaceName == null) {
          final rootName = data['name'] as String?;
          if (rootName != null && rootName.isNotEmpty) {
            resolvedPlaceName = rootName;
          }
        }

        if (resolvedPlaceName == null) {
          final addressData = data['address'] as Map<String, dynamic>?;
          if (addressData != null) {
            final poiKeys = [
              'marketplace',
              'shop',
              'restaurant',
              'cafe',
              'fast_food',
              'mosque',
              'church',
              'temple',
              'bank',
              'hotel',
              'attraction',
              'office',
              'leisure',
              'amenity',
              'hospital',
              'university',
              'school',
              'building',
              'tourism',
              'place',
            ];
            for (final key in poiKeys) {
              if (addressData.containsKey(key)) {
                final val = addressData[key] as String?;
                if (val != null && val.isNotEmpty) {
                  resolvedPlaceName = val;
                  break;
                }
              }
            }
          }
        }

        final displayName = data['display_name'] as String?;
        if (displayName != null && mounted) {
          final parts = displayName.split(',');
          
          // Filter out generic parts like "Bangladesh", zip codes, or empty values to keep the address highly detailed but clean
          final cleanParts = parts.map((p) => p.trim()).where((p) {
            if (p.isEmpty) return false;
            final lower = p.toLowerCase();
            if (lower == 'bangladesh') return false;
            if (RegExp(r'^\d{4,5}$').hasMatch(p)) return false; // Exclude numeric postcodes e.g. "3100"
            return true;
          }).toList();
          
          String address = cleanParts.isNotEmpty ? cleanParts.join(', ') : displayName;

          // Prepend the place name if we resolved one and it's not already present
          if (resolvedPlaceName != null && resolvedPlaceName.isNotEmpty) {
            if (!address.toLowerCase().contains(resolvedPlaceName.toLowerCase())) {
              address = '$resolvedPlaceName, $address';
            }
          }

          setState(() {
            _resolvedAddress = address;
            _isResolvingAddress = false;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      String fallbackAddress = 'Sylhet Metropolitan Area';
      if (resolvedPlaceName != null && resolvedPlaceName.isNotEmpty) {
        fallbackAddress = '$resolvedPlaceName, $fallbackAddress';
      } else {
        fallbackAddress = '$fallbackAddress (Lat: ${point.latitude.toStringAsFixed(4)}, Lng: ${point.longitude.toStringAsFixed(4)})';
      }
      setState(() {
        _resolvedAddress = fallbackAddress;
        _isResolvingAddress = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Search Auto-complete
  // ─────────────────────────────────────────────────────────────────────────────
  void _onSearchChanged(String val) {
    // Rebuild immediately to make the clear icon instantly responsive
    setState(() {});

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (val.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final results = await _performOnlineSearch(val);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _showSearchResults = results.isNotEmpty;
        });
      }
    });
  }

  Future<List<PickerLandmark>> _performOnlineSearch(String query) async {
    final normalizedQuery = query.toLowerCase().trim();
    
    // Split the user's input into multiple search keywords (by-word keyword matching)
    final queryWords = normalizedQuery.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    if (queryWords.isEmpty) return [];

    // 1. Get quick local matches by checking if name contains ALL input words (case-insensitive)
    final localMatches = pickerLandmarks.where((lm) {
      final nameLower = lm.name.toLowerCase();
      return queryWords.every((word) => nameLower.contains(word));
    }).toList();

    // 2. Fetch from Nominatim search API
    final List<PickerLandmark> onlineMatches = [];
    try {
      String searchQ = query;
      // Append Sylhet to narrow down metropolitan coordinates if user did not type it
      if (!normalizedQuery.contains('sylhet') && !normalizedQuery.contains('bangladesh')) {
        searchQ = '$query, Sylhet';
      }
      
      // Use high-accuracy Sylhet bounding box coordinates as a preference (bias)
      // to ensure street names & keywords resolve directly within Sylhet metropolitan area first.
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(searchQ)}&limit=8&viewbox=91.75,24.98,92.00,24.80',
      );
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'ShieldX_Safety_Application/1.0.0 (contact: support@shieldx.com)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        for (final item in data) {
          final displayName = item['display_name'] as String?;
          final latStr = item['lat'] as String?;
          final lonStr = item['lon'] as String?;
          
          if (displayName != null && latStr != null && lonStr != null) {
            final lat = double.tryParse(latStr);
            final lon = double.tryParse(lonStr);
            if (lat != null && lon != null) {
              final parts = displayName.split(',');
              final cleanName = parts.length > 3
                  ? parts.take(3).join(', ').trim()
                  : displayName.trim();
                  
              final osmType = (item['type'] as String? ?? '').toLowerCase();
              final osmClass = (item['class'] as String? ?? '').toLowerCase();
              PickerPlaceType pType = PickerPlaceType.general;
              if (osmType.contains('hospital') || osmClass.contains('medical') || osmType.contains('pharmacy')) {
                pType = PickerPlaceType.hospital;
              } else if (osmType.contains('university') || osmType.contains('school') || osmType.contains('college')) {
                pType = PickerPlaceType.education;
              } else if (osmType.contains('bus') || osmType.contains('railway') || osmType.contains('station') || osmType.contains('airport')) {
                pType = PickerPlaceType.transport;
              } else if (osmType.contains('mall') || osmType.contains('market') || osmType.contains('shop')) {
                pType = PickerPlaceType.shopping;
              } else if (osmType.contains('park') || osmType.contains('river') || osmType.contains('garden') || osmType.contains('lake')) {
                pType = PickerPlaceType.nature;
              } else if (osmType.contains('mosque') || osmType.contains('temple') || osmType.contains('worship') || osmType.contains('church')) {
                pType = PickerPlaceType.worship;
              }

              onlineMatches.add(PickerLandmark(
                cleanName,
                LatLng(lat, lon),
                type: pType,
              ));
            }
          }
        }
      } else {
        debugPrint('Nominatim Geocoding API returned non-200 status: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      debugPrint('Nominatim Geocoding Exception: $e\n$stackTrace');
    }

    // Deduplicate matches
    final combined = [...localMatches];
    for (final online in onlineMatches) {
      if (!combined.any((local) =>
          local.name.toLowerCase() == online.name.toLowerCase() ||
          ((local.location.latitude - online.location.latitude).abs() < 0.0001 &&
              (local.location.longitude - online.location.longitude).abs() < 0.0001))) {
        combined.add(online);
      }
    }

    return combined;
  }

  void _selectLandmark(PickerLandmark lm) {
    setState(() {
      _searchController.text = lm.name;
      _showSearchResults = false;
      _selectedPoint = lm.location;
    });
    _mapController.move(lm.location, 16.0);
    _handleMapTap(lm.location, placeName: lm.name);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  IconData _getIconForPickerType(PickerPlaceType type) {
    switch (type) {
      case PickerPlaceType.hospital:
        return Icons.local_hospital_rounded;
      case PickerPlaceType.education:
        return Icons.school_rounded;
      case PickerPlaceType.transport:
        return Icons.directions_bus_rounded;
      case PickerPlaceType.shopping:
        return Icons.shopping_bag_rounded;
      case PickerPlaceType.nature:
        return Icons.park_rounded;
      case PickerPlaceType.worship:
        return Icons.mosque_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  Color _getColorForPickerType(PickerPlaceType type) {
    switch (type) {
      case PickerPlaceType.hospital:
        return const Color(0xFFEF4444);
      case PickerPlaceType.education:
        return const Color(0xFF8B5CF6);
      case PickerPlaceType.transport:
        return const Color(0xFF3B82F6);
      case PickerPlaceType.shopping:
        return const Color(0xFFF59E0B);
      case PickerPlaceType.nature:
        return const Color(0xFF10B981);
      case PickerPlaceType.worship:
        return const Color(0xFF0EA5E9);
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final liveSim = ref.watch(gpsSimulationProvider);
    final gpsUserLocation = LatLng(liveSim.latitude, liveSim.longitude);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Flutter Map Widget ─────────────────────────────────────────────
          ref.watch(crimeHotspotProvider).when(
            data: (complaints) {
              _calculateClusters(complaints);
              return _buildMap(gpsUserLocation, complaints);
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => _buildMap(gpsUserLocation, []),
          ),

          // ── Search overlay ────────────────────────────────────────────────
          _buildSearchOverlay(),

          // ── Floating back button ──────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black.withOpacity(0.6),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // ── Bottom Dashboard ──────────────────────────────────────────────
          if (_selectedPoint != null) _buildBottomDashboard(),
        ],
      ),
    );
  }

  Widget _buildMap(LatLng defaultCenter, List<ComplaintModel> complaints) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _selectedPoint ?? defaultCenter,
        initialZoom: 14.5,
        minZoom: 10.0,
        maxZoom: 18.0,
        onMapReady: () {
          setState(() => _isMapReady = true);
          if (_selectedPoint == null) {
            _handleMapTap(defaultCenter);
          }
        },
        onTap: (_, latLng) => _handleMapTap(latLng),
      ),
      children: [
        // Google Maps Street view tiles
        TileLayer(
          urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
          userAgentPackageName: 'com.shieldx.app',
        ),

        // Green safe concentric zones around dummy police stations
        CircleLayer<Object>(
          circles: [
            for (final s in dummyPoliceStations) ...[
              CircleMarker(
                point: s.location,
                radius: 300,
                useRadiusInMeter: true,
                color: const Color(0xFF10B981).withOpacity(0.04),
                borderStrokeWidth: 0,
              ),
              CircleMarker(
                point: s.location,
                radius: 150,
                useRadiusInMeter: true,
                color: const Color(0xFF10B981).withOpacity(0.08),
                borderStrokeWidth: 0,
              ),
              CircleMarker(
                point: s.location,
                radius: 50,
                useRadiusInMeter: true,
                color: const Color(0xFF10B981).withOpacity(0.18),
                borderColor: const Color(0xFF10B981).withOpacity(0.3),
                borderStrokeWidth: 1.0,
              ),
            ]
          ],
        ),

        // Glowing concentric crime heatmap circles
        CircleLayer<Object>(
          circles: [
            for (final cl in _clusters) ...[
              // Outer faint glow
              CircleMarker(
                point: cl.center,
                radius: cl.totalWeight >= 5.0 ? 280.0 : cl.totalWeight >= 2.0 ? 210.0 : 150.0,
                useRadiusInMeter: true,
                color: (cl.totalWeight >= 5.0 ? const Color(0xFFEF4444) : cl.totalWeight >= 2.0 ? const Color(0xFFF97316) : const Color(0xFFFBBF24)).withOpacity(0.06),
                borderStrokeWidth: 0,
              ),
              // Middle glow
              CircleMarker(
                point: cl.center,
                radius: (cl.totalWeight >= 5.0 ? 280.0 : cl.totalWeight >= 2.0 ? 210.0 : 150.0) * 0.65,
                useRadiusInMeter: true,
                color: (cl.totalWeight >= 5.0 ? const Color(0xFFEF4444) : cl.totalWeight >= 2.0 ? const Color(0xFFF97316) : const Color(0xFFFBBF24)).withOpacity(0.14),
                borderStrokeWidth: 0,
              ),
              // Center core glow
              CircleMarker(
                point: cl.center,
                radius: (cl.totalWeight >= 5.0 ? 280.0 : cl.totalWeight >= 2.0 ? 210.0 : 150.0) * 0.20,
                useRadiusInMeter: true,
                color: (cl.totalWeight >= 5.0 ? const Color(0xFFEF4444) : cl.totalWeight >= 2.0 ? const Color(0xFFF97316) : const Color(0xFFFBBF24)).withOpacity(0.4),
                borderColor: (cl.totalWeight >= 5.0 ? const Color(0xFFEF4444) : cl.totalWeight >= 2.0 ? const Color(0xFFF97316) : const Color(0xFFFBBF24)).withOpacity(0.6),
                borderStrokeWidth: 1.0,
              ),
            ]
          ],
        ),

        // Glowing live GPS user location marker
        MarkerLayer(
          markers: [
            Marker(
              point: defaultCenter,
              width: 22,
              height: 22,
              alignment: Alignment.center,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(color: Colors.blue.withOpacity(0.5), blurRadius: 10, spreadRadius: 3),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Landmarks icons
        MarkerLayer(
          markers: [
            for (final lm in pickerLandmarks)
              Marker(
                point: lm.location,
                width: 28,
                height: 28,
                alignment: Alignment.center,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _selectLandmark(lm),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _getColorForPickerType(lm.type),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
                      ),
                      child: Icon(_getIconForPickerType(lm.type), color: Colors.white, size: 12),
                    ),
                  ),
                ),
              ),
          ],
        ),

        // Selected Pin marker (Neon glowing pointer)
        if (_selectedPoint != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _selectedPoint!,
                width: 80,
                height: 80,
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFF97316).withOpacity(0.4), blurRadius: 12, spreadRadius: 2),
                        ],
                      ),
                      child: const Icon(Icons.place_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange.withOpacity(0.5)),
                      ),
                      child: Text(
                        'Incident Point',
                        style: GoogleFonts.inter(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSearchOverlay() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 72,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.card.withOpacity(0.92),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12)],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search city landmarks...',
                hintStyle: GoogleFonts.inter(color: AppColors.textHint, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textHint),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_showSearchResults)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(top: 6),
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: AppColors.card.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _searchResults.length,
                separatorBuilder: (_, __) => const Divider(color: AppColors.cardBorder, height: 1),
                itemBuilder: (context, index) {
                  final lm = _searchResults[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(_getIconForPickerType(lm.type), color: _getColorForPickerType(lm.type), size: 16),
                    title: Text(lm.name, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    onTap: () => _selectLandmark(lm),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomDashboard() {
    final info = _safetyInfo ?? _SafetyInfo(
      level: 'Analyzing Risk…',
      description: 'Gauging spatial complaint reports coordinates density…',
      color: Colors.grey,
      icon: Icons.hourglass_empty_rounded,
    );

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: AppColors.card.withOpacity(0.92),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 20)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Safe zone / Heat indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: info.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: info.color.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Icon(info.icon, color: info.color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Crime Threat Assessment: ',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                  ),
                  Text(
                    info.level.toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 12, color: info.color, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                info.description,
                style: GoogleFonts.inter(fontSize: 10.5, color: Colors.white60, fontStyle: FontStyle.italic),
              ),
            ),
            const Divider(color: AppColors.cardBorder, height: 24),

            // Location details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.place_rounded, color: Colors.orange, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RESOLVED ADDRESS',
                        style: GoogleFonts.inter(fontSize: 10, color: AppColors.textHint, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      _isResolvingAddress
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.orange),
                            )
                          : Text(
                              _resolvedAddress ?? 'Tap the map to resolve point',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Station detail
            Row(
              children: [
                const Icon(Icons.account_balance_outlined, color: Colors.blueAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'JURISDICTION STATION (AUTO-DETECTED)',
                        style: GoogleFonts.inter(fontSize: 10, color: AppColors.textHint, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _detectedStationName ?? 'Detecting station sector…',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Selection CTA Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.cardBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isResolvingAddress || _selectedPoint == null
                        ? null
                        : () {
                            Navigator.pop(context, {
                              'latitude': _selectedPoint!.latitude,
                              'longitude': _selectedPoint!.longitude,
                              'address': _resolvedAddress,
                              'police_station': _detectedStationName,
                            });
                          },
                    child: Text(
                      'Select Location',
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
