import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shieldx/common/core/constants/app_constants.dart';

class ConnectivityNotifier extends StateNotifier<bool> {
  Timer? _timer;
  bool _isChecking = false;
  ConnectivityNotifier() : super(true) {
    _startMonitoring();
  }
  void _startMonitoring() {
    checkConnection();
    _timer =
        Timer.periodic(const Duration(seconds: 6), (_) => checkConnection());
  }

  Future<bool> checkConnection() async {
    if (kIsWeb) {
      if (!state) {
        state = true;
      }
      return true;
    }
    if (_isChecking) return state;
    _isChecking = true;
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.supabaseUrl}/rest/v1/'),
        headers: {
          'apikey': AppConstants.supabaseAnonKey,
        },
      ).timeout(const Duration(seconds: 3));
      final isNowOnline =
          response.statusCode == 200 || response.statusCode == 401;
      if (state != isNowOnline) {
        state = isNowOnline;
      }
    } catch (e, stack) {
      debugPrint('Connectivity check failed with error: $e');
      debugPrint('Stacktrace: $stack');
      if (state) {
        state = false;
      }
    } finally {
      _isChecking = false;
    }
    return state;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  return ConnectivityNotifier();
});
