import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shieldx/common/data/models/police_station_model.dart';
import 'package:shieldx/common/data/models/complaint_model.dart';

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

IconData getIconForType(PlaceType type) {
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

Color getColorForType(PlaceType type) {
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
  CityLandmark('Osmani Medical Hospital', LatLng(24.9015, 91.8519),
      type: PlaceType.hospital),
  CityLandmark('Mount Adora Hospital', LatLng(24.9069, 91.8582),
      type: PlaceType.hospital),
  CityLandmark('Al Haramain Hospital', LatLng(24.8872, 91.8797),
      type: PlaceType.hospital),
  CityLandmark('Ragib-Rabeya Medical', LatLng(24.9216, 91.8340),
      type: PlaceType.hospital),
  CityLandmark('SUST', LatLng(24.9248, 91.8329), type: PlaceType.education),
  CityLandmark('MC College', LatLng(24.9063, 91.9022),
      type: PlaceType.education),
  CityLandmark('Agricultural Uni', LatLng(24.9069, 91.9038),
      type: PlaceType.education),
  CityLandmark('Engineering College', LatLng(24.9030, 91.9056),
      type: PlaceType.education),
  CityLandmark('Madan Mohan College', LatLng(24.8933, 91.8643),
      type: PlaceType.education),
  CityLandmark('Osmani Airport', LatLng(24.9632, 91.8681),
      type: PlaceType.transport),
  CityLandmark('Kadamtali Bus Terminal', LatLng(24.8778, 91.8706),
      type: PlaceType.transport),
  CityLandmark('Railway Station', LatLng(24.8812, 91.8661),
      type: PlaceType.transport),
  CityLandmark('Kumargaon Bus Stand', LatLng(24.9125, 91.8415),
      type: PlaceType.transport),
  CityLandmark('Zindabazar', LatLng(24.8967, 91.8687),
      type: PlaceType.shopping),
  CityLandmark('Hasan Market', LatLng(24.8911, 91.8694),
      type: PlaceType.shopping),
  CityLandmark('Al Hamra', LatLng(24.8988, 91.8688), type: PlaceType.shopping),
  CityLandmark('Blue Water', LatLng(24.8962, 91.8681),
      type: PlaceType.shopping),
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
  CityLandmark('Shahjalal Mazar', LatLng(24.9013, 91.8714),
      type: PlaceType.worship),
  CityLandmark('Shah Poran Mazar', LatLng(24.9028, 91.9048),
      type: PlaceType.worship),
  CityLandmark('Shahi Eidgah', LatLng(24.9049, 91.8799),
      type: PlaceType.worship),
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

class HotspotCluster {
  double sumLat = 0;
  double sumLng = 0;
  int count = 0;
  double totalWeight = 0;
  final List<ComplaintModel> complaints = [];
  LatLng get center => LatLng(sumLat / count, sumLng / count);
}

class PatrolRoute {
  final String id;
  final String routeName;
  final PoliceStation station;
  final LatLng hotspotCenter;
  final String hotspotName;
  final String threatDescription;
  final int complaintCount;
  final double matchScore;
  final List<LatLng> routePoints;
  LatLng? currentCarLocation;
  int currentRouteIndex = 0;
  bool isMovingForward = true;
  PatrolRoute({
    required this.id,
    required this.routeName,
    required this.station,
    required this.hotspotCenter,
    required this.hotspotName,
    required this.threatDescription,
    required this.complaintCount,
    required this.matchScore,
    required this.routePoints,
    this.currentCarLocation,
  });
}
