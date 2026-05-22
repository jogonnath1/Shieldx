import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/complaint_model.dart';
import '../models/status_history_model.dart';
import '../../core/constants/app_constants.dart';
import 'activity_log_service.dart';

class ComplaintService {
  final SupabaseClient _client = Supabase.instance.client;
  final ActivityLogService _logService = ActivityLogService();

  // User: Submit complaint
  Future<ComplaintModel> submitComplaint(Map<String, dynamic> data) async {
    final response = await _client
        .from(AppConstants.complaintsTable)
        .insert(data)
        .select()
        .single();
    final model = ComplaintModel.fromMap(response);

    await _logService.logEvent(
      actionType: 'report_submit',
      details: {
        'complaint_id': model.id,
        'category': model.crimeCategory ?? 'Other',
        'is_anonymous': model.isAnonymous,
      },
    );

    return model;
  }

  // User: Get own complaints
  Future<List<ComplaintModel>> getUserComplaints(String userId) async {
    final response = await _client
        .from(AppConstants.complaintsTable)
        .select()
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
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
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    if (status != null && status != 'all') {
      query = _client
          .from(AppConstants.complaintsTable)
          .select()
          .eq('status', status)
          .isFilter('deleted_at', null)
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
        .isFilter('deleted_at', null)
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

    await _logService.logEvent(
      actionType: 'report_edit',
      details: {
        'complaint_id': id,
      },
    );
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
        .select('status')
        .isFilter('deleted_at', null);
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
        .select('crime_category')
        .isFilter('deleted_at', null);
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

  Future<void> deleteComplaint(String id) async {
    await _client
        .from(AppConstants.complaintsTable)
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', id);

    await _logService.logEvent(
      actionType: 'report_delete',
      details: {
        'complaint_id': id,
        'type': 'soft_delete',
      },
    );
  }

  // Get soft-deleted user complaints
  Future<List<ComplaintModel>> getDeletedUserComplaints(String userId) async {
    final response = await _client
        .from(AppConstants.complaintsTable)
        .select()
        .eq('user_id', userId)
        .not('deleted_at', 'is', null)
        .order('deleted_at', ascending: false);
    return (response as List).map((e) => ComplaintModel.fromMap(e)).toList();
  }

  // Get all soft-deleted complaints (admin)
  Future<List<ComplaintModel>> getDeletedAllComplaints() async {
    final response = await _client
        .from(AppConstants.complaintsTable)
        .select()
        .not('deleted_at', 'is', null)
        .order('deleted_at', ascending: false);
    return (response as List).map((e) => ComplaintModel.fromMap(e)).toList();
  }

  // Restore complaint
  Future<void> restoreComplaint(String id) async {
    await _client
        .from(AppConstants.complaintsTable)
        .update({'deleted_at': null})
        .eq('id', id);
  }

  // Restore multiple complaints
  Future<void> restoreComplaints(List<String> ids) async {
    await _client
        .from(AppConstants.complaintsTable)
        .update({'deleted_at': null})
        .inFilter('id', ids);
  }

  // Hard delete multiple complaints
  Future<void> hardDeleteComplaints(List<String> ids) async {
    await _client
        .from(AppConstants.complaintsTable)
        .delete()
        .inFilter('id', ids);
  }

  // Hard delete all user's deleted complaints
  Future<void> hardDeleteAllUserComplaints(String userId) async {
    await _client
        .from(AppConstants.complaintsTable)
        .delete()
        .eq('user_id', userId)
        .not('deleted_at', 'is', null);
  }

  // Hard delete all deleted complaints
  Future<void> hardDeleteAllComplaints() async {
    await _client
        .from(AppConstants.complaintsTable)
        .delete()
        .not('deleted_at', 'is', null);
  }

  // Get historical complaint coordinates for heatmap
  Future<List<ComplaintModel>> getHistoricalCrimeCoordinates() async {
    final response = await _client
        .from(AppConstants.complaintsTable)
        .select()
        .isFilter('deleted_at', null)
        .not('latitude', 'is', null)
        .not('longitude', 'is', null);
    return (response as List).map((e) => ComplaintModel.fromMap(e)).toList();
  }

  // Real-time stream for user complaints
  Stream<List<ComplaintModel>> watchUserComplaints(String userId) {
    return _client
        .from(AppConstants.complaintsTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) => data
            .map((e) => ComplaintModel.fromMap(e))
            .where((c) => c.deletedAt == null)
            .toList());
  }

  // Real-time stream for all complaints (admin) — optionally scoped to a thana
  Stream<List<ComplaintModel>> watchAllComplaints({String? stationThana}) {
    final stream = _client
        .from(AppConstants.complaintsTable)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data
            .map((e) => ComplaintModel.fromMap(e))
            .where((c) => c.deletedAt == null)
            .toList());

    if (stationThana == null || stationThana.isEmpty) return stream;

    // Filter client-side: match locationAddress or jurisdiction field containing thana keywords
    final keywords = _thanaKeywords(stationThana);
    return stream.map((list) => list.where((c) {
      final addr = (c.locationAddress ?? '').toLowerCase();
      return keywords.any((kw) => addr.contains(kw));
    }).toList());
  }

