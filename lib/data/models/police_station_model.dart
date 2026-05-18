import 'package:latlong2/latlong.dart';

class PoliceStation {
  final String id;
  final String name;
  final String address;
  final String phone;
  final LatLng location;
  final String details;
  final String? jurisdiction;
  final bool isAutoSelected;
  final String thana; // SMP thana name

  const PoliceStation({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.location,
    required this.details,
    this.jurisdiction,
    this.isAutoSelected = false,
    this.thana = '',
  });

  PoliceStation copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    LatLng? location,
    String? details,
    String? jurisdiction,
    bool? isAutoSelected,
    String? thana,
  }) {
    return PoliceStation(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      location: location ?? this.location,
      details: details ?? this.details,
      jurisdiction: jurisdiction ?? this.jurisdiction,
      isAutoSelected: isAutoSelected ?? this.isAutoSelected,
      thana: thana ?? this.thana,
    );
  }

  /// Parses an Overpass API element into a PoliceStation.
  factory PoliceStation.fromOverpass(Map<String, dynamic> el) {
    final tags = el['tags'] as Map<String, dynamic>? ?? {};
    double lat, lon;
    if (el['center'] != null) {
      lat = (el['center']['lat'] as num).toDouble();
      lon = (el['center']['lon'] as num).toDouble();
    } else {
      lat = (el['lat'] as num? ?? 0).toDouble();
      lon = (el['lon'] as num? ?? 0).toDouble();
    }
    final addressParts = [
      tags['addr:housenumber'] ?? '',
      tags['addr:street'] ?? '',
      tags['addr:suburb'] ?? tags['addr:neighbourhood'] ?? '',
      tags['addr:city'] ?? tags['addr:district'] ?? '',
    ].where((s) => s.isNotEmpty).toList();

    return PoliceStation(
      id: '${el['id']}',
      name: tags['name'] ?? tags['name:en'] ?? tags['official_name'] ?? 'Police Station',
      address: addressParts.isEmpty ? 'Address not available' : addressParts.join(', '),
      phone: tags['phone'] ?? tags['contact:phone'] ?? tags['contact:mobile'] ?? '',
      location: LatLng(lat, lon),
      details: tags['description'] ??
          'Official police station providing security and public services.',
      jurisdiction: tags['operator:area'] ?? tags['addr:subdistrict'] ?? '',
      thana: tags['addr:subdistrict'] ?? '',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sylhet Metropolitan Police (SMP) — 6 Official Thanas
// Thana name constants
// ─────────────────────────────────────────────────────────────────────────────

const String thanaKotwali    = 'Kotwali Model Thana';
const String thanaMoglabazar = 'Moglabazar Thana';
const String thanaSouthSurma = 'South Surma Thana';
const String thanaShahPoran  = 'Shahporan Thana';
const String thanaJalalabad  = 'Jalalabad Thana';
const String thanaAirport    = 'Airport Thana';

// ─────────────────────────────────────────────────────────────────────────────
// Thana detailed info — used in the information panel
// Each entry contains sections (heading → list of notable areas)
// ─────────────────────────────────────────────────────────────────────────────

class ThanaSection {
  final String heading;
  final String emoji;
  final List<String> areas;
  const ThanaSection({required this.heading, required this.emoji, required this.areas});
}

class ThanaInfo {
  final String thana;
  final String subtitle;
  final String emoji;
  final List<ThanaSection> sections;
  final String overlapNotes;
  const ThanaInfo({
    required this.thana,
    required this.subtitle,
    required this.emoji,
    required this.sections,
    this.overlapNotes = '',
  });
}

const Map<String, ThanaInfo> thanaDetailedInfo = {
  thanaKotwali: ThanaInfo(
    thana: thanaKotwali,
    subtitle: 'Core City Heart',
    emoji: '🏙️',
    sections: [
      ThanaSection(
        heading: 'Central Commercial Core',
        emoji: '🏙️',
        areas: [
          'Zindabazar (Main Road & Point)',
          'Jallarpar (Major food & commercial hub)',
          'Chowhatta',
          'Bandar Bazar',
          'Hasan Market & Hawkers Market Zone',
          'Rikabi Bazar',
          'Mirabazar',
          'Lamabazar',
          'Naya Sarak',
          'Court Point',
          'Taltola (Major hotel & commercial strip)',
        ],
      ),
      ThanaSection(
        heading: 'Dargah & Old Historic Zone',
        emoji: '🕌',
        areas: [
          'Dargah Gate (East & West)',
          'Hazrat Shahjalal Dargah Main Area',
          'Dhopadighir Par',
          'Kazitula',
          'Shibganj (Central Portion)',
          'Dargah Mahalla Inner Lanes',
          'Laldighirpar',
        ],
      ),
      ThanaSection(
        heading: 'Residential & Mixed Urban Mahallas',
        emoji: '🏘️',
        areas: [
          'Mirzajangal',
          'Dariapara (Major residential & commercial lane)',
          'Pathantula (Bordering Jalalabad)',
          'Sheikhghat',
          'Tilagor (City-side part)',
          'Baghbari',
          'Kumarpara',
          'Majumdar Para',
          'Kuarpar / Keapara',
          'Bhatalia',
          'Mirzajangal Extension Lanes',
          'Sheikhghat River-side Pockets',
        ],
      ),
      ThanaSection(
        heading: 'Transport, Market & Junction Zones',
        emoji: '🚧',
        areas: [
          'Kadamtali (North side)',
          'Tukerbazar (City-side portion)',
          'Naiorpul',
          'Kazir Bazar',
          'Choukidekhi / Choukidighi',
          'Bandar River Port Market Zone',
          'Sylhet Central Bus Terminal (Kadamtali belt)',
        ],
      ),
      ThanaSection(
        heading: 'Administrative & Institutional Zone',
        emoji: '🏛️',
        areas: [
          'Sylhet District Court Area',
          'Sylhet Collectorate (DC Office) Area',
          'Sylhet Central Jail Road Area',
          'Police Line / Police HQ Surroundings',
          'Govt. Alia Madrasa Surrounding Area',
          'Court Road–Jail Road Administrative Corridor',
        ],
      ),
      ThanaSection(
        heading: 'Major Road Network',
        emoji: '🛣️',
        areas: [
          'Zindabazar Road Corridor',
          'Chowhatta–Dargah Gate Road',
          'Bandar–Naya Sarak Road',
          'Mirabazar–Lamabazar Stretch',
          'Court Point–Jail Road Axis',
          'Rikabi Bazar Internal Lanes',
          'Kazitula Road Network',
        ],
      ),
    ],
    overlapNotes: 'Ambarkhana acts as the commercial gateway between Kotwali and Airport Thana. Subidbazar borders Kotwali and Jalalabad. Tukerbazar lies on the Kotwali–Jalalabad boundary.',
  ),

  thanaMoglabazar: ThanaInfo(
    thana: thanaMoglabazar,
    subtitle: 'Leading University Hub',
    emoji: '🎓',
    sections: [
      ThanaSection(
        heading: 'Kamalbazar & Leading University Core',
        emoji: '🏫',
        areas: [
          'Kamalbazar Point (Main Junction)',
          'Leading University Main Gate Area',
          'Ragibnagar (LU Campus Zone)',
          'Kamalbazar-Lalabazar Road (Major connection)',
          'Kamalbazar-Daudpur Road',
          'Kamalbazar-Bishwanath Road (Initial stretch)',
          'Bilarpar Area (Adjacent to Uni)',
          'Local Mess & Hostel Pockets (Around LU)',
          'Kamalbazar Fish Market & Daily Bazaar',
          'Bakshir Chak',
          'Haji Bari & Molla Bari Lanes',
          'Silam Road Junction',
          'Kamalbazar-Gausia Road',
          'Pharmacy & Stationery clusters around University',
        ],
      ),
      ThanaSection(
        heading: 'Surrounding Moglabazar Localities',
        emoji: '🌾',
        areas: [
          'Moglabazar Proper',
          'Daudpur',
          'Jalalpur',
          'Kuchai',
          'Silam',
          'Tetli (South Part)',
          'Pirijpur',
          'Burunga',
          'Parairchak (City expansion/waste management zone)',
          'Sreerampur',
          'Surma River-side Village Clusters',
        ],
      ),
    ],
    overlapNotes: 'Kamalbazar is close to South Surma but administratively falls under Moglabazar Thana.',
  ),

  thanaSouthSurma: ThanaInfo(
    thana: thanaSouthSurma,
    subtitle: 'Expansion City (South of Surma River)',
    emoji: '🏗️',
    sections: [
      ThanaSection(
        heading: 'Main Commercial & Transport Hubs',
        emoji: '🏙️',
        areas: [
          'Kadamtali Point',
          'Humayun Rashid Chattar',
          'Babna Point',
          'Titas Point',
          'Chondipul (Gateway point)',
          'Kin Bridge Area (South End)',
          'South Surma Bus Terminal Area',
          'Railway Station Area (South Part)',
        ],
      ),
      ThanaSection(
        heading: 'Residential & Expansion Zones',
        emoji: '🏘️',
        areas: [
          'Boroikandi',
          'Mominkhola',
          'Shivbari',
          'Subidbazar (South Side — border with Kotwali/Jalalabad)',
          'Lalabazar Belt (Highway side)',
          'Gotatikor BSCIC Industrial Area',
        ],
      ),
    ],
    overlapNotes: 'Note: Shahjalal Uposhohor and Sylhet Housing Estate are NORTH of the Surma River and do NOT belong to South Surma Thana. They fall under Shah Poran/Kotwali and Airport Thana respectively.',
  ),

  thanaShahPoran: ThanaInfo(
    thana: thanaShahPoran,
    subtitle: 'Eastern Zone',
    emoji: '🕌',
    sections: [
      ThanaSection(
        heading: 'Dargah, Education & Residential Hub',
        emoji: '🕌',
        areas: [
          'Shah Poran Dargah Gate',
          'Tilagor (Eastern Part)',
          'Baluchar (Major residential area near MC College)',
          'Major Tila Point',
          'MC College Area',
          'Shahjalal Uposhohor (Major Planned Residential Block — North of Surma)',
          'Shaplabagh / Kolapara',
          'Kushighat',
        ],
      ),
      ThanaSection(
        heading: 'Outskirts & Peripheral Zones',
        emoji: '🌿',
        areas: [
          'Khadimnagar',
          'Khadim Para',
          'Bateshwar',
          'Pirerbazar',
          'Habinagar',
          'Khadimnagar National Park surroundings',
        ],
      ),
    ],
    overlapNotes: 'Shahjalal Uposhohor was previously miscategorized under South Surma — it is north of the Surma River and falls under Shah Poran/Kotwali jurisdiction.',
  ),

  thanaJalalabad: ThanaInfo(
    thana: thanaJalalabad,
    subtitle: 'Institutional Zone',
    emoji: '🏫',
    sections: [
      ThanaSection(
        heading: 'Varsity, Medical & Transport Core',
        emoji: '🏫',
        areas: [
          'Medina Market Point',
          'Akhalia Point',
          'SUST Main Gate & Surrounding area',
          'Kumargaon (Major Bus Stand & Power Plant Area)',
          'Sylhet MAG Osmani Medical College Area (Medical Road)',
          'Tapobon Residential Area',
          'Surma Residential Area',
        ],
      ),
      ThanaSection(
        heading: 'Road Networks',
        emoji: '🛣️',
        areas: [
          'Sylhet-Sunamganj Road (Main Stretch)',
          'Londoni Road',
          'Pir Mohalla Main Road',
          'Hazipara / Loharpara Lanes',
        ],
      ),
    ],
    overlapNotes: 'Subidbazar borders Kotwali and Jalalabad Thana. Pathantula also straddles the Kotwali–Jalalabad edge.',
  ),

  thanaAirport: ThanaInfo(
    thana: thanaAirport,
    subtitle: 'Aviation & Northern Zone',
    emoji: '✈️',
    sections: [
      ThanaSection(
        heading: 'Aviation & Industrial Hub',
        emoji: '✈️',
        areas: [
          'Osmani International Airport Area',
          'Airport Road (Full Corridor)',
          'Airport Roundabout',
          'Electric Supply Road / PDB Area',
          'Boro Shala Point',
          'Khasdobir',
        ],
      ),
      ThanaSection(
        heading: 'Tea Garden & Residential Zones',
        emoji: '🌳',
        areas: [
          'Lakkatura Tea Garden Area',
          'Malnichhara Tea Estate Road',
          'Sylhet International Cricket Stadium Area',
          'Sylhet Housing Estate (Central Planned Blocks — North of Surma)',
          'Gowai Para',
          'Dhopadighirpar (Airport Edge)',
        ],
      ),
    ],
    overlapNotes: 'Ambarkhana is a massive commercial hub acting as the true gateway to Airport Road — it straddles the Kotwali and Airport Thana boundary. Sylhet Housing Estate was previously miscategorized under South Surma — it is north of the river.',
  ),
};

/// The 6 SMP thana police stations — only these appear on the map.
/// Coordinates corrected for accuracy per Google Maps verification.
final List<PoliceStation> dummyPoliceStations = [
  // ── 1. KOTWALI MODEL THANA ──────────────────────────────────────────────
  const PoliceStation(
    id: 'smp_kotwali',
    name: 'Kotwali Model Police Station',
    address: 'VVQ8+C9M, Road, Sylhet 3100, Bangladesh',
    phone: '01320-067568',
    location: LatLng(24.8978, 91.8682), // Verified: Zindabazar police HQ
    details:
        'Address: VVQ8+C9M, Road, Sylhet 3100, Bangladesh\n'
        'Hours: Open 24 Hours\n'
        'Phone Number: 01320-067568',
    jurisdiction: 'Kotwali',
    thana: thanaKotwali,
  ),

  // ── 2. MOGLABAZAR THANA ─────────────────────────────────────────────────
  const PoliceStation(
    id: 'smp_moglabazar',
    name: 'Moglabazar Police Station',
    address: 'Moglabazar, Sylhet, Bangladesh',
    phone: '01320-067714',
    location: LatLng(24.8847, 91.8912), // Verified: Moglabazar area
    details:
        'Address: Moglabazar, Sylhet, Bangladesh\n'
        'Hours: Open 24 Hours\n'
        'Phone Number: 01320-067714',
    jurisdiction: 'Moglabazar',
    thana: thanaMoglabazar,
  ),

  // ── 3. SOUTH SURMA THANA ────────────────────────────────────────────────
  // NOTE: South of Surma River. Uposhohor & Housing Estate are NOT here.
  const PoliceStation(
    id: 'smp_south_surma',
    name: 'South Surma Police Station',
    address: 'South Surma, Sylhet, Bangladesh',
    phone: '01320-067688',
    location: LatLng(24.8726, 91.8618), // Verified: Kadamtali South Surma side
    details:
        'Address: South Surma, Sylhet, Bangladesh\n'
        'Hours: Open 24 Hours\n'
        'Phone Number: 01320-067688',
    jurisdiction: 'South Surma',
    thana: thanaSouthSurma,
  ),

  // ── 4. SHAHPORAN (RH.) THANA ────────────────────────────────────────────
  // NOTE: Shahjalal Uposhohor is NORTH of Surma River — correctly here.
  const PoliceStation(
    id: 'smp_shahporan',
    name: 'Shahporan Police Station',
    address: 'Khadimpara, Shahporan, Sylhet, Bangladesh',
    phone: '01320-067740',
    location: LatLng(24.9028, 91.9048), // Verified: Shah Poran Dargah eastern area
    details:
        'Address: Khadimpara, Shahporan, Sylhet, Bangladesh\n'
        'Hours: Open 24 Hours\n'
        'Phone Number: 01320-067740',
    jurisdiction: 'Shah Poran',
    thana: thanaShahPoran,
  ),

  // ── 5. JALALABAD THANA ──────────────────────────────────────────────────
  const PoliceStation(
    id: 'smp_jalalabad',
    name: 'Jalalabad Police Station',
    address: 'Jalalabad, Sylhet, Bangladesh',
    phone: '01320-067594',
    location: LatLng(24.9087, 91.8512), // Verified: Akhalia/SUST area
    details:
        'Address: Jalalabad, Sylhet, Bangladesh\n'
        'Hours: Open 24 Hours\n'
        'Phone Number: 01320-067594',
    jurisdiction: 'Jalalabad',
    thana: thanaJalalabad,
  ),

  // ── 6. AIRPORT (BIMANBANDAR) THANA ──────────────────────────────────────
  // NOTE: Housing Estate is north of the river — correctly here.
  const PoliceStation(
    id: 'smp_airport',
    name: 'Airport Police Station',
    address: 'Salutikor Road (Airport Bypass), Dhopagul, Sylhet, Bangladesh',
    phone: '01320-067620',
    location: LatLng(24.9632, 91.8681), // Verified: Near Osmani Airport
    details:
        'Address: Salutikor Road (Airport Bypass), Dhopagul, Sylhet, Bangladesh\n'
        'Hours: Open 24 Hours\n'
        'Phone Number: 01320-067620',
    jurisdiction: 'Airport',
    thana: thanaAirport,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Geographic bounding boxes for each SMP thana.
// Used for instant GPS-based thana auto-selection (no internet needed).
// Format: [minLat, maxLat, minLon, maxLon]
// CORRECTED: Uposhohor & Housing Estate moved to correct thanas (north of river).
// ─────────────────────────────────────────────────────────────────────────────
const Map<String, List<double>> smpThanaBounds = {
  // Kotwali: tight city core including Dargah, Zindabazar, Bandar, Kadamtali(N)
  thanaKotwali:    [24.882, 24.912, 91.856, 91.882],
  // Moglabazar: east of Kotwali, LU campus zone, south towards Moglabazar Proper
  thanaMoglabazar: [24.870, 24.900, 91.878, 91.918],
  // South Surma: SOUTH of Surma river only
  thanaSouthSurma: [24.850, 24.885, 91.845, 91.878],
  // Shah Poran: eastern zone including Uposhohor (north of river), MC College, Khadimnagar
  thanaShahPoran:  [24.890, 24.945, 91.885, 91.960],
  // Jalalabad: west zone, SUST, Medical College, Akhalia
  thanaJalalabad:  [24.893, 24.940, 91.815, 91.870],
  // Airport: northern zone including Housing Estate (north of river), Lakkatura, Cricket Stadium
  thanaAirport:    [24.918, 24.995, 91.840, 91.910],
};

/// Returns the SMP thana name that contains [lat, lon], or null if outside all.
String? detectThanaForPoint(double lat, double lon) {
  // Priority order matters for overlapping regions — more specific first
  final priorityOrder = [
    thanaSouthSurma, // south of river — check first to avoid false positives
    thanaKotwali,
    thanaMoglabazar,
    thanaShahPoran,
    thanaJalalabad,
    thanaAirport,
  ];
  for (final key in priorityOrder) {
    final b = smpThanaBounds[key]!;
    if (lat >= b[0] && lat <= b[1] && lon >= b[2] && lon <= b[3]) {
      return key;
    }
  }
  return null;
}

/// Returns the SMP thana whose centroid is closest to [lat, lon].
/// Used as fallback when the point isn't inside any bounding box.
String nearestThanaForPoint(double lat, double lon) {
  const centroids = {
    thanaKotwali:    [24.8978, 91.8682],
    thanaMoglabazar: [24.8847, 91.8912],
    thanaSouthSurma: [24.8726, 91.8618],
    thanaShahPoran:  [24.9028, 91.9048],
    thanaJalalabad:  [24.9087, 91.8512],
    thanaAirport:    [24.9632, 91.8681],
  };

  String best = thanaKotwali;
  double bestDist = double.infinity;
  for (final entry in centroids.entries) {
    final dlat = lat - entry.value[0];
    final dlon = lon - entry.value[1];
    final dist = dlat * dlat + dlon * dlon;
    if (dist < bestDist) {
      bestDist = dist;
      best = entry.key;
    }
  }
  return best;
}

/// Resolves the SMP thana for a GPS point:
/// 1. Checks bounding boxes first (instant, no internet)
/// 2. Falls back to nearest centroid
String resolveSmpThana(double lat, double lon) {
  return detectThanaForPoint(lat, lon) ?? nearestThanaForPoint(lat, lon);
}
