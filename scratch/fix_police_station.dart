// ignore_for_file: unused_local_variable, prefer_interpolation_to_compose_strings
import 'dart:io';

void main() {
  final modelFile = File('lib/data/models/police_station_model.dart');
  var content = modelFile.readAsStringSync();

  // 1. Add `final String division;` and constructor argument to PoliceStation
  content = content.replaceFirst('  final String thana; // SMP thana name\n',
      '  final String thana; // SMP thana name\n  final String division;\n');
  content = content.replaceFirst('    this.thana = \'\',\n  });',
      '    this.thana = \'\',\n    this.division = \'\',\n  });');
  content = content.replaceFirst('    String? thana,\n  }) {',
      '    String? thana,\n    String? division,\n  }) {');
  content = content.replaceFirst('      thana: thana ?? this.thana,\n    );',
      '      thana: thana ?? this.thana,\n      division: division ?? this.division,\n    );');
  content = content.replaceFirst(
      '      thana: tags[\'addr:subdistrict\'] ?? \'\',\n    );',
      '      thana: tags[\'addr:subdistrict\'] ?? \'\',\n      division: \'\',\n    );');

  // 2. Add division constants and emojis
  const constants = '''
const String divisionDhaka = 'Dhaka';
const String divisionChattogram = 'Chattogram';
const String divisionSylhet = 'Sylhet';
const String divisionRajshahi = 'Rajshahi';
const String divisionKhulna = 'Khulna';
const String divisionBarishal = 'Barishal';
const String divisionRangpur = 'Rangpur';
const String divisionMymensingh = 'Mymensingh';

final List<String> allDivisions = [
  divisionDhaka,
  divisionChattogram,
  divisionSylhet,
  divisionRajshahi,
  divisionKhulna,
  divisionBarishal,
  divisionRangpur,
  divisionMymensingh,
];

const Map<String, String> divisionEmojis = {
  divisionDhaka: '🏢',
  divisionChattogram: '🚢',
  divisionSylhet: '🍃',
  divisionRajshahi: '🥭',
  divisionKhulna: '🐅',
  divisionBarishal: '🚤',
  divisionRangpur: '🌾',
  divisionMymensingh: '🌳',
};
''';

  content = content.replaceFirst(
      'const String thanaKotwali    = \'Kotwali Model Thana\';',
      '$constants\nconst String thanaKotwali    = \'Kotwali Model Thana\';');

  // 3. Inject stations (including the division field which is in scratch/stations_out.dart)
  // Re-generate stations with division included!
  const data = '''
**Dhaka Division**
- **Dhaka Metropolitan Police (DMP):** Ramna, Dhanmondi, Shahbag, New Market, Lalbagh, Kotwali, Hazaribagh, Kamrangirchar, Sutrapur, Demra, Shampur, Jatrabari, Motijheel, Sabujbagh, Khilgaon, Paltan, Adabor, Badda, Banani, Gulshan, Cantonment, Mirpur, Mohammadpur, and Pallabi.
- **Dhaka District & Others:** Savar, Ashulia, Dhamrai, and Keranigonj.

**Chattogram Division**
- **Chattogram Metropolitan Police (CMP):** Kotwali, Double Mooring, Halishahar, Khulshi, Pahartali, Panchlaish, Bakalia, Bayezid Bostami, Chandgaon, Karnaphuli, Bandar, and EPZ.
- **Chattogram District & Others:** Fatikchari, Bhujpur, Patiya, Boalkhali, Mirsharai, Sitakunda, Sandwip, Raozan, Rangunia, and Hathazari. 

**Sylhet Division**
- **Sylhet Metropolitan Police (SMP):** Kotwali, Airport, Dakshin Surma, Jalalabad, Moglabazar, and Shah Poran.
- **Sylhet District & Others:** Sylhet Sadar, Beanibazar, Bishwanath, Companiganj, Fenchuganj, Golapganj, Gowainghat, Jaintiapur, Kanaighat, Zakiganj, Balaganj, and South Surma.

**Rajshahi Division**
- **Rajshahi Metropolitan Police (RMP):** Boalia, Rajpara, Motihar, Shah Makhdum, Katakhali, Kasiadanga, Airport, and Belpukur.
- **Rajshahi District & Others:** Godagari, Tanor, Mohanpur, Bagmara, Charghat, Durgapur, Puthia, and Bagha. 

**Khulna Division**
- **Khulna Metropolitan Police (KMP):** Khulna Sadar, Sonadanga, Khalishpur, Daulatpur, Khan Jahan Ali, Harintana, Labanchora, and Aranghata.
- **Khulna District & Others:** Batiaghata, Dacope, Dumuria, Dighalia, Koyra, Paikgachha, Phultala, Rupsha, and Terokhada. 

**Barishal Division**
- **Barishal Metropolitan Police (BMP):** Kotwali, Kaunia, Kawnia, Airport, Bandar, and C.R.F.
- **Barishal District & Others:** Muladi, Babuganj, Bakerganj, Banaripara, Agailjhara, Gournadi, Hizla, Mehendiganj, and Wazirpur. 

**Rangpur Division**
- **Rangpur Metropolitan Police (RpMP):** Kotwali, Parshuram, Tajhat, Haragach, Mahiganj, and Hazirhat.
- **Rangpur District & Others:** Rangpur Sadar, Badarganj, Mithapukur, Pirgachha, Pirganj, Taraganj, and Kaunia.

**Mymensingh Division**
- **Mymensingh District & Others:** Mymensingh Sadar, Kotwali, Muktagachha, Phulbaria, Trishal, Bhaluka, Gouripur, Haluaghat, Iswarganj, Nandail, and Phulpur.
''';

  final lines = data.split('\n');
  String currentDivision = '';
  final StringBuffer buffer = StringBuffer();
  int idCounter = 0;

  for (var line in lines) {
    line = line.trim();
    if (line.isEmpty) continue;
    if (line.startsWith('**') && line.contains('Division**')) {
      currentDivision = line.replaceAll('**', '').trim();
    } else if (line.startsWith('-')) {
      final parts = line.split(':**');
      if (parts.length < 2) continue;
      final group = parts[0].replaceAll('- **', '').trim();
      var stationsStr =
          parts[1].replaceAll('.', '').replaceAll(' and ', ', ').trim();
      final stations = stationsStr
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      for (var s in stations) {
        if (currentDivision == 'Sylhet Division' &&
            group == 'Sylhet Metropolitan Police (SMP)') {
          continue;
        }
        final divName = currentDivision.replaceAll(' Division', '');
        final idStr =
            "${divName.toLowerCase()}_${s.toLowerCase().replaceAll(' ', '_')}_$idCounter";
        final divVar = "division$divName";
        idCounter++;

        buffer.writeln('  const PoliceStation(');
        buffer.writeln(
            '    id: \'$idStr\', name: \'$s Police Station\', address: \'$s, $divName\',');
        buffer.writeln(
            '    phone: \'+880 1320-000000\', location: LatLng(23.0, 90.0), division: $divVar, thana: \'$s\',');
        buffer.writeln(
            '    details: \'Serving $s area.\', jurisdiction: \'$s\',');
        buffer.writeln('  ),');
      }
    }
  }

  final smpStations = '''
final List<PoliceStation> dummyPoliceStations = [
  const PoliceStation(
    id: 'smp_kotwali', name: 'Kotwali Model Police Station',
    address: 'VVQ8+C9M, Road, Sylhet 3100, Bangladesh', phone: '01320-067568',
    location: LatLng(24.8978, 91.8682), division: divisionSylhet, thana: thanaKotwali,
    details: \\'\\'\\'Address: VVQ8+C9M, Road, Sylhet 3100, Bangladesh
Hours: Open 24 Hours
Phone Number: 01320-067568\\'\\'\\',
    jurisdiction: 'Kotwali',
  ),
  const PoliceStation(
    id: 'smp_moglabazar', name: 'Moglabazar Police Station',
    address: 'Moglabazar, Sylhet, Bangladesh', phone: '01320-067714',
    location: LatLng(24.8847, 91.8912), division: divisionSylhet, thana: thanaMoglabazar,
    details: \\'\\'\\'Address: Moglabazar, Sylhet, Bangladesh
Hours: Open 24 Hours
Phone Number: 01320-067714\\'\\'\\',
    jurisdiction: 'Moglabazar',
  ),
  const PoliceStation(
    id: 'smp_south_surma', name: 'South Surma Police Station',
    address: 'South Surma, Sylhet, Bangladesh', phone: '01320-067688',
    location: LatLng(24.8726, 91.8618), division: divisionSylhet, thana: thanaSouthSurma,
    details: \\'\\'\\'Address: South Surma, Sylhet, Bangladesh
Hours: Open 24 Hours
Phone Number: 01320-067688\\'\\'\\',
    jurisdiction: 'South Surma',
  ),
  const PoliceStation(
    id: 'smp_shahporan', name: 'Shahporan Police Station',
    address: 'Khadimpara, Shahporan, Sylhet, Bangladesh', phone: '01320-067740',
    location: LatLng(24.9028, 91.9048), division: divisionSylhet, thana: thanaShahPoran,
    details: \\'\\'\\'Address: Khadimpara, Shahporan, Sylhet, Bangladesh
Hours: Open 24 Hours
Phone Number: 01320-067740\\'\\'\\',
    jurisdiction: 'Shah Poran',
  ),
  const PoliceStation(
    id: 'smp_jalalabad', name: 'Jalalabad Police Station',
    address: 'Jalalabad, Sylhet, Bangladesh', phone: '01320-067594',
    location: LatLng(24.9087, 91.8512), division: divisionSylhet, thana: thanaJalalabad,
    details: \\'\\'\\'Address: Jalalabad, Sylhet, Bangladesh
Hours: Open 24 Hours
Phone Number: 01320-067594\\'\\'\\',
    jurisdiction: 'Jalalabad',
  ),
  const PoliceStation(
    id: 'smp_airport', name: 'Airport Police Station',
    address: 'Salutikor Road (Airport Bypass), Dhopagul, Sylhet, Bangladesh', phone: '01320-067620',
    location: LatLng(24.9632, 91.8681), division: divisionSylhet, thana: thanaAirport,
    details: \\'\\'\\'Address: Salutikor Road (Airport Bypass), Dhopagul, Sylhet, Bangladesh
Hours: Open 24 Hours
Phone Number: 01320-067620\\'\\'\\',
    jurisdiction: 'Airport',
  ),
'''
      .replaceAll(r"\'\'\'", "'''");

  final adminStationsString =
      '// Admin Only Stations List\nfinal List<PoliceStation> adminAllPoliceStations = [\n' +
          buffer.toString() +
          '];\n';

  final parts = content.split('// Admin Only Stations List');
  final pre = parts[0];

  final finalContent = pre + adminStationsString;

  modelFile.writeAsStringSync(finalContent);
  File('scratch/stations_out.txt').writeAsStringSync(buffer.toString());
}
