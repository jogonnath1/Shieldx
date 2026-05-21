import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/profile_model.dart';
import '../data/services/auth_service.dart';
import '../core/services/preferences_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.session?.user,
    loading: () => Supabase.instance.client.auth.currentUser,
    error: (_, __) => null,
  );
});

final currentProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final service = ref.read(authServiceProvider);
  return await service.getCurrentProfile();
});

class AuthNotifier extends StateNotifier<AsyncValue<ProfileModel?>> {
  final AuthService _service;
  final Ref _ref;

  AuthNotifier(this._service, this._ref) : super(const AsyncValue.loading()) {
    _init();
    
    // Listen to Supabase auth state changes to stay in sync automatically
    _service.authStateChanges.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
        if (state.valueOrNull == null && !state.isLoading) {
          refresh();
        }
      } else if (event == AuthChangeEvent.signedOut) {
        state = const AsyncValue.data(null);
      }
    });
  }

  Future<void> _init() async {
    try {
      // 1. Try to fetch the active session profile
      var profile = await _service.getCurrentProfile();
      
      // 2. If no active session, check for saved credentials
      if (profile == null) {
        final prefs = _ref.read(preferencesServiceProvider);
        final email = prefs.getSavedEmail();
        final password = prefs.getSavedPassword();
        
        if (email != null && password != null) {
          // Perform background sign in
          await _service.signIn(email: email, password: password);
          profile = await _service.getCurrentProfile();
        }
      }
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _service.signIn(email: email, password: password);
      final profile = await _service.getCurrentProfile();
      state = AsyncValue.data(profile);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow; // let the UI show the real error
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? nid,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.signUp(
          email: email, password: password, name: name, phone: phone, nid: nid);
      
      // If Supabase auto-logins after signup, fetch the profile
      if (_service.isLoggedIn) {
        final profile = await _service.getCurrentProfile();
        state = AsyncValue.data(profile);
      } else {
        state = const AsyncValue.data(null);
      }
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<Map<String, bool>> checkContactExists({
    required String email,
    required String phone,
  }) async {
    return await _service.checkContactExists(email: email, phone: phone);
  }

  Future<void> sendPhoneOtp(String phone) async {
    try {
      await _service.sendPhoneOtp(phone);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> verifyPhoneOtp(String phone, String token) async {
    try {
      await _service.verifyPhoneOtp(phone, token);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveMockOtp(String phone, String otp) async {
    try {
      await _service.saveMockOtp(phone, otp);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> verifyMockOtp(String phone, String otp) async {
    try {
      return await _service.verifyMockOtp(phone, otp);
    } catch (e) {
      rethrow;
    }
  }



  Future<void> signOut() async {
    await _service.signOut();
    state = const AsyncValue.data(null);
    final prefs = _ref.read(preferencesServiceProvider);
    await prefs.clearLastRoute();
    await prefs.clearCredentials();
  }

  Future<void> refresh() async {
    try {
      final profile = await _service.getCurrentProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<ProfileModel?>>((ref) {
  return AuthNotifier(ref.read(authServiceProvider), ref);
});
