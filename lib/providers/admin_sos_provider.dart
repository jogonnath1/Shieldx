import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/emergency_model.dart';
import 'sos_provider.dart';

// Stream of all active emergencies
final activeEmergenciesStreamProvider = StreamProvider<List<EmergencyModel>>((ref) {
  final service = ref.read(emergencyServiceProvider);
  return service.watchActiveEmergencies();
});

// Admin command provider to resolve emergencies
final resolveEmergencyProvider = Provider((ref) {
  final service = ref.read(emergencyServiceProvider);
  return (String emergencyId, String adminId) async {
    await service.resolveEmergency(emergencyId, adminId);
  };
});
