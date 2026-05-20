import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../../core/constants/app_constants.dart';

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<ProfileModel?> getProfile(String userId) async {
    try {
      final data = await _client
          .from(AppConstants.profilesTable)
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data == null) return null;
      return ProfileModel.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await _client
        .from(AppConstants.profilesTable)
        .update(data)
        .eq('id', userId);
  }

  Future<List<ProfileModel>> getAllUsers() async {
    final response = await _client
        .from(AppConstants.profilesTable)
        .select()
        .order('created_at', ascending: false);
    return (response as List).map((e) => ProfileModel.fromMap(e)).toList();
  }

  Future<void> setUserRole(String userId, String role) async {
    await _client
        .from(AppConstants.profilesTable)
        .update({'role': role})
        .eq('id', userId);
  }

  Future<void> setVerified(String userId, bool verified) async {
    await _client
        .from(AppConstants.profilesTable)
        .update({'is_verified': verified})
        .eq('id', userId);
  }

  Future<int> getTotalUserCount() async {
    final response = await _client
        .from(AppConstants.profilesTable)
        .select('id')
        .eq('role', 'user');
    return (response as List).length;
  }
}
