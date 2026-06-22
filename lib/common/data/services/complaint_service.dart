import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shieldx/common/data/models/complaint_model.dart';
import 'package:shieldx/common/data/models/status_history_model.dart';
import 'package:shieldx/common/core/constants/app_constants.dart';

/// Service responsible for all CRUD operations on crime complaints.
/// Communicates directly with the Supabase `complaints` and `status_history` tables.
class ComplaintService {
  final SupabaseClient _client = Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // Private Helpers
  // ---------------------------------------------------------------------------

  /// Builds a status count map from a list of complaint rows.
  /// Used by [getStats], [getStatsForStation], and [getAllStationsStats]
  /// to avoid repeating the same counting logic in multiple places.
  Map<String, int> _buildStatusStats(List<dynamic> items) {
    final stats = <String, int>{
      'total': items.length,
      'submitted': 0,
      'in_progress': 0,
      'under_investigation': 0,
      'resolved': 0,
      'closed': 0,
      'rejected': 0,
    };
    for (final item in items) {
      final status = item['status'] as String? ?? 'submitted';
      stats[status] = (stats[status] ?? 0) + 1;
    }
    return stats;
  }

  Future<ComplaintModel> submitComplaint(Map<String, dynamic> data) async {
    final response = await _client
        .from(AppConstants.complaintsTable)
        .insert(data)
        .select()
        .single();
    final model = ComplaintModel.fromMap(response);
    return model;
  }

