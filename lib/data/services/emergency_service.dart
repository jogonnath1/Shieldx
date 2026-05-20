import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/emergency_model.dart';
import '../models/profile_model.dart';

class EmergencyService {
  final SupabaseClient _client = Supabase.instance.client;

  // Trigger a new SOS emergency
  Future<EmergencyModel> triggerSOS(double lat, double lng) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final response = await _client
        .from('emergencies')
        .insert({
          'user_id': user.id,
          'latitude': lat,
          'longitude': lng,
          'status': 'active',
        })
        .select()
        .single();
    
    return EmergencyModel.fromMap(response);
  }

  // Update live GPS coordinates of an active emergency
  Future<void> updateEmergencyLocation(String emergencyId, double lat, double lng) async {
    await _client
        .from('emergencies')
        .update({
          'latitude': lat,
          'longitude': lng,
        })
        .eq('id', emergencyId)
        .eq('status', 'active'); // Guard: only update active ones
  }

  // Citizen: Cancel own emergency
  Future<void> cancelEmergency(String emergencyId) async {
    await _client
        .from('emergencies')
        .update({
          'status': 'cancelled',
          'resolved_at': DateTime.now().toIso8601String(),
        })
        .eq('id', emergencyId);
  }

  // Admin: Resolve an active emergency
  Future<void> resolveEmergency(String emergencyId, String adminId) async {
    await _client
        .from('emergencies')
        .update({
          'status': 'resolved',
          'resolved_at': DateTime.now().toIso8601String(),
          'resolved_by': adminId,
        })
        .eq('id', emergencyId);
  }

  // Stream active emergencies for the admin panel in real-time
  Stream<List<EmergencyModel>> watchActiveEmergencies() {
    return _client
        .from('emergencies')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap((data) async {
          if (data.isEmpty) return [];
          final list = <EmergencyModel>[];
          // Filter ONLY active ones client-side so updates to non-active status are processed and removed instantly
          final activeRows = data.where((row) => row['status'] == 'active').toList();
          for (final row in activeRows) {
            try {
              final profileRes = await _client
                  .from('profiles')
                  .select()
                  .eq('id', row['user_id'])
                  .maybeSingle();
              final profile = profileRes != null ? ProfileModel.fromMap(profileRes) : null;
              list.add(EmergencyModel.fromMap(row, userProfile: profile));
            } catch (e) {
              // Gracefully handle missing profile profile mapping
              list.add(EmergencyModel.fromMap(row));
            }
          }
          return list;
        });
  }

  // Stream single emergency for real-time tracking
  Stream<EmergencyModel?> watchEmergency(String emergencyId) {
    return _client
        .from('emergencies')
        .stream(primaryKey: ['id'])
        .eq('id', emergencyId)
        .asyncMap((data) async {
          if (data.isEmpty) return null;
          final row = data.first;
          try {
            final profileRes = await _client
                .from('profiles')
                .select()
                .eq('id', row['user_id'])
                .maybeSingle();
            final profile = profileRes != null ? ProfileModel.fromMap(profileRes) : null;
            return EmergencyModel.fromMap(row, userProfile: profile);
          } catch (e) {
            return EmergencyModel.fromMap(row);
          }
        });
  }
}
