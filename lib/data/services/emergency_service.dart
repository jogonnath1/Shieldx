import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/emergency_model.dart';
import '../models/profile_model.dart';

class EmergencyService {
  final SupabaseClient _client = Supabase.instance.client;

  // Send notification to all admins
  Future<void> _notifyAdmins({
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    try {
      // Fetch all admins from profiles table
      final adminProfiles = await _client
          .from('profiles')
          .select('id')
          .eq('role', 'admin');
          
      if (adminProfiles == null || adminProfiles.isEmpty) return;
      
      final uuid = const Uuid();
      final notificationsToInsert = adminProfiles.map((admin) {
        return {
          'id': uuid.v4(),
          'user_id': admin['id'],
          'title': title,
          'message': message,
          'type': type,
          'related_id': relatedId,
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        };
      }).toList();
      
      await _client
          .from('notifications')
          .insert(notificationsToInsert);
    } catch (e) {
      // Ignore or log error
      print('Failed to notify admins: $e');
    }
  }

  // Trigger a new SOS emergency
  Future<EmergencyModel> triggerSOS(double lat, double lng) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Fetch user profile first to get their name and phone number for the notification
    String citizenName = 'A citizen';
    String citizenPhone = 'N/A';
    try {
      final profileRes = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (profileRes != null) {
        citizenName = profileRes['display_name'] ?? 'A citizen';
        citizenPhone = profileRes['phone_number'] ?? 'N/A';
      }
    } catch (_) {}

    // Automatically cancel any existing active emergencies for this user to prevent duplicates
    try {
      await _client
          .from('emergencies')
          .update({
            'status': 'cancelled',
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', user.id)
          .eq('status', 'active');
    } catch (_) {
      // Ignore cleanup failures to ensure SOS trigger still works
    }

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
    
    final emergency = EmergencyModel.fromMap(response);

    // Notify all admins about the active SOS
    await _notifyAdmins(
      title: '🚨 Emergency SOS Triggered',
      message: '$citizenName ($citizenPhone) has triggered an active SOS alert! Coordinates: $lat, $lng.',
      type: 'sos',
      relatedId: emergency.id,
    );
    
    return emergency;
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
    // Fetch the emergency row to know who the user is for the safety notification
    try {
      final emergencyRes = await _client
          .from('emergencies')
          .select()
          .eq('id', emergencyId)
          .maybeSingle();
          
      if (emergencyRes != null) {
        final userId = emergencyRes['user_id'] as String?;
        if (userId != null) {
          // Fetch user profile
          final profileRes = await _client
              .from('profiles')
              .select()
              .eq('id', userId)
              .maybeSingle();
              
          final name = profileRes != null ? (profileRes['display_name'] ?? 'A citizen') : 'A citizen';
          final phone = profileRes != null ? (profileRes['phone_number'] ?? 'N/A') : 'N/A';
          
          // Notify all admins that the user marked themselves safe
          await _notifyAdmins(
            title: '✅ SOS Cancelled / Safe',
            message: '$name ($phone) has marked themselves safe and cancelled the SOS alarm.',
            type: 'sos',
            relatedId: emergencyId,
          );
        }
      }
    } catch (_) {}

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
          
          // Deduplicate by user_id to ensure a user only has one active SOS card in the dashboard
          final seenUserIds = <String>{};
          final uniqueActiveRows = <Map<String, dynamic>>[];
          for (final row in activeRows) {
            final userId = row['user_id'] as String?;
            if (userId != null) {
              if (!seenUserIds.contains(userId)) {
                seenUserIds.add(userId);
                uniqueActiveRows.add(row);
              }
            } else {
              uniqueActiveRows.add(row);
            }
          }

          for (final row in uniqueActiveRows) {
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