  Future<List<ComplaintModel>> getUserComplaints(String userId) async {
    final response = await _client
        .from(AppConstants.complaintsTable)
        .select()
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);
    return (response as List).map((e) => ComplaintModel.fromMap(e)).toList();
  }

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

  Future<void> updateComplaint(String id, Map<String, dynamic> data) async {
    await _client.from(AppConstants.complaintsTable).update({
      ...data,
      'updated_at': DateTime.now().toUtc().toIso8601String()
    }).eq('id', id);
  }

  Future<void> updateComplaintStatus({
    required String complaintId,
    required String status,
    String? note,
    String? assignedOfficerId,
    required String changedBy,
  }) async {
    final updateData = <String, dynamic>{
      'status': status,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (assignedOfficerId != null) {
      updateData['assigned_officer_id'] = assignedOfficerId;
    }
    await _client
        .from(AppConstants.complaintsTable)
        .update(updateData)
        .eq('id', complaintId);
    await _client.from(AppConstants.statusHistoryTable).insert({
      'complaint_id': complaintId,
      'status': status,
      'note': note,
      'changed_by': changedBy,
    });
  }

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

  // ---------------------------------------------------------------------------
  // Statistics
  // ---------------------------------------------------------------------------

  /// Returns overall complaint counts grouped by status (for the admin dashboard).
  Future<Map<String, int>> getStats() async {
    final response = await _client
        .from(AppConstants.complaintsTable)
        .select('status')
        .isFilter('deleted_at', null);
    return _buildStatusStats(response as List);
  }

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
    final sorted = stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(7));
  }

  Future<void> deleteComplaint(String id) async {
    await _client.from(AppConstants.complaintsTable).update({
      'deleted_at': DateTime.now().toUtc().toIso8601String()
    }).eq('id', id);
  }

  Future<void> deleteComplaints(List<String> ids) async {
    await _client.from(AppConstants.complaintsTable).update({
      'deleted_at': DateTime.now().toUtc().toIso8601String()
    }).inFilter('id', ids);
  }

  Future<List<ComplaintModel>> getDeletedUserComplaints(String userId) async {
    final response = await _client
        .from(AppConstants.complaintsTable)
        .select()
        .eq('user_id', userId)
        .not('deleted_at', 'is', null)
        .order('deleted_at', ascending: false);
    return (response as List).map((e) => ComplaintModel.fromMap(e)).toList();
  }

  Future<List<ComplaintModel>> getDeletedAllComplaints() async {
    final response = await _client
        .from(AppConstants.complaintsTable)
        .select()
        .not('deleted_at', 'is', null)
        .order('deleted_at', ascending: false);
    return (response as List).map((e) => ComplaintModel.fromMap(e)).toList();
  }

  Future<void> restoreComplaint(String id) async {
    await _client
        .from(AppConstants.complaintsTable)
        .update({'deleted_at': null}).eq('id', id);
  }

  Future<void> restoreComplaints(List<String> ids) async {
    await _client
        .from(AppConstants.complaintsTable)
        .update({'deleted_at': null}).inFilter('id', ids);
  }

  Future<void> hardDeleteComplaints(List<String> ids) async {
    await _client
        .from(AppConstants.complaintsTable)
        .delete()
        .inFilter('id', ids);
  }

  Future<void> hardDeleteAllUserComplaints(String userId) async {
    await _client
        .from(AppConstants.complaintsTable)
        .delete()
        .eq('user_id', userId)
        .not('deleted_at', 'is', null);
  }

  Future<void> hardDeleteAllComplaints() async {
    await _client
        .from(AppConstants.complaintsTable)
        .delete()
        .not('deleted_at', 'is', null);
  }

  Future<List<ComplaintModel>> getHistoricalCrimeCoordinates() async {
    final response = await _client
        .from(AppConstants.complaintsTable)
        .select()
        .isFilter('deleted_at', null)
        .not('latitude', 'is', null)
        .not('longitude', 'is', null);
    return (response as List).map((e) => ComplaintModel.fromMap(e)).toList();
  }

  Stream<List<ComplaintModel>> watchUserComplaints(String userId) {
    return _client
        .from(AppConstants.complaintsTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) {
          final uniqueMap = <String, ComplaintModel>{};
          for (final e in data) {
            final c = ComplaintModel.fromMap(e);
            if (c.deletedAt == null) {
              uniqueMap[c.id] = c;
            }
          }
          final list = uniqueMap.values.toList();
          list.sort((a, b) => (b.createdAt ?? DateTime.now())
              .compareTo(a.createdAt ?? DateTime.now()));
          return list;
        });
  }

  Stream<List<ComplaintModel>> watchAllComplaints({String? stationThana}) {
    final stream = _client
        .from(AppConstants.complaintsTable)
        .stream(primaryKey: ['id']).map((data) {
      final uniqueMap = <String, ComplaintModel>{};
      for (final e in data) {
        final c = ComplaintModel.fromMap(e);
        if (c.deletedAt == null) {
          uniqueMap[c.id] = c;
        }
      }
      final list = uniqueMap.values.toList();
      list.sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));
      return list;
    });
    if (stationThana == null || stationThana.isEmpty) return stream;
    final keywords = _thanaKeywords(stationThana);
    return stream.map((list) => list.where((c) {
          final addr = (c.locationAddress ?? '').toLowerCase();
          return keywords.any((kw) => addr.contains(kw));
        }).toList());
  }

  /// Fetches stats for ALL thanas at once — used by the station switcher
  /// to compare complaint volumes across all police stations.
  Future<Map<String, Map<String, int>>> getAllStationsStats(
      List<String> thanas) async {
    final response = await _client
        .from(AppConstants.complaintsTable)
        .select('status, location_address')
        .isFilter('deleted_at', null);
    final list = response as List;
    final result = <String, Map<String, int>>{};
    for (final thana in thanas) {
      final filtered = _filterByThana(list, thana);
      result[thana] = _buildStatusStats(filtered); // reuse helper
    }
    return result;
  }

  /// Returns status counts filtered for a specific police station's thana.
  /// If [stationThana] is null/empty, returns global stats across all stations.
  Future<Map<String, int>> getStatsForStation({String? stationThana}) async {
    final response = await _client
        .from(AppConstants.complaintsTable)
        .select('status, location_address')
        .isFilter('deleted_at', null);
    final filtered = _filterByThana(response as List, stationThana);
    return _buildStatusStats(filtered); // reuse helper
  }

  Future<Map<String, int>> getCategoryStatsForStation(
      {String? stationThana}) async {
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
    final sorted = stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(7));
  }

  // ---------------------------------------------------------------------------
  // Private: Thana Filtering
  // ---------------------------------------------------------------------------

  /// Filters complaint rows by matching each row's `location_address` against
  /// the set of known keywords for the given thana (police sub-district).
  /// Returns all rows unfiltered if [stationThana] is null or empty.
  List<Map<String, dynamic>> _filterByThana(
      List<dynamic> list, String? stationThana) {
    if (stationThana == null || stationThana.isEmpty) {
      return list.cast<Map<String, dynamic>>();
    }
    final keywords = _thanaKeywords(stationThana);
    return list.cast<Map<String, dynamic>>().where((item) {
      final addr = (item['location_address'] as String? ?? '').toLowerCase();
      return keywords.any((kw) => addr.contains(kw));
    }).toList();
  }

  /// Maps each thana name to a list of known local landmarks, areas, and
  /// street names within that jurisdiction. Used by [_filterByThana] to match
  /// complaint addresses to the correct police station.
  ///
  /// Falls back to splitting the thana name into words (>3 chars) if no
  /// explicit mapping is found.
  List<String> _thanaKeywords(String thana) {
    const Map<String, List<String>> thanaKeywordsMap = {
      'Kotwali Model Thana': [
        'kotwali',
        'zindabazar',
        'dargah',
        'bandar bazar',
        'chowhatta',
        'mirabazar',
        'lamabazar',
        'osmani medical',
        'kajalshah'
      ],
      'Moglabazar Thana': [
        'moglabazar',
        'daudpur',
        'jalalpur',
        'kuchai',
        'silam'
      ],
      'South Surma Thana': [
        'south surma',
        'kadamtali',
        'boroikandi',
        'mominkhola',
        'shivbari',
        'babna',
        'kamalbazar',
        'leading university',
        'ragibnagar'
      ],
      'Shahporan Thana': [
        'shahporan',
        'shah poran',
        'tilagor',
        'baluchar',
        'khadimnagar',
        'uposhohor'
      ],
      'Jalalabad Thana': [
        'jalalabad',
        'akhalia',
        'sust',
        'kumargaon',
        'medina market',
        'housing estate'
      ],
      'Airport Thana': [
        'airport',
        'bimanbandar',
        'lakkatura',
        'osmani international',
        'dhopagul'
      ],
    };
    final lower = thana.toLowerCase();
    for (final entry in thanaKeywordsMap.entries) {
      if (entry.key.toLowerCase() == lower) return entry.value;
    }
    return lower.split(' ').where((w) => w.length > 3).toList();
  }
}
