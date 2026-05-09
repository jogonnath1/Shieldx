import 'package:latlong2/latlong.dart';

class PoliceStation {
  final String name;
  final String address;
  final String phone;
  final LatLng location;
  final String details;

  const PoliceStation({
    required this.name,
    required this.address,
    required this.phone,
    required this.location,
    required this.details,
  });
}

// Dummy data for Dhaka
final List<PoliceStation> dummyPoliceStations = [
  PoliceStation(
    name: 'Dhanmondi Police Station',
    address: 'Road No. 6, Dhanmondi, Dhaka 1205',
    phone: '+880 1320-039981',
    location: const LatLng(23.7431, 90.3837),
    details: 'Covers Dhanmondi residential area. Available 24/7 for emergency reporting and general inquiries.',
  ),
  PoliceStation(
    name: 'Gulshan Police Station',
    address: 'Gulshan-2, Dhaka 1212',
    phone: '+880 1320-039999',
    location: const LatLng(23.7925, 90.4078),
    details: 'Serving the Gulshan, Banani, and Baridhara diplomatic zones. Features a dedicated expatriate help desk.',
  ),
  PoliceStation(
    name: 'Uttara West Police Station',
    address: 'Sector 11, Uttara, Dhaka 1230',
    phone: '+880 1320-040011',
    location: const LatLng(23.8732, 90.3951),
    details: 'Responsible for Uttara West zones. Equipped with a fast-response patrol team.',
  ),
  PoliceStation(
    name: 'Tejgaon Police Station',
    address: 'Tejgaon Industrial Area, Dhaka 1208',
    phone: '+880 1320-040030',
    location: const LatLng(23.7604, 90.3905),
    details: 'Covers the central industrial and commercial district of Tejgaon.',
  ),
  PoliceStation(
    name: 'Mirpur Model Police Station',
    address: 'Mirpur-2, Dhaka 1216',
    phone: '+880 1320-040050',
    location: const LatLng(23.8041, 90.3628),
    details: 'Model station serving the densely populated Mirpur area with extended citizen services.',
  ),
];
