import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/officer_model.dart';
import '../../core/constants/app_constants.dart';

class OfficerService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<OfficerModel>> getAllOfficers() async {
    final response = await _client
        .from(AppConstants.officersTable)
        .select()
        .order('created_at', ascending: false);
    return (response as List).map((e) => OfficerModel.fromMap(e)).toList();
  }

  Future<OfficerModel> addOfficer(Map<String, dynamic> data) async {
    final response = await _client
        .from(AppConstants.officersTable)
        .insert(data)
        .select()
        .single();
    return OfficerModel.fromMap(response);
  }

  Future<void> updateOfficer(String id, Map<String, dynamic> data) async {
    await _client
        .from(AppConstants.officersTable)
        .update(data)
        .eq('id', id);
  }

  Future<void> deleteOfficer(String id) async {
    await _client
        .from(AppConstants.officersTable)
        .delete()
        .eq('id', id);
  }

  Future<void> toggleActive(String id, bool isActive) async {
    await _client
        .from(AppConstants.officersTable)
        .update({'is_active': isActive})
        .eq('id', id);
  }

  Future<List<OfficerModel>> getActiveOfficers() async {
    final response = await _client
        .from(AppConstants.officersTable)
        .select()
        .eq('is_active', true)
        .order('name');
    return (response as List).map((e) => OfficerModel.fromMap(e)).toList();
  }
}
