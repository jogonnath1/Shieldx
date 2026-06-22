import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MapService {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';
  Future<Map<String, dynamic>?> getJurisdictionInfo(LatLng location) async {
    for (final level in [8, 7, 6]) {
      final result = await _fetchAdminArea(location, level);
      if (result != null) return result;
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchAdminArea(
      LatLng location, int adminLevel) async {
    final query = ''' [out:json][timeout:20];
is_in(${location.latitude},${location.longitude})->.a; area.a[admin_level=$adminLevel]; out body; ''';
    try {
      final response = await http
          .post(
            Uri.parse(_overpassUrl),
            body: query,
          )
          .timeout(const Duration(seconds: 20));
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
      debugPrint('[MapService] Failed to fetch admin area: $e');
    }
    return null;
  }

  Future<List<LatLng>?> getAreaPolygon(int areaId) async {
    final query = ''' [out:json][timeout:30]; relation($areaId); out geom; ''';
    try {
      final response = await http
          .post(
            Uri.parse(_overpassUrl),
            body: query,
          )
          .timeout(const Duration(seconds: 28));
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
    } catch (_) {}
    return null;
  }
}
