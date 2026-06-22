import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService(ref.watch(sharedPreferencesProvider));
});

// NOTE: Credentials are stored in plaintext in SharedPreferences for auto-login
// convenience during the demo/development phase. In a production release these
// should be removed or replaced with a secure token/keychain solution.
class PreferencesService {
  final SharedPreferences _prefs;
  PreferencesService(this._prefs);
  static const _lastRouteKey = 'last_route';
  static const _savedEmailKey = 'saved_email';
  static const _savedPasswordKey = 'saved_password';
  static const _complaintDraftKey = 'complaint_draft';
  Future<void> saveComplaintDraft(Map<String, dynamic> draft) async {
    await _prefs.setString(_complaintDraftKey, jsonEncode(draft));
  }

  Map<String, dynamic>? getComplaintDraft() {
    final json = _prefs.getString(_complaintDraftKey);
    if (json == null) return null;
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearComplaintDraft() async {
    await _prefs.remove(_complaintDraftKey);
  }

  Future<void> saveLastRoute(String route) async {
    if (route == '/splash' ||
        route == '/login' ||
        route == '/register' ||
        route == '/forgot-password') {
      return;
    }
    await _prefs.setString(_lastRouteKey, route);
  }

  String? getLastRoute() {
    return _prefs.getString(_lastRouteKey);
  }

  Future<void> clearLastRoute() async {
    await _prefs.remove(_lastRouteKey);
  }

  Future<void> saveCredentials(String email, String password) async {
    await _prefs.setString(_savedEmailKey, email);
    await _prefs.setString(_savedPasswordKey, password);
  }

  String? getSavedEmail() {
    return _prefs.getString(_savedEmailKey);
  }

  String? getSavedPassword() {
    return _prefs.getString(_savedPasswordKey);
  }

  Future<void> clearCredentials() async {
    await _prefs.remove(_savedEmailKey);
    await _prefs.remove(_savedPasswordKey);
  }
}
