import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_colors.dart';
import '../widgets/common/widgets.dart';

class NearbyStation {
  final String id;
  final String name;
  final String address;
  final String phone;
  final LatLng location;

  const NearbyStation({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.location,
  });

  factory NearbyStation.fromOverpass(Map<String, dynamic> el) {
    final tags = el['tags'] as Map<String, dynamic>? ?? {};
    double lat, lon;
    if (el['type'] == 'way' && el['center'] != null) {
      lat = (el['center']['lat'] as num).toDouble();
      lon = (el['center']['lon'] as num).toDouble();
    } else {
      lat = (el['lat'] as num).toDouble();
      lon = (el['lon'] as num).toDouble();
    }
    final parts = [
      tags['addr:housenumber'] ?? '',
      tags['addr:street'] ?? '',
      tags['addr:suburb'] ?? tags['addr:city'] ?? '',
    ].where((s) => s.isNotEmpty).toList();

    return NearbyStation(
      id: '${el['id']}',
      name: tags['name'] ?? tags['name:en'] ?? 'Police Station',
      address: parts.isEmpty ? 'Address not available' : parts.join(', '),
      phone: tags['phone'] ?? tags['contact:phone'] ?? '',
      location: LatLng(lat, lon),
    );
  }
}

// Fallback seeds for major Bangladesh cities
const _seedStations = <NearbyStation>[
  NearbyStation(id: 's1', name: 'Kotwali Police Station (Sylhet)', address: 'Kotwali, Sylhet', phone: '+880821-716781', location: LatLng(24.8965, 91.8687)),
  NearbyStation(id: 's2', name: 'Jalalabad Police Station', address: 'Jalalabad, Sylhet', phone: '', location: LatLng(24.9069, 91.8678)),
  NearbyStation(id: 's3', name: 'Airport Police Station (Sylhet)', address: 'Airport Road, Sylhet', phone: '', location: LatLng(24.9633, 91.8680)),
  NearbyStation(id: 's4', name: 'South Surma Police Station', address: 'South Surma, Sylhet', phone: '', location: LatLng(24.8764, 91.8823)),
  NearbyStation(id: 's5', name: 'Dhanmondi Police Station', address: 'Road No. 6, Dhanmondi, Dhaka', phone: '+880 1320-039981', location: LatLng(23.7431, 90.3837)),
  NearbyStation(id: 's6', name: 'Gulshan Police Station', address: 'Gulshan-2, Dhaka', phone: '+880 1320-039999', location: LatLng(23.7925, 90.4078)),
  NearbyStation(id: 's7', name: 'Mirpur Model Police Station', address: 'Mirpur-2, Dhaka', phone: '+880 1320-040050', location: LatLng(23.8041, 90.3628)),
];

class PoliceStationsScreen extends StatefulWidget {
  const PoliceStationsScreen({super.key});

  @override
  State<PoliceStationsScreen> createState() => _PoliceStationsScreenState();
}