  // Admin: Get stats for all stations in a single query optimized in memory
  Future<Map<String, Map<String, int>>> getAllStationsStats(List<String> thanas) async {
    final response = await _client
        .from(AppConstants.complaintsTable)
        .select('status, location_address')
        .isFilter('deleted_at', null);
    final list = response as List;

    final result = <String, Map<String, int>>{};
    for (final thana in thanas) {
      final filtered = _filterByThana(list, thana);
      final stats = <String, int>{
        'total': filtered.length,
        'submitted': 0,
        'in_progress': 0,
        'under_investigation': 0,
        'resolved': 0,
        'closed': 0,
        'rejected': 0,
      };
      for (final item in filtered) {
        final status = item['status'] as String? ?? 'submitted';
        stats[status] = (stats[status] ?? 0) + 1;
      }
      result[thana] = stats;
    }
    return result;
  }

  // Admin: Get stats optionally scoped to a thana
  Future<Map<String, int>> getStatsForStation({String? stationThana}) async {
    final response = await _client
        .from(AppConstants.complaintsTable)
        .select('status, location_address')
        .isFilter('deleted_at', null);
    final list = response as List;
    final filtered = _filterByThana(list, stationThana);
    final stats = <String, int>{
      'total': filtered.length,
      'submitted': 0,
      'in_progress': 0,
      'under_investigation': 0,
      'resolved': 0,
      'closed': 0,
      'rejected': 0,
    };
    for (final item in filtered) {
      final status = item['status'] as String? ?? 'submitted';
      stats[status] = (stats[status] ?? 0) + 1;
    }
    return stats;
  }

  // Admin: Get category stats optionally scoped to a thana
  Future<Map<String, int>> getCategoryStatsForStation({String? stationThana}) async {
    final response = await _client
        .from(AppConstants.complaintsTable)
        .select('crime_category, location_address')
        .isFilter('deleted_at', null);
    final list = response as List;
    final filtered = _filterByThana(list, stationThana);
    final stats = <String, int>{};
    for (final item in filtered) {
      final cat = (item['crime_category'] as String?) ?? 'Other';
      stats[cat] = (stats[cat] ?? 0) + 1;
    }
    final sorted = stats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(7));
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  List<Map<String, dynamic>> _filterByThana(
      List<dynamic> list, String? stationThana) {
    if (stationThana == null || stationThana.isEmpty) {
      return list.cast<Map<String, dynamic>>();
    }
    final keywords = _thanaKeywords(stationThana);
    return list
        .cast<Map<String, dynamic>>()
        .where((item) {
          final addr = (item['location_address'] as String? ?? '').toLowerCase();
          return keywords.any((kw) => addr.contains(kw));
        })
        .toList();
  }

  /// Returns lowercase keywords extracted from the thana name for address matching.
  List<String> _thanaKeywords(String thana) {
    // Map each SMP thana to distinguishing location keywords
    const Map<String, List<String>> thanaKeywordsMap = {
      'Kotwali Model Thana': ['kotwali', 'zindabazar', 'dargah', 'bandar bazar', 'chowhatta', 'mirabazar', 'lamabazar', 'osmani medical', 'kajalshah'],
      'Moglabazar Thana':    ['moglabazar', 'daudpur', 'jalalpur', 'kuchai', 'silam'],
      'South Surma Thana':   ['south surma', 'kadamtali', 'boroikandi', 'mominkhola', 'shivbari', 'babna', 'kamalbazar', 'leading university', 'ragibnagar'],
      'Shahporan Thana':     ['shahporan', 'shah poran', 'tilagor', 'baluchar', 'khadimnagar', 'uposhohor'],
      'Jalalabad Thana':     ['jalalabad', 'akhalia', 'sust', 'kumargaon', 'medina market', 'housing estate'],
      'Airport Thana':       ['airport', 'bimanbandar', 'lakkatura', 'osmani international', 'dhopagul'],
    };
    final lower = thana.toLowerCase();
    // Try exact map lookup first
    for (final entry in thanaKeywordsMap.entries) {
      if (entry.key.toLowerCase() == lower) return entry.value;
    }
    // Fallback: split the thana name into individual words
    return lower.split(' ').where((w) => w.length > 3).toList();
  }
}
