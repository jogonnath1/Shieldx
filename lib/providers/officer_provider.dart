import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/officer_model.dart';
import '../data/services/officer_service.dart';

final officerServiceProvider =
    Provider<OfficerService>((ref) => OfficerService());

final officersProvider = FutureProvider<List<OfficerModel>>((ref) {
  return ref.watch(officerServiceProvider).getAllOfficers();
});

final activeOfficersProvider = FutureProvider<List<OfficerModel>>((ref) {
  return ref.watch(officerServiceProvider).getActiveOfficers();
});
