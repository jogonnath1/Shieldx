import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/complaint_model.dart';
import '../models/status_history_model.dart';
import '../../core/constants/app_constants.dart';

class ComplaintService {
  final SupabaseClient _client = Supabase.instance.client;

  // User: Submit complaint
  Future<ComplaintModel> submitComplaint(Map<String, dynamic> data) async {
    final response = await _client
        .from(AppConstants.complaintsTable)
        .insert(data)
        .select()
        .single();
    return ComplaintModel.fromMap(response);
  }

  // User: Get own complaints
  Future<List<ComplaintModel>> getUserComplaints(String userId) async {
    final response = await _client
        .from(AppConstants.complaintsTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (response as List).map((e) => ComplaintModel.fromMap(e)).toList();
  }

  // Admin: Get all complaints with pagination
  Future<List<ComplaintModel>> getAllComplaints({
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    var query = _client
        .from(AppConstants.complaintsTable)
        .select()
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    if (status != null && status != 'all') {
      query = _client
          .from(AppConstants.complaintsTable)
          .select()
          .eq('status', status)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
    }

    final response = await query;
    return (response as List).map((e) => ComplaintModel.fromMap(e)).toList();
  }

  // Get single complaint
  Future<ComplaintModel?> getComplaint(String id) async {
    final response = await _client
        .from(AppConstants.complaintsTable)
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return ComplaintModel.fromMap(response);
  }

  // User: Update own complaint (only while status == 'submitted')
  Future<void> updateComplaint(String id, Map<String, dynamic> data) async {
    await _client
        .from(AppConstants.complaintsTable)
        .update({...data, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', id)
        .eq('status', 'submitted'); // safety: only update if still submitted
  }

  // Admin: Update complaint status
  Future<void> updateComplaintStatus({
    required String complaintId,
    required String status,
    String? note,
    String? assignedOfficerId,
    required String changedBy,
  }) async {
    // Update complaint
    final updateData = <String, dynamic>{
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (assignedOfficerId != null) {
      updateData['assigned_officer_id'] = assignedOfficerId;
    }
    await _client
        .from(AppConstants.complaintsTable)
        .update(updateData)
        .eq('id', complaintId);

    // Log status history
    await _client.from(AppConstants.statusHistoryTable).insert({
      'complaint_id': complaintId,
      'status': status,
      'note': note,
      'changed_by': changedBy,
    });
  }

  // Get status history for a complaint
  Future<List<StatusHistoryModel>> getStatusHistory(String complaintId) async {
    final response = await _client
        .from(AppConstants.statusHistoryTable)
        .select()
        .eq('complaint_id', complaintId)
        .order('changed_at', ascending: true);
    return (response as List)
        .map((e) => StatusHistoryModel.fromMap(e))
        .toList();
  }

  // Admin: Get stats
  Future<Map<String, int>> getStats() async {
    final response = await _client
        .from(AppConstants.complaintsTable)
        .select('status');
    final list = response as List;
    final stats = <String, int>{
      'total': list.length,
      'submitted': 0,
      'in_progress': 0,
      'under_investigation': 0,
      'resolved': 0,
      'closed': 0,
      'rejected': 0,
    };
    for (final item in list) {
      final status = item['status'] as String? ?? 'submitted';
      stats[status] = (stats[status] ?? 0) + 1;
    }
    return stats;
  }

  // Admin: Get stats grouped by category
  Future<Map<String, int>> getCategoryStats() async {
    final response = await _client
        .from(AppConstants.complaintsTable)
        .select('crime_category');
    final list = response as List;
    final stats = <String, int>{};
    for (final item in list) {
      final cat = (item['crime_category'] as String?) ?? 'Other';
      stats[cat] = (stats[cat] ?? 0) + 1;
    }
    // Sort descending by count, keep top 7
    final sorted = stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(7));
  }

  // Delete complaint (admin only)
  Future<void> deleteComplaint(String id) async {
    await _client
        .from(AppConstants.complaintsTable)
        .delete()
        .eq('id', id);
  }

  // Real-time stream for user complaints
  Stream<List<ComplaintModel>> watchUserComplaints(String userId) {
    return _client
        .from(AppConstants.complaintsTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data.map((e) => ComplaintModel.fromMap(e)).toList());
  }

  // Real-time stream for all complaints (admin)
  Stream<List<ComplaintModel>> watchAllComplaints() {
    return _client
        .from(AppConstants.complaintsTable)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((e) => ComplaintModel.fromMap(e)).toList());
  }
}
