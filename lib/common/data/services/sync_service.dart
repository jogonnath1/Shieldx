import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldx/common/data/models/complaint_model.dart';
import 'package:shieldx/common/data/services/complaint_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();
  static const _outboxKey = 'offline_complaint_outbox';
  static const _userCachePrefix = 'cached_user_complaints_';
  static const _adminCacheKey = 'cached_admin_complaints';
  Future<void> cacheUserComplaints(
      String userId, List<ComplaintModel> complaints) async {
    final prefs = await _prefs;
    final key = '$_userCachePrefix$userId';
    final List<String> list = complaints.map((c) {
      final map = {
        'id': c.id,
        'user_id': c.userId,
        'first_name': c.firstName,
        'last_name': c.lastName,
        'phone': c.phone,
        'nid': c.nid,
        'profession': c.profession,
        'present_address': c.presentAddress,
        'permanent_address': c.permanentAddress,
        'crime_category': c.crimeCategory,
        'description': c.description,
        'latitude': c.latitude,
        'longitude': c.longitude,
        'location_address': c.locationAddress,
        'incident_datetime': c.incidentDatetime?.toIso8601String(),
        'status': c.status,
        'assigned_officer_id': c.assignedOfficerId,
        'evidence_urls': c.evidenceUrls,
        'created_at': c.createdAt?.toIso8601String(),
        'updated_at': c.updatedAt?.toIso8601String(),
        'assigned_officer_name': c.assignedOfficerName,
        'user_email': c.userEmail,
        'user_name': c.userName,
        'is_anonymous': c.isAnonymous,
      };
      return jsonEncode(map);
    }).toList();
    await prefs.setStringList(key, list);
  }

  Future<List<ComplaintModel>> getCachedUserComplaints(String userId) async {
    final prefs = await _prefs;
    final key = '$_userCachePrefix$userId';
    final list = prefs.getStringList(key) ?? [];
    return list.map((item) {
      final map = jsonDecode(item) as Map<String, dynamic>;
      return ComplaintModel.fromMap(map);
    }).toList();
  }

  Future<void> cacheAdminComplaints(List<ComplaintModel> complaints) async {
    final prefs = await _prefs;
    final List<String> list = complaints.map((c) {
      final map = {
        'id': c.id,
        'user_id': c.userId,
        'first_name': c.firstName,
        'last_name': c.lastName,
        'phone': c.phone,
        'nid': c.nid,
        'profession': c.profession,
        'present_address': c.presentAddress,
        'permanent_address': c.permanentAddress,
        'crime_category': c.crimeCategory,
        'description': c.description,
        'latitude': c.latitude,
        'longitude': c.longitude,
        'location_address': c.locationAddress,
        'incident_datetime': c.incidentDatetime?.toIso8601String(),
        'status': c.status,
        'assigned_officer_id': c.assignedOfficerId,
        'evidence_urls': c.evidenceUrls,
        'created_at': c.createdAt?.toIso8601String(),
        'updated_at': c.updatedAt?.toIso8601String(),
        'assigned_officer_name': c.assignedOfficerName,
        'user_email': c.userEmail,
        'user_name': c.userName,
        'is_anonymous': c.isAnonymous,
      };
      return jsonEncode(map);
    }).toList();
    await prefs.setStringList(_adminCacheKey, list);
  }

  Future<List<ComplaintModel>> getCachedAdminComplaints() async {
    final prefs = await _prefs;
    final list = prefs.getStringList(_adminCacheKey) ?? [];
    return list.map((item) {
      final map = jsonDecode(item) as Map<String, dynamic>;
      return ComplaintModel.fromMap(map);
    }).toList();
  }

  Future<void> addToOutbox(Map<String, dynamic> complaintData) async {
    final prefs = await _prefs;
    final outbox = prefs.getStringList(_outboxKey) ?? [];
    outbox.add(jsonEncode(complaintData));
    await prefs.setStringList(_outboxKey, outbox);
    debugPrint(
        'SYNC: Added complaint ${complaintData['id']} to offline outbox. Total: ${outbox.length}');
    final userId = complaintData['user_id'] as String?;
    if (userId != null) {
      final cached = await getCachedUserComplaints(userId);
      final fullData = {
        ...complaintData,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'offline_pending',
      };
      final offlineComplaint = ComplaintModel.fromMap(fullData);
      final updatedList = [offlineComplaint, ...cached];
      await cacheUserComplaints(userId, updatedList);
    }
  }

  Future<int> getOutboxCount() async {
    final prefs = await _prefs;
    final outbox = prefs.getStringList(_outboxKey) ?? [];
    return outbox.length;
  }

  Future<void> syncOfflineOutbox() async {
    final prefs = await _prefs;
    final outbox = prefs.getStringList(_outboxKey) ?? [];
    if (outbox.isEmpty) return;
    debugPrint(
        'SYNC: Starting background sync of ${outbox.length} offline complaints...');
    final remaining = <String>[];
    final complaintService = ComplaintService();
    for (final itemStr in outbox) {
      try {
        final data = jsonDecode(itemStr) as Map<String, dynamic>;
        final dataToSubmit = Map<String, dynamic>.from(data);
        if (dataToSubmit['status'] == 'offline_pending') {
          dataToSubmit.remove('status');
        }
        await complaintService.submitComplaint(dataToSubmit);
        debugPrint(
            'SYNC: Successfully synced offline complaint ${data['id']} to Supabase!');
      } catch (e) {
        debugPrint('SYNC: Failed to sync offline complaint: $e');
        remaining.add(itemStr);
      }
    }
    await prefs.setStringList(_outboxKey, remaining);
    debugPrint(
        'SYNC: Sync completed. Remaining in outbox: ${remaining.length}');
  }

  List<ComplaintModel> filterComplaintsByThana(
      List<ComplaintModel> list, String? stationThana) {
    if (stationThana == null || stationThana.isEmpty) {
      return list;
    }
    final keywords = _thanaKeywords(stationThana);
    return list.where((c) {
      final addr = (c.locationAddress ?? '').toLowerCase();
      return keywords.any((kw) => addr.contains(kw));
    }).toList();
  }

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