class _PoliceStationsScreenState extends State<PoliceStationsScreen> {
  final MapController _mapController = MapController();
  LatLng? _userLocation;
  List<NearbyStation> _stations = [];
  NearbyStation? _selectedStation;
  bool _loadingLocation = true;
  bool _loadingStations = false;
  String? _statusMsg;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loadingLocation = true;
      _loadingStations = false;
      _statusMsg = null;
    });
    await _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _useDefaultAndLoad(const LatLng(24.8965, 91.8687), 'GPS disabled – showing Sylhet');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        _useDefaultAndLoad(const LatLng(24.8965, 91.8687), 'Permission denied – showing Sylhet');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      final loc = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _userLocation = loc;
        _loadingLocation = false;
        _statusMsg = 'Searching police stations near you…';
        _loadingStations = true;
      });
      _moveMap(loc, 13.0);
      await _fetchOverpass(loc);
    } catch (_) {
      _useDefaultAndLoad(const LatLng(24.8965, 91.8687), 'Location error – showing Sylhet');
    }
  }

  void _useDefaultAndLoad(LatLng loc, String msg) {
    if (!mounted) return;
    setState(() {
      _userLocation = loc;
      _loadingLocation = false;
      _statusMsg = msg;
      _loadingStations = true;
    });
    _moveMap(loc, 13.0);
    _fetchOverpass(loc);
  }

  void _moveMap(LatLng loc, double zoom) {
    if (_mapReady) {
      _mapController.move(loc, zoom);
    }
  }

  Future<void> _fetchOverpass(LatLng center) async {
    const query = '''[out:json][timeout:20];
(node["amenity"="police"](around:20000,LAT,LON);
 way["amenity"="police"](around:20000,LAT,LON););
out center body;''';
    final q = query
        .replaceAll('LAT', '${center.latitude}')
        .replaceAll('LON', '${center.longitude}');
    try {
      final res = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: q,
      ).timeout(const Duration(seconds: 20));

      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final els = data['elements'] as List<dynamic>;
        final fetched = <NearbyStation>[];
        for (final el in els) {
          try {
            if ((el['lat'] != null || el['center'] != null)) {
              fetched.add(NearbyStation.fromOverpass(el as Map<String, dynamic>));
            }
          } catch (_) {}
        }
        if (fetched.isNotEmpty) {
          _applyStations(fetched, center);
          return;
        }
      }
    } catch (_) {}

    // Fall back to seeds nearest to user
    if (!mounted) return;
    final seeds = _seedStations.where((s) {
      final d = const Distance().as(LengthUnit.Kilometer, center, s.location);
      return d < 50;
    }).toList();
    _applyStations(seeds.isNotEmpty ? seeds : _seedStations, center);
  }

  void _applyStations(List<NearbyStation> stations, LatLng center) {
    const dist = Distance();
    stations.sort((a, b) =>
        dist.as(LengthUnit.Meter, center, a.location)
            .compareTo(dist.as(LengthUnit.Meter, center, b.location)));
    setState(() {
      _stations = stations;
      _loadingStations = false;
      _statusMsg = '${stations.length} stations found';
      _selectedStation = stations.isNotEmpty ? stations.first : null;
    });
    if (stations.isNotEmpty && _mapReady) {
      _mapController.move(stations.first.location, 14.0);
    }
  }

  String _distLabel(NearbyStation s) {
    if (_userLocation == null) return '';
    final m = const Distance().as(LengthUnit.Meter, _userLocation!, s.location);
    return m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(1)} km';
  }

  Future<void> _callStation(String phone) async {
    final uri = Uri.parse('tel:${phone.replaceAll(' ', '')}');
    if (!await launchUrl(uri)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot open dialer')));
    }
  }

  Future<void> _openMaps(NearbyStation s) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${s.location.latitude},${s.location.longitude}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final loading = _loadingLocation || _loadingStations;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xDD0A0E1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Police Stations', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
            if (_statusMsg != null)
              Text(_statusMsg!, style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary)),
          ],
        ),
        actions: [
          if (!loading)
            IconButton(
              icon: const Icon(Icons.my_location_rounded, color: AppColors.primary),
              onPressed: () => _userLocation != null ? _moveMap(_userLocation!, 13.0) : null,
            ),
          if (!loading)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _init,
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation ?? const LatLng(24.8965, 91.8687),
              initialZoom: 13.0,
              onMapReady: () {
                _mapReady = true;
                if (_userLocation != null) _mapController.move(_userLocation!, 13.0);
                if (_stations.isNotEmpty) _mapController.move(_stations.first.location, 14.0);
              },
              onTap: (_, __) => setState(() => _selectedStation = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.shieldx.app',
              ),
              MarkerLayer(
                markers: [
                  // User location dot
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 44, height: 44,
                      child: Stack(alignment: Alignment.center, children: [
                        Container(width: 30, height: 30, decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.25), shape: BoxShape.circle)),
                        Container(width: 14, height: 14, decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2.5))),
                      ]),
                    ),
                  // ALL police station markers – always highlighted
                  ..._stations.map((s) {
                    final sel = _selectedStation?.id == s.id;
                    return Marker(
                      point: s.location,
                      width: sel ? 60 : 48,
                      height: sel ? 70 : 58,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedStation = s);
                          _moveMap(s.location, 15.0);
                        },
                        child: Column(
                          children: [
                            Container(
                              width: sel ? 44 : 36,
                              height: sel ? 44 : 36,
                              decoration: BoxDecoration(
                                color: sel ? AppColors.primary : const Color(0xFF1565C0),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [BoxShadow(color: (sel ? AppColors.primary : const Color(0xFF1565C0)).withValues(alpha: 0.6), blurRadius: sel ? 14 : 8, spreadRadius: sel ? 3 : 1)],
                              ),
                              child: const Icon(Icons.local_police_rounded, color: Colors.white, size: 18),
                            ),
                            // Pin tail
                            Container(width: 3, height: sel ? 10 : 8, color: sel ? AppColors.primary : const Color(0xFF1565C0)),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // Loading overlay
          if (loading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    _loadingLocation ? 'Getting your location…' : 'Finding police stations…',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                  ),
                ]),
              ),
            ),

          // Station detail card
          if (_selectedStation != null)
            Positioned(
              left: 16, right: 16, bottom: 20,
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.local_police_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_selectedStation!.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                        Row(children: [
                          const Icon(Icons.near_me_rounded, size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(_distLabel(_selectedStation!), style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ]),
                      ])),
                      IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary), onPressed: () => setState(() => _selectedStation = null)),
                    ]),
                    const Divider(height: 16, color: Color(0xFF2A2D3E)),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(child: Text(_selectedStation!.address, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary))),
                    ]),
                    if (_selectedStation!.phone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.phone_outlined, size: 15, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(_selectedStation!.phone, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                      ]),
                    ],
                    const SizedBox(height: 14),
                    Row(children: [
                      if (_selectedStation!.phone.isNotEmpty) ...[
                        Expanded(child: GradientButton(label: 'Call', icon: Icons.call_rounded, onTap: () => _callStation(_selectedStation!.phone))),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openMaps(_selectedStation!),
                          icon: const Icon(Icons.navigation_rounded, size: 16),
                          label: Text('Navigate', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: Color(0xFF2A2D3E)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),

          // Stations count badge
          if (!loading && _stations.isNotEmpty)
            Positioned(
              top: kToolbarHeight + MediaQuery.of(context).padding.top + 6,
              left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF1565C0).withValues(alpha: 0.92), borderRadius: BorderRadius.circular(20)),
                  child: Text('${_stations.length} police stations highlighted', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
