import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/police_station_model.dart';

class MapService {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';

  // ---------------------------------------------------------------------------
  // 1. Jurisdiction Detection — tries admin_level=8 first (Thana/Upazila),
  //    falls back to admin_level=6 (District) if nothing is found.
  // ---------------------------------------------------------------------------

  /// Returns a map with keys: 'id' (int), 'name' (String).
  /// Returns null if the API call fails or returns no data.
  Future<Map<String, dynamic>?> getJurisdictionInfo(LatLng location) async {
    for (final level in [8, 7, 6]) {
      final result = await _fetchAdminArea(location, level);
      if (result != null) return result;
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchAdminArea(LatLng location, int adminLevel) async {
    final query = '''
    [out:json][timeout:20];
    is_in(${location.latitude},${location.longitude})->.a;
    area.a[admin_level=$adminLevel];
    out body;
    ''';

    try {
      final response = await http.post(
        Uri.parse(_overpassUrl),
        body: query,
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final elements = data['elements'] as List<dynamic>;
        if (elements.isNotEmpty) {
          final element = elements.first as Map<String, dynamic>;
          final tags = element['tags'] as Map<String, dynamic>? ?? {};
          final name = tags['name'] ??
              tags['name:en'] ??
              tags['official_name:en'] ??
              tags['official_name'];
          if (name != null) {
            return {
              'id': element['id'],
              'name': name as String,
              'admin_level': adminLevel,
            };
          }
        }
      }
    } catch (e) {
      // silently fail — caller will try next level
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // 2. Police Station Fetching — fetches nodes, ways, relations tagged amenity=police
  // ---------------------------------------------------------------------------

  Future<List<PoliceStation>> fetchPoliceStations(
    LatLng location, {
    double radius = 25000,
  }) async {
    final query = '''
    [out:json][timeout:25];
    (
      node["amenity"="police"](around:$radius,${location.latitude},${location.longitude});
      way["amenity"="police"](around:$radius,${location.latitude},${location.longitude});
      relation["amenity"="police"](around:$radius,${location.latitude},${location.longitude});
    );
    out center body;
    ''';

    try {
      final response = await http.post(
        Uri.parse(_overpassUrl),
        body: query,
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final elements = data['elements'] as List<dynamic>;
        final stations = <PoliceStation>[];
        for (final e in elements) {
          try {
            stations.add(PoliceStation.fromOverpass(e as Map<String, dynamic>));
          } catch (_) {
            // skip malformed entries
          }
        }
        return stations;
      }
    } catch (e) {
      // silently fail — caller will use dummy data
    }
    return [];
  }

  // ---------------------------------------------------------------------------
  // 3. Jurisdiction Boundary Polygon — fetches the outline of the admin area
  //    so we can draw it on the map. Returns null if unavailable.
  // ---------------------------------------------------------------------------

  Future<List<LatLng>?> getAreaPolygon(int areaId) async {
    // Overpass 'relation' query to get boundary way geometry
    final query = '''
    [out:json][timeout:30];
    relation($areaId);
    out geom;
    ''';

    try {
      final response = await http.post(
        Uri.parse(_overpassUrl),
        body: query,
      ).timeout(const Duration(seconds: 28));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final elements = data['elements'] as List<dynamic>;
        if (elements.isNotEmpty) {
          final points = <LatLng>[];
          for (final el in elements) {
            final members = el['members'] as List<dynamic>? ?? [];
            for (final member in members) {
              if (member['role'] == 'outer' && member['geometry'] != null) {
                for (final pt in member['geometry'] as List<dynamic>) {
                  points.add(LatLng(
                    (pt['lat'] as num).toDouble(),
                    (pt['lon'] as num).toDouble(),
                  ));
                }
              }
            }
          }
          return points.isNotEmpty ? points : null;
        }
      }
    } catch (_) {
      // polygon is purely cosmetic — fail silently
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // 4. Smart Station Matching — given a jurisdiction name, find the best
  //    matching station using token overlap scoring.
  // ---------------------------------------------------------------------------

  /// Returns the index of the best matching station in [stations], or -1.
  int findBestJurisdictionMatch(
    List<PoliceStation> stations,
    String jurisdictionName,
  ) {
    if (stations.isEmpty || jurisdictionName.isEmpty) return -1;

    // Normalize: lowercase, remove common words, split into tokens
    final jurTokens = _tokenize(jurisdictionName);

    int bestIndex = -1;
    int bestScore = 0;

    for (int i = 0; i < stations.length; i++) {
      final s = stations[i];
      final nameTokens = _tokenize(s.name);
      final jurFieldTokens = _tokenize(s.jurisdiction ?? '');
      final addressTokens = _tokenize(s.address);

      // Score = weighted overlap
      int score = 0;
      for (final t in jurTokens) {
        if (nameTokens.contains(t)) score += 3;
        if (jurFieldTokens.contains(t)) score += 2;
        if (addressTokens.contains(t)) score += 1;
      }

      if (score > bestScore) {
        bestScore = score;
        bestIndex = i;
      }
    }

    // Only return a match if the score is meaningful
    return bestScore >= 2 ? bestIndex : -1;
  }

  Set<String> _tokenize(String text) {
    const stopWords = {
      'police', 'station', 'thana', 'model', 'sadar', 'the', 'of', 'and',
      'পুলিশ', 'থানা',
    };
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1 && !stopWords.contains(w))
        .toSet();
  }
}
