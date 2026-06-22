import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shieldx/common/data/models/emergency_model.dart';
import 'package:shieldx/user/providers/sos_provider.dart';

final activeEmergenciesStreamProvider =
    StreamProvider<List<EmergencyModel>>((ref) {
  final service = ref.read(emergencyServiceProvider);
  return service.watchActiveEmergencies();
});
final resolveEmergencyProvider = Provider((ref) {
  final service = ref.read(emergencyServiceProvider);
  return (String emergencyId, String adminId) async {
    await service.resolveEmergency(emergencyId, adminId);
  };
});
