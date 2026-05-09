import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService(ref.watch(sharedPreferencesProvider));
});

class PreferencesService {
  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  static const _lastRouteKey = 'last_route';

  Future<void> saveLastRoute(String route) async {
    // Only save routes that make sense to restore
    if (route == '/splash' || route == '/login' || route == '/register' || route == '/forgot-password') {
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
}
